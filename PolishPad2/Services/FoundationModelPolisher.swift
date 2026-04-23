import Foundation
import FoundationModels

@Generable(description: "The final polished rewrite for the user.")
private struct PolishedTextPayload {
    @Guide(description: "Only the rewritten text. No explanations, labels, markdown fences, or commentary.")
    let text: String
}

struct FoundationModelPolisher: Sendable {
    private let model = SystemLanguageModel.default

    func capability(for locale: Locale) -> PolishCapability {
        guard model.supportsLocale(locale) else {
            return .basicFormatter(
                reason: "This device language is not currently supported by Apple’s on-device model. Using a basic local formatter instead."
            )
        }

        switch model.availability {
        case .available:
            return .foundationModel
        case .unavailable(.deviceNotEligible):
            return .basicFormatter(
                reason: "Full polish needs Apple Intelligence on a supported iPad. Basic local formatting is still available."
            )
        case .unavailable(.appleIntelligenceNotEnabled):
            return .basicFormatter(
                reason: "Turn on Apple Intelligence in Settings for full polish. Basic local formatting remains available."
            )
        case .unavailable(.modelNotReady):
            return .basicFormatter(
                reason: "The on-device model is still getting ready. Using a basic local formatter for now."
            )
        case .unavailable:
            return .basicFormatter(
                reason: "Full polish is unavailable right now. Using a basic local formatter instead."
            )
        }
    }

    func polish(_ request: PolishRequest) async throws -> PolishResponse {
        let session = LanguageModelSession(
            model: model,
            instructions: systemInstructions(for: request.mode)
        )

        let response = try await session.respond(
            to: prompt(for: request),
            generating: PolishedTextPayload.self,
            options: generationOptions(for: request.input)
        )

        let sanitized = sanitize(response.content.text)

        guard !sanitized.isEmpty else {
            throw PolishEngineError.processingFailed(
                "PolishPad returned an empty rewrite. Try adding a little more context."
            )
        }

        return PolishResponse(text: sanitized, capability: .foundationModel)
    }

    private func systemInstructions(for mode: PolishMode) -> String {
        """
        You rewrite rough dictated or typed text for a calm, private, on-device iPad writing utility.
        Preserve the writer’s intent.
        Correct grammar, spelling, punctuation, and paragraphing.
        Improve readability without becoming verbose.
        Never invent facts, names, dates, promises, or explanations.
        Return only the polished text.
        If the input is already clean, make minimal changes.
        \(mode.foundationInstructions)
        """
    }

    private func prompt(for request: PolishRequest) -> String {
        """
        Rewrite this text as a \(request.mode.shortTitle.lowercased()).

        Input:
        \(request.input)
        """
    }

    private func generationOptions(for input: String) -> GenerationOptions {
        let estimatedTokens = max(192, min(1_200, (input.count / 3) + 160))
        return GenerationOptions(
            sampling: .greedy,
            maximumResponseTokens: estimatedTokens
        )
    }

    private func sanitize(_ text: String) -> String {
        var output = text.replacingOccurrences(of: "\r\n", with: "\n")
        output = output.replacingOccurrences(
            of: #"^```[A-Za-z0-9_-]*\n?"#,
            with: "",
            options: .regularExpression
        )
        output = output.replacingOccurrences(
            of: #"\n?```$"#,
            with: "",
            options: .regularExpression
        )
        return output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
