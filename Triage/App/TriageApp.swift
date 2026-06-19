import SwiftUI
import SwiftData
import Sparkle

@main
struct TriageApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    private let updaterController = SPUStandardUpdaterController(
        startingUpdater: true, updaterDelegate: nil, userDriverDelegate: nil
    )

    let modelContainer: ModelContainer
    let statsStore: StatsStore
    let snoozeService: SnoozeService
    let keyboardService: KeyboardShortcutService

    init() {
        let schema = Schema([ActivityRecord.self, SnoozedMessage.self])
        let config = ModelConfiguration("Triage", schema: schema)
        let container = try! ModelContainer(for: schema, configurations: [config])

        let snooze = SnoozeService(modelContainer: container)
        let stats = StatsStore(modelContainer: container)

        self.modelContainer = container
        self.statsStore = stats
        self.snoozeService = snooze
        self.keyboardService = KeyboardShortcutService()

        DispatchQueue.main.async {
            stats.startPolling()
            snooze.startChecking()
        }
    }

    var body: some Scene {
        MenuBarExtra {
            PopoverView(updater: updaterController.updater)
                .environment(statsStore)
                .environment(keyboardService)
        } label: {
            Label(
                statsStore.totalUnread > 0 ? "\(statsStore.totalUnread)" : "",
                systemImage: statsStore.totalUnread > 0 ? "envelope.badge.fill" : "envelope"
            )
        }
        .menuBarExtraStyle(.window)

        Window("Triage Dashboard", id: "dashboard") {
            DashboardView(updater: updaterController.updater)
                .environment(statsStore)
                .environment(snoozeService)
                .modelContainer(modelContainer)
        }
        .defaultSize(width: 800, height: 500)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About Triage") { appDelegate.showAboutPanel(nil) }
            }
            CommandGroup(after: .appInfo) {
                CheckForUpdatesView(updater: updaterController.updater)
            }
        }
    }
}
