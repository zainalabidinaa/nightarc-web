import SwiftUI
import LunaCore

struct MacSubtitleAppearanceView: View {
    @StateObject private var store = SubtitleAppearanceStore.shared
    @Environment(\.dismiss) private var dismiss

    // Local mirror for live preview — synced to store on change
    @State private var fontSize: Double = SubtitleAppearanceStore.shared.fontSize
    @State private var scale: Double = SubtitleAppearanceStore.shared.scale
    @State private var isBold: Bool = SubtitleAppearanceStore.shared.isBold
    @State private var isItalic: Bool = SubtitleAppearanceStore.shared.isItalic
    @State private var textColorHex: String = SubtitleAppearanceStore.shared.textColorHex
    @State private var outlineColorHex: String = SubtitleAppearanceStore.shared.outlineColorHex
    @State private var backgroundColorHex: String = SubtitleAppearanceStore.shared.backgroundColorHex
    @State private var backgroundOpacity: Double = SubtitleAppearanceStore.shared.backgroundOpacity
    @State private var verticalPosition: Double = SubtitleAppearanceStore.shared.verticalPosition
    @State private var horizontalAlignment: SubtitleAlignment = SubtitleAppearanceStore.shared.horizontalAlignment
    @State private var horizontalMargin: Double = SubtitleAppearanceStore.shared.horizontalMargin
    @State private var textBlur: Double = SubtitleAppearanceStore.shared.textBlur
    @State private var scaleWithWindowSize: Bool = SubtitleAppearanceStore.shared.scaleWithWindowSize

