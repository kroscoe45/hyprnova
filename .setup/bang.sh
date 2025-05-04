#!/usr/bin/env bash
set -e

# Core configuration
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKUP_DIR="$HOME/.dotfiles.backup.$(date +%Y%m%d%H%M%S)"

# Define mapping of repo directories to home locations
declare -A DIR_MAPPING=(
  ["config"]="$HOME/.config"
  ["local"]="$HOME/.local"
)

# Parse args
FORCE=false
BACKUP=false
for arg in "$@"; do
  [[ "$arg" == "--force" ]] && FORCE=true
  [[ "$arg" == "--backup" ]] && BACKUP=true
done

# Simplified color functions
info() { echo -e "\e[34m[INFO]\e[0m $1"; }
success() { echo -e "\e[32m[OK]\e[0m $1"; }
warn() { echo -e "\e[33m[WARN]\e[0m $1"; }

# Create symlink function
link() {
  local src="$1" dst="$2" dstdir="$(dirname "$dst")"
  
  # Create target directory if needed
  [[ ! -d "$dstdir" ]] && mkdir -p "$dstdir"
  
  # Special handling for symlinks
  if [[ -L "$src" ]]; then
    # If source is already a symlink, recreate the symlink
    local link_target=$(readlink "$src")
    
    # Check if link is relative and adjust if needed
    if [[ "$link_target" != /* ]]; then
      # Relative link - needs path adjustment
      local src_dir=$(dirname "$src")
      link_target="$src_dir/$link_target"
    fi
    
    # If the target exists in our repo, we'll link to repo version instead
    local repo_relative=${link_target#$HOME/}
    for base in "${!DIR_MAPPING[@]}"; do
      local mapped_dir=${DIR_MAPPING[$base]}
      local mapped_relative=${mapped_dir#$HOME/}
      
      if [[ "$repo_relative" == "$mapped_relative"* ]]; then
        local in_repo_path="$DOTFILES_DIR/${repo_relative/$mapped_relative/$base}"
        if [[ -e "$in_repo_path" ]]; then
          link_target="$in_repo_path"
          break
        fi
      fi
    done
    
    info "Recreating symlink at $dst -> $link_target"
    
    # Handle existing destination
    if [[ -e "$dst" || -L "$dst" ]]; then
      if [[ "$FORCE" == true ]]; then
        [[ "$BACKUP" == true ]] && backup "$dst"
        rm -rf "$dst"
      else
        warn "Skipping existing file: $dst (use --force to overwrite)"
        return 0
      fi
    fi
    
    ln -s "$link_target" "$dst"
    success "Linked: $dst -> $link_target"
    return 0
  fi
  
  # Handle existing destination (for regular files)
  if [[ -e "$dst" || -L "$dst" ]]; then
    # Already correctly linked
    if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
      info "Already linked: $dst"
      return 0
    fi
    
    # Need to handle existing file
    if [[ "$FORCE" == true ]]; then
      [[ "$BACKUP" == true ]] && backup "$dst"
      rm -rf "$dst"
    else
      warn "Skipping existing file: $dst (use --force to overwrite)"
      return 0
    fi
  fi
  
  # Create the link
  ln -s "$src" "$dst"
  success "Linked: $dst -> $src"
}

# Backup function
backup() {
  local path="$1"
  local backup_path="$BACKUP_DIR${path#$HOME}"
  local backup_dir="$(dirname "$backup_path")"
  
  [[ ! -d "$backup_dir" ]] && mkdir -p "$backup_dir"
  info "Backing up to $backup_path"
  cp -R "$path" "$backup_path"
}

# Process directory
process_dir() {
  local base="$1"
  local home_dir="${DIR_MAPPING[$base]}"
  local repo_dir="$DOTFILES_DIR/$base"
  
  [[ ! -d "$repo_dir" ]] && return 0
  
  info "Processing: $base -> $home_dir"
  
  # Create directory structure first
  find "$repo_dir" -type d | while read -r dir; do
    [[ "$dir" == "$repo_dir" ]] && continue
    local target_dir="${home_dir}${dir#$repo_dir}"
    [[ ! -d "$target_dir" ]] && mkdir -p "$target_dir"
  done
  
  # Then create symlinks for files
  find "$repo_dir" -type f -o -type l | while read -r file; do
    local target="${home_dir}${file#$repo_dir}"
    link "$file" "$target"
  done
}

# Main process
info "Setting up dotfiles from $DOTFILES_DIR"

# Process each mapped directory
for base in "${!DIR_MAPPING[@]}"; do
  process_dir "$base"
done

success "Done!"
[[ -d "$BACKUP_DIR" ]] && info "Backups created in: $BACKUP_DIR"
