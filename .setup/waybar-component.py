#!/usr/bin/env python3
"""
HyprNova Waybar Component Installer
"""

import os
import subprocess
from pathlib import Path
import shutil
import tempfile
from typing import Dict, Any
import json

def process_template(template_path, output_path, color_vars, additional_vars=None):
    """
    Process a template file with color variables
    
    Args:
        template_path: Path to the template file
        output_path: Path to write the processed file
        color_vars: Dictionary of color variables
        additional_vars: Dictionary of additional variables (optional)
    
    Returns:
        bool: True if successful, False otherwise
    """
    if not template_path.exists():
        return False
        
    # Create output directory if it doesn't exist
    output_path.parent.mkdir(parents=True, exist_ok=True)
    
    # Read template file
    with open(template_path, "r") as f:
        content = f.read()
        
    # Replace variables
    for var_name, var_value in color_vars.items():
        content = content.replace(f"${var_name}", var_value)
        
    if additional_vars:
        for var_name, var_value in additional_vars.items():
            content = content.replace(f"${var_name}", str(var_value))
            
    # Write output file
    with open(output_path, "w") as f:
        f.write(content)
        
    return True

def install(context: Dict[str, Any]) -> bool:
    """
    Install Waybar configuration
    
    Args:
        context: Installation context containing helper functions and paths
        
    Returns:
        bool: True if installation was successful, False otherwise
    """
    logger = context["logger"]
    repo_root = context["repo_root"]
    config_dir = context["config_dir"]
    color_vars = context["color_vars"]
    create_backup = context["create_backup"]
    
    logger.info("Installing Waybar configuration...")
    
    # Create Waybar config directory
    waybar_dir = config_dir / "waybar"
    waybar_dir.mkdir(parents=True, exist_ok=True)
    
    # Additional variables for templates
    additional_vars = {
        "r_deg": "0",
        "w_output": '"*"',
        "w_position": "top",
        "hv_pos": "height",
        "w_height": "32",
        "i_size": "16",
        "i_task": "16",
        "i_priv": "16",
        "i_theme": "Papirus-Dark",
        "font_name": "JetBrainsMono Nerd Font",
        "s_fontpx": "13",
        # Additional layout variables for style.css
        "x1": "top",
        "x2": "right",
        "x3": "bottom",
        "x4": "left",
        "x1g_margin": "0",
        "x2g_margin": "0",
        "x3g_margin": "0",
        "x4g_margin": "0",
        "g_paddin": "0",
        "w_margin": "5",
        "w_paddin": "5",
        "w_padact": "10",
        "e_margin": "0",
        "e_paddin": "0",
        "w_radius": "8",
        "t_radius": "8",
        "x1rb_radius": "8", 
        "x2rb_radius": "8",
        "x3rb_radius": "8",
        "x4rb_radius": "8",
        "x1lb_radius": "8",
        "x2lb_radius": "8",
        "x3lb_radius": "8",
        "x4lb_radius": "8",
        "x1rc_radius": "8",
        "x2rc_radius": "8",
        "x3rc_radius": "8",
        "x4rc_radius": "8",
        "x1lc_radius": "8",
        "x2lc_radius": "8",
        "x3lc_radius": "8",
        "x4lc_radius": "8",
        "modules_ls": "",
    }
    
    # Process Waybar config template
    config_template = repo_root / "waybar" / "config.jsonc.template"
    config_output = waybar_dir / "config.jsonc"
    
    if config_template.exists():
        logger.info(f"Processing Waybar config template: {config_template}")
        create_backup(config_output)
        success = process_template(config_template, config_output, color_vars, additional_vars)
        if success:
            logger.info(f"Generated Waybar config: {config_output}")
        else:
            logger.error(f"Failed to process Waybar config template")
            return False
    else:
        logger.warning(f"Waybar config template not found at {config_template}")
        
        # If template doesn't exist, create a basic config using the modules
        logger.info("Creating basic Waybar configuration from available modules")
        
        # Create consolidated config from module files
        modules_dir = repo_root / "waybar" / "modules"
        if modules_dir.exists():
            # Basic config structure
            config = {
                "layer": "top",
                "position": "top",
                "height": 32,
                "modules-left": ["hyprland/workspaces"],
                "modules-center": ["clock"],
                "modules-right": ["tray"],
            }
            
            # Add modules
            for module_file in modules_dir.glob("*.jsonc"):
                try:
                    module_name = module_file.stem
                    if module_name.endswith("##"):
                        # Skip alternate versions
                        continue
                        
                    with open(module_file, "r") as f:
                        module_content = f.read()
                        
                    # Clean up the module content (remove trailing commas, etc.)
                    module_content = module_content.strip()
                    if module_content.endswith(","):
                        module_content = module_content[:-1]
                        
                    # Parse module content
                    module_json = json.loads("{" + module_content + "}")
                    
                    # Add module to config
                    config.update(module_json)
                    
                    # Add module to appropriate section
                    if "battery" in module_name or "backlight" in module_name or "pulseaudio" in module_name:
                        if module_name not in config["modules-right"]:
                            config["modules-right"].insert(0, module_name)
                    elif "workspaces" in module_name:
                        if module_name not in config["modules-left"]:
                            config["modules-left"].insert(0, module_name)
                    elif "clock" in module_name:
                        if module_name not in config["modules-center"]:
                            config["modules-center"].insert(0, module_name)
                    else:
                        if module_name not in config["modules-right"]:
                            config["modules-right"].append(module_name)
                            
                except Exception as e:
                    logger.warning(f"Error processing module {module_file}: {e}")
                    
            # Write consolidated config
            create_backup(config_output)
            with open(config_output, "w") as f:
                json.dump(config, f, indent=4)
                
            logger.info(f"Created consolidated Waybar config: {config_output}")
        else:
            logger.warning(f"Waybar modules directory not found at {modules_dir}")
            
    # Process Waybar style template
    style_template = repo_root / "waybar" / "style.css.template"
    style_output = waybar_dir / "style.css"
    
    if style_template.exists():
        logger.info(f"Processing Waybar style template: {style_template}")
        create_backup(style_output)
        success = process_template(style_template, style_output, color_vars, additional_vars)
        if success:
            logger.info(f"Generated Waybar style: {style_output}")
        else:
            logger.error(f"Failed to process Waybar style template")
            return False
    else:
        # If no style template exists, create basic CSS with color variables
        logger.warning(f"Waybar style template not found at {style_template}")
        logger.info("Creating basic Waybar style.css with color variables")
        
        # Create a basic style.css
        basic_style = """
/* HyprNova Waybar Style
 * Auto-generated basic style with color variables
 */

:root {
    --background: ${background};
    --background-alt: ${background-alt};
    --foreground: ${foreground};
    --accent-primary: ${accent-primary};
    --accent-secondary: ${accent-secondary};
    --accent-warning: ${accent-warning};
    --accent-danger: ${accent-danger};
}

* {
    font-family: "JetBrainsMono Nerd Font", "Font Awesome 6 Free";
    font-size: 13px;
    border: none;
    border-radius: 0;
}

window#waybar {
    background-color: ${background-80};
    color: ${foreground};
}

#workspaces button {
    padding: 0 5px;
    background-color: transparent;
    color: ${foreground};
    transition: all 0.3s;
}

#workspaces button.active {
    background-color: ${accent-primary};
    color: ${background};
}

#workspaces button.urgent {
    background-color: ${accent-danger};
    color: ${background};
}

#clock,
#battery,
#cpu,
#memory,
#disk,
#temperature,
#network,
#pulseaudio,
#custom-media,
#custom-power,
#tray {
    padding: 0 10px;
    color: ${foreground};
    background-color: ${background-alt-80};
    border-radius: 8px;
    margin: 6px 3px;
}

#battery.warning {
    background-color: ${accent-warning};
    color: ${background};
}

#battery.critical {
    background-color: ${accent-danger};
    color: ${background};
}
"""
        
        # Replace variables
        for var_name, var_value in color_vars.items():
            basic_style = basic_style.replace(f"${{{var_name}}}", var_value)
            
        # Write basic style
        create_backup(style_output)
        with open(style_output, "w") as f:
            f.write(basic_style)
            
        logger.info(f"Created basic Waybar style: {style_output}")
        
    logger.info("Waybar configuration installed successfully")
    return True
