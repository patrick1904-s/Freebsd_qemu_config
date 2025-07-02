r 🐚 FreeBSD in QEMU with KVM on Linux

This repository helps you run **FreeBSD** in a **QEMU virtual machine** using **KVM acceleration** on a Linux host. It's designed for beginners, developers, and researchers who want to experiment with FreeBSD in a safe and fast environment.

---

## 🚀 Features

- Run FreeBSD with QEMU + KVM
- Automated setup script
- SSH access from host to guest
- Easy-to-understand and clean configuration
- Works on Debian-based systems (e.g., Parrot OS, Ubuntu)

---

## 📦 Requirements

- Linux OS with:
  - `qemu-system-x86`
  - `xz-utils`
  - `wget`
- CPU with virtualization support (`kvm`)

---

## 📥 Step 1: Download FreeBSD ISO

```bash
wget https://download.freebsd.org/releases/amd64/amd64/ISO-IMAGES/14.3/FreeBSD-14.3-RELEASE-amd64-disc1.iso.xz

 step 2: Run the script:
    * Extract the iso from the .xz
    * creates a 20 GB virtual disk(freebsd.qcow2)
    * Launches the Freebsd installer with 4 GB RAM and 4CPUs

 step 3: Run the installation script
    * Run the setupBSD.sh
```bash
        chmod +x setupBSD.sh
        ./setupBSD.sh 
 
 step 4: Freebsd Installation Notes

    FreeBSD Installation Notes

Inside the QEMU window:

    Keymap: default (US)

    Partitioning: Auto (UFS)

    Enable Services: enable sshd and ntpd

    Create User: add a user and give it wheel group (for su or sudo)

    Root Password: set it securely

    Reboot: after install, remove CD-ROM and reboot 


![Made with Love](https://img.shields.io/badge/Made%20with-FreeBSD-blue?style=for-the-badge&logo=freebsd)
![Powered by QEMU](https://img.shields.io/badge/Powered%20by-QEMU-ff69b4?style=for-the-badge&logo=qemu)


