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

@MainActor
final class PolishWorkflowModelTests: XCTestCase {
    func testCancelStopsProcessingWithoutDroppingText() async {
        let model = PolishWorkflowModel(
            service: MockPolishService { request in
                try await Task.sleep(for: .seconds(5))
                return PolishResponse(text: request.input.uppercased(), capability: .foundationModel)
            }
        )

        model.sourceText = "rough text"
        model.polish(as: .note)

        await Task.yield()
        XCTAssertTrue(model.canCancel)

        model.cancelPolish()
        await settle()

        XCTAssertFalse(model.isProcessing)
        XCTAssertNil(model.activeMode)
        XCTAssertEqual(model.sourceText, "rough text")
        XCTAssertEqual(model.polishedText, "")
    }

    func testUndoRestoresPrePolishSnapshot() async {
        let model = PolishWorkflowModel(
            service: MockPolishService { _ in
                PolishResponse(text: "Cleaned up.", capability: .foundationModel)
            }
        )

        model.sourceText = "rough text"
        model.polish(as: .message)
        await settle()

        XCTAssertEqual(model.selectedSurface, .result)
        XCTAssertEqual(model.polishedText, "Cleaned up.")
        XCTAssertTrue(model.canUndo)

        model.undo()

        XCTAssertEqual(model.sourceText, "rough text")
        XCTAssertEqual(model.polishedText, "")
        XCTAssertEqual(model.selectedSurface, .draft)
        XCTAssertNil(model.lastCompletedMode)
    }

    func testUndoRestoresPreClearSnapshot() {
        let model = PolishWorkflowModel(service: MockPolishService())

        model.sourceText = "rough text"
        model.polishedText = "Cleaned up."
        model.selectedSurface = .result
        model.lastCompletedMode = .email

        model.clearAll()

        XCTAssertEqual(model.sourceText, "")
        XCTAssertEqual(model.polishedText, "")
        XCTAssertTrue(model.canUndo)

        model.undo()

        XCTAssertEqual(model.sourceText, "rough text")
        XCTAssertEqual(model.polishedText, "Cleaned up.")
        XCTAssertEqual(model.selectedSurface, .result)
        XCTAssertEqual(model.lastCompletedMode, .email)
    }

    func testPolishAutoSwitchesToResult() async {
        let model = PolishWorkflowModel(
            service: MockPolishService { _ in
                PolishResponse(text: "Cleaned up.", capability: .foundationModel)
            }
        )

        model.sourceText = "rough text"
        model.selectedSurface = .draft

        model.polish(as: .email)
        await settle()

        XCTAssertEqual(model.selectedSurface, .result)
        XCTAssertEqual(model.polishedText, "Cleaned up.")
        XCTAssertEqual(model.lastCompletedMode, .email)
    }

    func testDockAvailabilityAcrossStates() async {
        let model = PolishWorkflowModel(
            service: MockPolishService { request in
                try await Task.sleep(for: .milliseconds(40))
                return PolishResponse(text: request.input.uppercased(), capability: .foundationModel)
            }
        )

        XCTAssertFalse(model.canPolish)
        XCTAssertFalse(model.canCopy)
        XCTAssertFalse(model.canShare)
        XCTAssertFalse(model.canUndo)
        XCTAssertFalse(model.canCancel)

        model.sourceText = "rough text"
        XCTAssertTrue(model.canPolish)
        XCTAssertTrue(model.canClear)

        model.polish(as: .note)
        await Task.yield()

        XCTAssertFalse(model.canPolish)
        XCTAssertTrue(model.canCancel)

        await settle(milliseconds: 80)

        XCTAssertTrue(model.canCopy)
        XCTAssertTrue(model.canShare)
        XCTAssertTrue(model.canUndo)
        XCTAssertFalse(model.canCancel)
    }

    func testSharePayloadOnlyExistsWhenOutputExists() {
        let model = PolishWorkflowModel(service: MockPolishService())

        XCTAssertNil(model.sharePayload)

        model.polishedText = "Cleaned up."
        model.lastCompletedMode = .email

        XCTAssertEqual(model.sharePayload?.text, "Cleaned up.")
        XCTAssertEqual(model.sharePayload?.subject, "Polished email")
    }

    private func settle(milliseconds: UInt64 = 20) async {
        await Task.yield()
        try? await Task.sleep(for: .milliseconds(milliseconds))
        await Task.yield()
    }
}

private struct MockPolishService: PolishServicing {
    let capability: PolishCapability
    let polishHandler: @Sendable (PolishRequest) async throws -> PolishResponse

    init(
        capability: PolishCapability = .foundationModel,
        polishHandler: @escaping @Sendable (PolishRequest) async throws -> PolishResponse = { request in
            PolishResponse(text: request.input, capability: .foundationModel)
        }
    ) {
        self.capability = capability
        self.polishHandler = polishHandler
    }

    func capability(for locale: Locale) -> PolishCapability {
        capability
    }

    func polish(_ request: PolishRequest) async throws -> PolishResponse {
        try await polishHandler(request)
    }
}
