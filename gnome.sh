#!/bin/bash
. ./check.sh

pacman_config(){
    printf "%b\n" "${YELLOW}Adding Extra Spice in pacman.conf...${RC}"
    pacman_conf="/etc/pacman.conf"

    # Remove comments '#' from specific lines
    lines_to_edit=(
        "Color"
        "CheckSpace"
        "VerbosePkgLists"
        "ParallelDownloads"
    )

    # Uncomment specified lines if they are commented out
    for line in "${lines_to_edit[@]}"; do
        if grep -q "^#$line" "$pacman_conf"; then
            sudo sed -i "s/^#$line/$line/" "$pacman_conf"
            printf "%b\n" "${GREEN}Uncommented: $line${RC}"
        else
            printf "%b\n" "${GREEN}$line is already uncommented${RC}"
        fi
    done

    # Add "ILoveCandy" below ParallelDownloads if it doesn't exist
    if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
        sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
        printf "%b\n" "${GREEN}Added ${CYAN}ILoveCandy${RC} after ${CYAN}ParallelDownloads${RC}"
    else
        printf "%b\n" "${YELLOW}It seems ${CYAN}ILoveCandy${RC} already exists moving on...${RC}"
    fi

    printf "%b\n" "${GREEN}Pacman.conf spicing up completed${RC}"

    # updating pacman.conf
    printf "%b\n" "${CYAN}Synchronizing Pacman Repo${RC}"
    sudo pacman -Sy
}

install_zsh(){
    printf "%b\n" "${YELLOW}Installing zsh packages${RC}"
    yay -S --needed --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting fzf starship fastfetch trash-cli

    # Check if the zsh-completions directory exists
    if [ -d "zsh-completions" ]; then
	rm -rf zsh-completions
    fi

    # Set zsh as default shell
    if command -v zsh >/dev/null; then
	# Check if the current shell is zsh
	current_shell=$(basename "$SHELL")
	if [ "$current_shell" != "zsh" ]; then
	    printf "%b\n" "${YELLOW}Changing default shell to zsh${RC}..."
	    # Loop to ensure the chsh command succeeds
	    while ! chsh -s "$(command -v zsh)"; do
		printf "%b\n" "${RED}Authentication failed. Please enter the correct password...${RC}"
		sleep 1
	    done
	    printf "%b\n" "${GREEN}Shell changed successfully to zsh${RC}" 
	else
	    printf "%b\n" "${GREEN}Your shell is already set to zsh${RC}"
	fi
    fi
}

install_my_packages(){
    printf "%b\n" "${YELLOW}Installing personal packages...${RC}"
    yay -S --needed --noconfirm neovim floorp-bin libreoffice-fresh libreoffice-extension-h2orestart signal-desktop mpv obs-studio gimp
    # thinkpad stuff
    sudo pacman -S --noconfirm fprintd
    # gnome stuff
    sudo pacman -S --noconfirm power-profiles-daemon
}

install_ibus(){
    printf "%b\n" "${YELLOW}Installing ibus with ibus-hangul and noto-fonts-cjk${RC}"
    yay -S --needed --noconfirm ibus ibus-hangul noto-fonts-cjk
}

checkEnv
pacman_config
install_ibus
#install_zsh
install_my_packages
