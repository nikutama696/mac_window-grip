import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate, EventMonitorDelegate {
    var menuBarController: MenuBarController?
    
    // Feature handlers
    private let windowMover = WindowMover()
    private let windowResizer = WindowResizer()
    
    // Track last known non-zero modifier state
    private var lastKnownModifierFlags: CGEventFlags = []
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Build timestamp for version tracking
        let buildDate = "2026-02-11 16:15:00"
        print("WindowGrip started - Build: \(buildDate)")
        
        // Request accessibility permissions
        if !AccessibilityManager.shared.checkAccessibilityPermission() {
             print("WARNING: Accessibility permission missing")
            let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
            NSWorkspace.shared.open(url)
        } else {
            print("Accessibility permission granted")
        }
        
        // Check Input Monitoring permission (separate from Accessibility on macOS 10.15+)
        if !AccessibilityManager.shared.checkInputMonitoringPermission() {
            print("WARNING: Input Monitoring permission may be missing!")
            print("Please go to System Settings > Privacy & Security > Input Monitoring")
            print("and enable the Terminal application (or the WindowGrip app if running standalone).")
            // Open Input Monitoring settings
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_ListenEvent") {
                NSWorkspace.shared.open(url)
            }
        } else {
            print("Input Monitoring permission granted")
        }
        
        // Initialize menu bar controller
        menuBarController = MenuBarController()
        
        // Start monitoring
        EventMonitor.shared.delegate = self
        EventMonitor.shared.startMonitoring()
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        EventMonitor.shared.stopMonitoring()
    }
    
    func handleMouseEvent(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>? {
        // Track modifier state from flagsChanged events
        if type == .flagsChanged {
            let flags = event.flags
            let filtered = NSEvent.ModifierFlags(rawValue: UInt(flags.rawValue)).intersection(.deviceIndependentFlagsMask)
            // Only save if it contains actual modifier keys
            if filtered.rawValue != 0 {
                lastKnownModifierFlags = flags
            } else {
                // Modifier keys released - reset all operations
                lastKnownModifierFlags = []
                windowMover.reset()
                windowResizer.reset()
            }
        }
        
        // Get from User Config
        let moveModifiers = UserConfig.shared.moveModifiers
        let resizeModifiers = UserConfig.shared.resizeModifiers
        
        // In CGEvent callback context, NSEvent.modifierFlags may not work reliably
        // Use our tracked state from flagsChanged events
        let trackedModifiers = NSEvent.ModifierFlags(rawValue: UInt(lastKnownModifierFlags.rawValue)).intersection(.deviceIndependentFlagsMask)
        
        // Fallback to NSEvent.modifierFlags if we have no tracked state
        let nsEventModifiers = NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
        
        // Use tracked if available, otherwise use NSEvent
        let currentModifiers = trackedModifiers.rawValue != 0 ? trackedModifiers : nsEventModifiers
        
        // Early return for mouseMoved events without relevant modifiers
        // This prevents blocking the UI when just moving the mouse normally
        if type == .mouseMoved {
            let hasRelevantModifiers = currentModifiers.contains(moveModifiers) || 
                                       currentModifiers.contains(resizeModifiers)
            if !hasRelevantModifiers {
                return Unmanaged.passUnretained(event)
            }
        }
        
        // Check for Move operation
        if currentModifiers.contains(moveModifiers) {
            if windowMover.handle(event: event, type: type) {
                return nil // Consume event
            }
        }
        
        // Check for Resize operation
        if currentModifiers.contains(resizeModifiers) {
            if windowResizer.handle(event: event, type: type) {
                return nil // Consume event
            }
        }
        
        return Unmanaged.passUnretained(event)
    }
}
