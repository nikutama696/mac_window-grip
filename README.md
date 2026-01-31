# WindowGrip

WindowGrip is a lightweight macOS menu bar utility that allows you to move and resize windows using modifier keys + mouse drag, similar to features found in BetterTouchTool.

## Features

- **Move Windows**: `Shift` + `Control` + Drag anywhere on a window
- **Resize Windows**: `Control` + `Command` + Drag anywhere on a window (resizes from top-left)
- **Move Windows**: `Shift` + `Control` + Drag anywhere on a window
- **Resize Windows**: `Control` + `Command` + Drag anywhere on a window (resizes from top-left)
- **Customizable Shortcuts**: Change modifier keys in Preferences

## Installation & Running

### Option 1: Double-click App (Recommended)

1. Run the helper script to create the app:
   ```bash
   ./create_app.sh
   ```
2. Move `WindowGrip.app` to your Applications folder.
3. Launch it. You will be prompted to grant Accessibility permissions to "WindowGrip".

### Option 2: Run via Command Line (For Development)

1. Open Terminal in this directory.
2. Run the application:
   ```bash
   swift run
   ```
3. **Important**: You will need to grant Accessibility permissions to "Terminal" in System Settings.

## Usage

1. Launch WindowGrip.
2. A menu bar icon (System default style) will appear.
3. Use the configured shortcuts to manipulate windows.
4. Click the menu bar icon and select "Preferences..." to change shortcuts.

## Troubleshooting

- **Permissions**: If window moving doesn't work, verify that Accessibility permissions are enabled. Remove and re-add the app in System Settings if issues persist.
