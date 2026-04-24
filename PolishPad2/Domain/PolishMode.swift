import Foundation

enum PolishMode: String, CaseIterable, Identifiable, Sendable {
    case note
    case email
    case message

    var id: Self { self }

    var title: String {
        switch self {
        case .note:
            "Polish as Note"
        case .email:
            "Polish as Email"
        case .message:
            "Polish as Message"
        }
    }

    var shortTitle: String {
        switch self {
        case .note:
            "Note"
        case .email:
            "Email"
        case .message:
            "Message"
        }
    }

    var dockTitle: String {
        switch self {
        case .note:
            "Polish for note"
        case .email:
            "Polish for email"
        case .message:
            "Polish for text"
        }
    }

    var symbolName: String {
        switch self {
        case .note:
            "note.text"
        case .email:
            "envelope"
        case .message:
            "message"
        }
    }

    var helpText: String {
        switch self {
        case .note:
            "Clear structure. Natural paragraphs or bullets only when useful."
        case .email:
            "Professional email tone without invented subject lines or sign-offs."
        case .message:
            "Shorter, warmer, and more conversational than an email."
        }
    }

    var shareSubject: String {
        switch self {
        case .note:
            "Polished note"
        case .email:
            "Polished email"
        case .message:
            "Polished message"
        }
    }
}
