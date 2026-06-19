import SwiftUI
import MoonlitCore

struct NetworkOfflineBanner: View {
    @ObservedObject private var monitor = NetworkMonitor.shared

    var body: some View {
        if !monitor.isConnected {
            HStack {
                Image(systemName: "wifi.slash")
                    .foregroundColor(.white)
                Text("No internet connection")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.white)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color.red.opacity(0.9))
        }
    }
}
