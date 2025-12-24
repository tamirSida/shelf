//
//  shelfApp.swift
//  shelf
//
//  Created by Tamir Sida on 24/12/2025.
//

import SwiftUI

@main
struct shelfApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Shelf", systemImage: "tray.and.arrow.down") {
            MenuBarView(shelfStore: appDelegate.shelfStore, panelController: appDelegate.panelController)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let shelfStore = ShelfStore()
    let panelController = ShelfPanelController()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register global hotkey (Control + `)
        HotkeyManager.shared.register { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.panelController.togglePanel(with: self.shelfStore)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        HotkeyManager.shared.unregister()
    }
}

struct MenuBarView: View {
    let shelfStore: ShelfStore
    let panelController: ShelfPanelController

    var body: some View {
        Button("Show Shelf") {
            panelController.togglePanel(with: shelfStore)
        }
        .keyboardShortcut("s", modifiers: [.control, .option])

        Divider()

        if shelfStore.items.isEmpty {
            Text("No items on shelf")
                .foregroundStyle(.secondary)
        } else {
            ForEach(shelfStore.items.prefix(5)) { item in
                Button {
                    shelfStore.copyItemToPasteboard(item)
                } label: {
                    Label(item.displayName, systemImage: item.icon)
                }
            }

            if shelfStore.items.count > 5 {
                Text("+ \(shelfStore.items.count - 5) more...")
                    .foregroundStyle(.secondary)
            }

            Divider()

            Button("Clear All") {
                shelfStore.clear()
            }
        }

        Divider()

        SettingsLink {
            Text("Settings...")
        }
        .keyboardShortcut(",", modifiers: .command)

        Button("Quit Shelf") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
