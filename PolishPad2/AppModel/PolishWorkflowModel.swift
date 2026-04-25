import Foundation
import Observation
import CoreTransferable
import UIKit

enum EditorSurface: String, CaseIterable, Identifiable, Sendable {
    case draft
    case result

    var id: Self { self }

    var title: String {
        switch self {
        case .draft:
            "Draft"
        case .result:
            "Result"
        }
    }

    var canvasTitle: String {
        switch self {
        case .draft:
            "Your text"
        case .result:
            "Polished result"
        }
    }

    var placeholder: String {
        switch self {
        case .draft:
            "Type or dictate here…"
        case .result:
            "Your polished text appears here."
        }
    }
}

enum WorkflowStatusState: Equatable, Sendable {
    case ready(lastCompletedMode: PolishMode?)
    case processing(PolishMode)
    case unavailable(String)
    case error(String)
    case copied

    var title: String {
        switch self {
        case .ready:
            "STATUS"
        case .processing:
            "STATUS"
        case .unavailable:
            "REQUIRED"
        case .error:
            "ERROR"
        case .copied:
            "COPIED"
        }
    }

    var message: String {
        switch self {
        case let .ready(lastCompletedMode):
            if let lastCompletedMode {
                return "ready. last polish: \(lastCompletedMode.shortTitle.lowercased())."
            }

            return "ready."
        case let .processing(mode):
            return "polishing as \(mode.shortTitle.lowercased())…"
        case let .unavailable(reason):
            return reason
        case let .error(message):
            return message
        case .copied:
            return "result copied."
        }
    }
}

struct WorkflowSnapshot: Equatable, Sendable {
    let sourceText: String
    let polishedText: String
    let selectedSurface: EditorSurface
    let lastCompletedMode: PolishMode?
}

struct PolishSharePayload: Transferable, Equatable, Sendable {
    let text: String
    let subject: String

    static var transferRepresentation: some TransferRepresentation {
        ProxyRepresentation(exporting: \.text)
    }
}

@MainActor
@Observable
final class PolishWorkflowModel {
    var sourceText = ""
    var polishedText = ""
    var selectedSurface: EditorSurface = .draft
    var capability: PolishCapability
    var isProcessing = false
    var activeMode: PolishMode?
    var lastCompletedMode: PolishMode?
    var copied = false
    var showClearConfirmation = false
    var errorMessage: String?
    private(set) var failedMode: PolishMode?

    private let service: any PolishServicing
    private var currentRunID = UUID()
    private var generationTask: Task<Void, Never>?
    private var copyResetTask: Task<Void, Never>?
    private var history: [WorkflowSnapshot] = []
    private let maxHistoryCount = 20

    init(service: any PolishServicing = LivePolishService()) {
        self.service = service
        self.capability = service.capability(for: .current)
    }

    var canPolish: Bool {
        !trimmedSourceText.isEmpty && !isProcessing && capability.isAvailableForPolish
    }

    var canCopy: Bool {
        !trimmedOutputText.isEmpty
    }

    var canShare: Bool {
        sharePayload != nil
    }

    var canClear: Bool {
        isProcessing || !sourceText.isEmpty || !polishedText.isEmpty
    }

    var canCancel: Bool {
        isProcessing
    }

    var canUndo: Bool {
        !history.isEmpty
    }

    var canRetryPolish: Bool {
        errorMessage != nil && failedMode != nil && !trimmedSourceText.isEmpty && !isProcessing && capability.isAvailableForPolish
    }

    var statusState: WorkflowStatusState {
        if let errorMessage {
            return .error(errorMessage)
        }

        if copied {
            return .copied
        }

        if let activeMode {
            return .processing(activeMode)
        }

        if let unavailableReason = capability.unavailableReason {
            return .unavailable(unavailableReason)
        }

        return .ready(lastCompletedMode: lastCompletedMode)
    }

    var selectedSurfaceCaption: String {
        switch selectedSurface {
        case .draft:
            return "Type or dictate rough wording. The original stays separate from the polished result."
        case .result:
            if let lastCompletedMode {
                return "Editable \(lastCompletedMode.shortTitle.lowercased()) output from on-device AI."
            }

            return "Choose Note, Email, or Message to generate polished text."
        }
    }

