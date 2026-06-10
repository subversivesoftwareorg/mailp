import Foundation

final class MailQueryService: Sendable {

    // MARK: - Account Queries

    func fetchAccountStats() async throws -> [AccountSnapshot] {
        let script = """
        tell application "Mail"
            set output to ""
            repeat with acct in every account
                set acctName to name of acct
                set acctEmail to email addresses of acct
                set firstEmail to ""
                if (count of acctEmail) > 0 then
                    set firstEmail to item 1 of acctEmail
                end if
                set inBox to inbox of acct
                set unreadNum to unread count of inBox
                set msgCount to count of messages of inBox
                set sentBox to sent mailbox of acct
                set sentNum to count of messages of sentBox
                set trashBox to trash mailbox of acct
                set trashNum to count of messages of trashBox
                set output to output & acctName & "\\t" & firstEmail & "\\t" & unreadNum & "\\t" & msgCount & "\\t" & sentNum & "\\t" & trashNum & linefeed
            end repeat
            return output
        end tell
        """
        let output = try await runAppleScript(script)
        return Self.parseAccountOutput(output)
    }

    // MARK: - Message Operations

    func moveMessageToMailbox(subject: String, fromMailbox: String, toMailbox: String, account: String) async throws {
        let script = """
        tell application "Mail"
            set acct to account "\(Self.escaped(account))"
            set srcBox to mailbox "\(Self.escaped(fromMailbox))" of acct
            set destBox to mailbox "\(Self.escaped(toMailbox))" of acct
            set matchingMessages to (every message of srcBox whose subject is "\(Self.escaped(subject))")
            repeat with msg in matchingMessages
                move msg to destBox
            end repeat
        end tell
        """
        _ = try await runAppleScript(script)
    }

    func ensureSnoozeMailbox(account: String) async throws {
        let script = """
        tell application "Mail"
            set acct to account "\(Self.escaped(account))"
            set boxNames to name of every mailbox of acct
            if boxNames does not contain "\(Constants.snoozeMailboxName)" then
                make new mailbox with properties {name:"\(Constants.snoozeMailboxName)"} at acct
            end if
        end tell
        """
        _ = try await runAppleScript(script)
    }

    // MARK: - Private

    private func runAppleScript(_ source: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", source]

            let stdout = Pipe()
            let stderr = Pipe()
            process.standardOutput = stdout
            process.standardError = stderr

            process.terminationHandler = { proc in
                let data = stdout.fileHandleForReading.readDataToEndOfFile()
                if proc.terminationStatus == 0, let output = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: output.trimmingCharacters(in: .whitespacesAndNewlines))
                } else {
                    let errData = stderr.fileHandleForReading.readDataToEndOfFile()
                    let errMsg = String(data: errData, encoding: .utf8) ?? "osascript failed"
                    continuation.resume(throwing: MailQueryError.scriptFailed(errMsg))
                }
            }

            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }

    private static func parseAccountOutput(_ output: String) -> [AccountSnapshot] {
        output
            .split(separator: "\n", omittingEmptySubsequences: true)
            .compactMap { line -> AccountSnapshot? in
                let parts = line.split(separator: "\t", omittingEmptySubsequences: false).map(String.init)
                guard parts.count >= 4 else { return nil }
                return AccountSnapshot(
                    name: parts[0],
                    email: parts.count > 1 ? parts[1] : "",
                    unreadCount: Int(parts[2]) ?? 0,
                    totalInboxCount: Int(parts[3]) ?? 0
                )
            }
    }

    private static func escaped(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
         .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

// MARK: - Errors

enum MailQueryError: Error, LocalizedError {
    case scriptFailed(String)

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let msg): "Mail+ query failed: \(msg)"
        }
    }
}
