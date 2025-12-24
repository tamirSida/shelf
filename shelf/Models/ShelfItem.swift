//
//  ShelfItem.swift
//  shelf
//

import Foundation
import AppKit

enum ShelfItemContent: Equatable {
    case text(String)
    case image(NSImage)
    case file(URL)

    static func == (lhs: ShelfItemContent, rhs: ShelfItemContent) -> Bool {
        switch (lhs, rhs) {
        case (.text(let a), .text(let b)):
            return a == b
        case (.image(let a), .image(let b)):
            return a === b
        case (.file(let a), .file(let b)):
            return a == b
        default:
            return false
        }
    }
}

struct ShelfItem: Identifiable, Equatable {
    let id: UUID
    let content: ShelfItemContent
    let createdAt: Date
    let sourceURL: URL?  // Original location if dragged in (for restore on delete)

    init(id: UUID = UUID(), content: ShelfItemContent, createdAt: Date = Date(), sourceURL: URL? = nil) {
        self.id = id
        self.content = content
        self.createdAt = createdAt
        self.sourceURL = sourceURL
    }

    var canRestore: Bool {
        sourceURL != nil
    }

    var displayName: String {
        switch content {
        case .text(let text):
            let preview = text.prefix(30)
            return preview.count < text.count ? "\(preview)..." : String(preview)
        case .image:
            return "Image"
        case .file(let url):
            return url.lastPathComponent
        }
    }

    var icon: String {
        switch content {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .file(let url):
            if url.hasDirectoryPath {
                return "folder"
            }
            return "doc"
        }
    }
}
