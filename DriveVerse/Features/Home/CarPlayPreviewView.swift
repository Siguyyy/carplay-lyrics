import SwiftUI

/// A local design preview that works in Simulator on iOS 17. It does not
/// pretend to be a connected CarPlay display or validate Live Activity routing.
struct CarPlayPreviewView: View {
    @EnvironmentObject private var model: AppModel
    @State private var dark = true

    var body: some View {
        ZStack {
            (dark ? Color(red: 0.035, green: 0.045, blue: 0.06) : Color(white: 0.90))
                .ignoresSafeArea()
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "car.side.fill")
                    Text("CarPlay")
                    Spacer()
                    Text("PREVIEW")
                        .font(.caption2.bold())
                        .tracking(1.4)
                        .padding(.horizontal, 10).padding(.vertical, 6)
                        .background(.white.opacity(0.1), in: Capsule())
                }
                .font(.headline)
                .padding(.horizontal, 24).padding(.vertical, 18)
                Spacer()
                VStack(alignment: .leading, spacing: 14) {
                    HStack(spacing: 10) {
                        Image(systemName: "waveform")
                            .foregroundStyle(.green)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(model.nowPlaying?.title ?? "Dreams")
                                .font(.subheadline.weight(.semibold)).lineLimit(1)
                            Text(model.nowPlaying?.artist ?? "Fleetwood Mac")
                                .font(.caption).foregroundStyle(.white.opacity(0.62)).lineLimit(1)
                        }
                        Spacer(minLength: 0)
                        Image(systemName: "music.note")
                            .foregroundStyle(.white.opacity(0.55))
                    }
                    Divider().overlay(.white.opacity(0.15))
                    Text(model.position?.currentLine ?? "Now here you go again")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .lineLimit(2).minimumScaleFactor(0.72)
                    Text(model.position?.nextLine ?? "You say you want your freedom")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(.white.opacity(0.58)).lineLimit(1)
                }
                .foregroundStyle(.white)
                .padding(24)
                .frame(maxWidth: 620, alignment: .leading)
                .background(.white.opacity(0.075), in: RoundedRectangle(cornerRadius: 26))
                Spacer()
                HStack {
                    Label("iOS 26+ displays Live Activities on CarPlay", systemImage: "info.circle")
                    Spacer()
                    Button { dark.toggle() } label: {
                        Image(systemName: dark ? "sun.max" : "moon")
                    }
                    .accessibilityLabel("Toggle preview appearance")
                }
                .font(.caption)
                .foregroundStyle(dark ? .white.opacity(0.68) : .black.opacity(0.65))
                .padding(.horizontal, 24).padding(.bottom, 18)
            }
            .padding(.horizontal, 18)
        }
        .navigationTitle("CarPlay Preview")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack { CarPlayPreviewView() }
        .environmentObject(AppModel.shared)
}
