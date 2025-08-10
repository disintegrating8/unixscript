#!/bin/bash

. ./check.sh
. ./common-script.sh

setupDWM(){
    printf "%b\n" "${YELLOW}Installing Dependencies for DWM...${RC}"
    yay -S --needed --noconfirm libx11 libxft libxinerama imlib2 
    
    # install dwm
    cd "$HOME" && git clone https://github.com/disintegrating8/suckless.git
    cd "$HOME/suckless/"
    sudo make clean install

    # install sl_status
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

stow_dotfiles() {
    DIRS="qt zsh zprofile rofi nvim kitty fastfetch starship"
    STOW_DIR="$HOME/dotfiles"

    # Ensure stow is installed
    command -v stow &>/dev/null || {
      printf "%b\n" "${YELLOW}Stow not found, installing...${RC}"
      yay -S --needed --noconfirm stow || { printf "%b\n" "${RED}Failed to install Stow${RC}"; exit 1; }
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
    for DIR in $DIRS; do
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

checkEnv
base
pacman_config
stow_dotfiles
setupDWM
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
