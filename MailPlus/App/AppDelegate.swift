import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {

    @objc func showAboutPanel(_ sender: Any?) {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"

        let credits = NSAttributedString(
            string: """
            Power tools for Mail.app
            Account stats, activity tracking, and snooze for your inbox.

            Subversive Software builds tools that put power back in people's hands.
            \u{00A9} 2026 subversivesoftware.org
            """,
            attributes: [.font: NSFont.systemFont(ofSize: 11)]
        )

        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "Mail+",
            .applicationVersion: version,
            .version: build,
            .credits: credits,
        ])
    }
}
