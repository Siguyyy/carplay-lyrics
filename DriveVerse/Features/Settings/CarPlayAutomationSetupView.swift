import SwiftUI
import AppIntents
import UIKit

struct CarPlayAutomationSetupView: View {
    private let ink = Color(red: 0.10, green: 0.12, blue: 0.18)
    private let violet = Color(red: 0.48, green: 0.36, blue: 0.96)

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                hero
                Label {
                    Text("Before setting this up, turn Drive Mode on once while Simon’s Karaoke is open. Follow the location prompts and choose Always so the CarPlay automation can start it in the background. You can turn Drive Mode back off afterward.")
                } icon: {
                    Image(systemName: "location.fill")
                        .foregroundStyle(violet)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))

                ShortcutsLink(action: {})
                    .shortcutsLinkStyle(.automaticOutline)

                automationCard(
                    number: "01",
                    title: "When CarPlay connects",
                    subtitle: "Start lyrics automatically",
                    icon: "car.side.fill",
                    steps: [
                        "In Shortcuts, open Automation and tap +.",
                        "Choose CarPlay → Connects. Set it to run automatically (on older iOS versions, turn off Ask Before Running).",
                        "Choose New Blank Automation → Add Action. Search Simon’s Karaoke, add Start Drive Mode, then tap Done."
                    ],
                    tint: violet
                )

                automationCard(
                    number: "02",
                    title: "When CarPlay disconnects",
                    subtitle: "Stop background tracking",
                    icon: "car.side.arrow.up.right",
                    steps: [
                        "Create another CarPlay automation and select Disconnects.",
                        "Set it to run automatically, add Simon’s Karaoke → Stop Drive Mode, then tap Done.",
                        "That’s it. Connect starts the lyrics session; disconnect stops Drive Mode and background tracking."
                    ],
                    tint: Color(red: 0.18, green: 0.66, blue: 0.56)
                )

                Label {
                    Text("This starts the lyrics Live Activity in the background. iOS controls what appears on the CarPlay screen; the automation cannot force Simon’s Karaoke to open as a CarPlay app.")
                } icon: {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(violet)
                }
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            }
            .padding(20)
        }
        .background(
            LinearGradient(colors: [Color(uiColor: .systemGroupedBackground), violet.opacity(0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
        )
        .navigationTitle("Automatic setup")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var hero: some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: "car.side.fill")
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(violet.gradient, in: RoundedRectangle(cornerRadius: 17))
            Text("Let CarPlay start the lyrics")
                .font(.system(size: 29, weight: .bold, design: .rounded))
                .foregroundStyle(ink)
                .fixedSize(horizontal: false, vertical: true)
            Text("Create two small Shortcuts automations once. They start Drive Mode when CarPlay connects and stop it when you leave.")
                .font(.body)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, 4)
    }

    private func automationCard(number: String, title: String, subtitle: String, icon: String, steps: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(tint)
                    .frame(width: 42, height: 42)
                    .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 13))
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline)
                    Text(subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                Text(number)
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(tint)
            }
            ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                HStack(alignment: .top, spacing: 11) {
                    Text("\(index + 1)")
                        .font(.caption.weight(.bold).monospacedDigit())
                        .foregroundStyle(tint)
                        .frame(width: 23, height: 23)
                        .background(tint.opacity(0.12), in: Circle())
                    Text(step)
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .padding(17)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(.white.opacity(0.35), lineWidth: 1))
        .shadow(color: ink.opacity(0.06), radius: 14, y: 7)
    }
}
