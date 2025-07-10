#!/bin/bash

base(){
    # Packages needed to run this script
    echo -e "\nInstalling ${SKY_BLUE}base-devel${RESET} and ${SKY_BLUE}archlinux-keyring${RESET}..."
    yay -S --needed --noconfirm base-devel archlinux-keyring findutils curl wget jq unzip python python-requests python-pyquery pacman-contrib

    # Packages for all de/wm
    yay -S --needed --noconfirm kitty bc imagemagick inxi xdg-user-dirs xdg-utils brightnessctl yad 
}

configure_backgrounds() {
    # Set the variable PIC_DIR which stores the path for images
    PIC_DIR="$HOME/Pictures"

    # Set the variable BG_DIR to the path where backgrounds will be stored
    BG_DIR="$PIC_DIR/backgrounds"

    # Check if the ~/Pictures directory exists
    if [ ! -d "$PIC_DIR" ]; then
        # If it doesn't exist, print an error message and return with a status of 1 (indicating failure)
        printf "%b\n" "${RED}Pictures directory does not exist${RC}"
        mkdir ~/Pictures
        printf "%b\n" "${GREEN}Directory was created in Home folder${RC}"
    fi

    # Check if the backgrounds directory (BG_DIR) exists
    if [ ! -d "$BG_DIR" ]; then
        # If the backgrounds directory doesn't exist, attempt to clone a repository containing backgrounds
        if ! git clone https://github.com/ChrisTitusTech/nord-background.git "$PIC_DIR/nord-background"; then
            # If the git clone command fails, print an error message and return with a status of 1
            printf "%b\n" "${RED}Failed to clone the repository${RC}"
            return 1
        fi
        # Rename the cloned directory to 'backgrounds'
        mv "$PIC_DIR/nord-background" "$PIC_DIR/backgrounds"
        # Print a success message indicating that the backgrounds have been downloaded
        printf "%b\n" "${GREEN}Downloaded desktop backgrounds to $BG_DIR${RC}"    
    else
        # If the backgrounds directory already exists, print a message indicating that the download is being skipped
        printf "%b\n" "${GREEN}Path $BG_DIR exists for desktop backgrounds, skipping download of backgrounds${RC}"
    fi
}

app_themes() {
    # installing engine needed for gtk themes
    yay -S --needed --noconfirm unzip gtk-engine-murrine kvantum qt5ct qt6ct qt6-svg lxappearance-gtk3

    # Check if the directory exists and delete it if present
    if [ -d "GTK-themes-icons" ]; then
        echo "$NOTE GTK themes and Icons directory exist..deleting..."
        rm -rf "GTK-themes-icons"
    fi

    echo "$NOTE Cloning ${SKY_BLUE}GTK themes and Icons${RESET} repository..."
    if git clone --depth=1 https://github.com/disintegrating8/GTK-themes-icons.git ; then
        cd GTK-themes-icons
    chmod +x auto-extract.sh
        ./auto-extract.sh
        cd ..
        echo "$OK Extracted GTK Themes & Icons to ~/.icons & ~/.themes directories"
    else
        echo "$ERROR Download failed for GTK themes and Icons.."
    fi
}

pipewire() {
    echo -e "${NOTE} Disabling pulseaudio to avoid conflicts..."
    systemctl --user disable --now pulseaudio.socket pulseaudio.service
    yay -S --needed --noconfirm pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse sof-firmware pamixer pavucontrol playerctl cava loupe mpv mpv-mpris yt-dlp libspng
    systemctl --user enable --now pipewire.service pipewire.socket pipewire-pulse.socket wireplumber.service
}

install_ibus(){
    yay -S --needed --noconfirm ibus ibus-hangul noto-fonts-cjk
}

install_fonts(){
    yay -S --needed --noconfirm adobe-source-code-pro-fonts otf-font-awesome ttf-droid ttf-fira-code ttf-fantasque-nerd ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-victor-mono ttf-meslo-nerd noto-fonts noto-fonts-emoji
}

