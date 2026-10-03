import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsStore()
    @StateObject private var remote = RemoteSession()
    @State private var isPlaying = false

    var body: some View {
        if isPlaying {
            SemaforoPlayView(settings: settings, remote: remote, isPlaying: $isPlaying)
        } else {
            SettingsView(settings: settings, remote: remote, isPlaying: $isPlaying)
        }
    }
}

#Preview {
    ContentView()
}
