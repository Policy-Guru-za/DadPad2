import SwiftUI

struct MainView: View {
    @Bindable var model: PolishWorkflowModel

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                ScrollView {
                    VStack(alignment: .leading, spacing: 28) {
                        StatusRailView(status: model.statusState)
                            .transition(.opacity.combined(with: .move(edge: .top)))

                        EditorialEditorCanvasView(
                            selectedSurface: $model.selectedSurface,
                            sourceText: $model.sourceText,
                            polishedText: $model.polishedText,
                            capability: model.capability,
                            caption: model.selectedSurfaceCaption,
                            lastCompletedMode: model.lastCompletedMode,
                            minHeight: max(proxy.size.height - 308, 440)
                        )
                    }
                    .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                    .padding(.top, 18)
                    .padding(.bottom, 36)
                    .frame(maxWidth: 1_560)
                    .frame(maxWidth: .infinity)
                }
                .scrollDismissesKeyboard(.interactively)
                .background(editorialBackground.ignoresSafeArea())
                .safeAreaInset(edge: .bottom) {
                    actionDock(for: proxy.size.width)
                        .padding(.horizontal, horizontalPadding(for: proxy.size.width))
                        .padding(.top, 12)
                        .padding(.bottom, 10)
                        .background(.clear)
                }
            }
            .toolbar(.hidden, for: .navigationBar)
            .task {
                model.refreshCapability()
            }
            .alert("Clear both fields?", isPresented: $model.showClearConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Clear", role: .destructive) {
                    model.clearAll()
                }
            } message: {
                Text("This removes the current draft and the polished result.")
            }
        }
    }

    private func actionDock(for width: CGFloat) -> some View {
        Group {
            if width >= 1_200 {
                HStack(spacing: 12) {
                    modeButtons
                    utilityButtons
                }
            } else {
                VStack(spacing: 12) {
                    HStack(spacing: 12) {
                        modeButtons
                    }

                    HStack(spacing: 12) {
                        utilityButtons
                    }
                }
            }
        }
    }

    private var modeButtons: some View {
        ForEach(PolishMode.allCases) { mode in
            Button {
                model.polish(as: mode)
            } label: {
                DockPillView(
                    title: mode.dockTitle,
                    style: .mode(isActive: model.activeMode == mode),
                    showsProgress: model.activeMode == mode
                )
            }
            .buttonStyle(.plain)
            .disabled(!model.canPolish)
            .opacity((model.canPolish || model.activeMode == mode) ? 1 : 0.7)
        }
    }

    private var utilityButtons: some View {
        Group {
            Button {
                model.cancelPolish()
            } label: {
                DockPillView(title: "Cancel", style: .utility(tint: .polishPadMutedText))
            }
            .buttonStyle(.plain)
            .disabled(!model.canCancel)
            .opacity(model.canCancel ? 1 : 0.68)

            Button {
                model.undo()
            } label: {
                DockPillView(title: "Undo", style: .utility(tint: .polishPadMutedText))
            }
            .buttonStyle(.plain)
            .disabled(!model.canUndo)
            .opacity(model.canUndo ? 1 : 0.68)

            Button(role: .destructive) {
                model.showClearConfirmation = true
            } label: {
                DockPillView(title: "Clear", style: .utility(tint: .polishPadDestructive))
            }
            .buttonStyle(.plain)
            .disabled(!model.canClear)
            .opacity(model.canClear ? 1 : 0.68)

            Button {
                model.copyOutput()
            } label: {
                DockPillView(title: "Copy", style: .utility(tint: .polishPadNavy))
            }
            .buttonStyle(.plain)
            .disabled(!model.canCopy)
            .opacity(model.canCopy ? 1 : 0.68)

            shareButton
        }
    }

    @ViewBuilder
    private var shareButton: some View {
        if let sharePayload = model.sharePayload {
            ShareLink(item: sharePayload.text, subject: Text(sharePayload.subject)) {
                DockPillView(title: "Share", style: .utility(tint: .polishPadNavy))
            }
            .buttonStyle(.plain)
        } else {
            Button {} label: {
                DockPillView(title: "Share", style: .utility(tint: .polishPadNavy))
            }
            .buttonStyle(.plain)
            .disabled(true)
            .opacity(0.68)
        }
    }

    private func horizontalPadding(for width: CGFloat) -> CGFloat {
        switch width {
        case ..<760:
            18
        case ..<1_120:
            28
        default:
            46
        }
    }

    private var editorialBackground: some View {
        ZStack {
            Color.polishPadPaper

            RadialGradient(
                colors: [Color.polishPadGlow.opacity(0.46), .clear],
                center: .topLeading,
                startRadius: 30,
                endRadius: 520
            )

            RadialGradient(
                colors: [Color.polishPadGlow.opacity(0.34), .clear],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 620
            )

            LinearGradient(
                colors: [
                    Color.polishPadShell.opacity(0.48),
                    .clear,
                    Color.polishPadShell.opacity(0.22)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

#Preview {
    MainView(model: PolishWorkflowModel())
}

extension Color {
    static let polishPadPaper = Color(red: 0.972, green: 0.953, blue: 0.922)
    static let polishPadShell = Color(red: 0.945, green: 0.923, blue: 0.882)
    static let polishPadGlow = Color(red: 0.929, green: 0.819, blue: 0.639)
    static let polishPadStroke = Color(red: 0.842, green: 0.775, blue: 0.649)
    static let polishPadTerracotta = Color(red: 0.79, green: 0.435, blue: 0.223)
    static let polishPadTeal = Color(red: 0.817, green: 0.879, blue: 0.861)
    static let polishPadNavy = Color(red: 0.152, green: 0.258, blue: 0.384)
    static let polishPadMutedText = Color(red: 0.557, green: 0.611, blue: 0.667)
    static let polishPadDestructive = Color(red: 0.784, green: 0.341, blue: 0.286)
}
