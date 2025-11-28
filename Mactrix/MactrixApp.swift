import SwiftUI
import OSLog

let applicationID = "dk.qpqp.mactrix"

@main
struct MactrixApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State var appState = AppState()

    var body: some Scene {
        WindowGroup(id: "main") {
            MainView()
        }
        .windowToolbarStyle(.unifiedCompact)
        .environment(appState)
        .commands {
            AppCommands()
        }

        Settings {
            SettingsView()
        }
        .environment(appState)
    }
}
