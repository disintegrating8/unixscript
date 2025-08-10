#!/bin/bash

RC='\033[0m' # Reset Color
RED='\033[0;31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

base(){
    printf "%b\n" "${YELLOW}Installing base-devel and archlinux-keyring...${RC}"
    yay -S --needed --noconfirm base-devel archlinux-keyring 
    printf "%b\n" "${YELLOW}Installing packages needed to run this script...${RC}"
    yay -S --needed --noconfirm curl wget jq unzip zip findutils curl python python-requests python-pyquery pacman-contrib
    # Packages for all de/wm
    yay -S --needed --noconfirm mate-polkit xdg-user-dirs xdg-utils xclip picom rofi imagemagick brightnessctl flameshot feh dunst rofi kitty
}

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
    yay -S --needed --noconfirm gtk-engine-murrine kvantum qt5ct qt6ct qt6-svg lxappearance-gtk3

    # Check if the directory exists and delete it if present
    if [ -d "GTK-themes-icons" ]; then
        printf "%b\n" "${YELLOW}GTK themes and Icons directory exist; deleting...${RC}"
        rm -rf "GTK-themes-icons"
    fi

    printf "%b\n" "${YELLOW}Cloning GTK themes and Icons repository...${RC}"
    if git clone --depth=1 https://github.com/disintegrating8/GTK-themes-icons.git ; then
        cd "$HOME/GTK-themes-icons"
        chmod +x auto-extract.sh
        ./auto-extract.sh
        cd "$HOME"
        printf "%b\n" "${GREEN}Extracted GTK Themes & Icons to ~/.icons & ~/.themes directories${RC}"
        rm -rf "$HOME/GTK-themes-icons"
    else
        printf "%b\n" "${RED}Download failed for GTK themes and Icons...${RC}"
    fi
}

pipewire() {
    printf "%b\n" "${YELLOW}Disabling pulseaudio to avoid conflicts...${RC}"
    systemctl --user disable --now pulseaudio.socket pulseaudio.service
    printf "%b\n" "${YELLOW}Installing Pipewire Packages...${RC}"
    yay -S --needed --noconfirm pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse sof-firmware pamixer pavucontrol loupe mpv mpv-mpris yt-dlp libspng
    printf "%b\n" "${YELLOW}Activating Pipewire Services...${RC}"
    systemctl --user enable --now pipewire.service pipewire.socket pipewire-pulse.socket wireplumber.service
}

install_ibus(){
    printf "%b\n" "${YELLOW}Installing ibus with ibus-hangul and noto-fonts-cjk${RC}"
    yay -S --needed --noconfirm ibus ibus-hangul noto-fonts-cjk
}

install_fonts(){
    yay -S --needed --noconfirm adobe-source-code-pro-fonts otf-font-awesome ttf-droid ttf-fira-code ttf-fantasque-nerd ttf-jetbrains-mono ttf-jetbrains-mono-nerd ttf-victor-mono ttf-meslo-nerd noto-fonts noto-fonts-emoji
}

configure_zsh(){
    printf "%b\n" "${YELLOW}Installing zsh packages${RC}"
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

configure_thunar(){
    printf "%b\n" "${YELLOW}Installing Thunar Packages...${RC}"  
    yay -S --needed --noconfirm thunar thunar-volman tumbler ffmpegthumbnailer thunar-archive-plugin xarchiver gvfs gvfs-mtp
    printf "%b\n" "${YELLOW}Setting Thunar as default file manager...${RC}"  
    xdg-mime default thunar.desktop inode/directory
    xdg-mime default thunar.desktop application/x-wayland-gnome-saved-search
    printf "%b\n" "${GREEN}Thunar is now set as the default file manager${RC}"
}

configure_nemo(){
    printf "%b\n" "${YELLOW}Installing Nemo Packages...${RC}"  
    yay -S --needed --noconfirm nemo nemo-seahorse nemo-share nemo-fileroller nemo-pastebin nemo-compare nemo-preview nemo-image-converter nemo-audio-tab gvfs gvfs-mtp gvfs-smb gvfs-nfs
    printf "%b\n" "${YELLOW}Setting Nemo as default file manager...${RC}"
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
    gsettings set org.nemo.desktop show-desktop-icons true
    gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
    printf "%b\n" "${GREEN}Nemo is now set as the default file manager${RC}"
}

setupDisplayManager() {
    printf "%b\n" "${YELLOW}Setting up Xorg${RC}"
    sudo pacman -S --needed --noconfirm xorg-xinit xorg-server xorg-xrandr xorg-xinput xorg-xprop
    printf "%b\n" "${GREEN}Xorg installed successfully${RC}"
    printf "%b\n" "${YELLOW}Setting up Display Manager${RC}"
    currentdm="none"
    for dm in gdm sddm lightdm; do
        if command -v "$dm" >/dev/null 2>&1 || sudo systemctl is-active --quiet "$dm"; then
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
    printf "%b\n" "${YELLOW}Installing personal packages...${RC}"
    yay -S --needed --noconfirm btop timeshift neovim github-desktop-bin brave-bin libreoffice-fresh signal-desktop mpv obs-studio gimp prismlauncher gamemode
    yay -S steam
    flatpak install -y com.discordapp.Discord com.github.iwalton3.jellyfin-media-player com.vysp3r.ProtonPlus
}
