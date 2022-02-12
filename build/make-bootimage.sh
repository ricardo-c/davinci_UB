#!/bin/bash
set -ex

KERNEL_OBJ=$(realpath $1)
RAMDISK=$(realpath $2)
OUT=$(realpath $3)

HERE=$(pwd)
source "${HERE}/deviceinfo"

case "$deviceinfo_arch" in
    aarch64*) ARCH="arm64" ;;
    arm*) ARCH="arm" ;;
    x86_64) ARCH="x86_64" ;;
    x86) ARCH="x86" ;;
esac

if [ -d "$HERE/ramdisk-overlay" ]; then
    if [ -d "$HERE/ramdisk-recovery-overlay" ] && [ -e "$HERE/ramdisk-overlay/ramdisk-recovery.img" ]; then
        mkdir -p "$HERE/ramdisk-recovery"

        cd "$HERE/ramdisk-recovery"
        gzip -dc "$HERE/ramdisk-overlay/ramdisk-recovery.img" | cpio -i
        cp -r "$HERE/ramdisk-recovery-overlay"/* "$HERE/ramdisk-recovery"

        find . | cpio -o -H newc | gzip >> "$HERE/ramdisk-overlay/ramdisk-recovery.img"
    fi

    cp "$RAMDISK" "${RAMDISK}-merged"
    RAMDISK="${RAMDISK}-merged"
    cd "$HERE/ramdisk-overlay"
    find . | cpio -o -H newc | gzip >> "$RAMDISK"
fi

if [ -n "$deviceinfo_kernel_image_name" ]; then
    KERNEL="$KERNEL_OBJ/arch/$ARCH/boot/$deviceinfo_kernel_image_name"
else
    # Autodetect kernel image name for boot.img
    if [ "$deviceinfo_bootimg_header_version" -eq 2 ]; then
        IMAGE_LIST="Image.gz Image"
    else
        IMAGE_LIST="Image.gz-dtb Image.gz Image"
    fi

    for image in $IMAGE_LIST; do
        if [ -e "$KERNEL_OBJ/arch/$ARCH/boot/$image" ]; then
            KERNEL="$KERNEL_OBJ/arch/$ARCH/boot/$image"
            break
        fi
    done
fi

if [ -n "$deviceinfo_bootimg_prebuilt_dtb" ]; then
    DTB="$HERE/$deviceinfo_bootimg_prebuilt_dtb"
elif [ -n "$deviceinfo_dtb" ]; then
    DTB="$KERNEL_OBJ/../$deviceinfo_codename.dtb"
    PREFIX=$KERNEL_OBJ/arch/$ARCH/boot/dts/
    DTBS="$PREFIX${deviceinfo_dtb// / $PREFIX}"
    cat $DTBS > $DTB
fi

if [ "$deviceinfo_bootimg_header_version" -eq 2 ]; then
    mkbootimg --kernel "$KERNEL" --ramdisk "$RAMDISK" --dtb "$DTB" --base $deviceinfo_flash_offset_base --kernel_offset $deviceinfo_flash_offset_kernel --ramdisk_offset $deviceinfo_flash_offset_ramdisk --second_offset $deviceinfo_flash_offset_second --tags_offset $deviceinfo_flash_offset_tags --dtb_offset $deviceinfo_flash_offset_dtb --pagesize $deviceinfo_flash_pagesize --cmdline "$deviceinfo_kernel_cmdline" -o "$OUT" --header_version $deviceinfo_bootimg_header_version --os_version $deviceinfo_bootimg_os_version --os_patch_level $deviceinfo_bootimg_os_patch_level
else
    mkbootimg --kernel "$KERNEL" --ramdisk "$RAMDISK" --base $deviceinfo_flash_offset_base --kernel_offset $deviceinfo_flash_offset_kernel --ramdisk_offset $deviceinfo_flash_offset_ramdisk --second_offset $deviceinfo_flash_offset_second --tags_offset $deviceinfo_flash_offset_tags --pagesize $deviceinfo_flash_pagesize --cmdline "$deviceinfo_kernel_cmdline" -o "$OUT"
fi
