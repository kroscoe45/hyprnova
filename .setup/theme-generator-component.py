#!/usr/bin/env python3
"""
HyprNova Theme Generator Component
"""

import os
from pathlib import Path
import shutil
import re
from typing import Dict, Any

def create_theme(colors_dir, name, theme_mode, primary_color=None, secondary_color=None):
    """
    Create a new theme based on the default colors
    
    Args:
        colors_dir: Directory containing color files
        name: Theme name (without extension)
        theme_mode: Theme mode (dark or light)
        primary_color: Primary accent color (RGB format, optional)
        secondary_color: Secondary accent color (RGB format, optional)
        
    Returns:
        Path: Path to the created theme file, or None if failed
    """
    # Validate inputs
    if not name or not theme_mode:
        return None
        
    if theme_mode not in ["dark", "light"]:
        return None
        
    # Source and destination files
    default_colors = colors_dir / "default.conf"
    theme_file = colors_dir / f"{name}.conf"
    
    if not default_colors.exists():
        return None
        
    # Read default colors
    with open(default_colors, "r") as f:
        content = f.read()
        
    # Update theme name
    content = re.sub(r'\$current-theme = ".*"', f'$current-theme = "{theme_mode}"', content)
    
    # Update theme comment
    title_case_name = "".join(word.capitalize() for word in name.split("_"))
    content = re.sub(
        r'# HyprNova Theme - Complete Color Definitions',
        f'# HyprNova {title_case_name} Theme - Complete Color Definitions',
        content
    )
    
    # Update primary color if provided
    if primary_color:
        content = re.sub(
            r'\$accent-primary = .*?#.*$',
            f'$accent-primary = {primary_color}    # Primary accent',
            content,
            flags=re.MULTILINE
        )
        
    # Update secondary color if provided
    if secondary_color:
        content = re.sub(
            r'\$accent-secondary = .*?#.*$',
            f'$accent-secondary = {secondary_color}   # Secondary accent',
            content,
            flags=re.MULTILINE
        )
        
    # Write theme file
    with open(theme_file, "w") as f:
        f.write(content)
        
    return theme_file

def install(context: Dict[str, Any]) -> bool:
    """
    Install the theme generator component
    
    Args:
        context: Installation context containing helper functions and paths
        
    Returns:
        bool: True if installation was successful, False otherwise
    """
    logger = context["logger"]
    repo_root = context["repo_root"]
    colors_dir = context["colors_dir"]
    args = context.get("args", None)
    
    logger.info("Installing theme generator component...")
    
    # Check if colors directory exists
    if not colors_dir.exists():
        logger.error(f"Colors directory not found: {colors_dir}")
        return False
        
    # Ensure default.conf exists
    default_colors = colors_dir / "default.conf"
    if not default_colors.exists():
        logger.error(f"Default colors file not found: {default_colors}")
        return False
        
    # Create a few example themes
    themes = [
        {
            "name": "nord",
            "mode": "dark",
            "primary": "rgb(129, 161, 193)",
            "secondary": "rgb(136, 192, 208)"
        },
        {
            "name": "dracula",
            "mode": "dark",
            "primary": "rgb(255, 121, 198)",
            "secondary": "rgb(189, 147, 249)"
        },
        {
            "name": "solarized",
            "mode": "dark",
            "primary": "rgb(38, 139, 210)",
            "secondary": "rgb(42, 161, 152)"
        }
    ]
    
    # Create example themes
    for theme in themes:
        theme_file = create_theme(
            colors_dir,
            theme["name"],
            theme["mode"],
            theme["primary"],
            theme["secondary"]
        )
        
        if theme_file:
            logger.info(f"Created example theme: {theme_file}")
        else:
            logger.warning(f"Failed to create example theme: {theme['name']}")
            
    logger.info("Theme generator component installed successfully")
    return True

def generate_theme(context, name, mode="dark", primary=None, secondary=None):
    """
    Generate a new theme with the given parameters
    
    Args:
        context: Installation context
        name: Theme name
        mode: Theme mode (dark or light)
        primary: Primary accent color
        secondary: Secondary accent color
        
    Returns:
        Path: Path to the created theme file, or None if failed
    """
    logger = context["logger"]
    colors_dir = context["colors_dir"]
    
    logger.info(f"Generating theme: {name}")
    
    theme_file = create_theme(colors_dir, name, mode, primary, secondary)
    
    if theme_file:
        logger.info(f"Theme generated successfully: {theme_file}")
        return theme_file
    else:
        logger.error(f"Failed to generate theme: {name}")
        return None
