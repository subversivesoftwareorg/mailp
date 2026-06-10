import AppKit
import ApplicationServices

@Observable
@MainActor
final class KeyboardShortcutService {

    var isEnabled = UserDefaults.standard.bool(forKey: Constants.keyboardShortcutsEnabled) {
        didSet {
            UserDefaults.standard.set(isEnabled, forKey: Constants.keyboardShortcutsEnabled)
            if isEnabled { startMonitoring() } else { stopMonitoring() }
        }
    }

    private(set) var isAccessibilityGranted = false
    private var monitor: Any?
    private let queryService = MailQueryService()
    private let snoozeService: SnoozeService

    // CGKeyCode values: a=0  d=2  f=3  h=4  r=15
    private static let keyActions: [UInt16: Action] = [
        0: .archive, 2: .delete, 3: .forward, 4: .hold, 15: .reply,
    ]

    enum Action {
        case delete, archive, reply, forward, hold
    }

    init(snoozeService: SnoozeService) {
        self.snoozeService = snoozeService
        if UserDefaults.standard.bool(forKey: Constants.keyboardShortcutsEnabled) {
            startMonitoring()
        }
    }

    // MARK: - Accessibility

    @discardableResult
    func checkAccessibility(prompt: Bool = true) -> Bool {
        let opts: NSDictionary = prompt
            ? [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true]
            : [:]
        isAccessibilityGranted = AXIsProcessTrustedWithOptions(opts)
        return isAccessibilityGranted
    }

    // MARK: - Monitoring

    private func startMonitoring() {
        guard checkAccessibility() else { return }
        stopMonitoring()

        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            MainActor.assumeIsolated {
                self?.handleKeyEvent(event)
            }
        }
    }

    private func stopMonitoring() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }

    // MARK: - Event handling

    private func handleKeyEvent(_ event: NSEvent) {
        guard NSWorkspace.shared.frontmostApplication?.bundleIdentifier == Constants.mailBundleID else { return }
        guard event.modifierFlags.intersection([.command, .control, .option]) .isEmpty else { return }
        guard let action = Self.keyActions[event.keyCode] else { return }
        guard !isTextInputFocused() else { return }

        perform(action)
    }

    private func isTextInputFocused() -> Bool {
        guard let app = NSWorkspace.shared.frontmostApplication else { return true }
        let axApp = AXUIElementCreateApplication(app.processIdentifier)

        var focused: AnyObject?
        guard AXUIElementCopyAttributeValue(axApp, kAXFocusedUIElementAttribute as CFString, &focused) == .success,
              let element = focused else {
            return true
        }

        var role: AnyObject?
        AXUIElementCopyAttributeValue(element as! AXUIElement, kAXRoleAttribute as CFString, &role)
        let roleStr = role as? String ?? ""

        if roleStr == kAXTextFieldRole as String
            || roleStr == kAXTextAreaRole as String
            || roleStr == "AXComboBox" {
            return true
        }

        // Web areas: only allow shortcuts if we can confirm the content is NOT editable.
        // Compose windows use an editable WebKit view; the message reader is read-only.
        // If the AX query fails, assume editable (safe — blocks shortcuts rather than
        // risking a stray Cmd+Delete in a compose window).
        if roleStr == "AXWebArea" {
            var settable: DarwinBoolean = false
            if AXUIElementIsAttributeSettable(element as! AXUIElement, kAXValueAttribute as CFString, &settable) == .success {
                return settable.boolValue
            }
            return true
        }

        return false
    }

    // MARK: - Actions

    private func perform(_ action: Action) {
        switch action {
        case .delete:
            postKeystroke(keyCode: 51, flags: .maskCommand)
        case .archive:
            postKeystroke(keyCode: 0, flags: [.maskControl, .maskCommand])
        case .reply:
            postKeystroke(keyCode: 15, flags: .maskCommand)
        case .forward:
            Task { try? await queryService.forwardSelectedMessage() }
        case .hold:
            Task { await holdSelectedMessage() }
        }
    }

    private func holdSelectedMessage() async {
        guard let msg = try? await queryService.fetchSelectedMessage() else { return }
        try? await snoozeService.snooze(
            subject: msg.subject,
            accountName: msg.accountName,
            mailbox: msg.mailboxName,
            duration: .oneDay,
            style: .moveAndResurface
        )
    }

    private func postKeystroke(keyCode: UInt16, flags: CGEventFlags) {
        let source = CGEventSource(stateID: .hidSystemState)
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false) else { return }
        down.flags = flags
        up.flags = flags
        down.post(tap: .cghidEventTap)
        up.post(tap: .cghidEventTap)
    }
}
