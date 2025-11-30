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

install_fcitx(){
    sudo pacman -S --noconfirm fcitx5-im fcitx5-hangul noto-fonts-cjk
    DIRS+=("fcitx")
}

install_my_packages(){
    printf "%b\n" "${YELLOW}Installing personal packages...${RC}"
    yay -S --needed --noconfirm man-pages man-db neovim floorp-bin libreoffice-fresh libreoffice-extension-h2orestart signal-desktop mpv obs-studio gimp
    #yay -S steam prismlauncher gamemode
    #flatpak install -y com.discordapp.Discord com.github.iwalton3.jellyfin-media-player com.vysp3r.ProtonPlus
    DIRS+=("nvim")
}

copy_dotfiles() {
    # Clone or update dotfiles
    if [ -d "$HOME/dotfiles" ]; then
	cd "$HOME/dotfiles" && git stash && git pull
    else
	cd "$HOME"
	if git clone https://github.com/disintegrating8/dotfiles "$HOME/dotfiles"; then
	    printf "%b\n" "${GREEN}Successfully cloned dotfiles${RC}"
	    ln -sf ~/dotfiles/.config/kitty ~/.config/kitty
	    ln -sf ~/dotfiles/.config/nvim ~/.config/nvim
	    ln -sf ~/dotfiles/.config/fastfetch ~/.config/fastfetch
	    ln -sf ~/dotfiles/.zshrc ~/.zshrc
	    ln -sf ~/dotfiles/.zprofile ~/.zprofile
	    ln -sf ~/dotfiles/.alias ~/.alias

	    ln -sf ~/dotfiles/.config/hypr ~/.config/hypr
	    ln -sf ~/dotfiles/.config/waybar ~/.config/waybar
	else
	    printf "%b\n" "${RED}Failed to clone dotfiles${RC}"
	    exit 1
	fi
    fi
}

checkEnv
install_base
install_fcitx
install_zsh
install_my_packages
copy_dotfiles
