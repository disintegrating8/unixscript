#!/bin/bash
. ../check.sh

printf "%b\n" "${YELLOW}Adding Extra Spice in pacman.conf...${RC}"
pacman_conf="/etc/pacman.conf"

# Remove comments '#' from specific lines
lines_to_edit=(
    "Color"
    "CheckSpace"
    "VerbosePkgLists"
    "ParallelDownloads"
)

# Uncomment specified lines if they are commented out
for line in "${lines_to_edit[@]}"; do
    if grep -q "^#$line" "$pacman_conf"; then
	sudo sed -i "s/^#$line/$line/" "$pacman_conf"
	printf "%b\n" "${GREEN}Uncommented: $line${RC}"
    else
	printf "%b\n" "${GREEN}$line is already uncommented${RC}"
    fi
done

# Add "ILoveCandy" below ParallelDownloads if it doesn't exist
if grep -q "^ParallelDownloads" "$pacman_conf" && ! grep -q "^ILoveCandy" "$pacman_conf"; then
    sudo sed -i "/^ParallelDownloads/a ILoveCandy" "$pacman_conf"
    printf "%b\n" "${GREEN}Added ${CYAN}ILoveCandy${RC} after ${CYAN}ParallelDownloads${RC}"
else
    printf "%b\n" "${YELLOW}It seems ${CYAN}ILoveCandy${RC} already exists moving on...${RC}"
fi

printf "%b\n" "${GREEN}Pacman.conf spicing up completed${RC}"

# updating pacman.conf
printf "%b\n" "${CYAN}Synchronizing Pacman Repo${RC}"
sudo pacman -Sy
