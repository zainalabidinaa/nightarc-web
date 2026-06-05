import SwiftUI
import LunaCore

struct AudioTrackModal: View {
    @ObservedObject var engine: PlayerEngine
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                LunaTheme.background.ignoresSafeArea()

                List {
                    ForEach(engine.availableAudioTracks, id: \.self) { track in
                        Button {
                            engine.selectedAudioTrack = track
                            dismiss()
                        } label: {
                            HStack {
                                Text(track)
                                    .foregroundColor(.white)
                                Spacer()
                                if engine.selectedAudioTrack == track {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(LunaTheme.accent)
                                }
                            }
                        }
                        .listRowBackground(LunaTheme.surface)
                    }
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Audio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
