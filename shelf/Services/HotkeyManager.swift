//
//  HotkeyManager.swift
//  shelf
//

import AppKit
import Carbon

final class HotkeyManager {
    static let shared = HotkeyManager()

    private var hotKeyRef: EventHotKeyRef?
    private var callback: (() -> Void)?

    // Store the handler to prevent deallocation
    private static var eventHandler: EventHandlerRef?
    private static var handlerCallback: (() -> Void)?

    private init() {}

    func register(callback: @escaping () -> Void) {
        self.callback = callback
        HotkeyManager.handlerCallback = callback

        // Install handler for hotkey events
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )

        let status = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (_, event, _) -> OSStatus in
                HotkeyManager.handlerCallback?()
                return noErr
            },
            1,
            &eventType,
            nil,
            &HotkeyManager.eventHandler
        )

        guard status == noErr else {
            print("Failed to install event handler: \(status)")
            return
        }

        // Register Control + ` (backtick, keyCode 50)
        var hotkeyID = EventHotKeyID(
            signature: OSType(0x53484C46), // "SHLF"
            id: 1
        )

        let registerStatus = RegisterEventHotKey(
            50, // keyCode for backtick
            UInt32(controlKey), // Control modifier
            hotkeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )

        if registerStatus != noErr {
            print("Failed to register hotkey: \(registerStatus)")
        }
    }

    func unregister() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
        if let handler = HotkeyManager.eventHandler {
            RemoveEventHandler(handler)
            HotkeyManager.eventHandler = nil
        }
        callback = nil
        HotkeyManager.handlerCallback = nil
    }

    deinit {
        unregister()
    }
}
