//
//  ShelfStore.swift
//  shelf
//

import Foundation
import AppKit
import Observation

@Observable
final class ShelfStore {
    private(set) var items: [ShelfItem] = []
    var notepadText: String = ""

    private let fileManager = FileManager.default
    private let shelfDirectory: URL

    init() {
        // Create a hidden shelf directory to hold files
        let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        shelfDirectory = appSupport.appendingPathComponent("Shelf/HeldFiles", isDirectory: true)
        try? fileManager.createDirectory(at: shelfDirectory, withIntermediateDirectories: true)
    }

    func addItem(_ item: ShelfItem) {
        items.insert(item, at: 0)
    }

    func addText(_ text: String) {
        let item = ShelfItem(content: .text(text))
        addItem(item)
    }

    func addImage(_ image: NSImage) {
        let item = ShelfItem(content: .image(image))
        addItem(item)
    }

    func addFile(_ url: URL, moveToShelf: Bool = false, sourceURL: URL? = nil) {
        // Check if file is already on the shelf (either by URL or already in HeldFiles)
        let isAlreadyOnShelf = items.contains { item in
            if case .file(let existingURL) = item.content {
                return existingURL.path == url.path || existingURL.lastPathComponent == url.lastPathComponent
            }
            return false
        }

        // Also check if the file is in our HeldFiles directory
        let isInShelfDirectory = url.path.contains("Shelf/HeldFiles")

        if isAlreadyOnShelf || isInShelfDirectory {
            // File already on shelf, don't add again
            return
        }

        if moveToShelf {
            // Move file to shelf's internal directory
            let destURL = shelfDirectory.appendingPathComponent(url.lastPathComponent)
            do {
                // Remove existing file at destination if any
                if fileManager.fileExists(atPath: destURL.path) {
                    try fileManager.removeItem(at: destURL)
                }
                try fileManager.moveItem(at: url, to: destURL)
                let item = ShelfItem(content: .file(destURL), sourceURL: sourceURL ?? url)
                addItem(item)
            } catch {
                print("Failed to move file to shelf: \(error)")
                // Fallback: just reference the file without moving
                let item = ShelfItem(content: .file(url), sourceURL: sourceURL ?? url)
                addItem(item)
            }
        } else {
            // Just reference the file (for paste operations)
            let item = ShelfItem(content: .file(url))
            addItem(item)
        }
    }

    func removeItem(_ item: ShelfItem) {
        items.removeAll { $0.id == item.id }
    }

    func removeItem(at index: Int) {
        guard items.indices.contains(index) else { return }
        items.remove(at: index)
    }

    /// Delete item - if it was dragged in, restore to source location
    func deleteItem(_ item: ShelfItem) {
        if case .file(let currentURL) = item.content {
            if let sourceURL = item.sourceURL {
                // Restore to original location
                do {
                    // Make sure parent directory exists
                    try fileManager.createDirectory(at: sourceURL.deletingLastPathComponent(), withIntermediateDirectories: true)
                    // Remove any existing file at source (shouldn't exist, but just in case)
                    if fileManager.fileExists(atPath: sourceURL.path) {
                        try fileManager.removeItem(at: sourceURL)
                    }
                    try fileManager.moveItem(at: currentURL, to: sourceURL)
                } catch {
                    print("Failed to restore file: \(error)")
                    // If restore fails, just delete from shelf storage
                    try? fileManager.removeItem(at: currentURL)
                }
            } else {
                // No source URL - file was pasted, so just remove from shelf storage if it's there
                if currentURL.path.contains(shelfDirectory.path) {
                    try? fileManager.removeItem(at: currentURL)
                }
            }
        }
        removeItem(item)
    }

    /// Move file out of shelf to a destination
    func moveItemOut(_ item: ShelfItem, to destinationDir: URL) -> Bool {
        guard case .file(let currentURL) = item.content else { return false }

        let destURL = destinationDir.appendingPathComponent(currentURL.lastPathComponent)
        do {
            if fileManager.fileExists(atPath: destURL.path) {
                try fileManager.removeItem(at: destURL)
            }
            try fileManager.moveItem(at: currentURL, to: destURL)
            removeItem(item)
            return true
        } catch {
            print("Failed to move file out of shelf: \(error)")
            return false
        }
    }

    func clear() {
        // Restore all files to their source locations
        for item in items {
            if case .file(let currentURL) = item.content, let sourceURL = item.sourceURL {
                try? fileManager.moveItem(at: currentURL, to: sourceURL)
            }
        }
        items.removeAll()
        notepadText = ""
    }

    func addFromPasteboard() {
        let pasteboard = NSPasteboard.general

        // Try to get file URLs first (these are references, not moves)
        if let urls = pasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL], !urls.isEmpty {
            for url in urls {
                addFile(url, moveToShelf: false)  // Pasted files don't move
            }
            return
        }

        // Try to get image
        if let image = NSImage(pasteboard: pasteboard) {
            addImage(image)
            return
        }

        // Try to get text
        if let text = pasteboard.string(forType: .string), !text.isEmpty {
            addText(text)
            return
        }
    }

    func copyItemToPasteboard(_ item: ShelfItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        switch item.content {
        case .text(let text):
            pasteboard.setString(text, forType: .string)
        case .image(let image):
            if let tiffData = image.tiffRepresentation {
                pasteboard.setData(tiffData, forType: .tiff)
            }
        case .file(let url):
            pasteboard.writeObjects([url as NSURL])
        }
    }
}
