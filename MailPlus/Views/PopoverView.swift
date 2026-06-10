import SwiftUI

struct PopoverView: View {
    @Environment(StatsStore.self) private var store
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            Divider()
            accountList
            Divider()
            footer
        }
        .frame(width: 320)
    }

    // MARK: - Sections

    private var header: some View {
        HStack {
            Text("Mail+")
                .font(.headline)
            Spacer()
            if store.isLoading {
                ProgressView()
                    .scaleEffect(0.6)
            }
            Button {
                Task { await store.refresh() }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
        }
        .padding(12)
    }

    @ViewBuilder
    private var accountList: some View {
        if let error = store.errorMessage {
            VStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle")
                    .font(.title2)
                    .foregroundStyle(.orange)
                Text(error)
                    .font(.caption)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
        } else if store.accounts.isEmpty && !store.isLoading {
            Text("No accounts found")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding()
                .frame(maxWidth: .infinity)
        } else {
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(store.accounts) { account in
                        AccountRow(account: account)
                            .padding(.horizontal, 12)
                        if account.id != store.accounts.last?.id {
                            Divider().padding(.leading, 48)
                        }
                    }
                }
            }
            .frame(maxHeight: 300)
        }
    }

    private var footer: some View {
        HStack {
            if let lastRefresh = store.lastRefresh {
                Text("Updated \(lastRefresh, format: .relative(presentation: .named))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            Button("Open Dashboard") {
                openWindow(id: "dashboard")
                NSApp.activate(ignoringOtherApps: true)
            }
            .buttonStyle(.borderless)
            .font(.caption)
        }
        .padding(12)
    }
}
