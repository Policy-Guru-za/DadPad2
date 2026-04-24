import Foundation

enum PolishStructureTargetShape: Equatable, Sendable {
    case paragraphs
    case bullets
    case hybrid
}

enum PolishStructureContentType: Equatable, Sendable {
    case message
    case email
    case note
    case mixed
}

struct PolishStructureIntent: Equatable, Sendable {
    let enabled: Bool
    let targetShape: PolishStructureTargetShape
    let isolateRequest: Bool
    let isolateClosing: Bool
    let preserveExistingLists: Bool
    let preserveExistingParagraphs: Bool
    let inferredContentType: PolishStructureContentType
    let shouldApplyGuidance: Bool
}

struct PolishPromptBuilder: Sendable {
    private struct ModePromptSpec {
        let label: String
        let styleRules: [String]
        let structureRules: [String]
    }

    private static let rewritePromptIntro =
        "You are a rewriting engine. Rewrite the user's text according to the requested mode."

    private static let userWrapperPrefix = "Rewrite the text below.\n\n[BEGIN TEXT]\n"
    private static let userWrapperSuffix = "\n[END TEXT]"

    private static let baseConstraints = [
        "Preserve the original meaning, facts, and intent. Do not invent new information.",
        "Preserve the original language of the input. Do not translate unless the input explicitly asks for translation.",
        "Keep the approximate length unless the mode explicitly asks for brevity. Light tightening is allowed; modest lengthening is allowed if it improves clarity and flow.",
        "Preserve exactly, character-for-character, any names, numbers, dates, times, currency amounts, percentages, addresses, URLs, email addresses, phone numbers, order/reference IDs, and quoted text.",
        "Fix grammar, spelling, punctuation, and sentence boundaries.",
        #"Remove obvious filler words, for example "um", "uh", "like", "you know", and unintentional verbatim repetition."#,
        "Homophones and wrong-word fixes: only change a word if the intended meaning is highly confident from context. If uncertain, leave it unchanged.",
        "Do not add greetings, sign-offs, signatures, subject lines, placeholder names like \"[Your Name]\", or extra calls to action unless they already exist in the input.",
        "Output only the rewritten text. No preamble, no labels, no explanations, no markdown fences, or commentary."
    ]

    private static let baseStructureRules = [
        "Keep the output as plain text.",
        "Prefer single blank lines between paragraphs.",
        "Prefer 2 to 4 compact paragraphs instead of one dense block when the content contains multiple ideas.",
        "Keep one idea per paragraph when possible: context/background, main request, next step/outcome, closing sentiment.",
        "If there is a clear ask, isolate it in its own paragraph unless the message is extremely short.",
        "If there is a closing sentiment, keep it separate from the operational request.",
        "Use bullets only when the message naturally contains multiple requests, deliverables, steps, options, or agenda items.",
        "Default bullet format is '- '. Use numbered items only when sequence matters or the source already implies sequence.",
        "Do not return one long block when the content clearly contains separate ideas.",
        "Do not over-format short or already clear messages.",
        "Do not introduce headings, labels, subject lines, greetings, sign-offs, signatures, or placeholder names just to organize the text.",
        "Do not flatten existing readable lists into prose unless that is clearly better."
    ]

    static func instructions(for request: PolishRequest) -> String {
        let intent = structureIntent(for: request.input, mode: request.mode)
        return instructions(for: request.mode, structureIntent: intent)
    }

    static func instructions(
        for mode: PolishMode,
        structureIntent: PolishStructureIntent? = nil
    ) -> String {
        let promptSpec = modePromptSpec(for: mode)
        var instructions = [
            rewritePromptIntro,
            "",
            "Non-negotiable constraints:"
        ]
        instructions.append(contentsOf: baseConstraints.map { "- \($0)" })
        instructions.append("")
        instructions.append("Mode: \(promptSpec.label)")
        instructions.append(contentsOf: promptSpec.styleRules)

        if let structureIntent, structureIntent.enabled, structureIntent.shouldApplyGuidance {
            instructions.append("")
            instructions.append(contentsOf: buildStructureGuidance(structureIntent))
            instructions.append(contentsOf: promptSpec.structureRules)
        }

        return instructions.joined(separator: "\n")
    }

