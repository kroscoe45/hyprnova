#!/usr/bin/env bash
set -e

# Configuration
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG_DIR="$REPO_DIR/config"
BACKUP_DIR="$HOME/.config.backup.$(date +%Y%m%d%H%M%S)"

# Parse args
FORCE=false
BACKUP=false
for arg in "$@"; do
  [[ "$arg" == "--force" ]] && FORCE=true
  [[ "$arg" == "--backup" ]] && BACKUP=true
done

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[OK]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Backup function
backup() {
  local file="$1"
  local backup_file="$BACKUP_DIR/${file#$HOME/.config/}"
  local backup_dir="$(dirname "$backup_file")"
  
  mkdir -p "$backup_dir"
  cp -a "$file" "$backup_file"
  info "Backed up: $file"
}

# Link function
link() {
  local src="$1"
  local dst="$2"
  
  # Handle existing destination
  if [ -e "$dst" ]; then
    if [ -L "$dst" ] && [ "$(readlink "$dst")" = "$src" ]; then
      info "Already linked: $dst"
      return 0
    fi
    
    if [ "$FORCE" = true ]; then
      [ "$BACKUP" = true ] && backup "$dst"
      rm -rf "$dst"
    else
      warn "Skipping existing file: $dst (use --force to overwrite)"
      return 0
    fi
  fi
  
  # Create parent directory if needed
  mkdir -p "$(dirname "$dst")"
  
  # Create symlink
  ln -s "$src" "$dst"
  success "Linked: $dst -> $src"
}

# Process a config directory
process_dir() {
  local config="$1"
  local src_dir="$CONFIG_DIR/$config"
  local dst_dir="$HOME/.config/$config"
  
  info "Processing: $config"
  
  # Check for symlinks file
  if [ -f "$src_dir/.symlinks" ]; then
    info "Found symlinks file for $config"
    while read -r line; do
      local rel_path="$(echo "$line" | cut -d' ' -f1)"
      local target="$(echo "$line" | cut -d' ' -f3-)"
      
      # Create the symlink
      local src_file="$HOME/$target"
      local dst_file="$dst_dir/$rel_path"
      
      # Create parent directory if needed
      mkdir -p "$(dirname "$dst_file")"
      
      # Create symlink if target exists
      if [ -e "$src_file" ]; then
        [ -e "$dst_file" ] && [ "$FORCE" = true ] && rm -f "$dst_file"
        [ ! -e "$dst_file" ] && ln -s "$src_file" "$dst_file" && success "Recreated symlink: $dst_file -> $src_file"
      else
        warn "Symlink target not found: $src_file"
      fi
    done < "$src_dir/.symlinks"
    
    # Remove the symlinks file so it doesn't get linked
    rm -f "$dst_dir/.symlinks"
  fi
  
  # Link all regular files
  find "$src_dir" -type f | grep -v "/.symlinks$" | while read -r file; do
    local rel_path="${file#$src_dir/}"
    local dst_file="$dst_dir/$rel_path"
    link "$file" "$dst_file"
  done
}

# Main process
info "Setting up Hyprland dotfiles from $REPO_DIR"

# Make sure .config exists
mkdir -p "$HOME/.config"

# Process each config directory
for config_dir in "$CONFIG_DIR"/*; do
  [ -d "$config_dir" ] || continue
  process_dir "$(basename "$config_dir")"
done

success "Done!"
[ -d "$BACKUP_DIR" ] && info "Backups created in: $BACKUP_DIR"
