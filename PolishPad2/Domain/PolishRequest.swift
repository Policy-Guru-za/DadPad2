import Foundation

struct PolishRequest: Sendable {
    let input: String
    let mode: PolishMode
    let locale: Locale
}

enum PolishCapability: Sendable, Equatable {
    case foundationModel
    case basicFormatter(reason: String)

    var usesFoundationModel: Bool {
        switch self {
        case .foundationModel:
            true
        case .basicFormatter:
            false
        }
    }

    var fallbackReason: String? {
        switch self {
        case .foundationModel:
            nil
        case let .basicFormatter(reason):
            reason
        }
    }

    var outputBadgeText: String {
        switch self {
        case .foundationModel:
            "On-device AI"
        case .basicFormatter:
            "Basic local"
        }
    }
}

struct PolishResponse: Sendable {
    let text: String
    let capability: PolishCapability
}

enum PolishEngineError: LocalizedError, Sendable {
    case inputTooLong
    case unsupportedContent
    case currentlyBusy
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .inputTooLong:
            "This draft is too long to polish on device in one pass. Try a shorter section."
        case .unsupportedContent:
            "This text could not be rewritten safely with the on-device model."
        case .currentlyBusy:
            "PolishPad is still finishing another request. Try again in a moment."
        case let .processingFailed(message):
            message
        }
    }
}
