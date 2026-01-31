import SwiftUI
import Combine

class UserConfig: ObservableObject {
    static let shared = UserConfig()
    
    @Published var moveModifiers: NSEvent.ModifierFlags = [.shift, .control]
    @Published var resizeModifiers: NSEvent.ModifierFlags = [.control, .command]
    
    private init() {
        loadSettings()
    }
    
    func loadSettings() {
        if let moveRaw = UserDefaults.standard.object(forKey: "moveModifiers") as? UInt {
            moveModifiers = NSEvent.ModifierFlags(rawValue: moveRaw)
        }
        if let resizeRaw = UserDefaults.standard.object(forKey: "resizeModifiers") as? UInt {
            resizeModifiers = NSEvent.ModifierFlags(rawValue: resizeRaw)
        }
    }
    
    func saveSettings() {
        UserDefaults.standard.set(moveModifiers.rawValue, forKey: "moveModifiers")
        UserDefaults.standard.set(resizeModifiers.rawValue, forKey: "resizeModifiers")
    }
}
