command_exists() {
for cmd in "$@"; do
    export PATH="$HOME/.local/share/flatpak/exports/bin:/var/lib/flatpak/exports/bin:$PATH"
    command -v "$cmd" >/dev/null 2>&1 || return 1
done
return 0
}

checkFlatpak() {
    if ! command_exists flatpak; then
        printf "%b\n" "${YELLOW}Installing Flatpak...${RC}"
	sudo pacman -S --needed --noconfirm flatpak
        printf "%b\n" "${YELLOW}Adding Flathub remote...${RC}"
        sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        printf "%b\n" "${YELLOW}Applications installed by Flatpak may not appear on your desktop until the user session is restarted...${RC}"
    else
        if ! flatpak remotes | grep -q "flathub"; then
            printf "%b\n" "${YELLOW}Adding Flathub remote...${RC}"
            sudo flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
        else
            printf "%b\n" "${CYAN}Flatpak is installed${RC}"
        fi
    fi
}

checkAURHelper() {
    if [ -z "$AUR_HELPER_CHECKED" ]; then
	AUR_HELPERS="yay paru"
	for helper in ${AUR_HELPERS}; do
	    if command_exists "${helper}"; then
		AUR_HELPER=${helper}
		printf "%b\n" "${CYAN}Using ${helper} as AUR helper${RC}"
		AUR_HELPER_CHECKED=true
		return 0
	    fi
	done

	printf "%b\n" "${YELLOW}Installing yay as AUR helper...${RC}"
	sudo pacman -S --needed --noconfirm base-devel git
	cd /opt && sudo git clone https://aur.archlinux.org/yay-bin.git && sudo chown -R "$USER":"$USER" ./yay-bin
	cd yay-bin && makepkg --noconfirm -si

	if command_exists yay; then
	    AUR_HELPER="yay"
	    AUR_HELPER_CHECKED=true
	else
	    printf "%b\n" "${RED}Failed to install AUR helper.${RC}"
	    exit 1
	fi
    fi
}
