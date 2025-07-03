# FreeBSD in  Qemu with KVM on Linux 

FreeBSD in QEMU is a beginner-friendly project that demonstrates how to install, configure, and run FreeBSD 14.3 inside a QEMU virtual machine on a Linux host system. It provides a fully documented workflow including ISO setup, disk image creation, user management, network configuration, essential package installation, and post-install tools.

This project is ideal for developers, system administrators, or hobbyists who want to:

    Learn FreeBSD in a sandboxed virtual environment

    Explore Unix-like systems without dual-booting

    Build lightweight and secure development VMs

    Automate FreeBSD VM setups with repeatable scripts

    
## ✨ Features

   - Run FreeBSD 14.3 in QEMU on any Linux host

   - Lightweight, scriptable VM environment

   - Learn core Unix concepts (users, networking, services)

   - Includes post-install setup (sudo, packages, SSH)

   - Customizable CPU, RAM, and disk size

   - Great for learning, testing, and problem-solvin
## 🖥️ System Requirements

To run FreeBSD smoothly inside a QEMU virtual machine on a Linux host, ensure your system meets the following minimum requirements:

---

### ✅ Operating System

- Any modern Linux distribution:
  - Debian
  - Ubuntu
  - Parrot OS
  - Arch Linux
  - Manjaro
  - Others with QEMU support

---

### ⚙️ Required Packages

Install the following packages based on your Linux distribution:

#### For **Debian / Ubuntu / Parrot OS**:

```bash
sudo apt update
sudo apt install qemu-system-x86 qemu-utils wget xz-utils
```
### 🐧 For Arch / Manjaro

Install the required packages using `pacman`:

```bash
sudo pacman -S qemu wget xz
```
## 💡 Minimum System Specs

To ensure smooth operation of FreeBSD inside QEMU, your system should meet the following minimum requirements:

| 🔧 Component   | 💻 Minimum Recommended     |
|---------------|----------------------------|
| 🧠 RAM        | 4 GB                        |
| 🧩 CPU        | 2 Cores                     |
| 💽 Disk Space | 20 GB free                  |
| 🌐 Internet   | Required (for ISO + packages) |

