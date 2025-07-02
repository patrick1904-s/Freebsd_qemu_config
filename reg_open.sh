#!/bin/bash

DISK_FILE="freebsd.qcow2"
RAM="4096"
CPUS="4"

qemu-system-x86_64 \
  -enable-kvm \
  -m "$RAM" \
  -hda "$DISK_FILE" \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=n1 \
  -smp "$CPUS" \
  -cpu host

