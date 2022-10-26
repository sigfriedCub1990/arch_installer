#!/bin/bash

name=$(cat /tmp/user_name)

apps_path="/tmp/apps.csv"
curl https://raw.githubusercontent.com/sigfriedcub1990/arch_installer/master/apps.csv >$apps_path

dialog --title "Welcom!" \
	--msgbox "Welcome to the installation script for your apps and dotfiles!" \
	10 60

apps=(
	"essential" "Essentials" on
	"network" "Network" on
	"tools" "Nice to have (recommended)" on
	"tmux" "Tmux" on
	"notifier" "Notification tools" on
	"git" "Git & some git tools" on
	"i3" "i3 wm" on
	"zsh" "The Z-Shell (zsh)" on
	"neovim" "Neovim" on
	"alacritty" "Alacritty" on
	"firefox" "Firefox (browser)" on
	"chromium" "Chromium (browser)" off
)

dialog --checklist \
	"You can now choose what group of application(s) you want to install. \n\n
    You can select an option with SPACE and validate your choices with ENTER." \
	0 0 0 \
	"${apps[@]}" 2>app_choices

choices=$(cat app_choices) && rm app_choices

selection="^$(echo $choices | sed -e 's/ /,|^/g'),"
lines=$(grep -E "$selection" "$apps_path")
count=$(echo "$lines" | wc -l)
packages=$(echo "$lines" | awk -F, {'print $2'})

echo "$selection" "$lines" "$count" >>"/tmp/packages"

pacman -Syu --noconfirm

rm -f /tmp/aur_queue

dialog --title "Let's go" --msgbox \
	"The system will now install everything you need. \n\n\
    It will take some time. \n\n " \
	13 60

c=0
echo "$packages" | while read -r line; do
	c=$(("$c" + 1))

	dialog --title "Arch Linux Installation" --infobox \
		"Downloading and installing program $c out of $count: $line..." \
		8 70

	( (pacman --noconfirm --needed -S "$line" >/tmp/arch_install 2>&1) ||
		echo "$line" >>/tmp/aur_queue) ||
		echo "$line" >>/tmp/arch_install_failed

	if [ "$line" = "zsh" ]; then
		# Set ZSH as the default shell for our user
		chsh -s "$(which zsh)" "$name"
	fi

	if [ "$line" = "networkmanager" ]; then
		systemctl enable NetworkManager.service
	fi
done

echo "%wheel ALL=(ALL) ALL" >>/etc/sudoers

curl https://raw.githubusercontent.com/sigfriedcub1990/arch_installer/master/install_user.sh >/tmp/install_user.sh

sudo -u "$name" sh /tmp/install_user.sh
