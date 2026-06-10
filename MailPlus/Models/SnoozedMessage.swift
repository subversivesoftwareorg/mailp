import Foundation
import SwiftData

enum SnoozeStyle: String, Codable, Sendable {
    case moveAndResurface
    case notifyOnly

    var displayName: String {
        switch self {
        case .moveAndResurface: "Hide & Resurface"
        case .notifyOnly: "Notify Only"
        }
    }

    var systemImage: String {
        switch self {
        case .moveAndResurface: "moon.zzz.fill"
        case .notifyOnly: "bell.fill"
        }
    }
}

enum SnoozeDuration: String, CaseIterable, Sendable {
    case oneDay = "1d"
    case threeDays = "3d"
    case oneWeek = "7d"
    case nextMonday = "monday"

    var displayName: String {
        switch self {
        case .oneDay: "1 Day"
        case .threeDays: "3 Days"
        case .oneWeek: "1 Week"
        case .nextMonday: "Next Monday"
        }
    }

    func wakeDate(from now: Date = .now) -> Date {
        let calendar = Calendar.current
        switch self {
        case .oneDay:
            return calendar.date(byAdding: .day, value: 1, to: now)!
        case .threeDays:
            return calendar.date(byAdding: .day, value: 3, to: now)!
        case .oneWeek:
            return calendar.date(byAdding: .day, value: 7, to: now)!
        case .nextMonday:
            let weekday = calendar.component(.weekday, from: now)
            let daysUntilMonday = (9 - weekday) % 7
            let days = daysUntilMonday == 0 ? 7 : daysUntilMonday
            let monday = calendar.date(byAdding: .day, value: days, to: now)!
            return calendar.date(bySettingHour: 9, minute: 0, second: 0, of: monday)!
        }
    }
}

@Model
final class SnoozedMessage {
    var messageSubject: String
    var accountName: String
    var originalMailbox: String
    var snoozedAt: Date
    var wakeAt: Date
    var style: String
    var isActive: Bool

    init(
        messageSubject: String,
        accountName: String,
        originalMailbox: String,
        snoozedAt: Date = .now,
        wakeAt: Date,
        style: SnoozeStyle,
        isActive: Bool = true
    ) {
        self.messageSubject = messageSubject
        self.accountName = accountName
        self.originalMailbox = originalMailbox
        self.snoozedAt = snoozedAt
        self.wakeAt = wakeAt
        self.style = style.rawValue
        self.isActive = isActive
    }

    var snoozeStyle: SnoozeStyle {
        SnoozeStyle(rawValue: style) ?? .notifyOnly
    }

    var isOverdue: Bool {
        isActive && wakeAt <= .now
    }
}
