#!/bin/bash

# === Install snapshot tool into PATH ===

# Configuration
INSTALL_DIR="$HOME/.local/bin"  # Safest place without needing sudo
SCRIPT_NAME="snapshot"
CURRENT_DIR=$(pwd)

# Check write permissions for INSTALL_DIR
if [ ! -w "$INSTALL_DIR" ]; then
    echo "[✖] Error: No write permission for $INSTALL_DIR"
    exit 1
fi

# Ensure install dir exists
mkdir -p "$INSTALL_DIR" || { echo "[✖] Failed to create $INSTALL_DIR"; exit 1; }

# Check if script exists in current dir, with or without .sh
if [ -f "$CURRENT_DIR/$SCRIPT_NAME" ]; then
    SOURCE_FILE="$CURRENT_DIR/$SCRIPT_NAME"
elif [ -f "$CURRENT_DIR/${SCRIPT_NAME}.sh" ]; then
    SOURCE_FILE="$CURRENT_DIR/${SCRIPT_NAME}.sh"
    echo "[!] Found '${SCRIPT_NAME}.sh'. Installing as '$SCRIPT_NAME' without extension."
    # Copy file without .sh extension
    cp "$SOURCE_FILE" "$CURRENT_DIR/$SCRIPT_NAME" || { echo "[✖] Failed to copy script"; exit 1; }
    SOURCE_FILE="$CURRENT_DIR/$SCRIPT_NAME"
else
    echo "[✖] Error: '$SCRIPT_NAME' or '${SCRIPT_NAME}.sh' not found in $CURRENT_DIR"
    exit 1
fi

# Ensure Unix line endings (macOS-compatible)
sed -i.bak 's/\r$//' "$SOURCE_FILE" && rm -f "${SOURCE_FILE}.bak" || { echo "[✖] Failed to fix line endings"; exit 1; }

# Check for existing snapshot command
if [ -e "$INSTALL_DIR/$SCRIPT_NAME" ] && [ ! -L "$INSTALL_DIR/$SCRIPT_NAME" ]; then
    echo "[!] Warning: $INSTALL_DIR/$SCRIPT_NAME already exists and is not a symlink."
    echo "    Overwrite? (y/n)"
    read -r response
    if [ "$response" != "y" ] && [ "$response" != "Y" ]; then
        echo "[✖] Installation aborted."
        exit 1
    fi
fi

# Simulate creating required project folders
mkdir -p "reinstantiation/spec" || { echo "[✖] Failed to create reinstantiation/spec"; exit 1; }

# Create .project_root if missing, with user-prompted project name
if [ ! -f ".project_root" ]; then
    echo "[!] No .project_root found. Enter project name (e.g., MyProject):"
    read -r project_name
    if [ -z "$project_name" ]; then
        echo "[✖] Error: Project name cannot be empty."
        exit 1
    fi
    # Sanitize project name
    project_name=$(echo "$project_name" | tr -d '\n\r' | sed 's/[^a-zA-Z0-9._-]/-/g')
    echo "$project_name" > ".project_root"
    echo "[+] Created .project_root with project name '$project_name'"
fi

# Install by symlink
ln -sf "$SOURCE_FILE" "$INSTALL_DIR/$SCRIPT_NAME" || { echo "[✖] Failed to create symlink"; exit 1; }
chmod +x "$INSTALL_DIR/$SCRIPT_NAME" || { echo "[✖] Failed to set executable permissions"; exit 1; }

# Update PATH in shell config if necessary
if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
    echo "[!] $INSTALL_DIR not found in PATH. Adding it to your shell config."
    SHELL_CONFIG=""
    case "$SHELL" in
        */bash)
            if [ -f "$HOME/.bashrc" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                SHELL_CONFIG="$HOME/.bash_profile"
            fi
            ;;
        */zsh) SHELL_CONFIG="$HOME/.zshrc" ;;
        */fish) SHELL_CONFIG="$HOME/.config/fish/config.fish" ;;
    esac

    if [ -n "$SHELL_CONFIG" ] && [ -w "$SHELL_CONFIG" ]; then
        if [ "${SHELL_CONFIG##*.}" = "fish" ]; then
            echo "set -gx PATH $INSTALL_DIR \$PATH" >> "$SHELL_CONFIG"
        else
            echo "export PATH=\"$INSTALL_DIR:\$PATH\"" >> "$SHELL_CONFIG"
        fi
        echo "[+] Added PATH export to $SHELL_CONFIG. Reload your shell or run: source $SHELL_CONFIG"
    else
        echo "[!] Couldn't find or write to shell config. Add this manually:"
        if [ "${SHELL_CONFIG##*.}" = "fish" ]; then
            echo "set -gx PATH $INSTALL_DIR \$PATH"
        else
            echo "export PATH=\"$INSTALL_DIR:\$PATH\""
        fi
    fi
fi

# Test if snapshot is callable
if command -v snapshot >/dev/null 2>&1; then
    echo "[✔] 'snapshot' is ready to use in your current shell."
else
    echo "[!] 'snapshot' not in PATH yet. Run 'source $SHELL_CONFIG' or open a new terminal."
fi

# Success
echo "[✔] Installed '$SCRIPT_NAME' into $INSTALL_DIR. Run 'snapshot' from any project root with a .project_root file."
