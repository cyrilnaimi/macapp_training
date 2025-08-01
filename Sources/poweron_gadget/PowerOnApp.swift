import SwiftUI
import AppKit

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

@main
struct PowerOnApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var locale: Locale

    init() {
        var currentLocale = Locale.current
        for i in 0..<CommandLine.arguments.count {
            if CommandLine.arguments[i] == "--lang" && i + 1 < CommandLine.arguments.count {
                let langCode = CommandLine.arguments[i+1]
                currentLocale = Locale(identifier: langCode)
                break
            }
        }
        _locale = State(initialValue: currentLocale)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.locale, locale)
        }
    }
}