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
    brew install ifstat lua jq switchaudio-osx nowplaying-cli 
    brew install yabai skhd sketchybar borders
    brew install --cask sf-symbols font-sf-mono font-sf-pro font-hack-nerd-font font-jetbrains-mono font-fira-code font-meslo-lg-nerd-font
    brew install --cask font-sketchybar-app-font
    # Add icon_map.sh file
    #curl -L https://github.com/kvndrsslr/sketchybar-app-font/releases/download/v2.0.32/icon_map.sh -o $HOME/.config/sketchybar/icon_map.sh
    # SbarLua
    #(git clone https://github.com/FelixKratz/SbarLua.git /tmp/SbarLua && cd /tmp/SbarLua/ && make install && rm -rf /tmp/SbarLua/)
    echo "$(whoami) ALL=(root) NOPASSWD: sha256:$(shasum -a 256 $(which yabai) | cut -d " " -f 1) $(which yabai) --load-sa" | sudo tee /private/etc/sudoers.d/yabai
}

install_my_apps(){
    brew install btop
    brew install --cask karabiner-elements linearmouse pearcleaner libreoffice iina gimp jellyfin-media-player nextcloud-vfs signal discord github
    brew install librewolf --no-quarantine
    brew install mas
    mas install 1451685025 #Wireguard
    # School Shit
    mas install 1645016851 #Bluebook
    mas install 1496582158 #Exam.net
    mas install 6450684725 #NWEA
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

removeAnimations() {
    printf "%b\n" "${YELLOW}Reducing motion and animations on macOS...${RC}"
    
    # Reduce motion in Accessibility settings (most effective)
    printf "%b\n" "${CYAN}Setting reduce motion preference...${RC}"
    defaults write com.apple.universalaccess reduceMotion -bool true
    
    # Disable window animations
    printf "%b\n" "${CYAN}Disabling window animations...${RC}"
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    
    # Speed up window resize animations
    printf "%b\n" "${CYAN}Speeding up window resize animations...${RC}"
    defaults write NSGlobalDomain NSWindowResizeTime -float 0.001
    
    # Disable smooth scrolling
    printf "%b\n" "${CYAN}Disabling smooth scrolling...${RC}"
    defaults write NSGlobalDomain NSScrollAnimationEnabled -bool false
    
    # Disable animation when opening and closing windows
    printf "%b\n" "${CYAN}Disabling window open/close animations...${RC}"
    defaults write NSGlobalDomain NSAutomaticWindowAnimationsEnabled -bool false
    
    # Disable animation when opening a Quick Look window
    printf "%b\n" "${CYAN}Disabling Quick Look animations...${RC}"
    defaults write -g QLPanelAnimationDuration -float 0
    
    # Disable animation when opening the Info window in Finder
    printf "%b\n" "${CYAN}Disabling Finder Info window animations...${RC}"
    defaults write com.apple.finder DisableAllAnimations -bool true
    
    # Speed up Mission Control animations
    printf "%b\n" "${CYAN}Speeding up Mission Control animations...${RC}"
    defaults write com.apple.dock expose-animation-duration -float 0.1
    defaults write com.apple.dock expose-group-apps -bool true

    # Speed up Launchpad animations
    printf "%b\n" "${CYAN}Speeding up Launchpad animations...${RC}"
    defaults write com.apple.dock springboard-show-duration -float 0.1
    defaults write com.apple.dock springboard-hide-duration -float 0.1
    
    # Disable dock hiding animation
    printf "%b\n" "${CYAN}Disabling dock hiding animations...${RC}"
    defaults write com.apple.dock autohide-time-modifier -float 0
    defaults write com.apple.dock autohide-delay -float 0
    
    # Disable animations in Mail.app
    printf "%b\n" "${CYAN}Disabling Mail animations...${RC}"
    defaults write com.apple.mail DisableReplyAnimations -bool true
    defaults write com.apple.mail DisableSendAnimations -bool true
    
    # Disable zoom animation when focusing on text input fields
    printf "%b\n" "${CYAN}Disabling text field zoom animations...${RC}"
    defaults write NSGlobalDomain NSTextShowsControlCharacters -bool true
    
    printf "%b\n" "${GREEN}Motion and animations have been reduced.${RC}"
    killall Dock
    printf "%b\n" "${YELLOW}Dock Restarted.${RC}"
}

fixfinder () {
    printf "%b\n" "${YELLOW}Applying global theme settings for Finder...${RC}"

    # Set the default Finder view to list view
    printf "%b\n" "${CYAN}Setting default Finder view to list view...${RC}"
    defaults write com.apple.finder FXPreferredViewStyle -string "Nlsv"
    
    # Configure list view settings for all folders
    printf "%b\n" "${CYAN}Configuring list view settings for all folders...${RC}"
    # Set default list view settings for new folders
    defaults write com.apple.finder FK_StandardViewSettings -dict-add ListViewSettings '{ "columns" = ( { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 300; }, { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; }, { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 97; } ); "iconSize" = 16; "showIconPreview" = 0; "sortColumn" = "name"; "textSize" = 13; "useRelativeDates" = 1; }'
    
    # Clear existing folder view settings to force use of default settings
    printf "%b\n" "${CYAN}Clearing existing folder view settings...${RC}"
    defaults delete com.apple.finder FXInfoPanesExpanded 2>/dev/null || true
    defaults delete com.apple.finder FXDesktopVolumePositions 2>/dev/null || true
    
    # Set list view for all view types
    printf "%b\n" "${CYAN}Setting list view for all folder types...${RC}"
    defaults write com.apple.finder FK_StandardViewSettings -dict-add ExtendedListViewSettings '{ "columns" = ( { "ascending" = 1; "identifier" = "name"; "visible" = 1; "width" = 300; }, { "ascending" = 0; "identifier" = "dateModified"; "visible" = 1; "width" = 181; }, { "ascending" = 0; "identifier" = "size"; "visible" = 1; "width" = 97; } ); "iconSize" = 16; "showIconPreview" = 0; "sortColumn" = "name"; "textSize" = 13; "useRelativeDates" = 1; }'
    
    # Sets default search scope to the current folder
    printf "%b\n" "${CYAN}Setting default search scope to the current folder...${RC}"
    defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

    # Remove trash items older than 30 days
    printf "%b\n" "${CYAN}Removing trash items older than 30 days...${RC}"
    defaults write com.apple.finder "FXRemoveOldTrashItems" -bool "true"

    # Remove .DS_Store files to reset folder view settings
    printf "%b\n" "${CYAN}Removing .DS_Store files to reset folder view settings...${RC}"
    find ~ -name ".DS_Store" -type f -delete 2>/dev/null || true

    # Show all filename extensions
    printf "%b\n" "${CYAN}Showing all filename extensions in Finder...${RC}"
    defaults write NSGlobalDomain AppleShowAllExtensions -bool true

    # Set the sidebar icon size to small
    printf "%b\n" "${CYAN}Setting sidebar icon size to small...${RC}"
    defaults write NSGlobalDomain NSTableViewDefaultSizeMode -int 1

    # Show status bar in Finder
    printf "%b\n" "${CYAN}Showing status bar in Finder...${RC}"
    defaults write com.apple.finder ShowStatusBar -bool true

    # Show path bar in Finder
    printf "%b\n" "${CYAN}Showing path bar in Finder...${RC}"
    defaults write com.apple.finder ShowPathbar -bool true

    # Clean up Finder's sidebar
    printf "%b\n" "${CYAN}Cleaning up Finder's sidebar...${RC}"
    defaults write com.apple.finder SidebarDevicesSectionDisclosedState -bool true
    defaults write com.apple.finder SidebarPlacesSectionDisclosedState -bool true
    defaults write com.apple.finder SidebarShowingiCloudDesktop -bool false

    # Restart Finder to apply changes
    printf "%b\n" "${GREEN}Finder has been restarted and settings have been applied.${RC}"
    killall Finder
}

my_defaults(){
    defaults write com.apple.dock "orientation" -string "left"
    defaults write com.apple.dock "autohide" -bool "true" # Autohide dock
    defaults write com.apple.dock "show-recents" -bool "false"
    defaults write com.apple.Accessibility "ReduceMotionEnabled" -bool "true"
    # Change screenshot location
    defaults write com.apple.screencapture "location" -string "~/Pictures" && killall SystemUIServer
    # Fix Missions control to NEVER rearrange spaces
    printf "%b\n" "${CYAN}Fixing Mission Control to never rearrange spaces...${RC}"
    defaults write com.apple.dock mru-spaces -bool false

    # Apple Intelligence Crap
    defaults write com.apple.CloudSubscriptionFeatures.optIn "545129924" -bool "false"
}

main() {
    printf "%b\n" "${YELLOW}Choose what to install:${RC}"
    printf "%b\n" "1. ${YELLOW}homebrew${RC}"
    printf "%b\n" "2. ${YELLOW}zsh${RC}"
    printf "%b\n" "3. ${YELLOW}neovim${RC}"
    printf "%b\n" "4. ${YELLOW}yabai, skhd, sketchybar, jankyborders${RC}"
    printf "%b\n" "5. ${YELLOW}my apps & settings${RC}"
    printf "%b\n" "6. ${YELLOW}All${RC}"
    printf "%b" "Enter your choice [1-6]: "
    read -r CHOICE
    case "$CHOICE" in
	1) install_homebrew ;;
	2) 
	    install_zsh
	    stow_dotfiles
	    ;;
	3) 
	    install_nvim
	    stow_dotfiles
	    ;;
	4) 
	    install_yabai
	    stow_dotfiles
	    ;;
	5) 
	    removeAnimations
	    fixfinder
	    my_defaults
	    install_my_apps
	    ;;
	6)
	    install_homebrew
	    install_zsh
	    install_nvim
	    install_yabai
	    stow_dotfiles
	    ;;
	*) printf "%b\n" "${RED}Invalid choice.${RC}" && exit 1 ;;
    esac
}
main
if [[ $tchoice = 1 ]]; then
    yabai --start-service
    skhd --start-service
    brew services start felixkratz/formulae/sketchybar
    brew services start felixkratz/formulae/borders
fi
