import ServiceManagement
import SwiftUI

class LoginItemManager: ObservableObject {
    static let shared = LoginItemManager()
    
    @Published var isLoginItemEnabled: Bool = false {
        didSet {
            updateLoginItem()
        }
    }
    
    private init() {
        // SMAppService is available on macOS 13+. For older versions, SMLoginItemSetEnabled is used.
        // Assuming macOS 13+ (Ventura) as per requirements (macOS 15.1 specified).
        checkStatus()
    }
    
    private func checkStatus() {
        let service = SMAppService.mainApp
        isLoginItemEnabled = (service.status == .enabled)
    }
    
    private func updateLoginItem() {
        let service = SMAppService.mainApp
        do {
            if isLoginItemEnabled {
                if service.status != .enabled {
                    try service.register()
                }
            } else {
                if service.status == .enabled {
                    try service.unregister()
                }
            }
        } catch {
            print("Failed to update login item: \(error)")
        }
    }
}
