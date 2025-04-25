#!/bin/bash

# === Install snapshot tool into PATH ===

# Configuration
INSTALL_DIR="$HOME/.local/bin"  # safest place without needing sudo
SCRIPT_NAME="snapshot"
CURRENT_DIR=$(pwd)

# Ensure install dir exists
mkdir -p "$INSTALL_DIR"

# Check if script exists in current dir, with or without .sh
if [ -f "$CURRENT_DIR/$SCRIPT_NAME" ]; then
    SOURCE_FILE="$CURRENT_DIR/$SCRIPT_NAME"
elif [ -f "$CURRENT_DIR/${SCRIPT_NAME}.sh" ]; then
    SOURCE_FILE="$CURRENT_DIR/${SCRIPT_NAME}.sh"
    echo "[!] Found '${SCRIPT_NAME}.sh'. Installing as '$SCRIPT_NAME' without extension."
    # Copy file without .sh extension
    cp "$SOURCE_FILE" "$CURRENT_DIR/$SCRIPT_NAME"
    SOURCE_FILE="$CURRENT_DIR/$SCRIPT_NAME"
else
    echo "[✖] Error: '$SCRIPT_NAME' or '${SCRIPT_NAME}.sh' not found in $CURRENT_DIR"
    exit 1
fi

# Ensure Unix line endings (prevent ^M issues)
sed -i 's/\r$//' "$SOURCE_FILE"

# Simulate creating required project folders
mkdir -p "reinstantiation/spec"

# Install by symlink (preferred: keeps it updatable easily)
ln -sf "$SOURCE_FILE" "$INSTALL_DIR/$SCRIPT_NAME"
chmod +x "$INSTALL_DIR/$SCRIPT_NAME"

# Update PATH in shell config if necessary
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "[!] $INSTALL_DIR not found in PATH. Adding it to your shell config."
    SHELL_CONFIG=""
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.zshrc" ]; then
        SHELL_CONFIG="$HOME/.zshrc"
    fi

    if [ -n "$SHELL_CONFIG" ]; then
        echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
        echo "[+] Added export to $SHELL_CONFIG. Reload your shell or run: source $SHELL_CONFIG"
    else
        echo "[!] Couldn't find your shell config automatically. Please add this line manually:"
        echo "export PATH=\"$INSTALL_DIR:\$PATH\""
    fi
fi

# Success
echo "[✔] Installed '$SCRIPT_NAME' into $INSTALL_DIR. You can now run '$SCRIPT_NAME' from your project root."

