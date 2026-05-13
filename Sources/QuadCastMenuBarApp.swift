import SwiftUI

@main
struct QuadCastMenuBarApp: App {
    @StateObject private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView(appState: appState)
        } label: {
            Image(systemName: appState.isConnected ? "mic.fill" : "mic.slash")
        }
        .menuBarExtraStyle(.window)
    }
}
