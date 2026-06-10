import SwiftUI

struct PopoverView: View {
    @Environment(StatsStore.self) private var store
    @Environment(KeyboardShortcutService.self) private var keyboardService
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            footer
        }
        .frame(width: 280)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text("Mail+")
                .font(.headline)
            Spacer()
            if store.totalUnread > 0 {
                Text("\(store.totalUnread) unread")
                    .font(.subheadline.bold())
                    .foregroundStyle(.blue)
            } else {
                Text("Inbox zero")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            if store.isLoading {
                ProgressView()
                    .scaleEffect(0.5)
            }
        }
        .padding(12)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            shortcutToggle
            HStack {
                if let lastRefresh = store.lastRefresh {
                    Text("Updated \(lastRefresh, format: .relative(presentation: .named))")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Button("Dashboard") {
                    openWindow(id: "dashboard")
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(12)
    }

    private var shortcutToggle: some View {
        @Bindable var service = keyboardService
        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Toggle("Keyboard Shortcuts", isOn: $service.isEnabled)
                    .toggleStyle(.switch)
                    .controlSize(.mini)
                    .font(.caption)
                if keyboardService.isEnabled {
                    if keyboardService.isMonitoring {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                            .font(.caption2)
                            .help("Active — d/a/r/f/h shortcuts enabled in Mail.app")
                    } else {
                        Button {
                            keyboardService.openAccessibilitySettings()
                        } label: {
                            HStack(spacing: 2) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text("Grant Access")
                            }
                        }
                        .buttonStyle(.borderless)
                        .foregroundStyle(.orange)
                        .font(.caption2)
                        .help("Click to open Accessibility settings — add Mail+ to the list")
                    }
                }
            }
        }
    }
}
