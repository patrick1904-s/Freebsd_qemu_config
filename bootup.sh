#!/bin/bash

qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -hda freebsd.qcow2 \
  -netdev user,id=n1,hostfwd=tcp::2222-:22 \
  -device e1000,netdev=n1 \
  -smp 4 \
  -cpu host

