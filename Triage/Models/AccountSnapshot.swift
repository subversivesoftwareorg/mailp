import Foundation

struct AccountSnapshot: Identifiable, Sendable {
    let id: String
    let name: String
    let email: String
    let unreadCount: Int
    let totalInboxCount: Int
    let timestamp: Date

    init(name: String, email: String, unreadCount: Int, totalInboxCount: Int, timestamp: Date = .now) {
        self.id = name
        self.name = name
        self.email = email
        self.unreadCount = unreadCount
        self.totalInboxCount = totalInboxCount
        self.timestamp = timestamp
    }

    var hasNewMail: Bool { unreadCount > 0 }
}
