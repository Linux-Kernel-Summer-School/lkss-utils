#!/bin/bash

set -e

KERNEL_ROOT=/home/student/work/nss-linux
ROOTFS_PATH=/home/student/work/images/rootfs.ext2
MNT_ENTRY_NAME=tmp
WORKING_DIRECTORY=$(pwd)

print_usage()
{
	echo "Usage:"
	echo "-m KERNEL_ROOT_PATH"
	echo "-r ROOTFS_PATH"
	echo "-m MNT_ENTRY_NAME"
	exit 1
}

while getopts k:r:m:h flags
do
	case "${flags}" in
		k) KERNEL_ROOT=${OPTARG};;
		r) ROOTFS_PATH=${OPTARG};;
		m) MNT_ENTRY_NAME=${OPTARG};;
		h) print_usage ;;
	esac
done

if [ ! -d /mnt/$MNT_ENTRY_NAME ]; then
	echo "Creating $MNT_ENTRY_NAME directory in /mnt"
	sudo mkdir -p /mnt/$MNT_ENTRY_NAME || echo "Failed to create /mnt/$MNT_ENTRY_NAME"
else
	echo "/mnt/$MNT_ENTRY_NAME already exists. Please change MNT_ENTRY_NAME" && exit 1
fi

if [ ! -f $ROOTFS_PATH ]; then
	echo "No file at $ROOTFS_PATH" && sudo rm -r /mnt/$MNT_ENTRY_NAME && exit 1
fi

echo "Mounting $ROOTFS_PATH at /mnt/$MNT_ENTRY_NAME"
sudo mount $ROOTFS_PATH /mnt/$MNT_ENTRY_NAME

if [ ! -d $KERNEL_ROOT ]; then
	echo "$KERNEL_ROOT not a directory" && sudo umount $ROOTFS_PATH && exit 1
fi

echo "Cleaning old modules"
sudo rm -rf /mnt/$MNT_ENTRY_NAME/lib/modules || exit 1

echo "Doing make modules_install at $KERNEL_ROOT"
cd $KERNEL_ROOT || exit 1
sudo ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- INSTALL_MOD_PATH=/mnt/$MNT_ENTRY_NAME make modules_install || exit 1
cd $WORKING_DIR || exit 1

echo "Unmounting $ROOTFS_PATH"
sudo umount /mnt/$MNT_ENTRY_NAME || cleanup "Failed to unmount /mnt/$MNT_ENTRY_NAME" "/mnt/$MNT_ENTRY_NAME"

echo "Removing /mnt/$MNT_ENTRY_NAME"
sudo rm -rf /mnt/$MNT_ENTRY_NAME
