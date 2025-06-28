#!/bin/bash

. ./check.sh
. ./common-script.sh

setupDWM(){
    sudo pacman -S libx11 libxinerama libxft imlib2 unzip xclip rofi picom flameshot feh dunst mate-polkit
    
    # install dwm
    cd "$HOME" && git clone https://github.com/disintegrating8/suckless.git
    cd "$HOME/suckless/"
    sudo make clean install

    # install sl_status
    cd "$HOME/suckless/slstatus" || {
      echo "Failed to change directory to slstatus"
      exit 1
    }
    if sudo make clean install; then
      echo "slstatus installed successfully"
    else
      echo "Failed to install slstaus"
      exit 1
    fi
    cd "$HOME"
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

checkEnv
base
stow_dotfiles
setupDWM
pipewire
install_fonts
app_themes
configure_backgrounds
configure_zsh
setupDisplayManager
install_ibus
configure_thunar
checkFlatpak