    var sharePayload: PolishSharePayload? {
        guard !trimmedOutputText.isEmpty else {
            return nil
        }

        let subject = lastCompletedMode?.shareSubject ?? "Polished text"
        return PolishSharePayload(text: trimmedOutputText, subject: subject)
    }

    func refreshCapability() {
        capability = service.capability(for: .current)
    }

    func polish(as mode: PolishMode) {
        let snapshot = trimmedSourceText
        guard canPolish else {
            return
        }

        generationTask?.cancel()
        generationTask = nil
        pushSnapshot()

        let runID = UUID()
        currentRunID = runID
        isProcessing = true
        activeMode = mode
        errorMessage = nil
        failedMode = nil
        copied = false

        let request = PolishRequest(
            input: snapshot,
            mode: mode,
            locale: .current
        )
        let service = self.service

        generationTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let response = try await service.polish(request)
                try Task.checkCancellation()

                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.polishedText = response.text
                    self.selectedSurface = .result
                    self.capability = response.capability
                    self.isProcessing = false
                    self.activeMode = nil
                    self.lastCompletedMode = mode
                    self.generationTask = nil
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.isProcessing = false
                    self.activeMode = nil
                    self.generationTask = nil
                }
            } catch let error as PolishEngineError {
                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.refreshCapability()
                    self.errorMessage = error.errorDescription
                    self.failedMode = mode
                    self.isProcessing = false
                    self.activeMode = nil
                    self.generationTask = nil
                }
            } catch {
                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.refreshCapability()
                    self.errorMessage = "PolishPad couldn’t finish this rewrite on device."
                    self.failedMode = mode
                    self.isProcessing = false
                    self.activeMode = nil
                    self.generationTask = nil
                }
            }
        }
    }

    func cancelPolish() {
        guard canCancel else {
            return
        }

        currentRunID = UUID()
        generationTask?.cancel()
        generationTask = nil
        isProcessing = false
        activeMode = nil
        errorMessage = nil
        failedMode = nil
    }

    func retryLastPolish() {
        guard canRetryPolish, let failedMode else {
            return
        }

        polish(as: failedMode)
    }

    func copyOutput() {
        guard canCopy else {
            return
        }

        UIPasteboard.general.string = polishedText
        copied = true

        copyResetTask?.cancel()
        copyResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.6))
            guard !Task.isCancelled else {
                return
            }

            await MainActor.run {
                self?.copied = false
            }
        }
    }

    func undo() {
        guard let snapshot = history.popLast() else {
            return
        }

        generationTask?.cancel()
        generationTask = nil
        copyResetTask?.cancel()
        copyResetTask = nil
        currentRunID = UUID()
        sourceText = snapshot.sourceText
        polishedText = snapshot.polishedText
        selectedSurface = snapshot.selectedSurface
        lastCompletedMode = snapshot.lastCompletedMode
        copied = false
        isProcessing = false
        activeMode = nil
        errorMessage = nil
        failedMode = nil
        refreshCapability()
    }

    func clearAll() {
        guard canClear else {
            return
        }

        pushSnapshot()
        generationTask?.cancel()
        generationTask = nil
        copyResetTask?.cancel()
        copyResetTask = nil

        currentRunID = UUID()
        sourceText = ""
        polishedText = ""
        selectedSurface = .draft
        copied = false
        isProcessing = false
        activeMode = nil
        lastCompletedMode = nil
        errorMessage = nil
        failedMode = nil

        refreshCapability()
    }

    private var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedOutputText: String {
        polishedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func pushSnapshot() {
        let snapshot = WorkflowSnapshot(
            sourceText: sourceText,
            polishedText: polishedText,
            selectedSurface: selectedSurface,
            lastCompletedMode: lastCompletedMode
        )

        guard history.last != snapshot else {
            return
        }

        history.append(snapshot)

        if history.count > maxHistoryCount {
            history.removeFirst(history.count - maxHistoryCount)
        }
    }
}
