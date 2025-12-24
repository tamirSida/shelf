//
//  ShelfContentView.swift
//  shelf
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ShelfContentView: View {
    @Bindable var store: ShelfStore
    var onDismiss: () -> Void

    @State private var isDropTargeted = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Shelf")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    store.addFromPasteboard()
                } label: {
                    Image(systemName: "doc.on.clipboard")
                }
                .buttonStyle(.borderless)
                .help("Paste from clipboard (⌘V)")

                Button {
                    store.clear()
                } label: {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .disabled(store.items.isEmpty)
                .help("Clear all items")

                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                }
                .buttonStyle(.borderless)
                .help("Close (Esc)")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Content area
            if store.items.isEmpty {
                emptyState
            } else {
                itemsGrid
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isDropTargeted ? Color.accentColor : Color.clear, lineWidth: 2)
        )
        .onDrop(of: [.fileURL, .image, .text, .utf8PlainText], isTargeted: $isDropTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
        .background(KeyEventHandlingView(onEscape: onDismiss, onPaste: { store.addFromPasteboard() }))
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 40))
                .foregroundStyle(.tertiary)

            Text("Drop files, images, or text here")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text("Or press ⌘V to paste")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var itemsGrid: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(store.items) { item in
                    ShelfItemView(item: item) {
                        store.copyItemToPasteboard(item)
                    } onDelete: {
                        withAnimation(.easeOut(duration: 0.2)) {
                            store.deleteItem(item)  // Restores file if it was dragged in
                        }
                    } onDragOut: {
                        // File was dragged out to another location - just remove from shelf
                        withAnimation(.easeOut(duration: 0.2)) {
                            store.removeItem(item)
                        }
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            // Try file URL first - MOVE file to shelf
            if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
                _ = provider.loadObject(ofClass: URL.self) { url, error in
                    if let url = url {
                        DispatchQueue.main.async {
                            self.store.addFile(url, moveToShelf: true, sourceURL: url)
                        }
                    }
                }
                continue
            }

            // Try image
            if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                _ = provider.loadObject(ofClass: NSImage.self) { image, error in
                    if let image = image as? NSImage {
                        DispatchQueue.main.async {
                            self.store.addImage(image)
                        }
                    }
                }
                continue
            }

            // Try text
            if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                _ = provider.loadObject(ofClass: String.self) { string, error in
                    if let text = string {
                        DispatchQueue.main.async {
                            self.store.addText(text)
                        }
                    }
                }
            }
        }
    }
}

struct KeyEventHandlingView: NSViewRepresentable {
    var onEscape: () -> Void
    var onPaste: () -> Void

    func makeNSView(context: Context) -> KeyEventNSView {
        let view = KeyEventNSView()
        view.onEscape = onEscape
        view.onPaste = onPaste
        return view
    }

    func updateNSView(_ nsView: KeyEventNSView, context: Context) {
        nsView.onEscape = onEscape
        nsView.onPaste = onPaste
    }
}

class KeyEventNSView: NSView {
    var onEscape: (() -> Void)?
    var onPaste: (() -> Void)?

    override var acceptsFirstResponder: Bool { true }

    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onEscape?()
        } else if event.modifierFlags.contains(.command) && event.charactersIgnoringModifiers == "v" {
            onPaste?()
        } else {
            super.keyDown(with: event)
        }
    }
}
