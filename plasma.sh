#!/bin/bash

# Prompt for disk
clear;
echo -e "* Please type the name (example: sda) of the disk you want to use (THIS WILL ERASE ALL CONTENTS)\n" && 
lsblk -a;
echo -n "* Disk name: " && read disk;
echo -n "* Please type 'CONFIRM' to confirm that you want to use $disk for arch linux. (I AM NOT RESPONIBLE FOR DATA LOSS.) THE DISK YOU HAVE CHOSEN WILL BE FULLY WIPED:" && read yn && echo "";
if [ "$yn" != "CONFIRM" ]; then
exit;
fi;

# Prompt for user and passwords
echo -n "* Choose a username: " && read username;
echo -n "* Choose a password: " && read userpass;
echo -n "* Choose ROOT ACCOUNT password (Should be different from user): " && read -n rootpass;
echo -n "* Do you want to make your user an administrator (yes/no): " && read useradminyn;

# Prompt for locale, timezone, hostname
