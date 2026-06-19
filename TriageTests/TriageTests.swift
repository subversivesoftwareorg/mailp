import Foundation
import Testing
@testable import Triage

@Suite("Snooze Duration")
struct SnoozeDurationTests {

    @Test func oneDay() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let wake = SnoozeDuration.oneDay.wakeDate(from: now)
        #expect(wake.timeIntervalSince(now) == 86400)
    }

    @Test func threeDays() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let wake = SnoozeDuration.threeDays.wakeDate(from: now)
        #expect(wake.timeIntervalSince(now) == 86400 * 3)
    }

    @Test func oneWeek() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let wake = SnoozeDuration.oneWeek.wakeDate(from: now)
        #expect(wake.timeIntervalSince(now) == 86400 * 7)
    }

    @Test func nextMondayFromWednesday() {
        // 2026-01-07 is a Wednesday
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        let wed = cal.date(from: DateComponents(year: 2026, month: 1, day: 7, hour: 14))!
        let wake = SnoozeDuration.nextMonday.wakeDate(from: wed)
        let weekday = cal.component(.weekday, from: wake)
        #expect(weekday == 2) // Monday
        #expect(cal.component(.hour, from: wake) == 9)
        #expect(wake > wed)
    }
}

@Suite("Account Output Parsing")
struct AccountParsingTests {

    @Test func parsesMultipleAccounts() {
        let output = "iCloud\tuser@icloud.com\t3\t10\t5\t2\nGMail\tuser@gmail.com\t0\t50\t20\t8"
        let accounts = MailQueryService.parseAccountOutput(output)
        #expect(accounts.count == 2)
        #expect(accounts[0].name == "iCloud")
        #expect(accounts[0].email == "user@icloud.com")
        #expect(accounts[0].unreadCount == 3)
        #expect(accounts[0].totalInboxCount == 10)
        #expect(accounts[1].name == "GMail")
        #expect(accounts[1].unreadCount == 0)
    }

    @Test func handlesEmptyOutput() {
        let accounts = MailQueryService.parseAccountOutput("")
        #expect(accounts.isEmpty)
    }

    @Test func skipsMalformedLines() {
        let output = "iCloud\tuser@icloud.com\t3\t10\t5\t2\nbadline\nGMail\tuser@gmail.com\t0\t50\t20\t8"
        let accounts = MailQueryService.parseAccountOutput(output)
        #expect(accounts.count == 2)
    }
}

@Suite("Keyboard Shortcut Key Mapping")
struct KeyMappingTests {

    @Test func allShortcutKeysAreMapped() {
        // a=0, d=2, f=3, h=4, r=15, t=17, j=38, k=40, /=44
        #expect(KeyboardShortcutService.keyActions[0] == .archive)
        #expect(KeyboardShortcutService.keyActions[2] == .delete)
        #expect(KeyboardShortcutService.keyActions[3] == .forward)
        #expect(KeyboardShortcutService.keyActions[4] == .remindTonight)
        #expect(KeyboardShortcutService.keyActions[15] == .reply)
        #expect(KeyboardShortcutService.keyActions[17] == .createTask)
        #expect(KeyboardShortcutService.keyActions[38] == .remindTomorrow)
        #expect(KeyboardShortcutService.keyActions[40] == .remindLater)
        #expect(KeyboardShortcutService.keyActions[44] == .search)
    }

    @Test func unmappedKeysReturnNil() {
        #expect(KeyboardShortcutService.keyActions[1] == nil) // s
        #expect(KeyboardShortcutService.keyActions[5] == nil) // g
        #expect(KeyboardShortcutService.keyActions[99] == nil)
    }

    @Test func exactlyNineShortcuts() {
        #expect(KeyboardShortcutService.keyActions.count == 9)
    }

    @Test func cmdSKeyCodeIsNotInSingleKeyMap() {
        // keyCode 1 = S. Must NOT be in the single-key map (it's a Cmd+S remap, not a bare key)
        #expect(KeyboardShortcutService.keyActions[1] == nil)
    }
}

@Suite("Email Extraction")
struct EmailExtractionTests {

    @Test func extractsEmailFromNameAngleBrackets() {
        let email = MailQueryService.extractEmail(from: "John Doe <john@example.com>")
        #expect(email == "john@example.com")
    }

    @Test func extractsBareEmail() {
        let email = MailQueryService.extractEmail(from: "john@example.com")
        #expect(email == "john@example.com")
    }

    @Test func extractsEmailWithDisplayNameQuotes() {
        let email = MailQueryService.extractEmail(from: "\"Doe, John\" <john@example.com>")
        #expect(email == "john@example.com")
    }

    @Test func extractsDomainFromEmail() {
        let domain = MailQueryService.extractDomain(from: "john@example.com")
        #expect(domain == "@example.com")
    }

    @Test func extractsDomainFromSubdomain() {
        let domain = MailQueryService.extractDomain(from: "alerts@mail.example.com")
        #expect(domain == "@mail.example.com")
    }

    @Test func returnsNilDomainForBareString() {
        let domain = MailQueryService.extractDomain(from: "no-at-sign")
        #expect(domain == nil)
    }
}

@Suite("Mail URL Construction")
struct MailURLTests {

    @Test func constructsFromAngleBrackets() {
        let url = KeyboardShortcutService.mailURL(from: "<ABC123@mail.gmail.com>")
        #expect(url == "message://%3CABC123@mail.gmail.com%3E")
    }

    @Test func constructsFromBareID() {
        let url = KeyboardShortcutService.mailURL(from: "ABC123@mail.gmail.com")
        #expect(url == "message://%3CABC123@mail.gmail.com%3E")
    }

    @Test func handlesWhitespace() {
        let url = KeyboardShortcutService.mailURL(from: "  <ABC@test.com>  \n")
        #expect(url == "message://%3CABC@test.com%3E")
    }
}

@Suite("AccountSnapshot")
struct AccountSnapshotTests {

    @Test func hasNewMailWhenUnread() {
        let account = AccountSnapshot(name: "Test", email: "test@test.com", unreadCount: 5, totalInboxCount: 10)
        #expect(account.hasNewMail == true)
    }

    @Test func noNewMailWhenZero() {
        let account = AccountSnapshot(name: "Test", email: "test@test.com", unreadCount: 0, totalInboxCount: 10)
        #expect(account.hasNewMail == false)
    }

    @Test func idMatchesName() {
        let account = AccountSnapshot(name: "GMail", email: "", unreadCount: 0, totalInboxCount: 0)
        #expect(account.id == "GMail")
    }
}
