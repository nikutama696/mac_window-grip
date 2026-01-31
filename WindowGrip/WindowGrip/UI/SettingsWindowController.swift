import Cocoa
import SwiftUI

class SettingsWindowController: NSWindowController {
    static let shared = SettingsWindowController()
    
    private init() {
        let settingsView = SettingsView()
        let hostingController = NSHostingController(rootView: settingsView)
        
        // Create a standard window
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        
        window.title = "Settings"
        window.contentViewController = hostingController
        window.center()
        window.isReleasedWhenClosed = false
        // Ensure it stays on top of other windows since it's an accessory app
        window.level = .floating
        
        super.init(window: window)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func show() {
        if let window = window {
            // Bring app to front first (important for menu bar apps)
            NSApp.activate(ignoringOtherApps: true)
            window.center() // Center every time
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless() // Force it
        }
    }
}