    private let alignments: [SubtitleAlignment] = [.left, .center, .right]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                previewPanel
                presetsSection
                fontSection
                colorsSection
                positionSection
                advancedSection
                resetButton
                Spacer().frame(height: 32)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
        }
        .frame(minWidth: 480, minHeight: 600)
        .background(LunaTheme.background)
        .navigationTitle("Subtitle Appearance")
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Done") { dismiss() }
            }
        }
    }

    // MARK: - Preview

    private var previewPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.black)
                .frame(height: 120)
                .overlay(
                    Image(systemName: "play.fill")
                        .font(.system(size: 30))
                        .foregroundColor(Color.white.opacity(0.08))
                )
            VStack {
                Spacer()
                Text("The quick brown fox jumps over the lazy dog")
                    .font(.system(
                        size: min(fontSize * 0.5, 18),
                        weight: isBold ? .bold : .regular
                    ))
                    .italic(isItalic)
                    .foregroundColor(Color(hex: textColorHex) ?? .white)
                    .shadow(color: (Color(hex: outlineColorHex) ?? .black).opacity(0.9), radius: 1, x: 1, y: 1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        (Color(hex: backgroundColorHex) ?? .black).opacity(backgroundOpacity)
                            .cornerRadius(4)
                    )
                    .padding(.bottom, 10)
            }
        }
    }

    // MARK: - Presets

    private var presetsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            subtitleSectionLabel("Presets")
            VStack(spacing: 0) {
                ForEach(SubtitlePreset.allCases, id: \.self) { preset in
                    Button {
                        applyPreset(preset)
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.displayName)
                                    .font(.subheadline)
                                    .foregroundColor(.white)
                                Text(preset.description)
                                    .font(.caption)
                                    .foregroundColor(LunaTheme.textSecondary)
                            }
                            Spacer()
                            if store.preset == preset {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(LunaTheme.accent)
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    if preset != SubtitlePreset.allCases.last {
                        Divider().background(Color.white.opacity(0.08))
                    }
                }
            }
            .background(LunaTheme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Font

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            subtitleSectionLabel("Font")
            VStack(spacing: 0) {
                sliderRow("Font Size", value: $fontSize, range: 12...72, step: 1, format: "%.0f pt") {
                    store.fontSize = fontSize
                }
                Divider().background(Color.white.opacity(0.08))
                sliderRow("Scale", value: $scale, range: 0.5...2.0, step: 0.1, format: "%.1fx") {
                    store.scale = scale
                }
                Divider().background(Color.white.opacity(0.08))
                Toggle(isOn: $isBold) {
                    Text("Bold").font(.subheadline).foregroundColor(.white)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .onChange(of: isBold) { _, v in store.isBold = v }
                Divider().background(Color.white.opacity(0.08))
                Toggle(isOn: $isItalic) {
                    Text("Italic").font(.subheadline).foregroundColor(.white)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .onChange(of: isItalic) { _, v in store.isItalic = v }
            }
            .background(LunaTheme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Colors

    private var colorsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            subtitleSectionLabel("Colors")
            VStack(spacing: 0) {
                colorRow("Text Color", hex: $textColorHex) { store.textColorHex = textColorHex }
                Divider().background(Color.white.opacity(0.08))
                colorRow("Outline Color", hex: $outlineColorHex) { store.outlineColorHex = outlineColorHex }
                Divider().background(Color.white.opacity(0.08))
                colorRow("Background Color", hex: $backgroundColorHex) { store.backgroundColorHex = backgroundColorHex }
                Divider().background(Color.white.opacity(0.08))
                sliderRow(
                    "Background Opacity",
                    value: $backgroundOpacity,
                    range: 0...1,
                    step: 0.05,
                    format: "%.0f%%",
                    displayScale: 100
                ) {
                    store.backgroundOpacity = backgroundOpacity
                }
            }
            .background(LunaTheme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Position

    private var positionSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            subtitleSectionLabel("Position")
            VStack(spacing: 0) {
                sliderRow("Vertical Position", value: $verticalPosition, range: 0...200, step: 1, format: "%.0f px") {
                    store.verticalPosition = verticalPosition
                }
                Divider().background(Color.white.opacity(0.08))
                HStack {
                    Text("Alignment").font(.subheadline).foregroundColor(.white)
                    Spacer()
                    Picker("", selection: $horizontalAlignment) {
                        ForEach(alignments, id: \.self) { a in
                            Text(a.rawValue.capitalized).tag(a)
                        }
                    }
                    .labelsHidden()
                    .onChange(of: horizontalAlignment) { _, v in store.horizontalAlignment = v }
                }
                .padding(.horizontal, 16).padding(.vertical, 8)
                Divider().background(Color.white.opacity(0.08))
                sliderRow("Horizontal Margin", value: $horizontalMargin, range: 0...100, step: 1, format: "%.0f px") {
                    store.horizontalMargin = horizontalMargin
                }
            }
            .background(LunaTheme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Advanced

    private var advancedSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            subtitleSectionLabel("Advanced")
            VStack(spacing: 0) {
                sliderRow("Text Blur", value: $textBlur, range: 0...5, step: 0.1, format: "%.1f") {
                    store.textBlur = textBlur
                }
                Divider().background(Color.white.opacity(0.08))
                Toggle(isOn: $scaleWithWindowSize) {
                    Text("Scale with Window Size").font(.subheadline).foregroundColor(.white)
                }
                .toggleStyle(.switch)
                .padding(.horizontal, 16).padding(.vertical, 12)
                .onChange(of: scaleWithWindowSize) { _, v in store.scaleWithWindowSize = v }
            }
            .background(LunaTheme.surface)
            .cornerRadius(10)
        }
    }

    // MARK: - Reset

    private var resetButton: some View {
        Button("Reset to Defaults") {
            store.resetToDefaults()
            syncFromStore()
        }
        .font(.subheadline)
        .foregroundColor(.red)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(LunaTheme.surface)
        .cornerRadius(10)
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func applyPreset(_ preset: SubtitlePreset) {
        store.preset = preset
        switch preset {
        case .standard:
            store.textColorHex = "#FFFFFF"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.0
            store.isBold = false
        case .boxed:
            store.textColorHex = "#FFFFFF"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.75
            store.isBold = false
        case .classic:
            store.textColorHex = "#FFFF00"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.0
            store.isBold = false
        case .minimal:
            store.textColorHex = "#FFFFFF"
            store.outlineColorHex = "#000000"
            store.backgroundColorHex = "#000000"
            store.backgroundOpacity = 0.0
            store.isBold = false
        }
        syncFromStore()
    }

    private func syncFromStore() {
        fontSize = store.fontSize
        scale = store.scale
        isBold = store.isBold
        isItalic = store.isItalic
        textColorHex = store.textColorHex
        outlineColorHex = store.outlineColorHex
        backgroundColorHex = store.backgroundColorHex
        backgroundOpacity = store.backgroundOpacity
        verticalPosition = store.verticalPosition
        horizontalAlignment = store.horizontalAlignment
        horizontalMargin = store.horizontalMargin
        textBlur = store.textBlur
        scaleWithWindowSize = store.scaleWithWindowSize
    }

    private func sliderRow(
        _ title: String,
        value: Binding<Double>,
        range: ClosedRange<Double>,
        step: Double,
        format: String,
        displayScale: Double = 1.0,
        onChange: @escaping () -> Void
    ) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.subheadline).foregroundColor(.white)
                Spacer()
                Text(String(format: format, value.wrappedValue * displayScale))
                    .font(.caption.monospacedDigit())
                    .foregroundColor(LunaTheme.textSecondary)
            }
            Slider(value: value, in: range, step: step)
                .tint(LunaTheme.accent)
                .onChange(of: value.wrappedValue) { _, _ in onChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    private func colorRow(_ title: String, hex: Binding<String>, onChange: @escaping () -> Void) -> some View {
        HStack {
            Text(title).font(.subheadline).foregroundColor(.white)
            Spacer()
            Circle()
                .fill(Color(hex: hex.wrappedValue) ?? .white)
                .frame(width: 20, height: 20)
                .overlay(Circle().stroke(Color.white.opacity(0.2), lineWidth: 1))
            TextField("#RRGGBB", text: hex)
                .textFieldStyle(.plain)
                .font(.caption.monospaced())
                .foregroundColor(LunaTheme.textSecondary)
                .frame(width: 72)
                .multilineTextAlignment(.trailing)
                .onChange(of: hex.wrappedValue) { _, _ in onChange() }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

@MainActor
private func subtitleSectionLabel(_ text: String) -> some View {
    Text(text.uppercased())
        .font(.caption.weight(.semibold))
        .foregroundColor(LunaTheme.textTertiary)
        .padding(.top, 4)
        .padding(.bottom, 2)
}
