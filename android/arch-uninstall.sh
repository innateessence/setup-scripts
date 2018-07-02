#!/bin/bash

cd /data/local
echo "[!] Unmounting fs"
umount arch/dev
umount arch/sys
umount arch/proc
echo "[!] Deleting Arch OS"
rm -r arch
