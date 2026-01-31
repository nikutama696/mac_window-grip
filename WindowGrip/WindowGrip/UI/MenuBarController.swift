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
        
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        statusItem.menu = menu
    }
    
    @objc func showSettings() {
        SettingsWindowController.shared.show()
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(nil)
    }
}
