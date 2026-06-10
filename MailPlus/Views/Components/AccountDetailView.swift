import SwiftUI

struct AccountDetailView: View {
    let account: AccountSnapshot
    let store: StatsStore
    @Binding var historyDays: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            accountHeader
            statCards
            Divider()
            activitySection
            Spacer()
        }
        .padding()
    }

    // MARK: - Sections

    private var accountHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(account.name)
                    .font(.title)
                if !account.email.isEmpty {
                    Text(account.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
    }

    private var statCards: some View {
        HStack(spacing: 24) {
            StatCard(title: "Unread", value: "\(account.unreadCount)", icon: "envelope.badge", color: .blue)
            StatCard(title: "Inbox Total", value: "\(account.totalInboxCount)", icon: "tray.full", color: .green)
        }
    }

    private var activitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Activity History")
                    .font(.headline)
                Spacer()
                Picker("Period", selection: $historyDays) {
                    Text("24h").tag(1)
                    Text("7d").tag(7)
                    Text("30d").tag(30)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
            }

            let records = store.activityHistory(for: account.name, days: historyDays)
            if records.isEmpty {
                Text("No history yet — data is recorded as you use Mail+.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 40)
            } else {
                ActivityTableView(records: records, days: historyDays)
            }
        }
    }
}

// MARK: - Supporting Views

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            Text(value)
                .font(.system(.title, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 120, height: 100)
        .background(.quaternary.opacity(0.5), in: RoundedRectangle(cornerRadius: 12))
    }
}

struct ActivityTableView: View {
    let records: [StatsStore.AggregatedRecord]
    let days: Int

    private var periodFormat: Date.FormatStyle {
        if days <= 1 {
            return .dateTime.hour().minute()
        } else if days <= 7 {
            return .dateTime.weekday(.abbreviated).hour()
        } else {
            return .dateTime.month(.abbreviated).day()
        }
    }

    var body: some View {
        Table(records) {
            TableColumn("Period") { record in
                Text(record.period, format: periodFormat)
                    .font(.caption)
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 120)

            TableColumn("Unread") { record in
                Text("\(record.unreadCount)")
                    .monospacedDigit()
            }
            .width(60)

            TableColumn("Inbox") { record in
                Text("\(record.totalInboxCount)")
                    .monospacedDigit()
            }
            .width(60)

            TableColumn("Sent") { record in
                Text("\(record.sentCount)")
                    .monospacedDigit()
            }
            .width(60)

            TableColumn("Trash") { record in
                Text("\(record.trashCount)")
                    .monospacedDigit()
            }
            .width(60)
        }
    }
}
