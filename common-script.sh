base(){
    # Packages needed to run this script
    echo -e "\nInstalling ${SKY_BLUE}base-devel${RESET} and ${SKY_BLUE}archlinux-keyring${RESET}..."
    sudo pacman -S --needed --noconfirm base-devel archlinux-keyring findutils curl wget jq unzip python python-requests python-pyquery pacman-contrib

    # Packages for all de/wm
    sudo pacman -S --needed --noconfrim kitty bc imagemagick inxi xdg-user-dirs xdg-utils brightnessctl yad 
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

stow_dotfiles() {
    DIRS="Kvantum qt5ct qt6ct zsh rofi nvim kitty fastfetch starship"
    STOW_DIR="$HOME/dotfiles"

    # Ensure stow is installed
    command -v stow &>/dev/null || {
      echo "Stow not found, installing..."
      sudo pacman -S stow --noconfirm || { echo "Failed to install Stow."; exit 1; }
    }

    # Clone or update dotfiles
    cd "$HOME" || exit 1
    if [ -d dotfiles ]; then
      cd dotfiles && git stash && git pull
    else
      git clone --depth=1 https://github.com/disintegrating8/dotfiles || {
	echo "❌ Failed to clone dotfiles."; exit 1;
      }
      cd dotfiles || exit 1
    fi

    # Process and stow each directory
    for DIR in $DIRS; do
      echo -e "\n🔧 Processing $DIR..."
      find "$STOW_DIR/$DIR" -type f | while read -r FILE; do
	REL_PATH="${FILE#$STOW_DIR/$DIR/}"
	DEST="$HOME/$REL_PATH"
	if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
	  BACKUP="$DEST.backup-$(date +"%m%d_%H%M")"
	  echo "📦 Backing up $DEST → $BACKUP"
	  mkdir -p "$(dirname "$BACKUP")"
	  mv "$DEST" "$BACKUP"
	fi
      done
      echo "📁 Stowing $DIR..."
      stow "$DIR" && echo "✅ $DIR stowed!" || { echo "❌ Failed to stow $DIR."; exit 1; }
    done
}

app_themes() {
    # installing engine needed for gtk themes
    sudo pacman -S --needed --noconfirm unzip gtk-engine-murrine kvantum qt5ct qt6ct qt6-svg lxappearance-gtk3

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
    sudo pacman -S --needed --noconfirm pipewire wireplumber pipewire-audio pipewire-alsa pipewire-pulse sof-firmware pamixer pavucontrol playerctl cava loupe mpv mpv-mpris yt-dlp libspng
    systemctl --user enable --now pipewire.service pipewire.socket pipewire-pulse.socket wireplumber.service
}

install_ibus(){
    sudo pacman -S --needed --noconfirm ibus ibus-hangul noto-fonts-cjk
}

configure_zsh(){
    sudo pacman -S --needed --noconfirm lsd zsh zsh-autosuggestions zsh-syntax-highlighting zsh-completions fzf starship fastfetch
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
