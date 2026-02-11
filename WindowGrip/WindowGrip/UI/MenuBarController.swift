import Cocoa

class MenuBarController: NSObject {
    var statusItem: NSStatusItem!
    
    override init() {
        super.init()
        setupMenuBar()
    }
    
    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "squares.leading.rectangle", accessibilityDescription: "WindowGrip")
        }
        
        let menu = NSMenu()
        menu.addItem(NSMenuItem(title: "WindowGrip is Active", action: nil, keyEquivalent: ""))
        menu.addItem(NSMenuItem.separator())
        
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(showSettings), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let restartItem = NSMenuItem(title: "Restart", action: #selector(restart), keyEquivalent: "r")
        restartItem.target = self
        menu.addItem(restartItem)
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func showSettings() {
        SettingsWindowController.shared.show()
    }
    
    @objc func restart() {
        // Get the path to the app bundle
        let appPath = Bundle.main.bundlePath
        let task = Process()
        
        // Use 'open' command to relaunch the app
        task.launchPath = "/usr/bin/open"
        task.arguments = [appPath]
        
        // Schedule the relaunch after a short delay to ensure clean termination
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            do {
                try task.run()
                // Terminate current instance
                NSApplication.shared.terminate(nil)
            } catch {
                print("Failed to restart: \(error)")
                // If restart fails, just quit
                NSApplication.shared.terminate(nil)
            }
        }
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
