import SwiftUI

struct IntroView: View {
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Welcome to Triage")
                .font(.largeTitle.bold())

            Text("Power-user shortcuts for Mail.app")
                .font(.title3)
                .foregroundStyle(.secondary)

            HStack(spacing: 24) {
                introCard(
                    step: "1",
                    icon: "gearshape",
                    title: "Enable Shortcuts",
                    detail: "Click the Triage icon in your menu bar and flip the Keyboard Shortcuts toggle."
                )
                introCard(
                    step: "2",
                    icon: "lock.shield",
                    title: "Grant Access",
                    detail: "Allow Triage in System Settings > Privacy & Security > Accessibility so it can intercept keys."
                )
                introCard(
                    step: "3",
                    icon: "keyboard",
                    title: "Use in Mail.app",
                    detail: "Select a message and press a key:\nD delete  A archive  R reply\nF forward  H/J/K remind  \u{2318}S send"
                )
            }
            .padding(.horizontal, 24)

            Button("Get Started") {
                onDismiss()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)

            Spacer()
        }
        .padding()
    }

    private func introCard(step: String, icon: String, title: String, detail: String) -> some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(.blue.opacity(0.1))
                    .frame(width: 56, height: 56)
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
            }

            Text(title)
                .font(.headline)

            Text(detail)
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.quaternary.opacity(0.3), in: RoundedRectangle(cornerRadius: 12))
    }
}
