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
            return .unavailable(
                reason: "PolishPad requires Apple Intelligence in a supported language. Change the device and Siri language to a supported language to polish text."
            )
        }

        switch model.availability {
        case .available:
            return .foundationModel
        case .unavailable(.deviceNotEligible):
            return .unavailable(
                reason: "PolishPad requires Apple Intelligence on a compatible iPad: iPad mini (A17 Pro) or an iPad with M1 or later."
            )
        case .unavailable(.appleIntelligenceNotEnabled):
            return .unavailable(
                reason: "Turn on Apple Intelligence in Settings to polish text with PolishPad."
            )
        case .unavailable(.modelNotReady):
            return .unavailable(
                reason: "Apple Intelligence is still getting ready. Keep the iPad on Wi-Fi and power, then try again after the model finishes downloading."
            )
        case .unavailable:
            return .unavailable(
                reason: "Apple Intelligence is unavailable right now. PolishPad can polish text when the on-device model is available."
            )
        }
    }

    func polish(_ request: PolishRequest) async throws -> PolishResponse {
        let session = LanguageModelSession(
            model: model,
            instructions: PolishPromptBuilder.instructions(for: request)
        )

        let response = try await session.respond(
            to: PolishPromptBuilder.userInput(for: request),
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