    static func userInput(for request: PolishRequest) -> String {
        "\(userWrapperPrefix)\(request.input)\(userWrapperSuffix)"
    }

    static func structureIntent(
        for inputText: String,
        mode: PolishMode,
        enabled: Bool = true
    ) -> PolishStructureIntent {
        if !enabled {
            return PolishStructureIntent(
                enabled: false,
                targetShape: .paragraphs,
                isolateRequest: false,
                isolateClosing: false,
                preserveExistingLists: false,
                preserveExistingParagraphs: false,
                inferredContentType: .message,
                shouldApplyGuidance: false
            )
        }

        let normalized = normalizeLineEndings(inputText)
        let preserveExistingLists = hasMatch(
            #"^\s*(?:[-*•]|\d+[.)])\s+\S"#,
            in: normalized,
            options: [.anchorsMatchLines]
        )
        let preserveExistingParagraphs = hasMatch(#"\n\s*\n"#, in: normalized)
        let requestSignalCount = countMatches(
            #"\b(?:can you|could you|would you|please|need you to|send|share|provide|review|confirm|approve|reply|respond|let me know|tell me|update|outline|schedule|move)\b"#,
            in: normalized,
            options: [.caseInsensitive]
        )
        let tailStart = normalized.index(
            normalized.endIndex,
            offsetBy: -min(220, normalized.count),
            limitedBy: normalized.startIndex
        ) ?? normalized.startIndex
        let tail = String(normalized[tailStart...])
        let isolateClosing = hasMatch(
            #"\b(?:thank you|thanks|appreciate it|appreciated|look forward|hope this|let me know if you have any questions|kind regards|best regards|regards|sincerely|yours sincerely|yours faithfully)\b(?:[\s,]+[A-Za-z][A-Za-z .'-]+)?\s*$"#,
            in: tail,
            options: [.caseInsensitive]
        )
        let targetShape = inferTargetShape(
            normalized,
            mode: mode,
            preserveExistingLists: preserveExistingLists
        )
        let contentType = inferContentType(
            normalized,
            mode: mode,
            preserveExistingLists: preserveExistingLists
        )
        let sentenceCount = countSentenceLikeSegments(normalized)
        let hasIntentionalParagraphs = preserveExistingParagraphs
        let denseSingleBlock = !hasIntentionalParagraphs && normalized.count >= 180 && sentenceCount >= 2
        let shouldApplyGuidance = preserveExistingLists
            || preserveExistingParagraphs
            || contentType == .email
            || contentType == .mixed
            || targetShape != .paragraphs
            || denseSingleBlock
            || isolateClosing
            || (requestSignalCount >= 2 && normalized.count >= 80)

        return PolishStructureIntent(
            enabled: true,
            targetShape: targetShape,
            isolateRequest: requestSignalCount >= 1,
            isolateClosing: isolateClosing,
            preserveExistingLists: preserveExistingLists,
            preserveExistingParagraphs: preserveExistingParagraphs,
            inferredContentType: contentType,
            shouldApplyGuidance: shouldApplyGuidance
        )
    }

    private static func modePromptSpec(for mode: PolishMode) -> ModePromptSpec {
        switch mode {
        case .note:
            ModePromptSpec(
                label: "REFINE",
                styleRules: [
                    "Rewrite into a clear, elegant, well-structured version suitable for general professional communication.",
                    "Actively improve sentence structure and paragraph flow.",
                    "It should read like a competent human wrote it carefully, not like a transcript, chat message, or template.",
                    "Preserve the writer's natural level of formality, directness, warmth, and personality.",
                    "Make this sound like the same person, just clearer and cleaner.",
                    "Do not professionalize casual writing unless the input already sounds formal.",
                    "Do not make it sound corporate, elegant, templated, assistant-like, or overly polished.",
                    "Preserve the original level of assertiveness.",
                    "Keep the tone neutral and polished, not especially chatty, corporate, or terse.",
                    "Avoid formulaic workplace-email wording when a neutral polished phrasing will do.",
                    #"Avoid business-email phrasing like "please confirm", "could you please", "I'd like to", and "thank you" unless it is already present in the input or clearly required to preserve the tone."#,
                    "If the input already contains a clear request, keep the request natural and polished rather than turning it into a more formal workplace instruction.",
                    "When the input is already short or reasonably clean, still improve cadence and clarity while keeping the tone neutral rather than chatty or terse.",
                    #"Tone reference: "Could you send that over when you have a chance? Thanks.""#,
                    "Keep approximate length: you may slightly tighten, and you may modestly expand if it makes the writing more elegant or easier to read."
                ],
                structureRules: [
                    "Prefer elegant, balanced paragraphs.",
                    "Use bullets only when multiple concrete asks or deliverables clearly make the message easier to scan."
                ]
            )
        case .email:
            ModePromptSpec(
                label: "PROFESSIONAL",
                styleRules: [
                    "Rewrite to sound professional, neutral, and polished for a workplace email or written update.",
                    "Clear, calm, courteous, and well-structured.",
                    "Prefer polished workplace phrasing over chatty wording, but do not become stiff or verbose.",
                    "Do not add a greeting, sign-off, signature, subject line, or sender name unless it is already present in the input.",
                    #"Prefer professional choices like "could you please", "I'd like to", "please confirm", and "thank you" when natural."#,
                    #"Prefer more formal workplace verbs like "confirm whether", "remain suitable", "inform", and "appreciate" when natural."#,
                    #"Prefer business-ready phrasing like "we may need to reschedule", "please let me know", and "avoid wasting anyone's time" over tentative first-person framing when natural."#,
                    "Prefer a slightly more formal workplace register than note mode whenever the two would otherwise come out the same.",
                    "If the input is already reasonably polished, do not leave it unchanged. Rephrase it into a clearer, more businesslike workplace version.",
                    "When the input contains a request, follow-up, or confirmation, make it more explicit and professionally courteous than note mode instead of leaving the original phrasing untouched.",
                    "When the input is already short or clean, still prefer visibly more professional wording than note or message mode instead of returning the same sentence unchanged.",
                    #"Tone reference for follow-ups: "Please send the final redlines today so legal can sign off.""#,
                    #"Tone reference for confirmations: "Please confirm whether Monday afternoon remains suitable for the review.""#,
                    #"Tone reference: "Could you please send that over when you have a chance? Thank you.""#,
                    "Keep approximate length; light tightening allowed."
                ],
                structureRules: [
                    "Prefer scan-friendly business blocks.",
                    "Bullets are acceptable for deliverables, options, or action items when they improve clarity."
                ]
            )
        case .message:
            ModePromptSpec(
                label: "MESSAGE",
                styleRules: [
                    "Rewrite the text as a concise message.",
                    "Improve grammar, spelling, punctuation, and clarity.",
                    "Keep it natural, human, and more conversational than an email.",
                    "Keep it shorter when possible without losing meaning.",
                    "Do not add unnecessary formality."
                ],
                structureRules: [
                    "Prefer short conversational paragraphs.",
                    "Use bullets rarely; keep the output feeling like a natural message, not a memo."
                ]
            )
        }
    }

    private static func buildStructureGuidance(_ intent: PolishStructureIntent) -> [String] {
        var rules = [
            "Structure guidance:"
        ]
        rules.append(contentsOf: baseStructureRules.map { "- \($0)" })
        rules.append("- \(contentTypeRule(for: intent.inferredContentType))")
        rules.append("- \(shapeRule(for: intent.targetShape))")

        if intent.isolateRequest {
            rules.append("- The main request should stand on its own paragraph or bullet when natural.")
        }

        if intent.isolateClosing {
            rules.append("- Keep any closing sentiment separate from the operational request.")
        }

        if intent.preserveExistingLists {
            rules.append("- Preserve existing readable bullets or numbering; improve spacing only.")
        }

        if intent.preserveExistingParagraphs {
            rules.append("- Preserve existing paragraph separation when it is already clear.")
        }

        return rules
    }

    private static func contentTypeRule(for contentType: PolishStructureContentType) -> String {
        switch contentType {
        case .message:
            "Treat the input as a plain-text message."
        case .email:
            "Treat the input as a plain-text email body."
        case .note:
            "Treat the input as a plain-text note."
        case .mixed:
            "Treat the input as a plain-text message that may contain mixed prose and list structure."
        }
    }

    private static func shapeRule(for targetShape: PolishStructureTargetShape) -> String {
        switch targetShape {
        case .paragraphs:
            "Preferred shape for this input: paragraphs."
        case .bullets:
            "Preferred shape for this input: bullets or a very short lead-in followed by bullets."
        case .hybrid:
            "Preferred shape for this input: a short lead-in paragraph plus bullets or compact follow-on paragraphs."
        }
    }

    private static func inferContentType(
        _ value: String,
        mode: PolishMode,
        preserveExistingLists: Bool
    ) -> PolishStructureContentType {
        let hasGreeting = hasMatch(
            #"^\s*(?:hi|hello|hey|dear)\b"#,
            in: value,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
        let hasSignOff = hasMatch(
            #"\b(?:best|best regards|kind regards|regards|sincerely|thank you|thanks),?\s*$"#,
            in: value,
            options: [.caseInsensitive, .anchorsMatchLines]
        )
        let hasBlankLine = hasMatch(#"\n\s*\n"#, in: value)

        if (hasGreeting || hasSignOff) && preserveExistingLists {
            return .mixed
        }

        if hasGreeting || hasSignOff {
            return .email
        }

        if preserveExistingLists && hasBlankLine {
            return .mixed
        }

        if preserveExistingLists {
            return .note
        }

        return mode == .message ? .message : .note
    }

    private static func inferTargetShape(
        _ value: String,
        mode: PolishMode,
        preserveExistingLists: Bool
    ) -> PolishStructureTargetShape {
        let sentenceCount = countSentenceLikeSegments(value)
        let hasIntentionalParagraphs = hasMatch(#"\n\s*\n"#, in: value)
        let denseSingleBlock = !hasIntentionalParagraphs && value.count >= 180 && sentenceCount >= 2
        let hasMultipleRequests = hasMatch(
            #"\b(?:send|share|provide|review|confirm|approve|reply|respond|update|outline|schedule|move|let me know|tell me)\b.*(?:,\s*|\band\b|\bor\b).*\b(?:send|share|provide|review|confirm|approve|reply|respond|update|outline|schedule|move|let me know|tell me)\b"#,
            in: value,
            options: [.caseInsensitive]
        )
        let hasExplicitListShape = hasMatch(
            #"\b(?:one|two|three|four|five|six|\d+)\s+(?:things|items|steps|options|issues|dates|reasons)\b|:\s*(?:the|a|an|\w+)"#,
            in: value,
            options: [.caseInsensitive]
        )

        if preserveExistingLists {
            return hasIntentionalParagraphs ? .hybrid : .bullets
        }

        if hasExplicitListShape {
            return mode == .email ? .bullets : .hybrid
        }

        if hasMultipleRequests {
            if denseSingleBlock && value.count >= 260 {
                return .paragraphs
            }

            if mode == .note || mode == .message {
                return .paragraphs
            }

            if denseSingleBlock || sentenceCount >= 3 {
                return .hybrid
            }

            return mode == .email ? .bullets : .paragraphs
        }

        if denseSingleBlock || hasIntentionalParagraphs || sentenceCount >= 3 {
            return .paragraphs
        }

        return .paragraphs
    }

    private static func countSentenceLikeSegments(_ value: String) -> Int {
        countMatches(#"[^.!?\n]+[.!?]?"#, in: value)
    }

    private static func normalizeLineEndings(_ value: String) -> String {
        value.replacingOccurrences(of: "\r\n", with: "\n")
    }

    private static func hasMatch(
        _ pattern: String,
        in value: String,
        options: NSRegularExpression.Options = []
    ) -> Bool {
        countMatches(pattern, in: value, options: options) > 0
    }

    private static func countMatches(
        _ pattern: String,
        in value: String,
        options: NSRegularExpression.Options = []
    ) -> Int {
        guard let regex = try? NSRegularExpression(pattern: pattern, options: options) else {
            return 0
        }

        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        return regex.numberOfMatches(in: value, options: [], range: range)
    }
}
