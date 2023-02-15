#!/bin/bash

# Prompt for disk
clear;
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
if [ ! -f "/usr/share/zoneinfo/" ];then
echo "* Invalid timezone, You can find timezone here: https://en.m.wikipedia.org/wiki/List_of_tz_database_time_zones#List";
echo "";
promptSysInfo;
return;
fi;
echo -n "* Please type your locale (Case sensitive) (Example: en-GB): " && read locale;
if [ ! -f "/usr/share/zoneinfo/" ];then
echo "* Invalid timezone, You can find timezone here: https://en.m.wikipedia.org/wiki/List_of_tz_database_time_zones#List";
echo "";
promptSysInfo;
return;
fi;
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
d
w
EEOF
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
fi;
else
if [ "$disktype" = "mbr" ]; then
fdisk "/dev/$disk" <<EEOF
d
w
EEOF
else
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
fi;
fi;
