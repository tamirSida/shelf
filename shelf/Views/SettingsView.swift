//
//  SettingsView.swift
//  shelf
//

import SwiftUI
import AppKit

struct SettingsView: View {
    @State private var settings = SettingsManager.shared

    var body: some View {
        Form {
            Section("Layout") {
                Picker("Shelf Layout", selection: $settings.layout) {
                    ForEach(ShelfLayout.allCases) { layout in
                        Label(layout.displayName, systemImage: layout.icon)
                            .tag(layout)
                    }
                }
                .pickerStyle(.inline)
            }

            Section("Hotkey") {
                LabeledContent("Toggle Shelf") {
                    Text(settings.hotkeyDescription)
                        .foregroundStyle(.secondary)
                }
            }

            Section("General") {
                Toggle("Launch at Login", isOn: $settings.launchAtLogin)
            }

            Section {
                LabeledContent("Version") {
                    Text("1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 350, height: 300)
        .onAppear {
            // Bring app to front when settings opens (needed for LSUIElement apps)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
}

#Preview {
    SettingsView()
}
