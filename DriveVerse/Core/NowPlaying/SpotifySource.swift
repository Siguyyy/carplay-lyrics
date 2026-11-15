import Foundation
import Combine

@MainActor
protocol SpotifyTokenProviding: AnyObject {
    var isConnected: Bool { get }
    func validAccessToken() async throws -> String
    func handleUnauthorized() async
}

extension SpotifyAuth: SpotifyTokenProviding {}

/// Polls the Spotify Web API's currently-playing endpoint. 5 s while Spotify
/// is playing, 15 s while idle-probing, per CLAUDE.md §4.3. Never talks to the
/// Spotify app — Web API only, Developer-Mode app, account owner.
final class SpotifySource: NowPlayingSource {
    static let endpoint = URL(string: "https://api.spotify.com/v1/me/player/currently-playing")!
    static let defaultActiveInterval: TimeInterval = 5
    static let idleInterval: TimeInterval = 15

    private let subject = CurrentValueSubject<NowPlayingState?, Never>(nil)
    var statePublisher: AnyPublisher<NowPlayingState?, Never> { subject.eraseToAnyPublisher() }

    private let session: URLSession
    private let tokenProvider: any SpotifyTokenProviding
    /// Settings-backed (3–10 s); read each cycle so changes apply immediately.
    var activeInterval: () -> TimeInterval = { SpotifySource.defaultActiveInterval }
    /// Human-readable, credential-free status for troubleshooting playback reads.
    var onDiagnostic: ((String, Date) -> Void)?
    private func report(_ message: String) { onDiagnostic?(message, Date()) }

    private var pollTask: Task<Void, Never>?

    init(session: URLSession = .shared, tokenProvider: any SpotifyTokenProviding) {
        self.session = session
        self.tokenProvider = tokenProvider
    }

    func start() {
        guard pollTask == nil else { return }
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                let cycleStartedAt = ProcessInfo.processInfo.systemUptime
                let delay = await self.pollOnce()
                // Keep the configured interval measured start-to-start rather
                // than adding network latency on top of every polling cycle.
                let elapsed = ProcessInfo.processInfo.systemUptime - cycleStartedAt
                let remaining = max(0, delay - elapsed)
                try? await Task.sleep(nanoseconds: UInt64(remaining * 1_000_000_000))
            }
        }
    }

    func stop() {
        pollTask?.cancel()
        pollTask = nil
    }

    /// Foreground resync: abandon the current sleep and poll immediately.
    func pollNow() {
        guard pollTask != nil else { return }
        stop()
        start()
    }

    /// One poll; returns the delay until the next one.
    func pollOnce() async -> TimeInterval {
        guard await tokenProvider.isConnected else {
            report("Not connected to Spotify. Reconnect from the app.")
            subject.send(nil)
            return Self.idleInterval
        }
        let token: String
        do {
            token = try await tokenProvider.validAccessToken()
        } catch {
            report("Could not get a Spotify access token: \(error.localizedDescription)")
            subject.send(nil)
            return Self.idleInterval
        }

        var request = URLRequest(url: Self.endpoint)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.timeoutInterval = 10

        do {
            let requestStartedAt = ProcessInfo.processInfo.systemUptime
            let (data, response) = try await session.data(for: request)
            guard let http = response as? HTTPURLResponse else { return Self.idleInterval }
            let responseTimeMs = Int((ProcessInfo.processInfo.systemUptime - requestStartedAt) * 1000)
            switch http.statusCode {
            case 200:
                let state = try Self.parseCurrentlyPlaying(data, capturedAt: Date())
                report(state == nil
                    ? "Spotify returned playback data without a track (possibly an ad or private session, \(responseTimeMs) ms)."
                    : "Playback detected (HTTP 200, \(responseTimeMs) ms).")
                subject.send(state)
                return state?.isPlaying == true ? activeInterval() : Self.idleInterval
            case 204: // nothing playing
                report("Spotify returned HTTP 204 (\(responseTimeMs) ms): no current playback is available to this account. Start playback on the connected account, then refresh.")
                subject.send(nil)
                return Self.idleInterval
            case 401:
                report("Spotify rejected the access token (HTTP 401). Refreshing authorization; reconnect if this persists.")
                await tokenProvider.handleUnauthorized()
                subject.send(nil)
                return Self.idleInterval
            case 429:
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
                report("Spotify rate limited playback checks (HTTP 429). Retrying after the server delay.")
                return max(retryAfter ?? Self.idleInterval, 1)
            case 403:
                report("Spotify denied playback access (HTTP 403). Check that this Spotify account is allowed by the developer app and that the playback-read permissions were approved.")
                subject.send(nil)
                return Self.idleInterval
            default:
                report("Spotify playback request failed (HTTP \(http.statusCode)).")
                subject.send(nil)
                return Self.idleInterval
            }
        } catch {
            // Transient network error (tunnel, dead zone) — just try again.
            report("Network or response error while checking Spotify: \(error.localizedDescription)")
            return Self.idleInterval
        }
    }

    // MARK: - Parsing (pure, fixture-tested)

    static func parseCurrentlyPlaying(_ data: Data, capturedAt: Date) throws -> NowPlayingState? {
        struct Payload: Decodable {
            struct Item: Decodable {
                struct Artist: Decodable { let name: String }
                struct Album: Decodable { let name: String? }
                let name: String
                let duration_ms: Int?
                let artists: [Artist]?
                let album: Album?
            }
            let progress_ms: Int?
            let is_playing: Bool?
            let item: Item?
        }

        let payload = try JSONDecoder().decode(Payload.self, from: data)
        guard let item = payload.item else { return nil } // e.g. private session or ad
        return NowPlayingState(
            title: item.name,
            artist: item.artists?.first?.name ?? "",
            album: item.album?.name,
            durationMs: item.duration_ms,
            positionMs: payload.progress_ms ?? 0,
            isPlaying: payload.is_playing ?? false,
            source: .spotify,
            capturedAt: capturedAt
        )
    }
}
