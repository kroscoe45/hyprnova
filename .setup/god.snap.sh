#!/usr/bin/env bash

# ╔════════════════════════════════════════════════════════════════════════════╗
# ║ HyprNova Installation Script                                               ║
# ║ Automatically installs the HyprNova Hyprland theme and configuration       ║
# ╚════════════════════════════════════════════════════════════════════════════╝

# Terminal colors
BOLD="\e[1m"
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
BLUE="\e[34m"
MAGENTA="\e[35m"
CYAN="\e[36m"
RESET="\e[0m"

# Repository and installation paths
REPO_DIR="$HOME/Code/my-repos/hyprnova"
BACKUP_DIR="$HOME/.config/hyprnova_backup_$(date +%Y%m%d%H%M%S)"
LOG_FILE="/tmp/hyprnova_install_$(date +%Y%m%d%H%M%S).log"

# Configuration directories and files
CONFIG_DIRS=(
    "$HOME/.config/hypr"
    "$HOME/.config/waybar"
    "$HOME/.config/dunst"
    "$HOME/.config/kitty"
    "$HOME/.config/rofi"
    "$HOME/.config/gtk-3.0"
    "$HOME/.config/qt5ct"
    "$HOME/.config/qt6ct"
    "$HOME/.config/nvim"
)

# Required packages
OFFICIAL_PACKAGES=(
    "hyprland" 
    "waybar"
    "kitty"
    "rofi-wayland"
    "dunst"
    "qt5ct"
    "qt6ct"
    "polkit-gnome"
    "xdg-desktop-portal-hyprland"
    "swww"
    "grim"
    "slurp"
    "wl-clipboard"
    "cliphist"
    "pamixer"
    "brightnessctl"
    "noto-fonts-emoji"
    "ttf-nerd-fonts-symbols"
    "neovim"
    "ripgrep"
    "fd"
    "lazygit"
)

AUR_PACKAGES=(
    "hyprpicker"
    "hypridle"
)

# Function to print banners
print_banner() {
    local message="$1"
    local length=${#message}
    local line=$(printf '═%.0s' $(seq 1 $((length + 6))))
    
    echo -e "${BOLD}${CYAN}╔${line}╗${RESET}"
    echo -e "${BOLD}${CYAN}║   ${message}   ║${RESET}"
    echo -e "${BOLD}${CYAN}╚${line}╝${RESET}"
    echo ""
}

# Function to log messages
log() {
    local message="$1"
    local type="$2"
    
    case "$type" in
        "info")
            echo -e "${BLUE}[INFO]${RESET} $message"
            ;;
        "success")
            echo -e "${GREEN}[SUCCESS]${RESET} $message"
            ;;
        "warning")
            echo -e "${YELLOW}[WARNING]${RESET} $message"
            ;;
        "error")
            echo -e "${RED}[ERROR]${RESET} $message"
            ;;
        *)
            echo -e "$message"
            ;;
    esac
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$type] $message" >> "$LOG_FILE"
}

# Function to check if running on Arch Linux
check_arch_linux() {
    print_banner "Checking System Compatibility"
    
    if [ -f /etc/arch-release ]; then
        log "Running on Arch Linux" "success"
    else
        if [ -f /etc/os-release ]; then
            source /etc/os-release
            log "Running on $PRETTY_NAME, which is not Arch Linux. Some features may not work as expected." "warning"
            
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                log "Installation aborted by user" "error"
                exit 1
            fi
        else
            log "Could not determine the operating system. HyprNova is designed for Arch Linux." "error"
            exit 1
        fi
    fi
}

