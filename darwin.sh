#!/bin/bash

stow_dotfiles() {
    DIRS=()
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


# Update & upgrade Homebrew
echo "Updating Homebrew..."
brew update && brew upgrade

## Taps
echo "Tapping Brew..."
brew tap FelixKratz/formulae
brew tap koekeishiya/formulae

brew install wget

#ZSH
read -n1 -rep "Do you want to config zsh? [y/n] " choice
if [[ $choice =~ ^[Yy]$ ]]; then
    echo "Configuring zsh"
    DIRS+=("zsh.mac kitty nvim starship")
    brew install --cask kitty
    brew install neovim ripgrep node fastfetch starship zsh-autosuggestions zsh-syntax-highlighting
else
    echo "skipping"
fi

# Tiling window manager setup for darwin
read -n1 -rep "Do you want to config tiling setup? [y/n] " tchoice
if [[ $tchoice =~ ^[Yy]$ ]]; then
    echo "Configuring yabai, sketchybar, jankeyborders"
    DIRS+=("yabai" "skhd" "sketchybar" "borders")

    echo "Installing dependencies for sketchybar config"
    brew install mas ifstat lua jq switchaudio-osx nowplaying-cli 

    brew install yabai skhd sketchybar borders

    echo "Installing fonts"
    brew install --cask sf-symbols font-sf-mono font-sf-pro font-hack-nerd-font font-jetbrains-mono font-fira-code font-meslo-lg-nerd-font

    # Sketchybar Plugins
    curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.28/sketchybar-app-font.ttf -o $HOME/Library/Fonts/sketchybar-app-font.ttf
    (git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)

else
    echo "skipping"
fi

#personal apps
read -n1 -rep "Do you want to config tiling setup? [y/n] " choice
if [[ $choice =~ ^[Yy]$ ]]; then
    brew install btop lazygit
    brew install --cask brave-browser karabiner-elements linearmouse pearcleaner libreoffice iina gimp jellyfin-media-player
else
    echo "skipping"
fi



# Run dotfiles-setup
echo "Installing dotfiles"
. dotfiles-setup.sh

if [[ $tchoice =~ ^[Yy]$ ]]; then
    yabai --start-service
    skhd --start-service
    brew services start sketchybar
    brew services start borders

echo "Setup complete!"
