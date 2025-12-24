//
//  ShelfPanelController.swift
//  shelf
//

import AppKit
import SwiftUI

@Observable
final class ShelfPanelController {
    private var panel: ShelfPanel?
    private(set) var isVisible: Bool = false

    func togglePanel(with store: ShelfStore) {
        if isVisible {
            hidePanel()
        } else {
            showPanel(with: store)
        }
    }

    func showPanel(with store: ShelfStore) {
        guard !isVisible else { return }

        if panel == nil {
            createPanel()
        }

        guard let panel = panel, let screen = NSScreen.main else { return }

        // Set content
        let contentView = ShelfContentView(store: store, onDismiss: { [weak self] in
            self?.hidePanel()
        })
        panel.contentView = NSHostingView(rootView: contentView)

        // Position at top center of screen
        let panelWidth: CGFloat = min(800, screen.visibleFrame.width - 40)
        let panelHeight: CGFloat = 220
        let xPos = screen.frame.midX - panelWidth / 2
        let yPos = screen.visibleFrame.maxY - panelHeight - 10

        panel.setFrame(NSRect(x: xPos, y: yPos + panelHeight, width: panelWidth, height: panelHeight), display: false)
        panel.alphaValue = 0

        panel.orderFrontRegardless()

        // Animate in
        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            context.timingFunction = CAMediaTimingFunction(name: .easeOut)
            panel.animator().setFrame(NSRect(x: xPos, y: yPos, width: panelWidth, height: panelHeight), display: true)
            panel.animator().alphaValue = 1
        }

        isVisible = true
    }

    func hidePanel() {
        guard isVisible, let panel = panel else { return }

        let currentFrame = panel.frame

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.15
            context.timingFunction = CAMediaTimingFunction(name: .easeIn)
            panel.animator().setFrame(
                NSRect(x: currentFrame.origin.x, y: currentFrame.origin.y + currentFrame.height, width: currentFrame.width, height: currentFrame.height),
                display: true
            )
            panel.animator().alphaValue = 0
        } completionHandler: { [weak self] in
            panel.orderOut(nil)
            self?.isVisible = false
        }
    }

    private func createPanel() {
        panel = ShelfPanel()
    }
}
