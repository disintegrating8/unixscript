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
