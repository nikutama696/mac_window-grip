import Cocoa

class WindowManager {
    static let shared = WindowManager()
    
    private init() {}
    
    func getWindowUnderCursor() -> AXUIElement? {
        let location = CGEvent(source: nil)?.location ?? .zero
        var element: AXUIElement?
        
        print("[DEBUG] Checking position: (\(location.x), \(location.y))")
        
        // Find system-wide element at position
        let result = AXUIElementCopyElementAtPosition(AXUIElementCreateSystemWide(), Float(location.x), Float(location.y), &element)
        
        print("[DEBUG] AXUIElementCopyElementAtPosition result: \(result.rawValue)")
        
        if result == .success, let element = element {
            // Get role of initial element
            var role: AnyObject?
            AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &role)
            if let roleStr = role as? String {
                print("[DEBUG] Initial element role: \(roleStr)")
            }
            
            if let window = findInformationWindow(from: element) {
                // Get app name for debugging
                var pid: pid_t = 0
                AXUIElementGetPid(window, &pid)
                if let app = NSRunningApplication(processIdentifier: pid) {
                    print("[DEBUG] Found window for app: \(app.localizedName ?? "Unknown")")
                }
                return window
            } else {
                print("[DEBUG] findInformationWindow returned nil")
            }
        } else {
            print("[DEBUG] Failed to get element at position, trying fallback method")
            // Fallback: Use CGWindowList for apps that don't support Accessibility properly
            if let window = getWindowUnderCursorFallback(at: location) {
                return window
            }
        }
        return nil
    }
    
    // Fallback method for apps like Adobe Illustrator that don't support Accessibility API properly
    private func getWindowUnderCursorFallback(at location: CGPoint) -> AXUIElement? {
        // Get the active (frontmost) application
        guard let activeApp = NSWorkspace.shared.frontmostApplication else {
            print("[DEBUG] Could not get frontmost application")
            return nil
        }
        
        let activePID = activeApp.processIdentifier
        print("[DEBUG] Active app: \(activeApp.localizedName ?? "Unknown"), PID: \(activePID)")
        
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            print("[DEBUG] Failed to get window list")
            return nil
        }
        
        var targetWindowID: CGWindowID?
        var targetWindowBounds: CGRect?
        
        // Find the topmost window of the active app at cursor position
        for windowInfo in windowList {
            guard let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = bounds["X"], let y = bounds["Y"],
                  let width = bounds["Width"], let height = bounds["Height"],
                  let windowLayer = windowInfo[kCGWindowLayer as String] as? Int,
                  let pid = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            
            // Only consider windows from the active application
            guard pid == activePID else { continue }
            
            // Only consider normal windows (layer 0)
            guard windowLayer == 0 else { continue }
            
            let rect = CGRect(x: x, y: y, width: width, height: height)
            if rect.contains(location) {
                // Found the first (topmost) window at this location
                targetWindowID = windowID
                targetWindowBounds = rect
                print("[DEBUG] Found target window ID: \(windowID), bounds: \(rect)")
                break  // Take the first match (topmost)
            }
        }
        
        guard let windowID = targetWindowID, let windowBounds = targetWindowBounds else {
            print("[DEBUG] No window of active app found at cursor position")
            return nil
        }
        
        // Create AXUIElement for the active application
        let appElement = AXUIElementCreateApplication(activePID)
        
        // Get all windows and find the one matching our target
        var windowsValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsValue)
        
        if result == .success, let windows = windowsValue as? [AXUIElement] {
            // Try to find matching window by size and position
            for window in windows {
                if let pos = getWindowPosition(window), let size = getWindowSize(window) {
                    let axRect = CGRect(origin: pos, size: size)
                    
                    // Match by bounds (with small tolerance for floating point)
                    if abs(axRect.origin.x - windowBounds.origin.x) < 1.0 &&
                       abs(axRect.origin.y - windowBounds.origin.y) < 1.0 &&
                       abs(axRect.size.width - windowBounds.size.width) < 1.0 &&
                       abs(axRect.size.height - windowBounds.size.height) < 1.0 {
                        print("[DEBUG] Found matching AXUIElement for window ID \(windowID)")
                        return window
                    }
                }
            }
            
            print("[DEBUG] Could not match CGWindow to AXUIElement, using fallback")
            // If we can't find exact match, return the largest window as fallback
            var largestWindow: AXUIElement?
            var maxArea: CGFloat = 0
            
            for window in windows {
                if let size = getWindowSize(window) {
                    let area = size.width * size.height
                    if area > maxArea {
                        maxArea = area
                        largestWindow = window
                    }
                }
            }
            
            if let fallbackWindow = largestWindow {
                print("[DEBUG] Returning largest window as fallback (area: \(maxArea))")
                return fallbackWindow
            }
        }
        
        return nil
    }
    
    private func findInformationWindow(from element: AXUIElement) -> AXUIElement? {
        var currentElement = element
        var role: AnyObject?
        var iterationCount = 0
        let maxIterations = 20  // Prevent infinite loops
        
        while iterationCount < maxIterations {
            iterationCount += 1
            let result = AXUIElementCopyAttributeValue(currentElement, kAXRoleAttribute as CFString, &role)
            if result == .success, let roleStr = role as? String {
                print("[DEBUG] Iteration \(iterationCount), role: \(roleStr)")
                if roleStr == kAXWindowRole {
                    print("[DEBUG] Found AXWindow at iteration \(iterationCount)")
                    return currentElement
                }
            } else {
                print("[DEBUG] Failed to get role at iteration \(iterationCount)")
            }
            
            var parent: AnyObject?
            let parentResult = AXUIElementCopyAttributeValue(currentElement, kAXParentAttribute as CFString, &parent)
            if parentResult == .success, let parentElement = parent {
                currentElement = parentElement as! AXUIElement
            } else {
                print("[DEBUG] No parent found at iteration \(iterationCount)")
                break
            }
        }
        
        if iterationCount >= maxIterations {
            print("[DEBUG] Reached max iterations without finding window")
        }
        return nil
    }
    
    func getWindowPosition(_ window: AXUIElement) -> CGPoint? {
        var positionValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXPositionAttribute as CFString, &positionValue)
        
        if result == .success, let value = positionValue {
            // value is likely already AXValue or CFTypeRef that is compatible
            let axValue = value as! AXValue
            var point = CGPoint.zero
            AXValueGetValue(axValue, .cgPoint, &point)
            return point
        }
        return nil
    }
    
    func setWindowPosition(_ window: AXUIElement, position: CGPoint) {
        var point = position
        if let value = AXValueCreate(.cgPoint, &point) {
            let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
            if result != .success {
                print("[DEBUG] Failed to set position: \(result.rawValue)")
                
                // If position is above menu bar (negative Y or very small Y), try workaround
                if position.y < 25 {
                    print("[DEBUG] Attempting to bypass menu bar restriction")
                    bypassMenuBarRestriction(window: window, position: position)
                }
            }
        }
    }
    
    // Try to bypass macOS menu bar restriction
    private func bypassMenuBarRestriction(window: AXUIElement, position: CGPoint) {
        // Get the window's PID
        var pid: pid_t = 0
        guard AXUIElementGetPid(window, &pid) == .success else {
            print("[DEBUG] Could not get PID for window")
            return
        }
        
        // Get window bounds
        guard let currentSize = getWindowSize(window) else {
            print("[DEBUG] Could not get window size")
            return
        }
        
        // Use CGWindow API to find and move the window
        guard let windowList = CGWindowListCopyWindowInfo([.optionOnScreenOnly, .excludeDesktopElements], kCGNullWindowID) as? [[String: Any]] else {
            return
        }
        
        // Find matching window by PID and size
        for windowInfo in windowList {
            guard let bounds = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let width = bounds["Width"], let height = bounds["Height"],
                  let windowPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  let windowID = windowInfo[kCGWindowNumber as String] as? CGWindowID else {
                continue
            }
            
            // Match by PID and size
            if windowPID == pid && abs(width - currentSize.width) < 1.0 && abs(height - currentSize.height) < 1.0 {
                print("[DEBUG] Found matching CGWindow ID: \(windowID)")
                
                // Try to move using CGPrivate API (this may not work due to sandboxing)
                // As a workaround, we'll try setting the position multiple times
                for attempt in 1...3 {
                    var newPoint = position
                    if let value = AXValueCreate(.cgPoint, &newPoint) {
                        let result = AXUIElementSetAttributeValue(window, kAXPositionAttribute as CFString, value)
                        if result == .success {
                            print("[DEBUG] Successfully set position on attempt \(attempt)")
                            break
                        }
                        // Small delay between attempts
                        usleep(10000) // 10ms
                    }
                }
                break
            }
        }
    }
    
    func getWindowSize(_ window: AXUIElement) -> CGSize? {
        var sizeValue: AnyObject?
        let result = AXUIElementCopyAttributeValue(window, kAXSizeAttribute as CFString, &sizeValue)
        
        if result == .success, let value = sizeValue {
             let axValue = value as! AXValue
            var size = CGSize.zero
            AXValueGetValue(axValue, .cgSize, &size)
            return size
        }
        return nil
    }
    
    func setWindowSize(_ window: AXUIElement, size: CGSize) {
        var newSize = size
        if let value = AXValueCreate(.cgSize, &newSize) {
            let result = AXUIElementSetAttributeValue(window, kAXSizeAttribute as CFString, value)
            if result != .success {
                print("[DEBUG] Failed to set size: \(result.rawValue)")
            }
        }
    }
}
