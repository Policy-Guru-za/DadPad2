import Foundation
import FoundationModels

protocol PolishServicing: Sendable {
    func capability(for locale: Locale) -> PolishCapability
    func polish(_ request: PolishRequest) async throws -> PolishResponse
}

struct LivePolishService: PolishServicing {
    private let foundation = FoundationModelPolisher()
    private let fallback = RuleBasedPolisher()

    func capability(for locale: Locale = .current) -> PolishCapability {
        foundation.capability(for: locale)
    }

    func polish(_ request: PolishRequest) async throws -> PolishResponse {
        let capability = foundation.capability(for: request.locale)

        switch capability {
        case .foundationModel:
            do {
                return try await foundation.polish(request)
            } catch is CancellationError {
                throw CancellationError()
            } catch let error as LanguageModelSession.GenerationError {
                switch error {
                case .assetsUnavailable, .unsupportedLanguageOrLocale:
                    return fallbackResponse(
                        for: request,
                        reason: "Full polish is temporarily unavailable. Using a basic local formatter instead."
                    )
                case .exceededContextWindowSize:
                    throw PolishEngineError.inputTooLong
                case .guardrailViolation, .refusal:
                    throw PolishEngineError.unsupportedContent
                case .concurrentRequests, .rateLimited:
                    throw PolishEngineError.currentlyBusy
                default:
                    throw PolishEngineError.processingFailed(
                        "PolishPad couldn’t finish this rewrite on device."
                    )
                }
            } catch {
                throw PolishEngineError.processingFailed(
                    "PolishPad couldn’t finish this rewrite on device."
                )
            }
        case let .basicFormatter(reason):
            return fallbackResponse(for: request, reason: reason)
        }
    }

    private func fallbackResponse(for request: PolishRequest, reason: String) -> PolishResponse {
        PolishResponse(
            text: fallback.polish(request),
            capability: .basicFormatter(reason: reason)
        )
    }
}