# Function to check system requirements
check_requirements() {
    print_banner "Checking System Requirements"
    
    # Check for Wayland support
    if ! command -v wlroots &> /dev/null && ! pacman -Q wlroots &> /dev/null; then
        log "Wayland compositor libraries not found. Please ensure your system supports Wayland." "error"
        exit 1
    fi
    
    # Check GPU and update config accordingly
    log "Detecting GPU..." "info"
    if lspci | grep -i 'VGA\|3D\|Display' | grep -i 'AMD\|ATI' &> /dev/null; then
        log "AMD GPU detected" "info"
        GPU_TYPE="amd"
    elif lspci | grep -i 'VGA\|3D\|Display' | grep -i 'NVIDIA' &> /dev/null; then
        log "NVIDIA GPU detected" "info"
        GPU_TYPE="nvidia"
    elif lspci | grep -i 'VGA\|3D\|Display' | grep -i 'Intel' &> /dev/null; then
        log "Intel GPU detected" "info"
        GPU_TYPE="intel"
    else
        log "Could not detect GPU type. Using generic configuration." "warning"
        GPU_TYPE="generic"
    fi
    
    # Check if AUR helper is installed
    if command -v yay &> /dev/null; then
        AUR_HELPER="yay"
        log "Found AUR helper: yay" "success"
    elif command -v paru &> /dev/null; then
        AUR_HELPER="paru"
        log "Found AUR helper: paru" "success"
    else
        log "No AUR helper found (yay or paru). AUR packages will not be installed." "warning"
        AUR_HELPER=""
    fi
    
    # Check disk space (need at least 1GB free in home directory)
    FREE_SPACE=$(df -h "$HOME" | awk 'NR==2 {print $4}')
    log "Free space in home directory: $FREE_SPACE" "info"
    
    FREE_KB=$(df -k "$HOME" | awk 'NR==2 {print $4}')
    if [ "$FREE_KB" -lt 1048576 ]; then  # 1GB in KB
        log "Less than 1GB of free space available in home directory. Installation may fail." "warning"
        
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log "Installation aborted by user" "error"
            exit 1
        fi
    fi
}

# Function to install required packages
install_packages() {
    print_banner "Installing Required Packages"
    
    # Update package database
    log "Updating package database..." "info"
    sudo pacman -Sy || { log "Failed to update package database" "error"; exit 1; }
    
    # Install packages from official repositories
    log "Installing packages from official repositories..." "info"
    for pkg in "${OFFICIAL_PACKAGES[@]}"; do
        if ! pacman -Q "$pkg" &> /dev/null; then
            log "Installing $pkg..." "info"
            sudo pacman -S --noconfirm "$pkg" || log "Failed to install $pkg" "warning"
        else
            log "$pkg is already installed" "info"
        fi
    done
    
    # Install AUR packages if AUR helper is available
    if [ -n "$AUR_HELPER" ]; then
        log "Installing AUR packages using $AUR_HELPER..." "info"
        for pkg in "${AUR_PACKAGES[@]}"; do
            if ! pacman -Q "$pkg" &> /dev/null; then
                log "Installing $pkg from AUR..." "info"
                $AUR_HELPER -S --noconfirm "$pkg" || log "Failed to install $pkg from AUR" "warning"
            else
                log "$pkg is already installed" "info"
            fi
        done
    fi
    
    log "Package installation completed" "success"
}

# Function to set up repository
setup_repository() {
    print_banner "Setting Up Repository"
    
    if [ -d "$REPO_DIR" ]; then
        log "Repository directory already exists at $REPO_DIR" "info"
        
        # Check if it's a git repository
        if [ -d "$REPO_DIR/.git" ]; then
            log "Updating existing repository..." "info"
            cd "$REPO_DIR" || { log "Failed to change to repository directory" "error"; exit 1; }
            git pull || log "Failed to update repository" "warning"
        else
            log "$REPO_DIR exists but is not a git repository" "warning"
            log "Using existing directory without updating" "info"
        fi
    else
        log "Creating repository directory..." "info"
        mkdir -p "$REPO_DIR" || { log "Failed to create repository directory" "error"; exit 1; }
        
        # If this is intended to be a fresh installation rather than using existing files,
        # uncomment the following lines to clone from a remote repository
        # log "Cloning HyprNova repository..." "info"
        # git clone https://github.com/yourusername/hyprnova.git "$REPO_DIR" || {
        #     log "Failed to clone repository" "error"
        #     exit 1
        # }
    fi
    
    # Create necessary subdirectories in the repository if they don't exist
    SUBDIRS=("hypr" "waybar" "dunst" "kitty" "rofi" "gtk-3.0" "qt5ct" "qt6ct" "nvim")
    for dir in "${SUBDIRS[@]}"; do
        if [ ! -d "$REPO_DIR/$dir" ]; then
            log "Creating $dir directory in repository..." "info"
            mkdir -p "$REPO_DIR/$dir" || log "Failed to create $dir directory" "warning"
        fi
    done
    
    log "Repository setup completed" "success"
}

