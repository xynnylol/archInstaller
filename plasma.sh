#!/bin/bash

# Prompt for disk
clear;
echo -e "* Warning: You WILL NEED a working internet conenction\n";
echo -e "* Please type the name (example: sda) of the disk you want to use (THIS WILL ERASE ALL CONTENTS)\n" && 
lsblk -a;
echo -n "* Disk name: " && read disk;
echo -n "* Please type 'CONFIRM' to confirm that you want to use $disk for arch linux. (I AM NOT RESPONIBLE FOR DATA LOSS.) THE DISK YOU HAVE CHOSEN WILL BE FULLY WIPED: " && read yn && echo "";
if [ "$yn" != "CONFIRM" ]; then
exit;
fi;

# Prompt for user and passwords
echo "";
echo -n "* Choose a username: " && read username;
echo -n "* Choose a password: " && read userpass;
echo -n "* Choose ROOT ACCOUNT password (Should be different from user): " && read rootpass;
echo -n "* Do you want to make your user an administrator (yes/no): " && read useradminyn;

# Prompt for locale, timezone, hostname
promptSysInfo(){
echo -e "\nYou can find timezone here: https://en.m.wikipedia.org/wiki/List_of_tz_database_time_zones#List\n\nYou can find your locale here: https://saimana.com/list-of-country-locale-code\n";
echo -n "* Please type your timezone (Case senitive) (Example: Europe/London): " && read timezone;
if [ ! -f "/usr/share/zoneinfo/$timezone" ];then
echo "* Invalid timezone, You can find timezone here: https://en.m.wikipedia.org/wiki/List_of_tz_database_time_zones#List";
echo "";
promptSysInfo;
return;
fi;
echo -n "* Please type your locale (Case sensitive) (Example: en-GB): " && read locale;
echo -n "* Please type the name for this pc: " && read hostname;
echo -n "* Is your pc legacy (BIOS) or UEFI ? (legacy/uefi): " && read boottype;
echo -n "* Is your pc MBR or GPT ? (gpt/mbr): " && read disktype;
};
promptSysInfo;

# Final confirmation
echo "";
echo -en "LAST CHANCE. Do you wish to install arch linux (Desktop: Plasma X11) onto disk $disk\n\nPlease type 'CONFIRM' to proceed: " && read yn;
if [ "$yn" != "CONFIRM" ]; then
exit;
fi;
clear;

# Start installing
echo -e "* Starting installation, This may take a while\n";

# Create partiton table
echo "* Creating partitions";
if [ "$disktype" = "mbr" ]; then
fdisk "/dev/$disk" <<EEOF
d
w
EEOF
else
fdisk "/dev/$disk" <<EEOF
g
w
EEOF
fi;

# Create partitions
if [ "$boottype" = "uefi" ]; then
if [ "$disktype" = "mbr" ]; then
fdisk "/dev/$disk" <<EEOF
n


+512M


n





a
1

w
EEOF
parted "/dev/$disk" set 1 boot on;
echo "y" | mkfs.ext4 "/dev/${disk}1";
echo "y" | mkfs.ext4 "/dev/${disk}2";
mount "/dev/${disk}2" /mnt;
mkdir -p /mnt/home /mnt/boot;
mount "/dev/${disk}1" /mnt/boot;
else
fdisk "/dev/$disk" <<EEOF
n


+512M


n





t
1
1

w
EEOF
mkfs.fat "/dev/${disk}1";
echo "y" | mkfs.ext4 "/dev/${disk}2";
mount "/dev/${disk}2" /mnt;
mkdir -p /mnt/home /mnt/boot/efi;
mount "/dev/${disk}1" /mnt/boot/efi;
fi;
else
if [ "$disktype" = "gpt" ]; then
fdisk "/dev/$disk" <<EEOF
n


+1M


n


+512M


n





t
1
4

t
2
1

w
EEOF
mkfs.fat "/dev/${disk}2";
echo "y" | mkfs.ext4 "/dev/${disk}3";
mount "/dev/${disk}3" /mnt;
mkdir -p /mnt/home /mnt/boot/efi;
mount "/dev/${disk}2" /mnt/boot/efi;
else
fdisk "/dev/$disk" <<EEOF
n


+512M


n





a
1

w
EEOF
parted "/dev/$disk" set 1 boot on;
echo "y" | mkfs.ext4 "/dev/${disk}1";
echo "y" | mkfs.ext4 "/dev/${disk}2";
mount "/dev/${disk}2" /mnt;
mkdir -p /mnt/home /mnt/boot;
mount "/dev/${disk}1" /mnt/boot;
fi;
fi;

# Install base system
echo "* Installing arch linux";
pacman-key --init;
pacman-key --populate;
echo "y" | pacman -Sy archlinux-keyring;
#echo -e "\n\n\n\n\n\n\n\n\n\n\n" | pacstrap /mnt base linux linux-headers man-db man-pages texinfo networkmanager git sudo nano curl chromium konsole sddm xorg-server xorg-xrandr dolphin plasma;
pacstrap -K /mnt;
genfstab -U /mnt > /mnt/etc/fstab;
arch-chroot /mnt <<EEOF

# Configure
echo "* Configuring system";
pacman-key --init
pacman-key --populate
echo "y" | pacman -Sy archlinux-keyring;
echo -e "\n\n\n\n\n\n\n\n\n\n\n\n\n\n" | pacman -Sy base linux linux-headers man-db man-pages texinfo networkmanager git sudo nano curl chromium konsole sddm xorg-server xorg-xrandr dolphin plasma;
ln -sf "/usr/share/zoneinfo/$timezone" /etc/localtime;
hwclock --systohc;
echo "$locale UTF-8" >> /etc/locale.gen;
locale-gen;
echo "$hostname" > /etc/hostname;
systemctl enable NetworkManager;
systemctl enable sddm;
( echo "$rootpass"; echo "$rootpass"; ) | passwd;
if [ "$useradminyn" = "yes" ]; then
useradd -m "$username" -G wheel,optical,disk,storage;
else
useradd -m "$username" -G optical,disk,storage;
fi;
( echo "$userpass"; echo "$userpass" ) | passwd "$username";
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers;
mkinitcpio -P

# Install bootloader
echo "* Installing bootloader";
if [ "$disktype" = "mbr" ]; then
echo "y" | pacman -Sy syslinux;
syslinux-install_update -i -a -m;
mkinitcpio -P;
else
echo "y" | pacman -Sy efibootmgr grub;
grub-install "/dev/$disk";
grub-mkconfig -o /boot/grub/grub.cfg;
mkinitcpio -P;
fi;
EEOF

# Unmount all partitions
genfstab -U /mnt > /mnt/etc/fstab
umount -a;
echo -n "* Install success press enter to reboot " && read;
reboot;
