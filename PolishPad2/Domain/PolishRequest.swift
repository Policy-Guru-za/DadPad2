import Foundation

struct PolishRequest: Sendable {
    let input: String
    let mode: PolishMode
    let locale: Locale
}

enum PolishCapability: Sendable, Equatable {
    case foundationModel
    case unavailable(reason: String)

    var isAvailableForPolish: Bool {
        switch self {
        case .foundationModel:
            true
        case .unavailable:
            false
        }
    }

    var unavailableReason: String? {
        switch self {
        case .foundationModel:
            nil
        case let .unavailable(reason):
            reason
        }
    }

    var outputBadgeText: String {
        switch self {
        case .foundationModel:
            "On-device AI"
        case .unavailable:
            "Requires Apple Intelligence"
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
    case unavailable(String)
    case processingFailed(String)

    var errorDescription: String? {
        switch self {
        case .inputTooLong:
            "This draft is too long to polish on device in one pass. Try a shorter section."
        case .unsupportedContent:
            "This text could not be rewritten safely with the on-device model."
        case .currentlyBusy:
            "PolishPad is still finishing another request. Try again in a moment."
        case let .unavailable(message):
            message
        case let .processingFailed(message):
            message
        }
    }
}