# Function to back up existing configurations
backup_existing_configs() {
    print_banner "Backing Up Existing Configurations"
    
    mkdir -p "$BACKUP_DIR" || { log "Failed to create backup directory" "error"; exit 1; }
    
    for dir in "${CONFIG_DIRS[@]}"; do
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")
            log "Backing up $dir_name configuration..." "info"
            cp -r "$dir" "$BACKUP_DIR/" || log "Failed to back up $dir_name configuration" "warning"
        fi
    done
    
    log "Backup completed at $BACKUP_DIR" "success"
}

# Function to create symlinks
create_symlinks() {
    print_banner "Creating Configuration Symlinks"
    
    for dir in "${SUBDIRS[@]}"; do
        config_dir="$HOME/.config/$dir"
        repo_config_dir="$REPO_DIR/$dir"
        
        if [ -d "$config_dir" ]; then
            log "Removing existing $dir configuration..." "info"
            rm -rf "$config_dir" || log "Failed to remove existing $dir configuration" "warning"
        fi
        
        log "Creating symlink for $dir configuration..." "info"
        ln -sf "$repo_config_dir" "$config_dir" || log "Failed to create symlink for $dir configuration" "warning"
    done
    
    # Creating special symlinks if needed
    if [ -f "$REPO_DIR/userprefs.conf" ]; then
        log "Creating symlink for userprefs.conf..." "info"
        ln -sf "$REPO_DIR/userprefs.conf" "$HOME/.config/hypr/userprefs.conf" || log "Failed to create symlink for userprefs.conf" "warning"
    fi
    
    log "Symlink creation completed" "success"
}

# Function to apply GPU-specific configuration
apply_gpu_config() {
    print_banner "Applying GPU-Specific Configuration"
    
    case "$GPU_TYPE" in
        "amd")
            log "Applying AMD GPU configuration..." "info"
            # Add AMD-specific environment variables to the Hyprland config
            cat > "$REPO_DIR/hypr/gpu.conf" << EOF
# AMD GPU optimizations
env = WLR_DRM_DEVICES,/dev/dri/card0
env = AMD_VULKAN_ICD,RADV
EOF
            ;;
        "nvidia")
            log "Applying NVIDIA GPU configuration..." "info"
            # Add NVIDIA-specific environment variables to the Hyprland config
            cat > "$REPO_DIR/hypr/gpu.conf" << EOF
# NVIDIA GPU optimizations
env = LIBVA_DRIVER_NAME,nvidia
env = XDG_SESSION_TYPE,wayland
env = GBM_BACKEND,nvidia-drm
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
env = WLR_NO_HARDWARE_CURSORS,1
EOF
            ;;
        "intel")
            log "Applying Intel GPU configuration..." "info"
            # Add Intel-specific environment variables to the Hyprland config
            cat > "$REPO_DIR/hypr/gpu.conf" << EOF
# Intel GPU optimizations
env = LIBVA_DRIVER_NAME,iHD
env = VDPAU_DRIVER,va_gl
EOF
            ;;
        *)
            log "Using generic GPU configuration..." "info"
            # Add generic environment variables to the Hyprland config
            cat > "$REPO_DIR/hypr/gpu.conf" << EOF
# Generic GPU configuration
# No specific optimizations
EOF
            ;;
    esac
    
    # Ensure Hyprland loads the GPU configuration
    if ! grep -q "source = ./gpu.conf" "$REPO_DIR/hypr/hyprland.conf"; then
        echo "source = ./gpu.conf # GPU-specific configuration" >> "$REPO_DIR/hypr/hyprland.conf"
    fi
    
    log "GPU configuration applied" "success"
}

