#!/bin/bash

RC='\033[0m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
GREEN='\033[32m'


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

checkArch() {
    case "$(uname -m)" in
        x86_64 | amd64) ARCH="x86_64" ;;
        aarch64 | arm64) ARCH="aarch64" ;;
        *) printf "%b\n" "${RED}Unsupported architecture: $(uname -m)${RC}" && exit 1 ;;
    esac

    printf "%b\n" "${CYAN}System architecture: ${ARCH}${RC}"
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

checkCommandRequirements() {
    REQUIREMENTS=$1
    for req in ${REQUIREMENTS}; do
	if ! command_exists "${req}"; then
	    printf "%b\n" "${RED}To run me, you need: ${REQUIREMENTS}${RC}"
	    exit 1
	fi
    done
}

checkSuperUser() {
    SUPERUSERGROUP='wheel sudo root'
    for sug in ${SUPERUSERGROUP}; do
        if groups | grep -q "${sug}"; then
            SUGROUP=${sug}
            printf "%b\n" "${CYAN}Super user group ${SUGROUP}${RC}"
            break
        fi
    done

    ## Check if member of the sudo group.
    if ! groups | grep -q "${SUGROUP}"; then
        printf "%b\n" "${RED}You need to be a member of the sudo group to run me!${RC}"
        exit 1
    fi
}

checkCurrentDirectoryWritable() {
    GITPATH="$(dirname "$(realpath "$0")")"
    if [ ! -w "$GITPATH" ]; then
        printf "%b\n" "${RED}Can't write to $GITPATH${RC}"
        exit 1
    fi
}

checkEnv() {
    checkArch
    checkCommandRequirements "curl groups sudo"
    checkCurrentDirectoryWritable
    checkSuperUser
    checkAURHelper
}
