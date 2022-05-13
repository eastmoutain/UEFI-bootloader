#!/bin/bash

IMAGE=efi.img
echo "Creating $IMAGE"

dd if=/dev/zero of=$IMAGE bs=1M count=20
sgdisk -og $IMAGE
sgdisk -n 1:0:16M -c 1:"EFI System Partition" -t 1:ef00 $IMAGE

dev=$(sudo losetup -v --show -P -f $IMAGE)
echo $dev ${dev}p1
sudo mkfs.vfat ${dev}p1
sudo mkdir -p mnt_point
sudo mount ${dev}p1 mnt_point
sudo mkdir -p mnt_point/EFI/BOOT

sudo cp -v cmdline mnt_point/cmdline
sudo cp -v lk.bin  mnt_point/lk.bin
sudo cp -v build/bootx64.efi  mnt_point/EFI/BOOT/

sync
sudo umount mnt_point
sudo losetup -d $dev

