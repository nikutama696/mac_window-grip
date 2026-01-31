import SwiftUI

struct SettingsView: View {
    @ObservedObject var settings = UserConfig.shared
    @ObservedObject var loginItemManager = LoginItemManager.shared
    
    var body: some View {
        Form {
            Section(header: Text("Shortcuts")) {
                ModifierKeyPicker(label: "Move Window:", selection: $settings.moveModifiers)
                ModifierKeyPicker(label: "Resize Window:", selection: $settings.resizeModifiers)
            }
            
            Section(header: Text("General")) {
                Toggle("Launch at Login", isOn: $loginItemManager.isLoginItemEnabled)
            }
            
            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                }
            }
        }
        .padding()
        .frame(width: 400)
        .onDisappear {
            settings.saveSettings()
        }
    }
}

struct ModifierKeyPicker: View {
    let label: String
    @Binding var selection: NSEvent.ModifierFlags
    
    var body: some View {
        HStack {
            Text(label)
            Spacer()
            // A simple representation for MVP. In a real app, a custom recorder or specialized picker is better.
            Menu {
                Button("Shift + Control") { selection = [.shift, .control] }
                Button("Control + Command") { selection = [.control, .command] }
                Button("Option + Command") { selection = [.option, .command] }
                Button("Shift + Command") { selection = [.shift, .command] }
            } label: {
                Text(modifierString(for: selection))
            }
        }
    }
    
    func modifierString(for flags: NSEvent.ModifierFlags) -> String {
        var components: [String] = []
        if flags.contains(.control) { components.append("⌃ Control") }
        if flags.contains(.option) { components.append("⌥ Option") }
        if flags.contains(.shift) { components.append("⇧ Shift") }
        if flags.contains(.command) { components.append("⌘ Command") }
        return components.joined(separator: " + ")
    }
}
