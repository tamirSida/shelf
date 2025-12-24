//
//  SettingsManager.swift
//  shelf
//

import Foundation
import SwiftUI

enum ShelfLayout: String, CaseIterable, Identifiable {
    case horizontal = "horizontal"
    case grid = "grid"
    case list = "list"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .horizontal: return "Horizontal"
        case .grid: return "Grid"
        case .list: return "List"
        }
    }

    var icon: String {
        switch self {
        case .horizontal: return "rectangle.split.3x1"
        case .grid: return "square.grid.2x2"
        case .list: return "list.bullet"
        }
    }
}

@Observable
final class SettingsManager {
    static let shared = SettingsManager()

    var layout: ShelfLayout {
        didSet {
            UserDefaults.standard.set(layout.rawValue, forKey: "shelfLayout")
        }
    }

    var launchAtLogin: Bool {
        didSet {
            UserDefaults.standard.set(launchAtLogin, forKey: "launchAtLogin")
            // Note: Actual launch at login requires SMAppService or LaunchServices
        }
    }

    var hotkeyDescription: String {
        "⌃` (Control + Backtick)"
    }

    private init() {
        if let layoutRaw = UserDefaults.standard.string(forKey: "shelfLayout"),
           let layout = ShelfLayout(rawValue: layoutRaw) {
            self.layout = layout
        } else {
            self.layout = .horizontal
        }

        self.launchAtLogin = UserDefaults.standard.bool(forKey: "launchAtLogin")
    }
}
