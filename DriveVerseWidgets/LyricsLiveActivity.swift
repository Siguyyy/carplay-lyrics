#if canImport(ActivityKit) && canImport(WidgetKit)
import WidgetKit
import SwiftUI
import ActivityKit

@main
struct DriveVerseWidgetsBundle: WidgetBundle {
    var body: some Widget {
        LyricsLiveActivity()
    }
}

struct LyricsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LyricsAttributes.self) { context in
            SmallAwareLyricsView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                        .font(.title3)
                        .foregroundStyle(.tint)
                        .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(context.state.currentLine)
                            .font(.headline)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                        Text(context.state.nextLine)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                DynamicIslandExpandedRegion(.bottom) {
                    ProgressView(value: context.state.progress)
                        .tint(.white.opacity(0.85))
                        .padding(.horizontal, 4)
                }
            } compactLeading: {
                Text(context.state.currentLine)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: 120, alignment: .leading)
            } compactTrailing: {
                EmptyView()
            } minimal: {
                Image(systemName: "music.note")
                    .font(.caption2)
                    .foregroundStyle(.tint)
            }
        }
        .supplementalActivityFamilies([.small])
    }
}

@available(iOS 18.0, *)
private struct SmallAwareLyricsView: View {
    @Environment(\.activityFamily) private var activityFamily
    let context: ActivityViewContext<LyricsAttributes>

    var body: some View {
        if activityFamily == .small {
            VStack(alignment: .leading, spacing: 3) {
                if context.state.lyricsFocus != true && context.state.currentLine.count <= 58 {
                    HStack(spacing: 4) {
                        Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                            .font(.system(size: 9, weight: .semibold))
                        Text(context.state.title)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                    }
                    .foregroundStyle(.secondary)
                }

                Text(context.state.currentLine)
                    .font(.system(size: 16, weight: .bold))
                    .lineLimit(context.state.lyricsFocus == true || context.state.currentLine.count > 58 ? nil : 3)
                    .fixedSize(
                        horizontal: false,
                        vertical: context.state.lyricsFocus == true || context.state.currentLine.count > 58
                    )

                if !context.state.nextLine.isEmpty && context.state.currentLine.count < 58 {
                    Text(context.state.nextLine)
                        .font(.system(size: context.state.lyricsFocus == true ? 16 : 12))
                        .foregroundStyle(.secondary)
                        .lineLimit(context.state.lyricsFocus == true ? 2 : 1)
                        .fixedSize(horizontal: false, vertical: context.state.lyricsFocus == true)
                }
                if context.state.lyricsFocus == true,
                   let nextNextLine = context.state.nextNextLine,
                   !nextNextLine.isEmpty,
                   context.state.currentLine.count + context.state.nextLine.count < 92 {
                    Text(nextNextLine)
                        .font(.system(size: 16))
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, 8)
            .activityBackgroundTint(Color.black.opacity(0.75))
            .activitySystemActionForegroundColor(.white)
        } else {
            LockScreenLyricsView(context: context)
        }
    }
}

struct LockScreenLyricsView: View {
    let context: ActivityViewContext<LyricsAttributes>

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: context.state.isPlaying ? "music.note" : "pause.fill")
                    .font(.caption2)
                Text(context.state.artist.isEmpty
                     ? context.state.title
                     : "\(context.state.title) — \(context.state.artist)")
                    .font(.caption)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if !context.state.sourceName.isEmpty {
                    Text(context.state.sourceName)
                        .font(.caption2.bold())
                        .lineLimit(1)
                }
            }
            .foregroundStyle(.secondary)

            Text(context.state.currentLine)
                .font(.title2.bold())
                .lineLimit(2)
                .minimumScaleFactor(0.72)

            Text(context.state.nextLine)
                .font(.callout)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(14)
        .activityBackgroundTint(Color.black.opacity(0.75))
        .activitySystemActionForegroundColor(.white)
    }
}
#endif
