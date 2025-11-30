#!/bin/bash
. ../check.sh

printf "%b\n" "${YELLOW}Installing zsh packages${RC}"
sudo pacman -S --needed --noconfirm zsh zsh-autosuggestions zsh-syntax-highlighting fzf fastfetch trash-cli

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
