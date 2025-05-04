#!/bin/bash

# Colors for better output readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Arch Linux Customization Software Finder ===${NC}"
echo "This script will check for popular Arch Linux customization software"
echo ""

# Define common directories to search in
SEARCH_DIRS=(
  "/usr/bin"
  "/usr/local/bin"
  "/usr/share"
  "$HOME/.local/bin"
  "$HOME/.local/share"
  "$HOME/.config"
)

# Arrays of software to check for, categorized
WINDOW_MANAGERS_COMPOSITORS=(
  "hyprland" "i3" "sway" "awesome" "bspwm" "dwm" "qtile" "xmonad" 
  "openbox" "fluxbox" "herbstluftwm" "leftwm" "spectrwm" "river"
  "wayfire" "labwc" "weston" "mutter" "kwin" "xfwm4" "picom"
)

BARS_PANELS=(
  "waybar" "polybar" "i3bar" "tint2" "xfce4-panel" "lemonbar" "yambar"
  "eww" "wibar" "swaybar" "wapanel" "plank"
)

NOTIFICATION_DAEMONS=(
  "dunst" "mako" "notify-osd" "xfce4-notifyd" "deadd-notification-center"
  "fnott" "twmn" "qtnotify"
)

LAUNCHERS=(
  "rofi" "dmenu" "wofi" "bemenu" "ulauncher" "albert" "kupfer"
  "lighthouse" "fuzzel" "tofi" "kickoff" "anyrun"
)

TERMINALS=(
  "kitty" "alacritty" "termite" "urxvt" "st" "xterm" "foot" "wezterm"
  "konsole" "gnome-terminal" "xfce4-terminal" "terminology" "sakura"
)

FILE_MANAGERS=(
  "thunar" "pcmanfm" "dolphin" "nemo" "caja" "nautilus" "spacefm"
  "ranger" "vifm" "mc" "lf" "fff" "joshuto" "xplr"
)

SYSTEM_MONITORS=(
  "conky" "htop" "btop" "gotop" "bpytop" "glances" "gkrellm"
)

THEMING_TOOLS=(
  "lxappearance" "qt5ct" "qt6ct" "kvantum" "gtk-chtheme" "wpgtk"
  "pywal" "oomox" "wal" "wpg" "themix"
)

LOCK_SCREENS=(
  "swaylock" "i3lock" "betterlockscreen" "xsecurelock" "light-locker"
  "xscreensaver" "physlock" "slock" "xlock" "gtklock"
)

SESSION_MANAGERS=(
  "wlogout" "sddm" "lightdm" "gdm" "lxdm" "slim" "xdm" "greetd"
  "logout_command.sh" "session-logout"
)

WALLPAPER_TOOLS=(
  "nitrogen" "feh" "variety" "wbg" "swaybg" "swww" "wpaperd" "azote"
  "hyprpaper" "mpvpaper" "xwallpaper" "wallutils"
)

SCREENSHOT_TOOLS=(
  "grim" "slurp" "grimshot" "scrot" "maim" "flameshot" "spectacle"
  "ksnip" "shutter" "swappy" "hyprshot"
)

CLIPBOARD_MANAGERS=(
  "wl-clipboard" "clipman" "xclip" "xsel" "copyq" "clipit" "clipmenu"
  "cliphist" "greenclip"
)

MISC_TOOLS=(
  "picom" "compton" "redshift" "gammastep" "wlsunset" "light" 
  "brightnessctl" "acpilight" "blueman" "networkmanager_dmenu"
  "nm-applet" "udiskie" "polkit-gnome-authentication-agent-1"
  "xdg-desktop-portal" "xdg-desktop-portal-wlr" "xdg-desktop-portal-hyprland"
  "pnmixer" "pasystray" "pavucontrol" "playerctl" "mpd" "ncmpcpp"
  "cava" "spotifyd" "wayvnc" "wf-recorder" "obs-studio" "pamixer"
)

# Configuration frameworks
CONFIG_FRAMEWORKS=(
  "HyDE" "dotfiles" "chezmoi" "yadm" "stow" "rcm" "dotbot" "ansible"
  "dotter" "dotdrop" "homeshick" "fresh" "homesick"
)

# Custom desktop utilities or packages
CUSTOM_PACKAGES=(
  "hyprland-contrib" "dracula-gtk-theme" "dracula-icons" "wal-telegram" 
  "pywalfox" "xob" "eww" "cagebreak" "ags" "dbus-hyprland-environment"
  "hyprland-autoname-workspaces" "hypridle" "hyprpicker" "hyprshot"
)

# Check for pacman packages
echo -e "${YELLOW}Checking pacman packages...${NC}"
INSTALLED_PACKAGES=$(pacman -Q | awk '{print $1}')

# Combine all arrays into one for checking
ALL_SOFTWARE=(
  "${WINDOW_MANAGERS_COMPOSITORS[@]}" 
  "${BARS_PANELS[@]}" 
  "${NOTIFICATION_DAEMONS[@]}" 
  "${LAUNCHERS[@]}" 
  "${TERMINALS[@]}" 
  "${FILE_MANAGERS[@]}" 
  "${SYSTEM_MONITORS[@]}" 
  "${THEMING_TOOLS[@]}" 
  "${LOCK_SCREENS[@]}" 
  "${SESSION_MANAGERS[@]}" 
  "${WALLPAPER_TOOLS[@]}" 
  "${SCREENSHOT_TOOLS[@]}" 
  "${CLIPBOARD_MANAGERS[@]}" 
  "${MISC_TOOLS[@]}"
  "${CONFIG_FRAMEWORKS[@]}"
  "${CUSTOM_PACKAGES[@]}"
)

