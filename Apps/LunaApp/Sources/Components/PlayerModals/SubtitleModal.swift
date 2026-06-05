import SwiftUI
import LunaCore

struct SubtitleModal: View {
    @ObservedObject var engine: PlayerEngine
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                List {
                    Section("Off") {
                        Button {
                            engine.setSubtitle(nil)
                            dismiss()
                        } label: {
                            HStack {
                                Text("None")
                                    .foregroundColor(.white)
                                Spacer()
                                if engine.selectedSubtitle == nil {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(LunaTheme.accent)
                                }
                            }
                        }
                        .listRowBackground(LunaTheme.surface)
                    }

                    if !engine.availableSubtitles.isEmpty {
                        Section("Available") {
                            ForEach(engine.availableSubtitles) { subtitle in
                                Button {
                                    engine.setSubtitle(subtitle)
                                    dismiss()
                                } label: {
                                    HStack {
                                        Text(subtitle.name ?? subtitle.lang)
                                            .foregroundColor(.white)
                                        Spacer()
                                        if engine.selectedSubtitle?.id == subtitle.id {
                                            Image(systemName: "checkmark")
                                                .foregroundColor(LunaTheme.accent)
                                        }
                                    }
                                }
                                .listRowBackground(LunaTheme.surface)
                            }
                        }
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Subtitles")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
