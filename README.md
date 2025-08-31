# 🔒 USB Kill-Switch

**USB Kill-Switch** is a Linux security tool that monitors a USB drive.  
If the drive is removed, the system will immediately **shutdown** (with an optional RAM wipe for anti-forensics).  

Created with simplicity and security in mind.  

---

## 📥 Installation

Clone the repository and run the installer:

```bash
git clone https://github.com/YOUR-USERNAME/usb-killswitch.git
cd usb-killswitch
chmod +x install.sh
./install.sh

This will install the tool to:

/usr/local/bin/usb-killswitch

🚀 Usage

Start the kill-switch with:

sudo usb-killswitch

Once started:

    The script waits for a USB drive to be connected.

    When detected, the system begins monitoring it.

    If the USB is removed → system shutdown is triggered immediately.

🖥 User Interface

    Interactive, menu-based UI

    Colored output for better readability

    Options include:

    1. Start Kill-Switch  
    2. Immediate Shutdown  
    3. Wipe RAM + Shutdown  

📋 Features

    ✅ Detects and monitors a specific USB drive

    ✅ Instant system shutdown on removal

    ✅ Optional RAM wipe before shutdown

    ✅ User-friendly interface

    ✅ Lightweight Bash script (no external dependencies)

🛠 Uninstallation

To remove the tool:

sudo rm /usr/local/bin/usb-killswitch

⚠️ Disclaimer

This tool is provided as-is without warranty.
It is intended for educational and personal security use only.
Improper use may result in data loss — use at your own risk.
📜 License

MIT License © 2025 bitroox
