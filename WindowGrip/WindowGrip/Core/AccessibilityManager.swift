import Cocoa
import IOKit
import IOKit.hid

class AccessibilityManager {
    static let shared = AccessibilityManager()
    
    private init() {}
    
    func checkAccessibilityPermission() -> Bool {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String : true]
        return AXIsProcessTrustedWithOptions(options)
    }
    
    func isAccessibilityTrusted() -> Bool {
        return AXIsProcessTrusted()
    }
    
    /// Check if Input Monitoring permission is granted
    /// This is separate from Accessibility and required for keyboard/mouse monitoring on macOS 10.15+
    func checkInputMonitoringPermission() -> Bool {
        // Try to create an event tap - if it fails, we likely don't have permission
        let eventMask = (1 << CGEventType.keyDown.rawValue)
        let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { _, _, event, _ in Unmanaged.passUnretained(event) },
            userInfo: nil
        )
        
        if tap == nil {
            return false
        }
        return true
    }
}
