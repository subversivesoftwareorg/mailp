import Foundation
import SwiftData

@Model
final class ActivityRecord {
    var accountName: String
    var timestamp: Date
    var unreadCount: Int
    var totalInboxCount: Int
    var sentCount: Int
    var trashCount: Int

    init(
        accountName: String,
        timestamp: Date = .now,
        unreadCount: Int = 0,
        totalInboxCount: Int = 0,
        sentCount: Int = 0,
        trashCount: Int = 0
    ) {
        self.accountName = accountName
        self.timestamp = timestamp
        self.unreadCount = unreadCount
        self.totalInboxCount = totalInboxCount
        self.sentCount = sentCount
        self.trashCount = trashCount
    }
}
