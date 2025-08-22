#!/usr/bin/env bash

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'

DIRS=()

install_homebrew(){
    if command -v brew >/dev/null 2>&1; then
	printf "%b\n" "${CYAN}Homebrew already installed${RC}"
    else
	printf "%b\n" "${YELLOW}Installing Homebrew...${RC}"
	/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

	# Add Homebrew to Path
	if [[ $(uname -m) == "arm64" ]]; then
	    echo >> $HOME/.zprofile
	    echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> $HOME/.zprofile
	    eval "$(/opt/homebrew/bin/brew shellenv)"
	else
	    echo >> $HOME/.zprofile
	    echo 'eval "$(/usr/local/bin/brew shellenv)"' >> $HOME/.zprofile
	    eval "$(/usr/local/bin/brew shellenv)"
	fi

	if command -v brew >/dev/null 2>&1; then
	    printf "%b\n" "${CYAN}Homebrew installed successfully${RC}"
	    printf "%b\n" "${YELLOW}Updating Homebrew...${RC}"
	    brew update && brew upgrade -g
	    brew install wget
	else
	    printf "%b\n" "${RED}Failed to install Homebrew.${RC}"
	    exit 1
	fi
    fi
}

install_zsh(){
    DIRS+=("zsh.mac" "kitty" "starship" "fastfetch")
    brew install --cask kitty
    brew install fastfetch starship zsh-autosuggestions zsh-syntax-highlighting trash-cli
}

install_nvim(){
    DIRS+=("nvim")
    brew install neovim ripgrep node
}

# Tiling window manager (more of a resizer) setup for darwin
install_yabai(){
    DIRS+=("yabai" "skhd" "sketchybar" "borders")
    tchoice=1
    brew tap FelixKratz/formulae
    brew tap koekeishiya/formulae
    brew install mas ifstat lua jq switchaudio-osx nowplaying-cli 
    brew install yabai skhd sketchybar borders
    brew install --cask sf-symbols font-sf-mono font-sf-pro font-hack-nerd-font font-jetbrains-mono font-fira-code font-meslo-lg-nerd-font
    brew install --cask font-sketchybar-app-font
}

install_my_apps(){
    brew install btop
    brew install --cask brave-browser karabiner-elements linearmouse pearcleaner libreoffice iina gimp jellyfin-media-player nextcloud-vfs signal discord
}

stow_dotfiles(){
    STOW_DIR="$HOME/dotfiles"
    BACKUP_DIR="$HOME/unixscript/backups"

    # Ensure stow is installed
    if ! command -v stow &>/dev/null; then
	printf "%b\n" "${YELLOW}Stow not found, installing...${RC}"
	if ! brew install stow; then
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
    printf "%b\n" "1. ${YELLOW}homebrew${RC}"
    printf "%b\n" "2. ${YELLOW}zsh${RC}"
    printf "%b\n" "3. ${YELLOW}neovim${RC}"
    printf "%b\n" "4. ${YELLOW}yabai, skhd, sketchybar, jankyborders${RC}"
    printf "%b\n" "5. ${YELLOW}my_apps${RC}"
    printf "%b\n" "6. ${YELLOW}All${RC}"
    printf "%b" "Enter your choice [1-6]: "
    read -r CHOICE
    case "$CHOICE" in
	1) install_homebrew ;;
	2) install_zsh ;;
	3) install_nvim ;;
	4) install_yabai ;;
	5) install_my_apps ;;
	6)
	    install_homebrew
	    install_zsh
	    install_nvim
	    install_yabai
	    ;;
	*) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}
main
stow_dotfiles
if [[ $tchoice = 1 ]]; then
    yabai --start-service
    skhd --start-service
    brew services start felixkratz/formulae/sketchybar
    brew services start felixkratz/formulae/borders
fi
