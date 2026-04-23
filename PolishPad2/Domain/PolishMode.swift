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
            "Note"
        case .email:
            "Email"
        case .message:
            "Text"
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
            "Professional email with a sensible greeting and closing."
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

    var foundationInstructions: String {
        switch self {
        case .note:
            """
            Rewrite the text as a clear, well-structured note.
            Improve grammar, spelling, punctuation, and sentence flow.
            Use paragraphs or bullets only when they genuinely improve readability.
            Preserve the original meaning and avoid becoming overly formal.
            """
        case .email:
            """
            Rewrite the text as a properly formatted email.
            Improve grammar, spelling, punctuation, and paragraph structure.
            Add a neutral salutation only when it helps, and never invent names.
            Add a simple natural closing only when it improves usefulness.
            Keep the tone professional and clear by default.
            Do not invent names, dates, promises, or facts.
            Do not generate a subject line unless the input clearly contains one.
            """
        case .message:
            """
            Rewrite the text as a concise message.
            Improve grammar, spelling, punctuation, and clarity.
            Keep it natural, human, and more conversational than an email.
            Keep it shorter when possible without losing meaning.
            Do not add unnecessary formality.
            """
        }
    }
}
