import Cocoa

class ModifierKeyDetector {
    static let shared = ModifierKeyDetector()
    
    private init() {}
    
    func currentModifiers() -> NSEvent.ModifierFlags {
        return NSEvent.modifierFlags.intersection(.deviceIndependentFlagsMask)
    }
    
    func isPressed(flags: NSEvent.ModifierFlags, matching target: NSEvent.ModifierFlags) -> Bool {
        // Check if the target flags are set in the current flags.
        // We use .isSuperset(of:) semantic logic: (current & target) == target
        let cleanFlags = flags.intersection(.deviceIndependentFlagsMask)
        return cleanFlags.contains(target)
    }
}
