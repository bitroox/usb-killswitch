#!/bin/bash
#
# Installer for USB Kill-Switch — bitroox
#

set -e

TARGET="/usr/local/bin/usb-killswitch"

echo "🔧 Installing USB Kill-Switch..."

# Copy script
sudo cp usb-killswitch.sh "$TARGET"

# Make executable
sudo chmod +x "$TARGET"

echo "✅ Installation complete!"
echo "You can now run it with: usb-killswitch"
