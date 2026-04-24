import SwiftUI

struct MainView: View {
    @Bindable var model: PolishWorkflowModel
    @State private var showAboutSheet = false
    @FocusState private var editorIsFocused: Bool

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(spacing: 18) {
                        brandHeader

                        EditorialEditorCanvasView(
                            selectedSurface: $model.selectedSurface,
                            sourceText: $model.sourceText,
                            polishedText: $model.polishedText,
                            editorIsFocused: $editorIsFocused,
                            minHeight: editorMinHeight(for: proxy.size)
                        )
                    }
                    .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                    .padding(.top, 20)
                    .padding(.bottom, 24)
                    .frame(maxWidth: 1_560)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .scrollIndicators(.hidden)
                .background(Color.ppBackground.ignoresSafeArea())
                .safeAreaInset(edge: .top, spacing: 0) {
                    if let status = visibleStatus {
                        StatusRailView(
                            status: status,
                            onRetry: model.canRetryPolish ? { model.retryLastPolish() } : nil
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
            .toolbar(.hidden, for: .navigationBar)
            .task {
                model.refreshCapability()
            }
            .alert("Clear draft and result?", isPresented: $model.showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) { model.clearAll() }
            } message: {
                Text("This removes the current draft and the polished result.")
            }
            .sheet(isPresented: $showAboutSheet) {
                AboutSheet()
                    .presentationDetents([.height(600), .large])
            }
        }
    }

    // MARK: - Brand

    private var brandHeader: some View {
        ZStack(alignment: .topTrailing) {
            VStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 28, weight: .light))
                    .foregroundStyle(Color.ppAccentSoft)
                    .accessibilityHidden(true)

                Text("PolishPad")
                    .font(.system(size: 42, weight: .regular, design: .serif))
                    .foregroundStyle(Color.ppText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
                    .accessibilityAddTraits(.isHeader)
            }
            .frame(maxWidth: .infinity)

            Button {
                showAboutSheet = true
            } label: {
                Image(systemName: "info.circle")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(Color.ppAccent)
                    .frame(width: 44, height: 44)
                    .background(Color.ppCanvas.opacity(0.88), in: Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.ppBorder, lineWidth: 1)
                    )
                    .contentShape(Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("About PolishPad")
            .accessibilityHint("Shows privacy policy and support links.")
        }
        .padding(.top, 2)
        .padding(.bottom, 4)
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
            actionDock(for: width)
                .padding(.horizontal, horizontalPadding(for: width))
                .padding(.top, 10)
                .padding(.bottom, 12)
                .frame(maxWidth: 1_560)
                .frame(maxWidth: .infinity)
                .background(Color.ppBackground.opacity(0.94).ignoresSafeArea(edges: .bottom))
        }
    }

    @ViewBuilder
    private var toastArea: some View {
        if case .copied = model.statusState {
            CopiedToastView()
                .padding(.bottom, 10)
                .transition(.opacity.combined(with: .move(edge: .bottom)))
        }
    }

    // MARK: - Dock rows

    private func actionDock(for width: CGFloat) -> some View {
        VStack(spacing: 16) {
            primaryRow(for: width)
            secondaryToolbar
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(Color.ppCanvas.opacity(0.74))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.ppBorder, lineWidth: 1)
        )
        .shadow(color: Color.ppWarmShadow.opacity(0.06), radius: 18, y: 8)
    }

    @ViewBuilder
    private func primaryRow(for width: CGFloat) -> some View {
        if width < 760 {
            VStack(spacing: 12) {
                primaryButtons
            }
        } else {
            HStack(spacing: PolishPadLayout.horizontalSpacing) {
                primaryButtons
            }
        }
    }

    private var primaryButtons: some View {
        ForEach(PolishMode.allCases) { mode in
            PrimaryPolishButton(
                mode: mode,
                isActive: model.activeMode == mode,
                isAnyActive: model.activeMode != nil,
                isEnabled: model.canPolish,
                onTap: { model.polish(as: mode) },
                onCancel: { model.cancelPolish() }
            )
        }
    }

    private var secondaryToolbar: some View {
        SecondaryActionToolbar(
            canUndo: model.canUndo,
            canCopy: model.canCopy,
            canClear: model.canClear,
            sharePayload: model.sharePayload,
            undo: { model.undo() },
            copy: { model.copyOutput() },
            clear: { model.showClearConfirmation = true }
        )
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

    private func editorMinHeight(for size: CGSize) -> CGFloat {
        let reservedHeight: CGFloat = size.width < 760 ? 560 : 500
        return max(size.height - reservedHeight, size.width < 760 ? 360 : 500)
    }
}

#Preview {
    MainView(model: PolishWorkflowModel())
}
