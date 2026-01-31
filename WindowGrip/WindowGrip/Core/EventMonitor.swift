import Cocoa

protocol EventMonitorDelegate: AnyObject {
    func handleMouseEvent(event: CGEvent, type: CGEventType) -> Unmanaged<CGEvent>?
}

class EventMonitor {
    static let shared = EventMonitor()
    
    weak var delegate: EventMonitorDelegate?
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?
    
    private init() {}
    
    func startMonitoring() {
        let eventMask = (1 << CGEventType.leftMouseDown.rawValue) |
                        (1 << CGEventType.leftMouseDragged.rawValue) |
                        (1 << CGEventType.leftMouseUp.rawValue) |
                        (1 << CGEventType.mouseMoved.rawValue) |
                        (1 << CGEventType.flagsChanged.rawValue)
        
        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .headInsertEventTap,
            options: .defaultTap,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                // Perform lightweight check first
                // Ignore events from our own process to prevent blocking menu bar interactions
                let pid = event.getIntegerValueField(.eventSourceUnixProcessID)
                if pid == getpid() {
                    return Unmanaged.passUnretained(event)
                }
                
                if let observer = Unmanaged<EventMonitor>.fromOpaque(refcon!).takeUnretainedValue() as EventMonitor?,
                   let delegate = observer.delegate {
                    return delegate.handleMouseEvent(event: event, type: type)
                }
                return Unmanaged.passUnretained(event)
            },
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else {
            print("Failed to create event tap")
            return
        }
        
        self.eventTap = eventTap
        self.runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("Event monitoring started")
    }
    
    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            }
        }
    }
}
