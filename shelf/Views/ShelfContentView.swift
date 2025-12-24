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
    var onStartDrag: ((NSPoint) -> Void)?

    @State private var isDropTargeted = false
    @State private var showNotepad = false

    var body: some View {
        VStack(spacing: 0) {
            // Header - draggable area
            HStack {
                Text("Shelf")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                Spacer()

                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showNotepad.toggle()
                    }
                } label: {
                    Image(systemName: showNotepad ? "note.text" : "note.text.badge.plus")
                }
                .buttonStyle(.borderless)
                .help("Toggle notepad")

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
                .disabled(store.items.isEmpty && store.notepadText.isEmpty)
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
            .background(DragHandleView(onDrag: onStartDrag))

            Divider()

            // Content area
            HStack(spacing: 0) {
                // Items section
                if store.items.isEmpty && !showNotepad {
                    emptyState
                } else if store.items.isEmpty && showNotepad {
                    notepadView
                } else {
                    itemsGrid

                    if showNotepad {
                        Divider()
                        notepadView
                            .frame(width: 200)
                    }
                }
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

    private var notepadView: some View {
        VStack(spacing: 0) {
            TextEditor(text: Binding(
                get: { store.notepadText },
                set: { store.notepadText = $0 }
            ))
            .font(.system(size: 13))
            .scrollContentBackground(.hidden)
            .background(Color.clear)
            .padding(8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primary.opacity(0.03))
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

// MARK: - Drag Handle for moving the shelf

struct DragHandleView: NSViewRepresentable {
    var onDrag: ((NSPoint) -> Void)?

    func makeNSView(context: Context) -> DragHandleNSView {
        let view = DragHandleNSView()
        view.onDrag = onDrag
        return view
    }

    func updateNSView(_ nsView: DragHandleNSView, context: Context) {
        nsView.onDrag = onDrag
    }
}

class DragHandleNSView: NSView {
    var onDrag: ((NSPoint) -> Void)?

    override var mouseDownCanMoveWindow: Bool { false }

    override func mouseDragged(with event: NSEvent) {
        onDrag?(NSEvent.mouseLocation)
    }
}
