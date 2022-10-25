#!/bin/bash

# Don't do this on a live system(why?)
pacman -Sy dialog

timdatectl set-ntp true

dialog --defaultno --title "Are you sure?" --yesno \
	"This is my personal arch linux install. \n\n\
It will DESTROY EVERYTHING on one of your hard disk. \n\n\
Don't say YES if you are not sure what you're doing! \n\n\
Do you want to continue?" 15 60 || exit

dialog --no-cancel --inputbox "Enter a name for your computer." \
	10 60 2>comp

# Verify whether we have UEFI or not
uefi=0
ls /sys/firmware/efi/efivars 2>/dev/null && uefi=1

# Choosing hard-drive to install the system
devices_list=($(lsblk -d | awk '{print "/dev/" $1 " " $4 " on"}' |
	grep -E 'sd|hd|vd|nvme|mmcblk'))

dialog --title "Choose your hard drive" --no-cancel --radiolist \
	"Where do you want to install your new system? \n\n
    Select with SPACE, valid with ENTER. \n\n
        WARNING: Everything will be DESTROYED on the hard disk!" \
	15 60 4 "${devices_list[@]}" 2>hd

hd=$(cat hd) && rm hd
