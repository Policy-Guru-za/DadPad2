import Foundation

struct RuleBasedPolisher: Sendable {
    func polish(_ request: PolishRequest) -> String {
        let body = normalizedBody(from: request.input)

        switch request.mode {
        case .note:
            return body
        case .email:
            return formatEmail(body: body)
        case .message:
            return body
        }
    }

    private func formatEmail(body: String) -> String {
        var sections: [String] = []

        if !startsWithGreeting(body) {
            sections.append("Hi,")
        }

        sections.append(body)

        if !endsWithClosing(body) {
            sections.append("Best,")
        }

        return sections.joined(separator: "\n\n")
    }

    private func normalizedBody(from input: String) -> String {
        let normalizedLineEndings = input.replacingOccurrences(of: "\r\n", with: "\n")
        let collapsedBlankLines = normalizedLineEndings.replacingOccurrences(
            of: #"\n{3,}"#,
            with: "\n\n",
            options: .regularExpression
        )

        let paragraphs = collapsedBlankLines
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let cleanedParagraphs = paragraphs.map(normalizeParagraph)
        return cleanedParagraphs.joined(separator: "\n\n")
    }

    private func normalizeParagraph(_ paragraph: String) -> String {
        let lines = paragraph
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard !lines.isEmpty else {
            return ""
        }

        let isBulletList = lines.allSatisfy { listItemContent(from: $0) != nil }

        if isBulletList {
            return lines
                .map { line in
                    let content = listItemContent(from: line) ?? line
                    return "• \(normalizeInlineText(content, ensureTerminalPunctuation: true))"
                }
                .joined(separator: "\n")
        }

        return normalizeInlineText(lines.joined(separator: " "), ensureTerminalPunctuation: true)
    }

    private func normalizeInlineText(_ text: String, ensureTerminalPunctuation: Bool) -> String {
        var cleaned = text.replacingOccurrences(
            of: #"[ \t]+"#,
            with: " ",
            options: .regularExpression
        )
        cleaned = cleaned.replacingOccurrences(
            of: #" +([,.;:!?])"#,
            with: "$1",
            options: .regularExpression
        )
        cleaned = cleaned.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleaned.isEmpty else {
            return ""
        }

        cleaned = capitalizingFirstLetter(cleaned)

        if ensureTerminalPunctuation, let last = cleaned.last, !".!?".contains(last) {
            cleaned.append(".")
        }

        return cleaned
    }

    private func startsWithGreeting(_ text: String) -> Bool {
        text.range(
            of: #"^(hi|hello)\b|^dear\b"#,
            options: [.regularExpression, .caseInsensitive]
        ) != nil
    }

    private func endsWithClosing(_ text: String) -> Bool {
        let lowercased = text.lowercased()
        return lowercased.contains("\n\nbest,")
            || lowercased.contains("\n\nthanks,")
            || lowercased.contains("\n\nregards,")
    }

    private func capitalizingFirstLetter(_ value: String) -> String {
        guard let first = value.first else {
            return value
        }

        return first.uppercased() + value.dropFirst()
    }

    private func listItemContent(from line: String) -> String? {
        guard !line.isEmpty else {
            return nil
        }

        let bulletMarkers: Set<Character> = ["-", "*", "•"]
        if let first = line.first, bulletMarkers.contains(first) {
            return line.dropFirst().trimmingCharacters(in: .whitespacesAndNewlines)
        }

        guard let range = line.range(of: #"^\d+[.)]\s*"#, options: .regularExpression) else {
            return nil
        }

        return String(line[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
