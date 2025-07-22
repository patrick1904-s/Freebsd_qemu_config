# FreeBSD in  Qemu with KVM on Linux 

FreeBSD in QEMU is a beginner-friendly project that demonstrates how to install, configure, and run FreeBSD 14.3 inside a QEMU virtual machine on a Linux host system. It provides a fully documented workflow including ISO setup, disk image creation, user management, network configuration, essential package installation, and post-install tools.

This project is ideal for developers, system administrators, or hobbyists who want to:

- Learn FreeBSD in a sandboxed virtual environment

- Explore Unix-like systems without dual-booting

- Build lightweight and secure development VMs

- Automate FreeBSD VM setups with repeatable scripts

- Smart ISO Detection & Reuse
---

## 📋 To-Do List

- [ ] Create a TUI 
- [ ] create a Declarative Script
    

    
## ✨ Features

   - Run FreeBSD 14.3 in QEMU on any Linux host

   - Lightweight, scriptable VM environment

   - Learn core Unix concepts (users, networking, services)

   - Includes post-install setup (sudo, packages, SSH)

   - Customizable CPU, RAM, and disk size
# 🧠 FreeBSD QEMU Setup Script

A fully interactive Bash script to automate the setup of a FreeBSD virtual machine using QEMU. This tool ensures a clean environment by handling dependency checks, ISO downloads, disk creation, and VM launching — all with a friendly TUI (Terminal User Interface).

---

## 🖥️ System Requirements

To run FreeBSD inside QEMU on a Linux host, your system should meet the following requirements:

### ✅ Operating System

- Any modern Linux distribution:
  - Debian / Ubuntu / Parrot OS
  - Arch Linux / Manjaro
  - Fedora / RHEL
  - Others with QEMU support

---
### The script will automatically checks the dependencies are installed or not if it is not installed the script will setup the dependencies automatically
---
## ⚙️ Required Packages

These dependencies will be checked and auto-installed by the script (if possible):

- `qemu-system-x86_64`
- `qemu-utils`
- `curl` or `wget`
- `xz-utils`

### 🧩 Manual Installation (if needed)

#### Debian / Ubuntu / Parrot OS:
```bash
sudo apt update
sudo apt install qemu-system-x86 qemu-utils wget xz-utils
## 🛠️ Installation

Follow these steps to set up and launch FreeBSD inside a QEMU virtual machine using the automated `setupBSD.sh` script.

---

### 🔃 Step 1: Clone the Repository

```bash
git clone https://github.com/patrick1904-s/Freebsd_qemu_config
cd freebsd-qemu-setup
```
---

### ⚙️ Step 2: Make the Script Executable

Before running the setup script, make it executable using the command below:

```bash
chmod +x setupBSD.sh
```
---

### 🚀 Step 3: Run the Script

```
./setupBSD.sh
```

---

## 📜 What This Script Does

The `setupBSD.sh` script automates the complete initial setup of a FreeBSD virtual machine using QEMU on a Linux host.

### ✅ Key Tasks Performed by the Script:

-  **Setup The Dependencies**  
             It checks Does the required package are present in the machine or in the shell if the package are not present it will automatically install the package from the required package of that distro.

- 🔍 **Fetches Available FreeBSD Versions**  
  Automatically queries the official FreeBSD mirror and lists available versions for you to choose from.

- 📥 **Downloads the Selected FreeBSD ISO**  
  Downloads the `.iso.xz` file for the selected version from FreeBSD’s official servers.

- 🗜️ **Extracts the ISO**  
  Decompresses the downloaded `.xz` ISO file for use with QEMU.

- 💽 **Creates a Virtual Disk Image**  
  Generates a QEMU-compatible `.qcow2` virtual hard disk with a default size of 20 GB.

- 🖥️ **Launches QEMU Installer**  
  Boots the FreeBSD installer in a QEMU window with user-defined RAM and CPU settings.

- **Enables KVM**   
             Enables KVM if it is present in the system , If KVM is not installed or Available it Downloads and Enables that Feature.

- 🔌 **Sets Up Network Port Forwarding**  
  Forwards host port `2222` to the VM's port `22`, allowing SSH access to the VM from the host.

### 🎯 Goal

To make it extremely easy for users—especially beginners—to install and explore FreeBSD in a virtual machine without manual downloading, extracting, and setup steps.

---

## 🔁 Boot FreeBSD After Installation

Once you've successfully installed FreeBSD using `setupBSD.sh`, you can boot into the system at any time using the included `bootBSD.sh` script.

---

### ▶️ Step-by-Step

 Ensure you're in the project directory:

```bash
cd freebsd-qemu-setup
```
### ▶️ Make the Script Executable

If the script is not already executable, run:

```bash
chmod +x bootBSD.sh
```
---
### 🚀 Run the Script to Start Your FreeBSD VM

To boot your FreeBSD virtual machine, execute the following command:

```bash
./bootBSD.sh
```
---
### 🧠 What This Script Will Do

The `bootBSD.sh` script is used to launch your FreeBSD virtual machine after it has been installed.

When executed, the script:

- ⚙️ Boots the FreeBSD OS directly from the `freebsd.qcow2` virtual disk (no ISO required)
- 🧠 Allocates:
  - 4 GB of RAM (`-m 4096`)
  - 4 CPU cores (`-smp 4`)
- 🚀 Enables KVM acceleration for better performance
- 🌐 Configures user-mode networking with:
  - Port forwarding from host `localhost:2222` to guest `22`
  - Allowing easy SSH access to the VM:

```bash
ssh youruser@localhost -p 2222
```
---





---

## 🤝 Contribute to This Project

This project was built to make virtual machine setup easier for everyone — especially beginners who want to explore FreeBSD in a safe and simple way using QEMU.

If you believe in making virtual environments accessible and beginner-friendly:

- ⭐ Star this repository
- 🍴 Fork and improve the scripts
- 🛠️ Add support for other operating systems (e.g., OpenBSD, NetBSD, Linux distros)
- 🧑‍💻 Submit a pull request with improvements or bug fixes

Let’s build a powerful tool for learning and automation — together. 💻✨
---


## 🐧 LINUX POWERED · BSD FLAVORED · CURIOSITY APPROVED

