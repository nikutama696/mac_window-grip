import Cocoa

class WindowMover {
    private var isMoving = false
    private var isProcessing = false
    private var initialWindowPosition: CGPoint?
    private var initialMousePosition: CGPoint?
    private var targetWindow: AXUIElement?
    private var lastUpdateTime: TimeInterval = 0
    private let throttleInterval: TimeInterval = 0.016  // 60fps (16ms)
    
    func handle(event: CGEvent, type: CGEventType) -> Bool {
        switch type {
        case .mouseMoved:
            // Start or continue moving
            if !isMoving {
                // Start new move operation
                if let window = WindowManager.shared.getWindowUnderCursor() {
                    targetWindow = window
                    initialWindowPosition = WindowManager.shared.getWindowPosition(window)
                    initialMousePosition = event.location
                    isMoving = true
                    lastUpdateTime = Date().timeIntervalSince1970
                    return true
                }
            } else {
                // Time-based throttling
                let now = Date().timeIntervalSince1970
                if now - lastUpdateTime < throttleInterval {
                    return true  // Skip this event
                }
                
                // Skip if already processing
                if isProcessing {
                    return true
                }
                
                // Continue moving
                if let startWindowPos = initialWindowPosition, let startMousePos = initialMousePosition, let window = targetWindow {
                    isProcessing = true
                    lastUpdateTime = now
                    
                    let currentMousePos = event.location
                    let deltaX = currentMousePos.x - startMousePos.x
                    let deltaY = currentMousePos.y - startMousePos.y
                    
                    // Allow windows to move beyond menu bar (no Y restriction)
                    let newPosition = CGPoint(x: startWindowPos.x + deltaX, y: startWindowPos.y + deltaY)
                    
                    // Perform move asynchronously
                    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                        WindowManager.shared.setWindowPosition(window, position: newPosition)
                        DispatchQueue.main.async {
                            self?.isProcessing = false
                        }
                    }
                    
                    return true
                }
            }
            
        default:
            break
        }
        
        return false
    }
    
    func reset() {
        isMoving = false
        isProcessing = false
        targetWindow = nil
        initialWindowPosition = nil
        initialMousePosition = nil
        lastUpdateTime = 0
    }
}
