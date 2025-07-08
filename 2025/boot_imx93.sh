#!/bin/bash

# Function to pad a file to 4096 bytes
pad_to_4096() {
	local file="$1"

	if [ -z "$file" ]; then
		echo "Usage: pad_to_4096 <file>"
		return 1
	fi

	if [ ! -f "$file" ]; then
		echo "Error: File '$file' not found."
		return 2
	fi

	local filesize
	filesize=$(stat -c%s "$file")
	local block_size=4096
	local remainder=$(( filesize % block_size ))
	local padding=$(( remainder == 0 ? 0 : block_size - remainder ))

	if [ "$padding" -ne 0 ]; then
		dd if=/dev/zero bs=1 count="$padding" >> "$file" 2>/dev/null
		echo "Padded $padding bytes to make '$file' a multiple of $block_size bytes."
	else
		echo "'$file' is already a multiple of $block_size bytes. No padding needed."
	fi
}

# Main script

if [ "$#" -ne 3 ]; then
	echo "Usage: $0 <path/to/Image> <path/to/device.dtb> <path/to/rootfs.ext2>"
	exit 1
fi

SRC_IMAGE="$1"
SRC_DTB="$2"
SRC_ROOTFS="$3"
FLASH_BIN="flash.bin"	# Assumes it's in current directory

# Check that flash.bin exists
if [ ! -f "$FLASH_BIN" ]; then
	echo "Error: '$FLASH_BIN' not found."
	exit 2
fi

# Copy input files locally
cp "$SRC_IMAGE" _Image || exit 1
cp "$SRC_DTB"   _dtb   || exit 1
cp "$SRC_ROOTFS" _rootfs || exit 1

# Pad all local copies
pad_to_4096 "_Image"
pad_to_4096 "_dtb"
pad_to_4096 "_rootfs"

# Add cwd to $PATH to be able to use the local uuu
PATH=$PATH:$(pwd)
# Run uuu
echo "Running uuu..."
uuu -b emmc_boot "$FLASH_BIN" "_rootfs" "_Image" "_dtb"

