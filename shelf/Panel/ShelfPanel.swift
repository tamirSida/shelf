//
//  ShelfPanel.swift
//  shelf
//

import AppKit
import SwiftUI

class ShelfPanel: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 200),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        isFloatingPanel = true
        level = .statusBar  // Higher level to stay above other windows
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false  // Don't hide when app loses focus
        isMovableByWindowBackground = false

        // Allow the panel to become key to receive keyboard events
        becomesKeyOnlyIfNeeded = true

        // Ensure it stays visible
        isReleasedWhenClosed = false
    }

    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}
