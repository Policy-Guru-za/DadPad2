import XCTest
@testable import PolishPad

final class RuleBasedPolisherTests: XCTestCase {
    private let polisher = RuleBasedPolisher()

    func testEmailDoesNotInventGreetingOrClosing() {
        let output = polisher.polish(
            PolishRequest(
                input: "can we move tomorrow's meeting to friday afternoon",
                mode: .email,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertEqual(output, "Can we move tomorrow's meeting to friday afternoon.")
        XCTAssertFalse(output.contains("Hi,"))
        XCTAssertFalse(output.contains("Best,"))
    }

    func testEmailPreservesExistingAddressedGreetingWithoutAddingClosing() {
        let output = polisher.polish(
            PolishRequest(
                input: "Hi Ryan,\ncan we move tomorrow's meeting to friday afternoon",
                mode: .email,
                locale: Locale(identifier: "en_ZA")
            )
        )

        XCTAssertFalse(output.hasPrefix("Hi,\n\nHi Ryan,"))
        XCTAssertTrue(output.hasPrefix("Hi Ryan,"))
        XCTAssertFalse(output.hasSuffix("Best,"))
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

final class PolishPromptBuilderTests: XCTestCase {
    func testNoteInstructionsUseDadPadRefineContract() {
        let request = PolishRequest(
            input: "this is a rough note that needs cleaning up",
            mode: .note,
            locale: Locale(identifier: "en_ZA")
        )
        let instructions = PolishPromptBuilder.instructions(for: request)

        XCTAssertTrue(instructions.contains("Mode: REFINE"))
        XCTAssertTrue(instructions.contains("Make this sound like the same person, just clearer and cleaner."))
        XCTAssertTrue(instructions.contains("Keep the tone neutral and polished, not especially chatty, corporate, or terse."))
    }

    func testEmailInstructionsUseStrictProfessionalContract() {
        let request = PolishRequest(
            input: "please confirm monday still works",
            mode: .email,
            locale: Locale(identifier: "en_ZA")
        )
        let instructions = PolishPromptBuilder.instructions(for: request)

        XCTAssertTrue(instructions.contains("Mode: PROFESSIONAL"))
        XCTAssertTrue(instructions.contains("Do not add a greeting, sign-off, signature, subject line, or sender name unless it is already present in the input."))
        XCTAssertTrue(instructions.contains("Prefer professional choices"))
        XCTAssertFalse(instructions.contains("Add a neutral salutation"))
        XCTAssertFalse(instructions.contains("Add a simple natural closing"))
    }

    func testMessageInstructionsRetainConciseMessageIntent() {
        let request = PolishRequest(
            input: "running ten minutes late see you soon",
            mode: .message,
            locale: Locale(identifier: "en_ZA")
        )
        let instructions = PolishPromptBuilder.instructions(for: request)

        XCTAssertTrue(instructions.contains("Mode: MESSAGE"))
        XCTAssertTrue(instructions.contains("Rewrite the text as a concise message."))
        XCTAssertTrue(instructions.contains("Do not add unnecessary formality."))
        XCTAssertFalse(instructions.contains("Mode: CASUAL"))
    }

    func testUserInputUsesDadPadWrapper() {
        let request = PolishRequest(
            input: "source",
            mode: .note,
            locale: Locale(identifier: "en_ZA")
        )

        XCTAssertEqual(
            PolishPromptBuilder.userInput(for: request),
            "Rewrite the text below.\n\n[BEGIN TEXT]\nsource\n[END TEXT]"
        )
    }

    func testInstructionsForbidExplanationsLabelsAndMarkdownFences() {
        let instructions = PolishPromptBuilder.instructions(
            for: .note,
            structureIntent: PolishPromptBuilder.structureIntent(for: "source", mode: .note)
        )

        XCTAssertTrue(instructions.contains("No preamble, no labels, no explanations, no markdown fences, or commentary."))
    }

    func testGreetingAndSignOffInferEmailStructure() {
        let intent = PolishPromptBuilder.structureIntent(
            for: "Hi Ryan,\n\nPlease send the final note today.\n\nBest,",
            mode: .email
        )
        let instructions = PolishPromptBuilder.instructions(for: .email, structureIntent: intent)

        XCTAssertEqual(intent.inferredContentType, .email)
        XCTAssertTrue(intent.shouldApplyGuidance)
        XCTAssertTrue(instructions.contains("Treat the input as a plain-text email body."))
    }

    func testBulletListInfersNoteStructureAndPreservesLists() {
        let intent = PolishPromptBuilder.structureIntent(
            for: "- call the pharmacy\n- book physio",
            mode: .note
        )
        let instructions = PolishPromptBuilder.instructions(for: .note, structureIntent: intent)

        XCTAssertEqual(intent.inferredContentType, .note)
        XCTAssertEqual(intent.targetShape, .bullets)
        XCTAssertTrue(intent.preserveExistingLists)
        XCTAssertTrue(instructions.contains("Preserve existing readable bullets or numbering; improve spacing only."))
    }

    func testDenseSingleBlockGetsParagraphGuidance() {
        let input = "We had a useful meeting yesterday but there are still a number of items that need to be clarified before we can move forward with the launch plan. Please confirm the budget, share the updated timing, and let me know who will own the final review before Friday."
        let intent = PolishPromptBuilder.structureIntent(for: input, mode: .note)
        let instructions = PolishPromptBuilder.instructions(for: .note, structureIntent: intent)

        XCTAssertEqual(intent.inferredContentType, .note)
        XCTAssertEqual(intent.targetShape, .paragraphs)
        XCTAssertTrue(intent.shouldApplyGuidance)
        XCTAssertTrue(instructions.contains("Treat the input as a plain-text note."))
        XCTAssertFalse(instructions.contains("Treat the input as a plain-text message."))
        XCTAssertTrue(instructions.contains("Do not return one long block when the content clearly contains separate ideas."))
    }

    func testDenseEmailModePlainProseDoesNotInferMessageStructure() {
        let input = "We had a useful meeting yesterday but there are still a number of items that need to be clarified before we can move forward with the launch plan. Please confirm the budget, share the updated timing, and let me know who will own the final review before Friday."
        let intent = PolishPromptBuilder.structureIntent(for: input, mode: .email)
        let instructions = PolishPromptBuilder.instructions(for: .email, structureIntent: intent)

        XCTAssertEqual(intent.inferredContentType, .note)
        XCTAssertTrue(intent.shouldApplyGuidance)
        XCTAssertTrue(instructions.contains("Treat the input as a plain-text note."))
        XCTAssertFalse(instructions.contains("Treat the input as a plain-text message."))
    }

    func testShortMessageDoesNotAddStructureGuidance() {
        let intent = PolishPromptBuilder.structureIntent(
            for: "can you send the file today",
            mode: .message
        )
        let instructions = PolishPromptBuilder.instructions(for: .message, structureIntent: intent)

        XCTAssertEqual(intent.targetShape, .paragraphs)
        XCTAssertFalse(intent.shouldApplyGuidance)
        XCTAssertFalse(instructions.contains("Structure guidance:"))
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
