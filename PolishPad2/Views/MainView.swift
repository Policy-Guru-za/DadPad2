import SwiftUI

struct MainView: View {
    @Bindable var model: PolishWorkflowModel
    @FocusState private var editorIsFocused: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    EditorialEditorCanvasView(
                        selectedSurface: $model.selectedSurface,
                        sourceText: $model.sourceText,
                        polishedText: $model.polishedText,
                        editorIsFocused: $editorIsFocused,
                        minHeight: max(proxy.size.height - 280, 380)
                    )
                    .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                    .padding(.top, 12)
                    .padding(.bottom, 28)
                    .frame(maxWidth: 1_560)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(Color.polishPadWindow.ignoresSafeArea())
                .safeAreaInset(edge: .top, spacing: 0) {
                    if let status = visibleStatus {
                        StatusRailView(
                            status: status,
                            onRetry: model.canUndo ? { model.undo() } : nil
                        )
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) {
                    bottomRegion(for: proxy.size.width)
                }
                .animation(.easeInOut(duration: 0.22), value: model.statusState)
                .animation(.easeInOut(duration: 0.22), value: model.activeMode)
            }
            .navigationTitle("PolishPad")
            .navigationBarTitleDisplayMode(.inline)
            .task {
                model.refreshCapability()
            }
            .alert("Clear draft and result?", isPresented: $model.showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { model.clearAll() }
            } message: {
                Text("This removes the current draft and the polished result.")
            }
        }
    }

    // MARK: - Status rail visibility

    private var visibleStatus: WorkflowStatusState? {
        switch model.statusState {
        case .processing, .fallback, .error:
            return model.statusState
        case .ready, .copied:
            return nil
        }
    }

    // MARK: - Bottom region (toast + dock)

    private func bottomRegion(for width: CGFloat) -> some View {
        VStack(spacing: 0) {
            toastArea
            actionDock
                .padding(.horizontal, horizontalPadding(for: width))
                .padding(.top, 12)
                .padding(.bottom, 8)
                .frame(maxWidth: 1_560)
                .frame(maxWidth: .infinity)
                .background(dockBackground)
        }
    }

    @ViewBuilder
    private var toastArea: some View {
        if case .copied = model.statusState {
            CopiedToastView()
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    private var dockBackground: some View {
        ZStack(alignment: .top) {
            Rectangle()
                .fill(.regularMaterial)
            Rectangle()
                .fill(Color(.separator).opacity(0.6))
                .frame(height: 0.5)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Dock rows

    private var actionDock: some View {
        VStack(spacing: 10) {
            primaryRow
            secondaryRow
        }
    }

    private var primaryRow: some View {
        HStack(spacing: 10) {
            ForEach(PolishMode.allCases) { mode in
                PrimaryPolishButton(
                    title: mode.dockTitle,
                    isActive: model.activeMode == mode,
                    isAnyActive: model.activeMode != nil,
                    isEnabled: model.canPolish,
                    onTap: { model.polish(as: mode) },
                    onCancel: { model.cancelPolish() }
                )
            }
        }
    }

    private var secondaryRow: some View {
        HStack(spacing: 10) {
            UtilityButton(
                title: "Undo",
                isEnabled: model.canUndo,
                action: { model.undo() }
            )
            UtilityButton(
                title: "Copy",
                isEnabled: model.canCopy,
                action: { model.copyOutput() }
            )
            shareControl
            UtilityButton(
                title: "Clear",
                isEnabled: model.canClear,
                action: { model.showClearConfirmation = true }
            )
        }
    }

    @ViewBuilder
    private var shareControl: some View {
        if let payload = model.sharePayload {
            ShareLink(item: payload.text, subject: Text(payload.subject)) {
                UtilityButtonLabel(title: "Share", isEnabled: true)
            }
            .buttonStyle(.plain)
        } else {
            UtilityButton(title: "Share", isEnabled: false, action: {})
        }
    }

    // MARK: - Layout helpers

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<760:
            16
        case ..<1_120:
            28
        default:
            44
        }
    }
}

#Preview {
    MainView(model: PolishWorkflowModel())
}

extension Color {
    /// Warm near-white window background. Provides subtle brand warmth
    /// without returning to the retired "paper" metaphor.
    static let polishPadWindow = Color(red: 0.965, green: 0.960, blue: 0.945)

    /// The single accent color. Used ONLY on the active polish button fill
    /// and on focus rings. Not on utility actions. Not on icons.
    static let polishPadAccent = Color(red: 0.76, green: 0.40, blue: 0.22)

    /// Warm-neutral button border — visible on the cream window at 1–1.5pt
    /// without requiring high saturation. Calibrated for users who benefit
    /// from clearly defined button edges.
    static let polishPadBorder = Color(red: 0.47, green: 0.43, blue: 0.38).opacity(0.28)

    /// Opaque warm off-white used as the button surface color. Contrasts
    /// clearly with the window background so buttons read as raised panels.
    static let polishPadButtonSurface = Color(red: 0.998, green: 0.995, blue: 0.985)
}
