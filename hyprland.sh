#!/bin/bash
. ./check.sh
DIRS=()

install_fcitx(){
    sudo pacman -S --noconfirm fcitx5-im fcitx5-hangul noto-fonts-cjk
    DIRS+=("fcitx")
}

install_zsh(){
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
    DIRS+=("zsh")
}

install_my_packages(){
    printf "%b\n" "${YELLOW}Installing personal packages...${RC}"
    yay -S --needed --noconfirm timeshift neovim github-desktop-bin brave-bin libreoffice-fresh signal-desktop mpv obs-studio gimp prismlauncher gamemode
    yay -S steam
    flatpak install -y com.discordapp.Discord com.github.iwalton3.jellyfin-media-player com.vysp3r.ProtonPlus
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

main() {
    printf "%b\n" "${YELLOW}Choose what to install:${RC}"
    printf "%b\n" "1. ${YELLOW}flatpak (hangul)${RC}"
    printf "%b\n" "2. ${YELLOW}fcitx5 (hangul)${RC}"
    printf "%b\n" "3. ${YELLOW}zsh${RC}"
    printf "%b\n" "4. ${YELLOW}my packages${RC}"
    printf "%b\n" "5. ${YELLOW}All (execpt my packages)${RC}"
    printf "%b" "Enter your choice [1-5]: "
    read -r CHOICE
    case "$CHOICE" in
	1) checkFlatpak ;;
	2) 
	    install_fcitx
	    stow_dotfiles
	    ;;
	3)
	    install_zsh
	    stow_dotfiles
	    ;;
	4) install_my_packages ;;
	5)
	    checkFlatpak
	    install_fcitx
	    install_zsh
	    ;;
	*) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}
main
