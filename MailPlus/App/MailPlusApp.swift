import SwiftUI
import SwiftData

@main
struct MailPlusApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    let modelContainer: ModelContainer
    let statsStore: StatsStore
    let snoozeService: SnoozeService

    init() {
        let schema = Schema([ActivityRecord.self, SnoozedMessage.self])
        let config = ModelConfiguration("MailPlus", schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [config])

        self.modelContainer = container
        self.statsStore = StatsStore(modelContainer: container)
        self.snoozeService = SnoozeService(modelContainer: container)
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView()
                .environment(statsStore)
        } label: {
            Label(
                statsStore.totalUnread > 0 ? "\(statsStore.totalUnread)" : "",
                systemImage: statsStore.totalUnread > 0 ? "envelope.badge.fill" : "envelope"
            )
        }
        .menuBarExtraStyle(.window)

        Window("Mail+ Dashboard", id: "dashboard") {
            DashboardView()
                .environment(statsStore)
                .environment(snoozeService)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 800, height: 500)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Mail+") { appDelegate.showAboutPanel(nil) }
            }
        }
    }
}
