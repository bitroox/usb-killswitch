# USB Kill-Switch 🔒
_A security tool for Linux systems_  
**Author:** bitroox  
**License:** MIT

---

## Overview
USB Kill-Switch is a Bash-based security utility for Debian-based Linux systems.  
It continuously monitors for a USB device. Once the device is removed, the system will immediately **shutdown**.  

In Secure Mode, the tool also attempts a **RAM wipe** before shutdown.

---

## Features
- 🔑 **Kill-Switch Mode** — Automatic shutdown when the USB key is removed  
- 🔐 **Secure Mode** — Attempts to wipe RAM, then shutdown  
- 🛠️ **Diagnostics Mode** — Test monitoring without shutdown  
- 🎨 **User-Friendly Interface** — Colorful, clean, and easy to use  

---

## Installation
Clone and install:
```bash
git clone https://github.com/bitroox/usb-killswitch.git
cd usb-killswitch
chmod +x install.sh
./install.sh
