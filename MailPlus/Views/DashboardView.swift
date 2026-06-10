import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(StatsStore.self) private var store
    @Environment(SnoozeService.self) private var snoozeService
    @State private var selectedAccountName: String?
    @State private var historyDays = 7

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            detailView
        }
        .navigationTitle("Mail+")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    Task { await store.refresh() }
                } label: {
                    Label("Refresh", systemImage: "arrow.clockwise")
                }
                .disabled(store.isLoading)
            }
        }
        .frame(minWidth: 600, minHeight: 400)
    }

    // MARK: - Sidebar

    private var sidebar: some View {
        List(selection: $selectedAccountName) {
            Section("Accounts") {
                ForEach(store.accounts) { account in
                    AccountRow(account: account)
                        .tag(account.name)
                }
            }

            if !snoozeService.activeSnoozed.isEmpty {
                Section("Snoozed (\(snoozeService.activeSnoozed.count))") {
                    ForEach(snoozeService.activeSnoozed) { snoozed in
                        HStack {
                            Image(systemName: snoozed.snoozeStyle.systemImage)
                                .foregroundStyle(.orange)
                            VStack(alignment: .leading) {
                                Text(snoozed.messageSubject)
                                    .lineLimit(1)
                                Text("Until \(snoozed.wakeAt, format: .dateTime.month().day().hour().minute())")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .frame(minWidth: 220)
    }

    // MARK: - Detail

    @ViewBuilder
    private var detailView: some View {
        if let name = selectedAccountName,
           let account = store.accounts.first(where: { $0.name == name }) {
            AccountDetailView(account: account, store: store, historyDays: $historyDays)
        } else {
            summaryView
        }
    }

    private var summaryView: some View {
        VStack(spacing: 16) {
            Image(systemName: "envelope.open")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("\(store.totalUnread) unread across \(store.accounts.count) accounts")
                .font(.title2)

            if let lastRefresh = store.lastRefresh {
                Text("Last updated \(lastRefresh, format: .relative(presentation: .named))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if let error = store.errorMessage {
                Label(error, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.orange)
                    .font(.caption)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
