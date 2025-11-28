import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("Did finish launching")
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        print("Open urls: \(urls)")
    }
}
