#!/bin/bash

# Read saved variables
uefi=$(cat /var_uefi)
hd=$(cat /var_hd)

# Set hostname
cat /comp >/etc/hostname && rm /comp

pacman --noconfirm -S dialog

pacman -S --noconfirm grub

if [ "$uefi" = 1 ]; then
	pacman -S --noconfirm efibootmgr
	grub-install --target=x86_64-efi \
		--bootloader-id=GRUB \
		--efi-directory=/boot/efi
else
	grub-install "$hd"
fi

grub-mkconfig -o /boot/grub/grub.cfg

# Set hardware clock from system clock
hwclock --systohc
timedatectl set-timezone "Europe/Moscow"

echo "en_US.UTF-8 UTF-8" >>/etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" >>/etc/locale.conf

# Create an user with a password
function config_user() {
	if [ -z "$1" ]; then
		dialog --no-cancel --inputbox "Please enter your user name." \
			10 60 2>name
	else
		echo "$1" >name
	fi

	dialog --no-cancel --passwordbox "Enter your password." \
		10 60 2>pass1
	dialog --no-cancel --passwordbox "Confirm your password." \
		10 60 2>pass2

	while [ "$(cat pass1)" != "$(cat pass2)" ]; do
		dialog --no-cancel --passwordbox "The passwords don't match. \n\n Enter your password again." \
			10 60 2>pass1
		dialog --no-cancel --passwordbox "Retype your password." \
			10 60 2>pass2
	done

	name=$(cat name) && rm name
	pass1=$(cat pass1) && rm pass1 pass2

	# Create user if doesn't exist
	if [[ ! "$(id -u "$name" 2>/dev/null)" ]]; then
		useradd -m -g wheel -s /bin/bash "$name"
	fi

	# Set User's password
	echo "$name:$pass1" | chpasswd
}

dialog --title "Root password" \
	--msgbox "Add password for the root user" \
	10 60
config_user root

dialog --title "Add user" \
	--msgbox "Let's create another user" \
	10 60
config_user

echo "$name" >/tmp/user_name
dialog --title "Continue installation" --yesno \
	"Do you want to install all of your apps and your dotfiles?" \
	10 60 &&
	curl https://raw.githubusercontent.com/sigfriedcub1990/arch_installer/master/install_apps.sh >/tmp/install_apps.sh &&
	bash /tmp/install_apps.sh
