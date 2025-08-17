#!/bin/bash

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
    brew install fastfetch starship zsh-autosuggestions zsh-syntax-highlighting
}

install_nvim(){
    brew install neovim ripgrep node
}

# Tiling window manager (more of a resizer) setup for darwin
install_yabai(){
    $tchoice = 1
    DIRS+=("yabai" "skhd" "sketchybar" "borders")
    brew tap FelixKratz/formulae
    brew tap koekeishiya/formulae
    brew install mas ifstat lua jq switchaudio-osx nowplaying-cli 
    brew install yabai skhd sketchybar borders
    brew install --cask sf-symbols font-sf-mono font-sf-pro font-hack-nerd-font font-jetbrains-mono font-fira-code font-meslo-lg-nerd-font
    # Sketchybar Plugins
    curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
    (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
}

install_my_apps(){
    brew install btop
    brew install --cask brave-browser karabiner-elements linearmouse pearcleaner libreoffice iina gimp jellyfin-media-player nextcloud-vfs signal discord
}

stow_dotfiles() {
    STOW_DIR="$HOME/dotfiles"

    # Ensure stow is installed
    command -v stow &>/dev/null || {
      printf "%b\n" "${YELLOW}Stow not found, installing...${RC}"
      brew install stow || { printf "%b\n" "${RED}Failed to install Stow${RC}"; exit 1; }
    }

    # Clone or update dotfiles
    cd "$HOME" || exit 1
    if [ -d dotfiles ]; then
      cd dotfiles && git stash && git pull
    else
      git clone --depth=1 https://github.com/disintegrating8/dotfiles || {
	printf "%b\n" "${RED}Failed to clone dotfiles${RC}"; exit 1;
      }
      cd dotfiles || exit 1
    fi

    # Process and stow each directory
    for DIR in "${DIRS[@]}"; do
      printf "%b\n" "${YELLOW}Processing $DIR...${RC}"
      find "$STOW_DIR/$DIR" -type f | while read -r FILE; do
	REL_PATH="${FILE#$STOW_DIR/$DIR/}"
	DEST="$HOME/$REL_PATH"
	if [ -e "$DEST" ] && [ ! -L "$DEST" ]; then
	  BACKUP="$DEST.backup-$(date +"%m%d_%H%M")"
	  printf "%b\n" "${YELLOW}Backing up $DEST → $BACKUP${RC}"
	  mkdir -p "$(dirname "$BACKUP")"
	  mv "$DEST" "$BACKUP"
	fi
      done
      printf "%b\n" "${YELLOW}Stowing $DIR...${RC}"
      stow "$DIR" && printf "%b\n" "${GREEN}$DIR stowed!${RC}" || { printf "%b\n" "${RED}Failed to stow $DIR.${RC}"; exit 1; }
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
            install_my_apps
            ;;
        *) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}

main
stow_dotfiles
if [[ $tchoice = 1 ]]; then
    yabai --start-service
    skhd --start-service
    brew services start sketchybar
    brew services start borders
fi
