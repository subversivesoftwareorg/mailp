import Foundation
import SwiftData
import UserNotifications

@Observable
@MainActor
final class SnoozeService {
    var activeSnoozed: [SnoozedMessage] = []

    private let queryService = MailQueryService()
    private let modelContainer: ModelContainer
    private var checkTask: Task<Void, Never>?

    init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
    }

    // MARK: - Public

    func loadActive() {
        let context = ModelContext(modelContainer)
        let descriptor = FetchDescriptor<SnoozedMessage>(
            predicate: #Predicate { $0.isActive },
            sortBy: [SortDescriptor(\.wakeAt)]
        )
        activeSnoozed = (try? context.fetch(descriptor)) ?? []
    }

    func snooze(
        subject: String,
        accountName: String,
        mailbox: String,
        duration: SnoozeDuration,
        style: SnoozeStyle
    ) async throws {
        let wakeAt = duration.wakeDate()

        if style == .moveAndResurface {
            try await queryService.ensureSnoozeMailbox(account: accountName)
            try await queryService.moveMessageToMailbox(
                subject: subject,
                fromMailbox: mailbox,
                toMailbox: Constants.snoozeMailboxName,
                account: accountName
            )
        }

        let record = SnoozedMessage(
            messageSubject: subject,
            accountName: accountName,
            originalMailbox: mailbox,
            wakeAt: wakeAt,
            style: style
        )

        let context = ModelContext(modelContainer)
        context.insert(record)
        try context.save()

        scheduleNotification(for: record)
        loadActive()
    }

    func recordHold(subject: String, accountName: String, originalMailbox: String, duration: SnoozeDuration) {
        let record = SnoozedMessage(
            messageSubject: subject,
            accountName: accountName,
            originalMailbox: originalMailbox,
            wakeAt: duration.wakeDate(),
            style: .moveAndResurface
        )

        let context = ModelContext(modelContainer)
        context.insert(record)
        try? context.save()

        scheduleNotification(for: record)
        notifyHoldConfirmation(subject: subject, duration: duration)
        loadActive()
    }

    private func notifyHoldConfirmation(subject: String, duration: SnoozeDuration) {
        let content = UNMutableNotificationContent()
        content.title = "Held — \(duration.displayName)"
        content.body = subject
        content.sound = nil
        let request = UNNotificationRequest(
            identifier: "hold-confirm-\(Date.now.timeIntervalSince1970)",
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    func startChecking(interval: TimeInterval = 30) {
        loadActive()
        checkTask?.cancel()
        checkTask = Task { [weak self] in
            while !Task.isCancelled {
                await self?.processOverdue()
                try? await Task.sleep(for: .seconds(interval))
            }
        }
    }

    func stopChecking() {
        checkTask?.cancel()
        checkTask = nil
    }

    // MARK: - Private

    private func processOverdue() async {
        let context = ModelContext(modelContainer)
        let now = Date.now
        let descriptor = FetchDescriptor<SnoozedMessage>(
            predicate: #Predicate { $0.isActive && $0.wakeAt <= now }
        )
        guard let overdue = try? context.fetch(descriptor), !overdue.isEmpty else { return }

        for message in overdue {
            if message.snoozeStyle == .moveAndResurface {
                try? await queryService.moveMessageToMailbox(
                    subject: message.messageSubject,
                    fromMailbox: Constants.snoozeMailboxName,
                    toMailbox: message.originalMailbox,
                    account: message.accountName
                )
            }
            message.isActive = false
        }

        try? context.save()
        loadActive()
    }

    private func scheduleNotification(for message: SnoozedMessage) {
        let content = UNMutableNotificationContent()
        content.title = "Mail+ Reminder"
        content.body = message.messageSubject
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: max(1, message.wakeAt.timeIntervalSinceNow),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: "snooze-\(message.messageSubject.hashValue)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }
}
