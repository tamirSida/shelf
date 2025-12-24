//
//  ShelfItemView.swift
//  shelf
//

import SwiftUI
import UniformTypeIdentifiers
import AppKit

struct ShelfItemView: View {
    let item: ShelfItem
    var onCopy: () -> Void
    var onDelete: () -> Void
    var onDragOut: (() -> Void)?  // Called when file is dragged out

    @State private var isHovered = false

    var body: some View {
        VStack(spacing: 6) {
            ZStack(alignment: .topTrailing) {
                itemContent
                    .frame(width: 100, height: 80)
                    .background(Color.primary.opacity(0.05))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        DraggableFileView(item: item, onCopy: onCopy, onHover: { hovering in
                            isHovered = hovering
                        }, onDragCompleted: {
                            onDragOut?()
                        })
                    )

                if isHovered {
                    Button {
                        onDelete()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(.white, .red)
                    }
                    .buttonStyle(.plain)
                    .offset(x: 6, y: -6)
                }
            }

            Text(item.displayName)
                .font(.caption)
                .lineLimit(1)
                .truncationMode(.middle)
                .frame(width: 100)
                .foregroundStyle(.secondary)
        }
        .contextMenu {
            Button("Copy") {
                onCopy()
            }
            if item.canRestore {
                Button("Return to Original Location") {
                    onDelete()
                }
            } else {
                Button("Delete", role: .destructive) {
                    onDelete()
                }
            }
        }
        .help(item.canRestore ? "Click to copy • Drag to move • X to return" : "Click to copy • Drag to use")
    }

    @ViewBuilder
    private var itemContent: some View {
        switch item.content {
        case .text(let text):
            Text(text)
                .font(.caption2)
                .lineLimit(4)
                .padding(6)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)

        case .image(let nsImage):
            Image(nsImage: nsImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(4)

        case .file(let url):
            Image(nsImage: NSWorkspace.shared.icon(forFile: url.path))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 48, height: 48)
        }
    }
}

// Custom NSView for file dragging that can detect drag completion
struct DraggableFileView: NSViewRepresentable {
    let item: ShelfItem
    var onCopy: () -> Void
    var onHover: (Bool) -> Void
    var onDragCompleted: () -> Void

    func makeNSView(context: Context) -> DraggableNSView {
        let view = DraggableNSView()
        view.item = item
        view.onCopy = onCopy
        view.onHover = onHover
        view.onDragCompleted = onDragCompleted
        view.wantsLayer = true

        // Create tracking area for hover
        let trackingArea = NSTrackingArea(
            rect: .zero,
            options: [.mouseEnteredAndExited, .activeAlways, .inVisibleRect],
            owner: view,
            userInfo: nil
        )
        view.addTrackingArea(trackingArea)

        return view
    }

    func updateNSView(_ nsView: DraggableNSView, context: Context) {
        nsView.item = item
        nsView.onCopy = onCopy
        nsView.onHover = onHover
        nsView.onDragCompleted = onDragCompleted
    }
}

class DraggableNSView: NSView, NSDraggingSource {
    var item: ShelfItem?
    var onCopy: (() -> Void)?
    var onHover: ((Bool) -> Void)?
    var onDragCompleted: (() -> Void)?
    private var dragStartPoint: NSPoint?
    private var didDrag = false

    override init(frame: NSRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override var mouseDownCanMoveWindow: Bool { false }
    override var acceptsFirstResponder: Bool { true }
    override var isFlipped: Bool { true }

    override func mouseEntered(with event: NSEvent) {
        onHover?(true)
    }

    override func mouseExited(with event: NSEvent) {
        onHover?(false)
    }

    override func mouseDown(with event: NSEvent) {
        dragStartPoint = event.locationInWindow
        didDrag = false
    }

    override func mouseDragged(with event: NSEvent) {
        guard let item = item, let startPoint = dragStartPoint else { return }

        // Only start drag if moved enough distance (reduced from 5 to 2 for responsiveness)
        let currentPoint = event.locationInWindow
        let distance = hypot(currentPoint.x - startPoint.x, currentPoint.y - startPoint.y)
        guard distance > 2 else { return }

        didDrag = true
        // Reset so we don't start multiple drags
        dragStartPoint = nil

        switch item.content {
        case .file(let url):
            // Use the file URL directly as the pasteboard writer
            let fileURL = url as NSURL

            let draggingItem = NSDraggingItem(pasteboardWriter: fileURL)

            let icon = NSWorkspace.shared.icon(forFile: url.path)
            icon.size = NSSize(width: 48, height: 48)

            let draggingFrame = NSRect(x: event.locationInWindow.x - 24,
                                        y: event.locationInWindow.y - 24,
                                        width: 48, height: 48)
            draggingItem.setDraggingFrame(draggingFrame, contents: icon)

            beginDraggingSession(with: [draggingItem], event: event, source: self)

        case .text(let text):
            let pasteboardItem = NSPasteboardItem()
            pasteboardItem.setString(text, forType: .string)

            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            let draggingFrame = NSRect(x: event.locationInWindow.x - 50,
                                        y: event.locationInWindow.y - 20,
                                        width: 100, height: 40)
            draggingItem.setDraggingFrame(draggingFrame, contents: nil)

            beginDraggingSession(with: [draggingItem], event: event, source: self)

        case .image(let image):
            let pasteboardItem = NSPasteboardItem()
            if let tiffData = image.tiffRepresentation {
                pasteboardItem.setData(tiffData, forType: .tiff)
            }

            let draggingItem = NSDraggingItem(pasteboardWriter: pasteboardItem)
            let thumbnail = image.copy() as! NSImage
            thumbnail.size = NSSize(width: 60, height: 60)

            let draggingFrame = NSRect(x: event.locationInWindow.x - 30,
                                        y: event.locationInWindow.y - 30,
                                        width: 60, height: 60)
            draggingItem.setDraggingFrame(draggingFrame, contents: thumbnail)

            beginDraggingSession(with: [draggingItem], event: event, source: self)
        }
    }

    override func mouseUp(with event: NSEvent) {
        // If we didn't drag, treat as a click
        if !didDrag {
            onCopy?()
        }
        dragStartPoint = nil
        didDrag = false
    }

    // MARK: - NSDraggingSource

    func draggingSession(_ session: NSDraggingSession, sourceOperationMaskFor context: NSDraggingContext) -> NSDragOperation {
        // Allow both copy and move - Finder will decide
        return [.copy, .move, .generic]
    }

    func draggingSession(_ session: NSDraggingSession, endedAt screenPoint: NSPoint, operation: NSDragOperation) {
        // If the drag resulted in a move or copy to another app, remove from shelf
        if !operation.isEmpty {
            DispatchQueue.main.async {
                self.onDragCompleted?()
            }
        }
    }
}
