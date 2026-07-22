import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsStore()
    @State private var isPlaying = false

    var body: some View {
        if isPlaying {
            SemaforoPlayView(settings: settings, isPlaying: $isPlaying)
        } else {
            SettingsView(settings: settings, isPlaying: $isPlaying)
        }
    }
}

#Preview {
    ContentView()
}
