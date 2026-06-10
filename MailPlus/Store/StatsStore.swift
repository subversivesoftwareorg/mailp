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

    func activityHistory(for accountName: String? = nil, days: Int = 7) -> [ActivityRecord] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: .now)!
        let context = ModelContext(modelContainer)
        var descriptor = FetchDescriptor<ActivityRecord>(
            predicate: #Predicate { $0.timestamp >= cutoff },
            sortBy: [SortDescriptor(\.timestamp, order: .reverse)]
        )
        if let name = accountName {
            descriptor.predicate = #Predicate { $0.timestamp >= cutoff && $0.accountName == name }
        }
        return (try? context.fetch(descriptor)) ?? []
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