configure_zsh(){
    yay -S --needed --noconfirm lsd zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf starship fastfetch
    # Check if the zsh-completions directory exists
    if [ -d "zsh-completions" ]; then
	rm -rf zsh-completions
    fi

    # Set zsh as default shell
    if command -v zsh >/dev/null; then
      # Check if the current shell is zsh
      current_shell=$(basename "$SHELL")
      if [ "$current_shell" != "zsh" ]; then
	printf "${NOTE} Changing default shell to ${MAGENTA}zsh${RESET}..."

	# Loop to ensure the chsh command succeeds
	while ! chsh -s "$(command -v zsh)"; do
	  echo "${ERROR} Authentication failed. Please enter the correct password." 2>&1 | tee -a "$LOG"
	  sleep 1
	done

	printf "${INFO} Shell changed successfully to ${MAGENTA}zsh${RESET}" 2>&1 | tee -a "$LOG"
      else
	echo "${NOTE} Your shell is already set to ${MAGENTA}zsh${RESET}."
      fi
    fi
}

configure_thunar(){
    printf "${INFO} Installing ${SKY_BLUE}Thunar${RESET} Packages...\n"  
    yay -S --needed --noconfirm thunar thunar-volman tumbler ffmpegthumbnailer thunar-archive-plugin xarchiver gvfs gvfs-mtp
     # Check for existing configs and copy if does not exist
    for DIR1 in gtk-3.0 Thunar xfce4; do
      DIRPATH=~/.config/$DIR1
      if [ -d "$DIRPATH" ]; then
        echo -e "${NOTE} Config for ${MAGENTA}$DIR1${RESET} found, no need to copy."
      else
        echo -e "${NOTE} Config for ${YELLOW}$DIR1${RESET} not found, copying from assets."
        cp -r assets/$DIR1 ~/.config/ && echo "${OK} Copy $DIR1 completed!" || echo "${ERROR} Failed to copy $DIR1 config files."
      fi
    done

    printf "${INFO} Setting ${SKY_BLUE}Thunar${RESET} as default file manager...\n"  
     
    xdg-mime default thunar.desktop inode/directory
    xdg-mime default thunar.desktop application/x-wayland-gnome-saved-search
    echo "${OK} ${MAGENTA}Thunar${RESET} is now set as the default file manager."
}

setupDisplayManager() {
    printf "%b\n" "${YELLOW}Setting up Xorg${RC}"
    sudo pacman -S --needed --noconfirm xorg-xinit xorg-server xorg-xrandr xorg-xinput xorg-xprop
    printf "%b\n" "${GREEN}Xorg installed successfully${RC}"
    printf "%b\n" "${YELLOW}Setting up Display Manager${RC}"
    currentdm="none"
    for dm in gdm sddm lightdm; do
        if command -v "$dm" >/dev/null 2>&1 || isServiceActive "$dm"; then
            currentdm="$dm"
            break
        fi
    done
    printf "%b\n" "${GREEN}Current display manager: $currentdm${RC}"
    if [ "$currentdm" = "none" ]; then
        printf "%b\n" "${YELLOW}--------------------------${RC}" 
        printf "%b\n" "${YELLOW}Pick your Display Manager ${RC}" 
        printf "%b\n" "${YELLOW}1. SDDM ${RC}" 
        printf "%b\n" "${YELLOW}2. LightDM ${RC}" 
        printf "%b\n" "${YELLOW}3. GDM ${RC}"
        printf "%b\n" "${YELLOW}4. Ly ${RC}" 
        printf "%b\n" "${YELLOW}5. None ${RC}" 
        printf "%b" "${YELLOW}Please select one: ${RC}"
        read -r choice
        case "$choice" in
            1)
                DM="sddm"
                ;;
            2)
                DM="lightdm"
                ;;
            3)
                DM="gdm"
                ;;
            4)
                DM="ly"
                ;;
            5)
                printf "%b\n" "${GREEN}No display manager will be installed${RC}"
                return 0
                ;;
            *)
                printf "%b\n" "${RED}Invalid selection! Please choose 1, 2, 3, or 4.${RC}"
                return 1
                ;;
        esac
        sudo pacman -S --needed --noconfirm "$DM"
	if [ "$DM" = "lightdm" ]; then
	    sudo pacman -S --needed --noconfirm lightdm-gtk-greeter
	fi
        printf "%b\n" "${GREEN}$DM installed successfully${RC}"
        enableService "$DM"
    fi
}

personal_packages(){
    echo "Installing dev tools..."
    yay -S --needed --noconfirm btop timeshift zip neovim bat
    echo "Installing apps..."
    yay -S --needed --noconfirm github-desktop-bin librewolf-bin libreoffice-fresh mpv obs-studio gimp steam prismlauncher gamescope gamemode
    flatpak install -y com.discordapp.Discord com.github.iwalton3.jellyfin-media-player com.vysp3r.ProtonPlus
}
