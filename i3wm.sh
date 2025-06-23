#!/bin/bash

printf "\n%s - Installing ${SKY_BLUE}necessary packages${RESET} .... \n" "${NOTE}"

sudo pacman -S --needed --noconfirm i3-wm i3blocks i3lock i3status sxhkd xclip polybar rofi picom flameshot feh dunst mate-polkit betterlockscreen
