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



