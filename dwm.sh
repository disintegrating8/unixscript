#!/bin/bash

. ./check.sh

base(){
    yay -S --needed --noconfirm base-devel archlinux-keyring mate-polkit
    yay -S --needed --noconfirm curl wget jq unzip zip findutils pacman-contrib
    # essential dwm dependencies
    yay -S --needed --noconfirm libx11 libxft libxinerama imlib2 
    # extra xorg stuff
    yay -S --needed --noconfirm xclip xscreensaver xorg-xinit xorg-server xorg-xrandr xorg-xinput xorg-xprop
    # xdg stuff
    yay -S --needed --noconfirm xdg-utils xdg-user-dirs xdg-desktop-portal-gtk
    # utilies
    yay -S --needed --noconfirm picom rofi imagemagick brightnessctl flameshot feh dunst rofi kitty man-db man-pages
}

makeDWM(){
    # make dwm
    cd "$HOME" && git clone https://github.com/disintegrating8/suckless.git
    cd "$HOME/suckless/"
    sudo make clean install

    # make sl_status
    printf "%b\n" "${YELLOW}Installing slstatus${RC}"
    cd "$HOME/suckless/slstatus" || {
      printf "%b\n" "${RED}Failed to change directory to slstatus${RC}"
      exit 1
    }
    if sudo make clean install; then
      printf "%b\n" "${GREEN}slstatus installed successfully${RC}"
    else
      printf "%b\n" "${RED}Failed to install slstatus${RC}"
      exit 1
    fi
    cd "$HOME"
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
    yay -S --needed --noconfirm gtk-engine-murrine kvantum qt5ct qt6ct qt6-svg nwg-look

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
    yay -S --needed --noconfirm lsd zsh zsh-autosuggestions zsh-syntax-highlighting fzf starship fastfetch trash-cli

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

configure_nemo(){
    # file system related stuff
    yay -S --needed --noconfirm ntfs-3g
    printf "%b\n" "${YELLOW}Installing Nemo Packages...${RC}"  
    yay -S --needed --noconfirm nemo nemo-seahorse nemo-share nemo-fileroller nemo-pastebin nemo-compare nemo-preview nemo-image-converter nemo-audio-tab gvfs gvfs-mtp gvfs-smb gvfs-nfs
    printf "%b\n" "${YELLOW}Setting Nemo as default file manager...${RC}"
    xdg-mime default nemo.desktop inode/directory application/x-gnome-saved-search
    gsettings set org.nemo.desktop show-desktop-icons true
    gsettings set org.cinnamon.desktop.default-applications.terminal exec kitty
    printf "%b\n" "${GREEN}Nemo is now set as the default file manager${RC}"
}

personal_packages(){
    printf "%b\n" "${YELLOW}Installing personal packages...${RC}"
    yay -S --needed --noconfirm btop timeshift neovim github-desktop-bin brave-bin libreoffice-fresh signal-desktop mpv obs-studio gimp prismlauncher gamemode
    yay -S steam
    flatpak install -y com.discordapp.Discord com.github.iwalton3.jellyfin-media-player com.vysp3r.ProtonPlus
}

stow_dotfiles() {
    DIRS=("theme" "zsh" "rofi" "nvim" "kitty" "fastfetch" "starship")
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
base
pacman_config
stow_dotfiles
makeDWM
pipewire
install_fonts
app_themes
configure_backgrounds
configure_zsh
install_ibus
configure_nemo
read -n1 -rep "Install personal packages? [y/n] " choice
if [[ $choice =~ ^[Yy]$ ]]; then
    personal_packages
fi
