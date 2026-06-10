import MailKit

final class MailPlusExtension: NSObject, MEExtension {

    func handler(for session: MEComposeSession) -> MEComposeSessionHandler {
        ComposeHandler()
    }
}

final class ComposeHandler: NSObject, MEComposeSessionHandler {

    func mailComposeSessionDidBegin(_ session: MEComposeSession) {}

    func mailComposeSessionDidEnd(_ session: MEComposeSession) {}

    func viewController(for session: MEComposeSession) -> MEExtensionViewController {
        MEExtensionViewController()
    }

    func allowMessageSendForSession(_ session: MEComposeSession, completion: @escaping (Error?) -> Void) {
        completion(nil)
    }
}