# Create arrays to store results
FOUND_PACMAN=()
FOUND_FILES=()
FOUND_DIRS=()

# Check for installed pacman packages
for pkg in "${ALL_SOFTWARE[@]}"; do
  if echo "$INSTALLED_PACKAGES" | grep -q "^$pkg"; then
    FOUND_PACMAN+=("$pkg")
  fi
  # Also check for packages that might contain the software name
  if echo "$INSTALLED_PACKAGES" | grep -q "$pkg"; then
    matching_pkgs=$(echo "$INSTALLED_PACKAGES" | grep "$pkg")
    while read -r matching_pkg; do
      if [[ ! " ${FOUND_PACMAN[*]} " =~ " ${matching_pkg} " ]]; then
        FOUND_PACMAN+=("$matching_pkg")
      fi
    done <<< "$matching_pkgs"
  fi
done

# Check for binary files or configuration directories
for pkg in "${ALL_SOFTWARE[@]}"; do
  # Check common binary locations
  for dir in "/usr/bin" "/usr/local/bin" "$HOME/.local/bin"; do
    if [[ -f "$dir/$pkg" ]]; then
      FOUND_FILES+=("$dir/$pkg")
    fi
  done
  
  # Check common config locations
  for dir in "$HOME/.config" "/etc"; do
    if [[ -d "$dir/$pkg" ]]; then
      FOUND_DIRS+=("$dir/$pkg")
    fi
  done
done

# Output the results
echo -e "\n${GREEN}=== Found Customization Software ===${NC}"

echo -e "${YELLOW}Installed Packages:${NC}"
if [ ${#FOUND_PACMAN[@]} -eq 0 ]; then
  echo "None found through pacman"
else
  for pkg in "${FOUND_PACMAN[@]}"; do
    echo "- $pkg"
  done
fi

echo -e "\n${YELLOW}Found Executable Files:${NC}"
if [ ${#FOUND_FILES[@]} -eq 0 ]; then
  echo "None found"
else
  for file in "${FOUND_FILES[@]}"; do
    echo "- $file"
  done
fi

echo -e "\n${YELLOW}Found Configuration Directories:${NC}"
if [ ${#FOUND_DIRS[@]} -eq 0 ]; then
  echo "None found"
else
  for dir in "${FOUND_DIRS[@]}"; do
    echo "- $dir"
  done
fi

# Additional search for any running processes related to customization
echo -e "\n${YELLOW}Currently Running Related Processes:${NC}"
for pkg in "${ALL_SOFTWARE[@]}"; do
  if pgrep -f "$pkg" > /dev/null; then
    echo "- $pkg"
  fi
done

# Output the found software by category
echo -e "\n${GREEN}=== Software by Category ===${NC}"

check_category() {
  local category=("$@")
  local found=false
  echo -e "${YELLOW}${category[0]}:${NC}"
  for pkg in "${category[@]:1}"; do
    if echo "${FOUND_PACMAN[*]}" | grep -q "$pkg" || echo "${FOUND_FILES[*]}" | grep -q "/$pkg$" || echo "${FOUND_DIRS[*]}" | grep -q "/$pkg$" || pgrep -f "$pkg" > /dev/null; then
      echo "- $pkg"
      found=true
    fi
  done
  if ! $found; then
    echo "None found"
  fi
  echo ""
}

check_category "Window Managers/Compositors" "${WINDOW_MANAGERS_COMPOSITORS[@]}"
check_category "Status Bars/Panels" "${BARS_PANELS[@]}"
check_category "Notification Daemons" "${NOTIFICATION_DAEMONS[@]}"
check_category "Application Launchers" "${LAUNCHERS[@]}"
check_category "Terminals" "${TERMINALS[@]}"
check_category "File Managers" "${FILE_MANAGERS[@]}"
check_category "System Monitors" "${SYSTEM_MONITORS[@]}"
check_category "Theming Tools" "${THEMING_TOOLS[@]}"
check_category "Lock Screens" "${LOCK_SCREENS[@]}"
check_category "Session Managers" "${SESSION_MANAGERS[@]}"
check_category "Wallpaper Tools" "${WALLPAPER_TOOLS[@]}"
check_category "Screenshot Tools" "${SCREENSHOT_TOOLS[@]}"
check_category "Clipboard Managers" "${CLIPBOARD_MANAGERS[@]}"
check_category "Miscellaneous Tools" "${MISC_TOOLS[@]}"
check_category "Configuration Frameworks" "${CONFIG_FRAMEWORKS[@]}"

# Check for Git repositories that might be related to customization
echo -e "${YELLOW}Searching for Git repositories in home directory that might be related to customization...${NC}"
find "$HOME" -name ".git" -type d -exec sh -c 'if [ -f "{}/../README.md" ]; then grep -l "dotfiles\|config\|rice\|theme\|customize\|hyprland\|wayland" "{}/../README.md" 2>/dev/null; fi' \; | sed 's/\/.git\/\.\.\/README.md//'

echo -e "\n${BLUE}=== Recommended Next Steps ===${NC}"
echo "1. Run this script with 'bash scriptname.sh > my_setup.txt' to save the output"
echo "2. Examine the output to confirm all your customization tools are listed"
echo "3. Use this information when creating your prompt for the LLM"

# Add a message about possible missing software
echo -e "\n${RED}Note:${NC} Some custom or unofficial software might not be detected."
echo "If you're using software not listed above, make sure to include it in your prompt."
