#!/bin/bash
# USB Kill-Switch Installer
# by bitroox

set -e

SCRIPT_NAME="usb-killswitch"
INSTALL_DIR="/usr/local/bin"

echo "🔧 Installing USB Kill-Switch..."

# Make script executable
chmod +x "$SCRIPT_NAME.sh"

# Copy to /usr/local/bin (without .sh extension)
sudo cp "$SCRIPT_NAME.sh" "$INSTALL_DIR/$SCRIPT_NAME"

echo "✅ Installation complete!"
echo ""
echo "👉 You can now run the tool with:"
echo "   sudo $SCRIPT_NAME"
