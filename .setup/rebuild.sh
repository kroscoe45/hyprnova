#!/usr/bin/env bash
set -e

# Configuration
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$HOME/.config"
OUTPUT_DIR="$REPO_DIR/config"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }

# Key config directories for Hyprland setup
CONFIGS=(
  "hypr"          # Hyprland compositor
  "waybar"        # Status bar
  "wofi"          # Application launcher
  "rofi"          # Alternative launcher
  "mako"          # Notifications
  "dunst"         # Alternative notifications
  "swaylock"      # Screen locker
  "kitty"         # Terminal
  "foot"          # Alternative terminal
  "alacritty"     # Alternative terminal
)

# File extensions to include (config files only)
INCLUDE_EXTS=(
  "conf"
  "ini"
  "json"
  "css"
  "sh"
  "lua"
  "yml"
  "yaml"
  "toml"
  "rasi"
  "svg"  # Small vector graphics for icons
)

# Create extension pattern for find
PATTERN=""
for ext in "${INCLUDE_EXTS[@]}"; do
  PATTERN="$PATTERN -o -name \"*.$ext\""
done
PATTERN="${PATTERN:4}"  # Remove initial " -o "

# Main process
info "Rebuilding config repository at $REPO_DIR"
mkdir -p "$OUTPUT_DIR"

for config in "${CONFIGS[@]}"; do
  src="$CONFIG_DIR/$config"
  dst="$OUTPUT_DIR/$config"
  
  # Skip if source doesn't exist
  if [ ! -e "$src" ]; then
    info "Skipping $config (not found)"
    continue
  fi
  
  info "Processing $config"
  mkdir -p "$dst"
  
  # Find and copy only configuration files
  eval "find \"$src\" -type f \\( $PATTERN -o -name \"config\" \\) -size -500k" | while read -r file; do
    rel_path="${file#$src/}"
    target="$dst/$rel_path"
    mkdir -p "$(dirname "$target")"
    
    # Check if it's a symlink
    if [ -L "$file" ]; then
      link_target="$(readlink "$file")"
      
      # Handle relative symlinks
      if [[ "$link_target" != /* ]]; then
        # Relative symlink - first resolve to absolute
        link_target="$(cd "$(dirname "$file")" && realpath "$link_target")"
      fi
      
      # Check if target is within config dirs
      if [[ "$link_target" == "$CONFIG_DIR"/* ]]; then
        # Store the symlink relationship
        rel_target="${link_target#$CONFIG_DIR/}"
        dir="$(dirname "$target")"
        mkdir -p "$dir"
        echo "$rel_path -> .config/$rel_target" >> "$dst/.symlinks"
      else
        # External symlink - only copy if it's a config file
        for ext in "${INCLUDE_EXTS[@]}"; do
          if [[ "$link_target" == *.$ext ]] || [[ "$(basename "$link_target")" == "config" ]]; then
            cp "$link_target" "$target"
            break
          fi
        done
      fi
    else
      # Regular file
      cp "$file" "$target"
    fi
  done
  
  success "Processed $config"
done

# Special handling for gtk themes (just the config files)
if [ -d "$CONFIG_DIR/gtk-3.0" ]; then
  mkdir -p "$OUTPUT_DIR/gtk-3.0"
  if [ -f "$CONFIG_DIR/gtk-3.0/settings.ini" ]; then
    cp "$CONFIG_DIR/gtk-3.0/settings.ini" "$OUTPUT_DIR/gtk-3.0/"
  fi
fi

if [ -d "$CONFIG_DIR/gtk-4.0" ]; then
  mkdir -p "$OUTPUT_DIR/gtk-4.0"
  if [ -f "$CONFIG_DIR/gtk-4.0/settings.ini" ]; then
    cp "$CONFIG_DIR/gtk-4.0/settings.ini" "$OUTPUT_DIR/gtk-4.0/"
  fi
fi

success "Rebuild complete!"
info "Current repository size:"
du -sh "$REPO_DIR"
