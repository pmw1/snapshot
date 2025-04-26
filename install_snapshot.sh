#!/bin/bash

# === Install snapshot tool system-wide into PATH ===

# Configuration
INSTALL_DIR="/usr/local/bin"  # System-wide install (requires sudo)
SCRIPT_NAME="snapshot"
CURRENT_DIR=$(pwd)

# Check if sudo is needed and available
if [ ! -w "$INSTALL_DIR" ]; then
    if ! command -v sudo >/dev/null 2>&1; then
        echo "[✖] Error: $INSTALL_DIR requires sudo, but sudo is not available"
        exit 1
    fi
fi

# Ensure install dir exists
sudo mkdir -p "$INSTALL_DIR" || { echo "[✖] Failed to create $INSTALL_DIR"; exit 1; }

# Check if script exists in current dir, with or without .sh
if [ -f "$CURRENT_DIR/$SCRIPT_NAME" ]; then
    SOURCE_FILE="$CURRENT_DIR/$SCRIPT_NAME"
elif [ -f "$CURRENT_DIR/${SCRIPT_NAME}.sh" ]; then
    SOURCE_FILE="$CURRENT_DIR/${SCRIPT_NAME}.sh"
else
    echo "[✖] Error: '$SCRIPT_NAME' or '${SCRIPT_NAME}.sh' not found in $CURRENT_DIR"
    exit 1
fi

# Ensure Unix line endings (macOS-compatible)
sed -i.bak 's/\r$//' "$SOURCE_FILE" && rm -f "${SOURCE_FILE}.bak" || { echo "[✖] Failed to fix line endings"; exit 1; }

# Check for existing snapshot command or dangling symlink
if [ -e "$INSTALL_DIR/$SCRIPT_NAME" ] || [ -L "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo "[!] Warning: $INSTALL_DIR/$SCRIPT_NAME already exists or is a dangling symlink."
    echo "    Overwrite? (y/n)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "[✖] Installation aborted."
        exit 1
    fi
    sudo rm -f "$INSTALL_DIR/$SCRIPT_NAME" || { echo "[✖] Failed to remove existing $INSTALL_DIR/$SCRIPT_NAME"; exit 1; }
fi

# Install by copying directly to INSTALL_DIR
sudo cp "$SOURCE_FILE" "$INSTALL_DIR/$SCRIPT_NAME" || { echo "[✖] Failed to copy to $INSTALL_DIR"; exit 1; }
sudo chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || { echo "[✖] Failed to set executable permissions"; exit 1; }

# Verify INSTALL_DIR is in PATH
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "[!] Warning: $INSTALL_DIR not found in PATH. Ensure it is included (usually /usr/local/bin is in PATH)."
    echo "    Add manually to ~/.bashrc if needed: export PATH=\"$INSTALL_DIR:\$PATH\""
else
    # Test if snapshot is callable
    if command -v snapshot >/dev/null 2>&1; then
        echo "[✔] 'snapshot' is ready to use in your current shell."
    else
        echo "[!] 'snapshot' not in PATH. Add $INSTALL_DIR to PATH or run with full path: $INSTALL_DIR/$SCRIPT_NAME"
    fi
fi

# Success
echo "[✔] Installed '$SCRIPT_NAME' system-wide into $INSTALL_DIR. Run 'snapshot' from any project root."