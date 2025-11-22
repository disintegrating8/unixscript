#!/bin/bash
. ./check.sh
DIRS=()

install_base(){
    sudo pacman -S --needed --noconfirm base-devel archlinux-keyring findutils curl wget jq python-requests python-pyquery unzip \
	xdg-user-dirs xdg-utils pacman-contrib \
	hyprland hypridle hyprlock hyprpolkitagent wlogout network-manager-applet rofi swaync swww wallust waybar \
	bc cliphist wl-clipboard grim slurp imagemagick inxi libspng qalculate-gtk \
	kitty nano vim neovim btop nvtop \
	nwg-look kvantum qt5ct qt6ct qt6-svg \
	pamixer pavucontrol playerctl brightnessctl mpv mpv-mpris yt-dlp ffmpeg \
	adobe-source-code-pro-fonts noto-fonts noto-fonts-emoji otf-font-awesome ttf-droid ttf-fira-code ttf-fantasque-nerd ttf-jetbrains-mono ttf-jetbrains-mono-nerd #ttf-victor-mono
}

setup_sddm(){
    sudo pacman -S --needed --noconfirm qt6-declarative qt6-svg qt6-virtualkeyboard qt6-multimedia-ffmpeg sddm
    sudo systemctl enable sddm
    wayland_sessions_dir=/usr/share/wayland-sessions
    [ ! -d "$wayland_sessions_dir" ] && { printf "$CAT - $wayland_sessions_dir not found, creating...\n"; sudo mkdir "$wayland_sessions_dir"; }
}

install_pipewire(){
    printf "%b\n" "${YELLOW}Installing Pipewire Packages...${RC}"
    sudo pacman -S --needed --noconfirm pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse sof-firmware
    printf "%b\n" "${YELLOW}Activating Pipewire Services...${RC}"
    systemctl --user enable --now pipewire.service pipewire.socket pipewire-pulse.socket wireplumber.service
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

install_fcitx(){
    sudo pacman -S --noconfirm fcitx5-im fcitx5-hangul noto-fonts-cjk
    DIRS+=("fcitx")
}

install_zsh(){
    printf "%b\n" "${YELLOW}Installing zsh packages${RC}"
    sudo pacman -S --needed --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting fzf fastfetch trash-cli

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
    DIRS+=("zsh" "starship")
}

install_my_packages(){
    printf "%b\n" "${YELLOW}Installing personal packages...${RC}"
    yay -S --needed --noconfirm man-pages man-db neovim floorp-bin libreoffice-fresh libreoffice-extension-h2orestart signal-desktop mpv obs-studio gimp
    #yay -S steam prismlauncher gamemode
    #flatpak install -y com.discordapp.Discord com.github.iwalton3.jellyfin-media-player com.vysp3r.ProtonPlus
    DIRS+=("nvim")
}

stow_dotfiles() {
    STOW_DIR="$HOME/dotfiles"
    BACKUP_DIR="$HOME/unixscript/backups"

    # Ensure stow is installed
    if ! command -v stow &>/dev/null; then
	printf "%b\n" "${YELLOW}Stow not found, installing...${RC}"
	if ! yay -S --needed --noconfirm stow; then
	    printf "%b\n" "${RED}Failed to install Stow${RC}"
	    exit 1
	fi
    fi

    # Clone or update dotfiles
    if [ -d "$HOME/dotfiles" ]; then
	cd "$HOME/dotfiles" && git stash && git pull
    else
	cd "$HOME"
	if git clone --depth=1 https://github.com/disintegrating8/dotfiles "$HOME/dotfiles"; then
	    cd "$HOME/dotfiles"
	else
	    printf "%b\n" "${RED}Failed to clone dotfiles${RC}"
	    exit 1
	fi
    fi

    # Process and stow each directory to avoid errors caused by already existing files
    for DIR in "${DIRS[@]}"; do
	printf "%b\n" "${YELLOW}Processing $DIR...${RC}"
	# Find all files in the stow directory
	find "$STOW_DIR/$DIR" -type f | while read -r FILE;do
	    REL_PATH="${FILE#$STOW_DIR/$DIR/}"
	    DEST="$HOME/$REL_PATH"

	    # If a file already exists at destination, back it up
	    if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
		BACKUP_PATH="$BACKUP_DIR/$REL_PATH.backup-$(date +"%m%d_%H%M")"
		printf "%b\n" "${YELLOW}Backing up existing $DEST -> $BACKUP_PATH${RC}"
		# Ensure backup directory exists
		mkdir -p "$(dirname "$BACKUP_PATH")"
		# Move the original file
		mv "$DEST" "$BACKUP_PATH"
	    fi
	done

	# Finally, stow the directory
	printf "%b\n" "${YELLOW}Stowing $DIR...${RC}"
	if stow -d "$STOW_DIR" "$DIR"; then
	    printf "%b\n" "${GREEN}$DIR stowed!${RC}"
	else
	    printf "%b\n" "${RED}Failed to stow $DIR.${RC}"
	    exit 1
	fi
    done
}

checkEnv
install_base
install_fcitx
install_zsh
install_my_packages
stow_dotfiles
