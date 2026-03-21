import AppKit
import Carbon.HIToolbox

class HotkeyManager {
    private let action: () -> Void
    private var hotKeyRef: EventHotKeyRef?
    private static var sharedAction: (() -> Void)?

    // Default hotkey: Cmd+Shift+7
    init(action: @escaping () -> Void) {
        self.action = action
        HotkeyManager.sharedAction = action
        registerCarbonHotkey()
    }

    deinit {
        if let ref = hotKeyRef {
            UnregisterEventHotKey(ref)
        }
    }

    private func registerCarbonHotkey() {
        // Install Carbon event handler
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        InstallEventHandler(
            GetApplicationEventTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.sharedAction?()
                return noErr
            },
            1,
            &eventType,
            nil,
            nil
        )

        // Register Cmd+Shift+7
        let hotKeyID = EventHotKeyID(
            signature: OSType(0x53435348), // "SCSH"
            id: 1
        )

        let modifiers: UInt32 = UInt32(cmdKey | shiftKey)

        RegisterEventHotKey(
            UInt32(kVK_ANSI_7),
            modifiers,
            hotKeyID,
            GetApplicationEventTarget(),
            0,
            &hotKeyRef
        )
    }
}
