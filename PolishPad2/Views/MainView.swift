import SwiftUI

struct MainView: View {
    @Bindable var model: PolishWorkflowModel

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                let wideEditors = proxy.size.width >= 900
                let horizontalButtons = proxy.size.width >= 760
                let editorHeight = wideEditors ? 360.0 : 220.0

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        header

                        if let fallbackMessage = model.fallbackMessage {
                            StatusBannerView(
                                title: "Basic local formatting",
                                message: fallbackMessage,
                                kind: .warning
                            )
                        }

                        if let errorMessage = model.errorMessage {
                            StatusBannerView(
                                title: "Couldn’t polish this draft",
                                message: errorMessage,
                                kind: .error
                            )
                        }

                        if wideEditors {
                            editorsSection(wideLayout: true, editorHeight: editorHeight)
                            modeButtonsSection(horizontalLayout: horizontalButtons)
                        } else {
                            sourceEditor(minHeight: editorHeight)
                            modeButtonsSection(horizontalLayout: horizontalButtons)
                            outputEditor(minHeight: editorHeight)
                        }

                        footerActions(wideLayout: horizontalButtons)
                    }
                    .padding(24)
                    .frame(maxWidth: 1_360)
                    .frame(maxWidth: .infinity)
                }
                .background(background.ignoresSafeArea())
            }
            .navigationBarTitleDisplayMode(.inline)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top, spacing: 16) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("PolishPad")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)

                    Text("Type or dictate rough text, choose a format, and get a clearer version that stays on your iPad.")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer(minLength: 16)

                Label("Private", systemImage: "lock.shield")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.12), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }

            Text("Built for a single flow: dictate or type, tap one polish button, then copy the result into Notes, Mail, or Messages.")
                .font(.body)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.82),
                    Color.accentColor.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: 30, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.72), lineWidth: 1)
        )
    }

    private func editorsSection(wideLayout: Bool, editorHeight: CGFloat) -> some View {
        Group {
            if wideLayout {
                HStack(alignment: .top, spacing: 20) {
                    sourceEditor(minHeight: editorHeight)
                    outputEditor(minHeight: editorHeight)
                }
            } else {
                VStack(alignment: .leading, spacing: 20) {
                    sourceEditor(minHeight: editorHeight)
                    outputEditor(minHeight: editorHeight)
                }
            }
        }
    }

    private func sourceEditor(minHeight: CGFloat) -> some View {
        EditorCard(
            title: "Your Draft",
            caption: "Type or use standard iPad dictation. Your original text stays separate from the polished result.",
            placeholder: "Type or dictate here…",
            minHeight: minHeight,
            text: $model.sourceText
        ) {
            Label("Type or dictate", systemImage: "mic")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.05), in: Capsule())
        }
    }

    private func outputEditor(minHeight: CGFloat) -> some View {
        EditorCard(
            title: "Polished Result",
            caption: model.outputStatusText,
            placeholder: "Your polished text appears here. You can edit it before copying.",
            minHeight: minHeight,
            text: $model.polishedText
        ) {
            Text(model.capability.outputBadgeText)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(model.capability.usesFoundationModel ? Color.accentColor : Color.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    (model.capability.usesFoundationModel ? Color.accentColor : Color.orange)
                        .opacity(0.12),
                    in: Capsule()
                )
        }
    }

    private func modeButtonsSection(horizontalLayout: Bool) -> some View {
        let layout = horizontalLayout ? AnyLayout(HStackLayout(spacing: 16)) : AnyLayout(VStackLayout(spacing: 14))

        return VStack(alignment: .leading, spacing: 14) {
            Text("Choose a format")
                .font(.title3.weight(.semibold))
                .foregroundStyle(.primary)

            layout {
                ForEach(PolishMode.allCases) { mode in
                    ModeButton(
                        mode: mode,
                        isRunning: model.activeMode == mode
                    ) {
                        model.polish(as: mode)
                    }
                    .disabled(!model.canPolish)
                    .opacity(model.canPolish ? 1 : 0.52)
                }
            }
        }
    }

    private func footerActions(wideLayout: Bool) -> some View {
        let layout = wideLayout ? AnyLayout(HStackLayout(spacing: 14)) : AnyLayout(VStackLayout(spacing: 12))

        return layout {
            Button {
                model.copyOutput()
            } label: {
                Label(model.copied ? "Copied" : "Copy Output", systemImage: model.copied ? "checkmark" : "doc.on.doc")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.accentColor)
            .disabled(!model.canCopy)
            .controlSize(.large)

            Button(role: .destructive) {
                model.showClearConfirmation = true
            } label: {
                Label("Clear All", systemImage: "trash")
                    .font(.headline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
            .disabled(!model.canPolish && !model.canCopy)
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(uiColor: .systemGroupedBackground),
                Color.accentColor.opacity(0.06),
                Color.white
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

#Preview {
    MainView(model: PolishWorkflowModel())
}
