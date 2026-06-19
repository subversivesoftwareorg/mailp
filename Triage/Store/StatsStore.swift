import Foundation
import SwiftData

@Observable
@MainActor
final class StatsStore {
    var accounts: [AccountSnapshot] = []
    var isLoading = false
    var lastRefresh: Date?
    var errorMessage: String?

    private let queryService = MailQueryService()
    private var pollTask: Task<Void, Never>?
    private let modelContainer: ModelContainer

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Computed

    var totalUnread: Int {
        accounts.reduce(0) { $0 + $1.unreadCount }
    }

    var menuBarTitle: String {
        let count = totalUnread
        return count > 0 ? "\(count)" : ""
    }

    // MARK: - Polling

    func startPolling(interval: TimeInterval = Constants.defaultPollInterval) {
        stopPolling()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.refresh()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }

    // MARK: - Refresh

    @discardableResult
    func refresh() async -> Bool {
        isLoading = true
        defer { isLoading = false }

        do {
            accounts = try await queryService.fetchAccountStats()
            lastRefresh = .now
            errorMessage = nil
            persistSnapshots()
            return true
        } catch {
            errorMessage = error.localizedDescription
            return false
        }
    }

    // MARK: - History

    struct AggregatedRecord: Identifiable {
        let id: Date
        let period: Date
        let unreadCount: Int
        let totalInboxCount: Int
        let sentCount: Int
        let trashCount: Int
    }

    func activityHistory(for accountName: String? = nil, days: Int = 7) -> [AggregatedRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<ActivityRecord>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp, order: .forward)]
        )
        if let name = accountName {
            descriptor.predicate = #Predicate { $0.timestamp >= cutoff && $0.accountName == name }
        }
        let raw = (try? context.fetch(descriptor)) ?? []
        guard !raw.isEmpty else { return [] }

        let cal = Calendar.current
        let byHour = days <= 1

        var buckets: [Date: (unread: Int, inbox: Int, sent: Int, trash: Int, count: Int)] = [:]
        for r in raw {
            let period = byHour
                ? cal.date(from: cal.dateComponents([.year, .month, .day, .hour], from: r.timestamp))!
                : cal.startOfDay(for: r.timestamp)
            let cur = buckets[period] ?? (0, 0, 0, 0, 0)
            buckets[period] = (
                max(cur.unread, r.unreadCount),
                max(cur.inbox, r.totalInboxCount),
                max(cur.sent, r.sentCount),
                max(cur.trash, r.trashCount),
                cur.count + 1
            )
        }

        return buckets.map { (period, v) in
            AggregatedRecord(id: period, period: period,
                             unreadCount: v.unread, totalInboxCount: v.inbox,
                             sentCount: v.sent, trashCount: v.trash)
        }
        .sorted { $0.period > $1.period }
    }

    // MARK: - Day Summary

    struct DaySummary {
        let unreadChange: Int
        let inboxChange: Int
        let peakUnread: Int
        let snapshotCount: Int
    }

    func todaySummary() -> DaySummary? {
        let records = activityHistory(days: 1)
        guard let oldest = records.last, let newest = records.first else { return nil }

        return DaySummary(
            unreadChange: newest.unreadCount - oldest.unreadCount,
            inboxChange: newest.totalInboxCount - oldest.totalInboxCount,
            peakUnread: records.map(\.unreadCount).max() ?? 0,
            snapshotCount: records.count
        )
    }

    // MARK: - Private

    private func persistSnapshots() {
        let context = ModelContext(modelContainer)
        for account in accounts {
            let record = ActivityRecord(
                accountName: account.name,
                unreadCount: account.unreadCount,
                totalInboxCount: account.totalInboxCount
            )
            context.insert(record)
        }
        try? context.save()
    }
}
