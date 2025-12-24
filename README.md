# Shelf

A lightweight macOS menu bar app for temporarily holding files, images, and text. Think of it as a clipboard shelf - a quick-access holding area for things you're working with.

![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-5.0-orange)
![License](https://img.shields.io/badge/license-MIT-green)

## Features

- **Quick Access** - Toggle with `Ctrl + `` ` (backtick) from anywhere
- **Drag & Drop Files** - Drag files/folders into the shelf to temporarily hold them
- **Smart File Handling** - Files are moved to shelf, not copied. Drag out to new location, or click X to return to original location
- **Clipboard Integration** - Paste text, images, or file references with `Cmd+V`
- **Built-in Notepad** - Quick scratchpad for jotting notes
- **Draggable Panel** - Move the shelf anywhere on screen
- **Menu Bar App** - Lives in your menu bar, no dock icon

## Installation

### From Source

1. Clone the repository
   ```bash
   git clone https://github.com/yourusername/shelf.git
   cd shelf
   ```

2. Open in Xcode
   ```bash
   open shelf.xcodeproj
   ```

3. Build and run (`Cmd+R`)

### Requirements

- macOS 14.0 or later
- Xcode 15.0 or later (for building)

## Usage

### Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl + `` ` | Toggle shelf visibility |
| `Cmd + V` | Paste from clipboard |
| `Esc` | Close shelf |

### Adding Items

- **Drag & drop** files, folders, or images onto the shelf
- **Paste** text, images, or files with `Cmd+V` or the clipboard button
- **Notepad** - Click the note icon to toggle the built-in scratchpad

### Managing Items

- **Click** an item to copy it to clipboard
- **Drag** an item out to move it to a new location
- **Hover + X** to delete (files return to original location)
- **Right-click** for context menu options

### File Behavior

When you drag a file into the shelf:
1. File is **moved** from its original location to the shelf
2. Drag it out → file moves to new destination
3. Click X → file returns to original location
4. Quit app → files return to original locations

## Project Structure

```
shelf/
├── shelfApp.swift          # App entry point, menu bar setup
├── Models/
│   └── ShelfItem.swift     # Item data model
├── Store/
│   └── ShelfStore.swift    # In-memory state management
├── Panel/
│   ├── ShelfPanel.swift    # NSPanel overlay window
│   └── ShelfPanelController.swift
├── Views/
│   ├── ShelfContentView.swift   # Main UI
│   ├── ShelfItemView.swift      # Individual item cards
│   └── SettingsView.swift       # Preferences
└── Services/
    ├── HotkeyManager.swift      # Global hotkey registration
    └── SettingsManager.swift    # User preferences
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Acknowledgments

Built with SwiftUI and AppKit for macOS.
