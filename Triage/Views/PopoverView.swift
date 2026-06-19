import SwiftUI
import Sparkle

struct PopoverView: View {
    @Environment(StatsStore.self) private var store
    @Environment(KeyboardShortcutService.self) private var keyboardService
    @Environment(\.openWindow) private var openWindow
    let updater: SPUUpdater

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            menuItems
            Divider()
            footerRow
        }
        .frame(width: 260)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text("Triage")
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

    private var menuItems: some View {
        VStack(alignment: .leading, spacing: 2) {
            menuButton("Dashboard", icon: "square.grid.2x2") {
                openWindow(id: "dashboard")
                NSApp.activate(ignoringOtherApps: true)
            }

            shortcutToggle

            CheckForUpdatesView(updater: updater)
                .buttonStyle(MenuRowButtonStyle(icon: "arrow.triangle.2.circlepath"))
        }
        .padding(.vertical, 4)
    }

    private var footerRow: some View {
        HStack {
            if let lastRefresh = store.lastRefresh {
                Text("Updated \(lastRefresh, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Quit") { NSApp.terminate(nil) }
                .buttonStyle(.borderless)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Components

    private func menuButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(MenuRowButtonStyle())
    }

    private var shortcutToggle: some View {
        @Bindable var service = keyboardService
        return HStack(spacing: 6) {
            Label("Keyboard Shortcuts", systemImage: "keyboard")
            Spacer()
            if keyboardService.isEnabled && !keyboardService.isMonitoring {
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
                .help("Click to open Accessibility settings — add Triage to the list")
            }
            Toggle("", isOn: $service.isEnabled)
                .toggleStyle(.switch)
                .controlSize(.mini)
                .labelsHidden()
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }
}

struct MenuRowButtonStyle: ButtonStyle {
    var icon: String?

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 6) {
            if let icon {
                Image(systemName: icon)
                    .frame(width: 16)
            }
            configuration.label
            Spacer()
        }
        .font(.system(size: 13))
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(configuration.isPressed ? Color.accentColor.opacity(0.15) : .clear)
        .contentShape(Rectangle())
    }
}
