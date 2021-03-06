#!/bin/sh
set -e

GENTOO_MIRROR="http://distfiles.gentoo.org"

GENTOO_ARCH="amd64"
GENTOO_STAGE3="amd64"

TARGET_DISK=/dev/sda

TARGET_BOOT_SIZE=100M
TARGET_SWAP_SIZE=1G

GRUB_PLATFORMS=pc

ROOT_PASSWORD=${ROOT_PASSWORD:-}

ntpd -gq

sfdisk ${TARGET_DISK} << END
size=$TARGET_BOOT_SIZE,bootable
size=$TARGET_SWAP_SIZE
;
END

yes | mkfs.ext4 ${TARGET_DISK}1
yes | mkswap ${TARGET_DISK}2
yes | mkfs.ext4 ${TARGET_DISK}3

e2label ${TARGET_DISK}1 boot
swaplabel ${TARGET_DISK}2 -L swap
e2label ${TARGET_DISK}3 root

swapon ${TARGET_DISK}2

mkdir -p /mnt/gentoo
mount ${TARGET_DISK}3 /mnt/gentoo

mkdir -p /mnt/gentoo/boot
mount ${TARGET_DISK}1 /mnt/gentoo/boot

cd /mnt/gentoo

STAGE3_PATH_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds/latest-stage3-$GENTOO_STAGE3-openrc.txt"
STAGE3_PATH=$(curl -s "$STAGE3_PATH_URL" | grep -v "^#" | cut -d" " -f1)
STAGE3_URL="$GENTOO_MIRROR/releases/$GENTOO_ARCH/autobuilds/$STAGE3_PATH"

wget "$STAGE3_URL"

tar xvpf "$(basename "$STAGE3_URL")" --xattrs-include='*.*' --numeric-owner

rm -fv "$(basename "$STAGE3_URL")"

LIVECD_KERNEL_VERSION=$(cut -d " " -f 3 < /proc/version)

cp -v "/mnt/cdrom/boot/gentoo" "/mnt/gentoo/boot/vmlinuz-$LIVECD_KERNEL_VERSION"
cp -v "/mnt/cdrom/boot/gentoo.igz" "/mnt/gentoo/boot/initramfs-$LIVECD_KERNEL_VERSION.img"
cp -vR "/lib/modules/$LIVECD_KERNEL_VERSION" "/mnt/gentoo/lib/modules/"

mkdir -p /mnt/gentoo/etc/kernels
cp -v /etc/kernels/* /mnt/gentoo/etc/kernels

cp -v /etc/resolv.conf /mnt/gentoo/etc/

cat >> /mnt/gentoo/etc/fstab << END

LABEL=boot /boot ext4 noauto,noatime 1 2
LABEL=swap none  swap sw             0 0
LABEL=root /     ext4 noatime        0 1
END

mount -t proc none /mnt/gentoo/proc
mount -t sysfs none /mnt/gentoo/sys
mount -o bind /dev /mnt/gentoo/dev
mount -o bind /dev/pts /mnt/gentoo/dev/pts
mount -o bind /dev/shm /mnt/gentoo/dev/shm

chroot /mnt/gentoo /bin/bash -s << END
#!/bin/bash

set -e

env-update
source /etc/profile

mkdir -p /etc/portage/repos.conf
cp -f /usr/share/portage/config/repos.conf /etc/portage/repos.conf/gentoo.conf
emerge-webrsync

emerge sys-kernel/gentoo-sources

emerge grub

cat >> /etc/portage/make.conf << IEND

GRUB_PLATFORMS="$GRUB_PLATFORMS"
IEND

cat >> /etc/default/grub << IEND

GRUB_CMDLINE_LINUX="net.ifnames=0"
GRUB_DEFAULT=0
GRUB_TIMEOUT=0
IEND

grub-install ${TARGET_DISK}
grub-mkconfig -o /boot/grub/grub.cfg

ln -s /etc/init.d/net.lo /etc/init.d/net.eth0
rc-update add net.eth0 default

echo "root:$ROOT_PASSWORD" | chpasswd

END

reboot