# Function to apply final touches
apply_final_touches() {
    print_banner "Applying Final Touches"
    
    # Set executable permissions for scripts
    log "Setting executable permissions for scripts..." "info"
    find "$REPO_DIR" -type f -name "*.sh" -exec chmod +x {} \;
    
    # Create autostart entry for Hyprland if needed
    if [ ! -f "$HOME/.config/autostart/hyprland.desktop" ]; then
        log "Creating autostart entry for Hyprland..." "info"
        mkdir -p "$HOME/.config/autostart"
        cat > "$HOME/.config/autostart/hyprland.desktop" << EOF
[Desktop Entry]
Type=Application
Name=Hyprland
Exec=/usr/bin/Hyprland
Terminal=false
Categories=System;
EOF
    fi
    
    # Set up Neovim plugin manager if needed
    if [ ! -f "$HOME/.local/share/nvim/site/autoload/plug.vim" ] && [ ! -d "$HOME/.local/share/nvim/lazy" ]; then
        log "Setting up Neovim plugin management..." "info"
        
        # For vim-plug (if that's what your config uses)
        if grep -q "vim-plug" "$REPO_DIR/nvim/init.lua" 2>/dev/null || grep -q "vim-plug" "$REPO_DIR/nvim/init.vim" 2>/dev/null; then
            log "Installing vim-plug..." "info"
            sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
                   https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
        fi
        
        # For lazy.nvim (modern plugin manager)
        if grep -q "lazy" "$REPO_DIR/nvim/init.lua" 2>/dev/null; then
            log "Setting up lazy.nvim (will be installed when Neovim first launches)..." "info"
        fi
        
        log "Neovim plugin management prepared" "success"
    else
        log "Neovim plugin management already set up" "info"
    fi
    
    log "Final touches applied" "success"
}

# Function to print installation summary
print_summary() {
    print_banner "Installation Summary"
    
    echo -e "${BOLD}${GREEN}HyprNova installation completed successfully!${RESET}"
    echo ""
    echo -e "Repository location: ${BOLD}$REPO_DIR${RESET}"
    echo -e "Configuration backup: ${BOLD}$BACKUP_DIR${RESET}"
    echo -e "Log file: ${BOLD}$LOG_FILE${RESET}"
    echo -e "GPU type detected: ${BOLD}$GPU_TYPE${RESET}"
    echo ""
    echo -e "${BOLD}${YELLOW}Next Steps:${RESET}"
    echo -e "1. Log out of your current session"
    echo -e "2. Select Hyprland from your display manager"
    echo -e "3. Log in to enjoy your new HyprNova environment"
    echo -e "4. Open Neovim to trigger plugin installation: ${BOLD}nvim${RESET}"
    echo ""
    echo -e "If you experience any issues, please check the log file or report them to the repository."
    echo -e "You can revert to your previous configuration by removing the symlinks and restoring from $BACKUP_DIR."
    echo ""
}

# Main installation function
main() {
    # Clear screen and show welcome message
    clear
    echo -e "${BOLD}${MAGENTA}"
    cat << "EOF"
 _   _                   _   _                    
| | | |_   _ _ __  _ __ | \ | | _____   ____ _    
| |_| | | | | '_ \| '_ \|  \| |/ _ \ \ / / _` |   
|  _  | |_| | |_) | | |_| |\  | (_) \ V / (_| |   
|_| |_|\__, | .__/|_|   |_| \_|\___/ \_/ \__,_|   
       |___/|_|                                   
EOF
    echo -e "${RESET}"
    print_banner "Hyprland Theme and Configuration Installer"
    
    echo -e "This script will install the HyprNova theme and configuration for Hyprland."
    echo -e "It will backup your existing configurations and create symlinks to the new ones."
    echo -e ""
    echo -e "${BOLD}${YELLOW}WARNING:${RESET} This will modify your existing Hyprland, Waybar, and other configurations."
    echo -e ""
    
    read -p "Do you want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Installation aborted by user" "error"
        exit 1
    fi
    
    # Create log file
    touch "$LOG_FILE" || { echo "Failed to create log file"; exit 1; }
    
    # Run installation steps
    check_arch_linux
    check_requirements
    install_packages
    setup_repository
    backup_existing_configs
    create_symlinks
    apply_gpu_config
    apply_final_touches
    print_summary
}

# Run the main function
main
