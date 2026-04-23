import XCTest
@testable import PolishPad

final class RuleBasedPolisherTests: XCTestCase {
    private let polisher = RuleBasedPolisher()

    func testEmailAddsNeutralGreetingAndClosing() {
        let output = polisher.polish(
            PolishRequest(
                input: "can we move tomorrow's meeting to friday afternoon",
                mode: .email,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertTrue(output.hasPrefix("Hi,"))
        XCTAssertTrue(output.contains("Can we move tomorrow's meeting to friday afternoon."))
        XCTAssertTrue(output.hasSuffix("Best,"))
    }

    func testEmailDoesNotDuplicateAddressedGreeting() {
        let output = polisher.polish(
            PolishRequest(
                input: "Hi Ryan,\ncan we move tomorrow's meeting to friday afternoon",
                mode: .email,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertFalse(output.hasPrefix("Hi,\n\nHi Ryan,"))
        XCTAssertTrue(output.hasPrefix("Hi Ryan,"))
        XCTAssertTrue(output.hasSuffix("Best,"))
    }

    func testMessageStaysCompact() {
        let output = polisher.polish(
            PolishRequest(
                input: "running 10 mins late see you soon",
                mode: .message,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertEqual(output, "Running 10 mins late see you soon.")
        XCTAssertFalse(output.contains("Hi,"))
        XCTAssertFalse(output.contains("Best,"))
    }

    func testNoteNormalizesBulletLists() {
        let output = polisher.polish(
            PolishRequest(
                input: "- call the pharmacy\n- book physio",
                mode: .note,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertEqual(output, "• Call the pharmacy.\n• Book physio.")
    }

    func testNotePreservesNumberedLists() {
        let output = polisher.polish(
            PolishRequest(
                input: "1. call the pharmacy\n2. book physio",
                mode: .note,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertEqual(output, "• Call the pharmacy.\n• Book physio.")
    }
}
