import Cocoa

class WindowResizer {
    private var isResizing = false
    private var isProcessing = false
    private var initialWindowSize: CGSize?
    private var initialMousePosition: CGPoint?
    private var targetWindow: AXUIElement?
    private var lastUpdateTime: TimeInterval = 0
    private let throttleInterval: TimeInterval = 0.016  // 60fps (16ms)
    
    func handle(event: CGEvent, type: CGEventType) -> Bool {
        switch type {
        case .mouseMoved:
            // Start or continue resizing
            if !isResizing {
                // Start new resize operation
                if let window = WindowManager.shared.getWindowUnderCursor() {
                    targetWindow = window
                    initialWindowSize = WindowManager.shared.getWindowSize(window)
                    initialMousePosition = event.location
                    isResizing = true
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
                
                // Continue resizing
                if let startSize = initialWindowSize, let startMousePos = initialMousePosition, let window = targetWindow {
                    isProcessing = true
                    lastUpdateTime = now
                    
                    let currentMousePos = event.location
                    let deltaX = currentMousePos.x - startMousePos.x
                    let deltaY = currentMousePos.y - startMousePos.y
                    
                    var newWidth = startSize.width + deltaX
                    var newHeight = startSize.height + deltaY
                    
                    // Minimum size constraint
                    newWidth = max(50, newWidth)
                    newHeight = max(50, newHeight)
                    
                    let newSize = CGSize(width: newWidth, height: newHeight)
                    
                    // Perform resize asynchronously to prevent blocking
                    DispatchQueue.global(qos: .userInteractive).async { [weak self] in
                        WindowManager.shared.setWindowSize(window, size: newSize)
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
        isResizing = false
        isProcessing = false
        targetWindow = nil
        initialWindowSize = nil
        initialMousePosition = nil
        lastUpdateTime = 0
    }
}
