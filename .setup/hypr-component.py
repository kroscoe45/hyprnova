#!/usr/bin/env python3
"""
HyprNova Hyprland Component Installer
"""

import os
from pathlib import Path
import shutil
from typing import Dict, Any

def install(context: Dict[str, Any]) -> bool:
    """
    Install Hyprland configuration
    
    Args:
        context: Installation context containing helper functions and paths
        
    Returns:
        bool: True if installation was successful, False otherwise
    """
    logger = context["logger"]
    repo_root = context["repo_root"]
    config_dir = context["config_dir"]
    colors_dir = context["colors_dir"]
    create_backup = context["create_backup"]
    create_symlink = context["create_symlink"]
    color_vars = context["color_vars"]
    
    logger.info("Installing Hyprland configuration...")
    
    # Create Hyprland config directory
    hypr_dir = config_dir / "hypr"
    hypr_dir.mkdir(parents=True, exist_ok=True)
    
    # Create symlink for colors
    colors_file = colors_dir / "default.conf"
    hypr_colors = hypr_dir / "colors.conf"
    create_symlink(colors_file, hypr_colors)
    
    # Install appearance config
    appearance_src = repo_root / "hypr" / "appearance.conf"
    appearance_dst = hypr_dir / "appearance.conf"
    
    if appearance_src.exists():
        create_symlink(appearance_src, appearance_dst)
    else:
        logger.warning(f"Hyprland appearance config not found at {appearance_src}")
        
    # Add source line to hyprland.conf if it doesn't exist
    hypr_conf = hypr_dir / "hyprland.conf"
    source_line = "source = ~/.config/hypr/appearance.conf"
    
    if hypr_conf.exists():
        with open(hypr_conf, "r") as f:
            content = f.read()
            
        if source_line not in content:
            logger.info("Adding appearance.conf source line to hyprland.conf")
            create_backup(hypr_conf)
            
            with open(hypr_conf, "a") as f:
                f.write(f"\n# HyprNova theme configuration\n{source_line}\n")
        else:
            logger.info("appearance.conf already sourced in hyprland.conf")
    else:
        logger.warning(f"hyprland.conf not found at {hypr_conf}")
        logger.info("Creating minimal hyprland.conf with theme configuration")
        
        with open(hypr_conf, "w") as f:
            f.write(f"# HyprNova minimal Hyprland configuration\n{source_line}\n")
            
    logger.info("Hyprland configuration installed successfully")
    return True
