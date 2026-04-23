import Foundation
import Observation
import UIKit

@MainActor
@Observable
final class PolishWorkflowModel {
    var sourceText = ""
    var polishedText = ""
    var capability: PolishCapability
    var isProcessing = false
    var activeMode: PolishMode?
    var lastCompletedMode: PolishMode?
    var copied = false
    var showClearConfirmation = false
    var errorMessage: String?

    private let service: LivePolishService
    private var currentRunID = UUID()
    private var generationTask: Task<Void, Never>?
    private var copyResetTask: Task<Void, Never>?

    init(service: LivePolishService = LivePolishService()) {
        self.service = service
        self.capability = service.capability(for: .current)
    }

    var canPolish: Bool {
        !trimmedSourceText.isEmpty
    }

    var canCopy: Bool {
        !trimmedOutputText.isEmpty
    }

    var fallbackMessage: String? {
        capability.fallbackReason
    }

    var outputStatusText: String {
        if let activeMode {
            return "Polishing as \(activeMode.shortTitle.lowercased())…"
        }

        if let lastCompletedMode {
            if capability.usesFoundationModel {
                return "Last polished as \(lastCompletedMode.shortTitle.lowercased()) with the on-device model."
            }

            return "Last polished as \(lastCompletedMode.shortTitle.lowercased()) with the basic local formatter."
        }

        return "Editable output. Copy it into Mail, Notes, or Messages."
    }

    func refreshCapability() {
        capability = service.capability(for: .current)
    }

    func polish(as mode: PolishMode) {
        let snapshot = trimmedSourceText
        guard !snapshot.isEmpty else {
            return
        }

        generationTask?.cancel()

        let runID = UUID()
        currentRunID = runID
        isProcessing = true
        activeMode = mode
        errorMessage = nil
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
                    self.capability = response.capability
                    self.isProcessing = false
                    self.activeMode = nil
                    self.lastCompletedMode = mode
                }
            } catch is CancellationError {
                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.isProcessing = false
                    self.activeMode = nil
                }
            } catch let error as PolishEngineError {
                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.refreshCapability()
                    self.errorMessage = error.errorDescription
                    self.isProcessing = false
                    self.activeMode = nil
                }
            } catch {
                await MainActor.run {
                    guard self.currentRunID == runID else {
                        return
                    }

                    self.refreshCapability()
                    self.errorMessage = "PolishPad couldn’t finish this rewrite on device."
                    self.isProcessing = false
                    self.activeMode = nil
                }
            }
        }
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

    func clearAll() {
        generationTask?.cancel()
        copyResetTask?.cancel()

        currentRunID = UUID()
        sourceText = ""
        polishedText = ""
        copied = false
        isProcessing = false
        activeMode = nil
        lastCompletedMode = nil
        errorMessage = nil

        refreshCapability()
    }

    private var trimmedSourceText: String {
        sourceText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var trimmedOutputText: String {
        polishedText.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
