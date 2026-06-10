import Testing
@testable import MailPlus

@Suite("MailPlus Tests")
struct MailPlusTests {

    @Test func snoozeDurationOneDay() {
        let now = Date(timeIntervalSince1970: 1_000_000)
        let wake = SnoozeDuration.oneDay.wakeDate(from: now)
        #expect(wake.timeIntervalSince(now) == 86400)
    }
}
