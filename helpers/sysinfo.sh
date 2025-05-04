#!/bin/bash

# Arch Linux System Information Collector
# This script gathers comprehensive system information for customization assistance

# Colors for better output readability
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Create output directory
OUTPUT_DIR="$HOME/arch_system_info"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="$OUTPUT_DIR/system_info.txt"

# Function to print section headers
print_header() {
    echo -e "\n${BLUE}=== $1 ===${NC}" | tee -a "$OUTPUT_FILE"
}

# Function to run a command and save its output
run_cmd() {
    local cmd="$1"
    local label="$2"
    
    echo -e "${YELLOW}$label:${NC}" | tee -a "$OUTPUT_FILE"
    eval "$cmd" 2>/dev/null | tee -a "$OUTPUT_FILE" || echo -e "${RED}Command failed: $cmd${NC}" | tee -a "$OUTPUT_FILE"
    echo "" | tee -a "$OUTPUT_FILE"
}

# Function to copy a config file if it exists
copy_config() {
    local src="$1"
    local dest="$OUTPUT_DIR/configs/$(basename "$src")"
    
    if [[ -f "$src" ]]; then
        mkdir -p "$(dirname "$dest")"
        cp "$src" "$dest" && echo "Config copied: $src -> $dest" | tee -a "$OUTPUT_FILE"
    elif [[ -d "$src" ]]; then
        mkdir -p "$dest"
        cp -r "$src"/* "$dest" 2>/dev/null && echo "Config dir copied: $src -> $dest" | tee -a "$OUTPUT_FILE"
    else
        echo "Config not found: $src" | tee -a "$OUTPUT_FILE"
    fi
}

# Start collecting information
echo -e "${GREEN}Collecting system information...${NC}"
echo "Arch Linux System Information - Generated on $(date)" > "$OUTPUT_FILE"
echo "=================================================" >> "$OUTPUT_FILE"

# Basic system information
print_header "SYSTEM INFORMATION"
run_cmd "hostnamectl" "Hostname and OS information"
run_cmd "uname -a" "Kernel information"
run_cmd "cat /etc/os-release" "OS release information"
run_cmd "uptime" "System uptime"

# Hardware information
print_header "HARDWARE INFORMATION"
run_cmd "lscpu" "CPU Information"
run_cmd "free -h" "Memory Information"
run_cmd "lspci | grep -i 'vga\|3d\|2d'" "Graphics Card"
run_cmd "lsblk -f" "Storage Information"
run_cmd "cat /proc/acpi/button/lid/*/state 2>/dev/null || echo 'No lid detected'" "Laptop Lid Status"
run_cmd "ls -la /dev/input/by-id/" "Input Devices"

# Display and monitor information
print_header "DISPLAY INFORMATION"
run_cmd "xrandr 2>/dev/null || echo 'xrandr not available (Wayland?)'" "Monitor setup (X11)"
run_cmd "wlr-randr 2>/dev/null || echo 'wlr-randr not available'" "Monitor setup (Wayland-wlroots)"
run_cmd "test -n \"$WAYLAND_DISPLAY\" && echo 'Running Wayland session' || echo 'Not running Wayland session'" "Wayland Status"

# Session information
print_header "SESSION INFORMATION"
run_cmd "echo \$XDG_SESSION_TYPE" "Session Type"
run_cmd "echo \$XDG_CURRENT_DESKTOP" "Current Desktop"
run_cmd "echo \$DESKTOP_SESSION" "Desktop Session"
run_cmd "env | grep -i 'wayland\|x11\|session\|desktop'" "Session Environment Variables"
run_cmd "systemctl --user list-units --state=running" "User Services Running"

# Package information
print_header "PACKAGE INFORMATION"
run_cmd "pacman -Q | grep -i 'theme\|icon\|cursor\|font'" "Theme-related Packages"
run_cmd "pacman -Qe | wc -l" "Explicitly Installed Package Count"
run_cmd "pacman -Qm | wc -l" "Foreign (AUR, etc.) Package Count"
run_cmd "pacman -Qg" "Package Groups"
run_cmd "pacman -Qe | grep -i 'wayland\|compositor\|wm'" "Window Manager/Compositor Packages"

# Theme and appearance
print_header "THEME INFORMATION"
run_cmd "gsettings list-recursively org.gnome.desktop.interface 2>/dev/null || echo 'gsettings not available'" "GTK Theme Settings"
run_cmd "test -f ~/.config/gtk-3.0/settings.ini && cat ~/.config/gtk-3.0/settings.ini" "GTK3 Settings"
run_cmd "test -f ~/.config/gtk-4.0/settings.ini && cat ~/.config/gtk-4.0/settings.ini" "GTK4 Settings"
run_cmd "ls -la ~/.themes 2>/dev/null || echo 'No ~/.themes directory'" "User Themes"
run_cmd "ls -la ~/.icons 2>/dev/null || echo 'No ~/.icons directory'" "User Icons"
run_cmd "fc-list | grep -i 'medium\|regular' | sort | uniq" "Installed Fonts"
run_cmd "test -f ~/.config/fontconfig/fonts.conf && cat ~/.config/fontconfig/fonts.conf" "Font Configuration"

# Window manager / Compositor configuration
print_header "WINDOW MANAGER CONFIGURATION"
run_cmd "test -f ~/.config/hypr/hyprland.conf && grep -v '^#' ~/.config/hypr/hyprland.conf | grep -v '^$'" "Hyprland Configuration (uncommented lines)"
run_cmd "test -f ~/.config/i3/config && grep -v '^#' ~/.config/i3/config | grep -v '^$'" "i3 Configuration (uncommented lines)"
run_cmd "test -f ~/.config/sway/config && grep -v '^#' ~/.config/sway/config | grep -v '^$'" "Sway Configuration (uncommented lines)"

# Core desktop components
print_header "DESKTOP COMPONENTS"
run_cmd "test -d ~/.config/waybar && find ~/.config/waybar -type f -name '*.json' | xargs grep -v '^$'" "Waybar JSON Configuration"
run_cmd "test -d ~/.config/waybar && find ~/.config/waybar -type f -name '*.css' | xargs cat" "Waybar CSS Configuration"
run_cmd "test -f ~/.config/dunst/dunstrc && grep -v '^#' ~/.config/dunst/dunstrc | grep -v '^$'" "Dunst Configuration"
run_cmd "test -f ~/.config/mako/config && cat ~/.config/mako/config" "Mako Configuration"
run_cmd "ls -la ~/.config/rofi 2>/dev/null || echo 'No Rofi config directory'" "Rofi Configuration Files"

# Terminal and shell
print_header "TERMINAL AND SHELL CONFIGURATION"
run_cmd "echo \$SHELL" "Current Shell"
run_cmd "test -f ~/.bashrc && grep -v '^#' ~/.bashrc | grep -v '^$'" "Bash Configuration"
run_cmd "test -f ~/.zshrc && grep -v '^#' ~/.zshrc | grep -v '^$'" "Zsh Configuration"
run_cmd "test -f ~/.config/fish/config.fish && grep -v '^#' ~/.config/fish/config.fish | grep -v '^$'" "Fish Configuration"
run_cmd "test -f ~/.config/starship.toml && cat ~/.config/starship.toml" "Starship Prompt Configuration"
run_cmd "test -f ~/.config/kitty/kitty.conf && grep -v '^#' ~/.config/kitty/kitty.conf | grep -v '^$'" "Kitty Configuration"
run_cmd "test -f ~/.config/alacritty/alacritty.yml && grep -v '^#' ~/.config/alacritty/alacritty.yml | grep -v '^$'" "Alacritty Configuration"

# File managers
print_header "FILE MANAGER CONFIGURATION"
run_cmd "test -d ~/.config/thunar && ls -la ~/.config/thunar" "Thunar Configuration Files"
run_cmd "test -d ~/.config/lf && cat ~/.config/lf/lfrc 2>/dev/null" "lf Configuration"
run_cmd "test -d ~/.config/ranger && cat ~/.config/ranger/rc.conf 2>/dev/null" "Ranger Configuration"

# System utilities
print_header "SYSTEM UTILITIES"
run_cmd "systemctl --user list-unit-files | grep enabled" "Enabled User Services"
run_cmd "systemctl list-unit-files | grep enabled" "Enabled System Services"
run_cmd "ls -la ~/.config/autostart 2>/dev/null || echo 'No autostart directory'" "Autostart Applications"
run_cmd "test -f ~/.config/environment.d/*.conf && cat ~/.config/environment.d/*.conf" "User Environment Variables"
run_cmd "test -f ~/.xprofile && cat ~/.xprofile" "X11 Profile"
run_cmd "test -f ~/.profile && cat ~/.profile" "Profile Configuration"
run_cmd "pactl info 2>/dev/null || echo 'PulseAudio not available'" "Audio Information"
run_cmd "bluetoothctl list 2>/dev/null || echo 'Bluetooth controller not available'" "Bluetooth Controllers"
run_cmd "nmcli device 2>/dev/null || echo 'NetworkManager not available'" "Network Devices"

# Dotfile management
print_header "DOTFILE MANAGEMENT"
run_cmd "find ~/HyDE -type f -name '*.sh' 2>/dev/null | head -n 10" "HyDE Framework Scripts"
run_cmd "find ~/HyDE -type f -name '*.yml' 2>/dev/null | head -n 10" "HyDE Framework Configs"
run_cmd "find ~/.config -type f -name '.git*' 2>/dev/null" "Git-managed Config Directories"
run_cmd "find ~ -maxdepth 3 -name '.git' -type d 2>/dev/null" "Git Repositories in Home"

# Copy important config files to output directory for reference
print_header "COPYING IMPORTANT CONFIGS"
mkdir -p "$OUTPUT_DIR/configs"

# Core configs
copy_config "$HOME/.config/hypr"
copy_config "$HOME/.config/waybar"
copy_config "$HOME/.config/dunst"
copy_config "$HOME/.config/mako"
copy_config "$HOME/.config/rofi"
copy_config "$HOME/.config/kitty"
copy_config "$HOME/.config/alacritty"
copy_config "$HOME/.config/qt5ct"
copy_config "$HOME/.config/qt6ct"
copy_config "$HOME/.config/gtk-3.0"
copy_config "$HOME/.zshrc"
copy_config "$HOME/.config/starship.toml"

# Compress collected information into a shareable file
ARCHIVE_FILE="$HOME/arch_system_info_$(date +%Y%m%d).tar.gz"
tar -czf "$ARCHIVE_FILE" -C "$(dirname "$OUTPUT_DIR")" "$(basename "$OUTPUT_DIR")"

echo -e "\n${GREEN}=== Collection Complete ===${NC}"
echo "Information saved to: $OUTPUT_FILE"
echo "Configs copied to: $OUTPUT_DIR/configs/"
echo "Archive created: $ARCHIVE_FILE"
echo ""
echo -e "${YELLOW}You can now share this information with the AI assistant for more personalized help.${NC}"
echo -e "${YELLOW}The archive file contains configuration details but no sensitive information.${NC}"
