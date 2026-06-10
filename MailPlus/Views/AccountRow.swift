import SwiftUI

struct AccountRow: View {
    let account: AccountSnapshot

    var body: some View {
        HStack {
            Image(systemName: account.hasNewMail ? "envelope.badge.fill" : "envelope")
                .foregroundStyle(account.hasNewMail ? .blue : .secondary)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(account.name)
                    .font(.headline)
                if !account.email.isEmpty {
                    Text(account.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if account.unreadCount > 0 {
                    Text("\(account.unreadCount) unread")
                        .font(.callout.bold())
                        .foregroundStyle(.blue)
                }
                Text("\(account.totalInboxCount) in inbox")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
