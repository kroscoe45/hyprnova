#!/usr/bin/env python3
"""
HyprNova Installer
A modular theme installer for Hyprland and associated tools
"""

import os
import sys
import argparse
import importlib.util
import logging
from pathlib import Path
import subprocess
import shutil
from typing import List, Dict, Any, Optional, Callable
import yaml

# Set up logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s - %(levelname)s - %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S"
)
logger = logging.getLogger("hyprnova")

class HyprNovaInstaller:
    def __init__(self, repo_root: Path):
        self.repo_root = repo_root
        self.colors_dir = repo_root / "colors"
        self.backup_dir = repo_root / ".oops-pit" / time.strftime("%Y%m%d_%H%M%S")
        self.config_dir = Path.home() / ".config"
        self.components = {}
        self.color_vars = {}
        
    def load_component_installers(self):
        """Load all component installers from the components directory"""
        components_dir = self.repo_root / "components"
        if not components_dir.exists():
            logger.error(f"Components directory not found at {components_dir}")
            return False
            
        for installer_file in components_dir.glob("*.py"):
            if installer_file.name.startswith("_"):
                continue
                
            component_name = installer_file.stem
            try:
                spec = importlib.util.spec_from_file_location(component_name, installer_file)
                module = importlib.util.module_from_spec(spec)
                spec.loader.exec_module(module)
                
                if hasattr(module, "install"):
                    self.components[component_name] = module
                    logger.info(f"Loaded component installer: {component_name}")
                else:
                    logger.warning(f"Component {component_name} does not have an install function")
            except Exception as e:
                logger.error(f"Failed to load component {component_name}: {e}")
                
        return len(self.components) > 0
        
    def load_color_variables(self, color_file: Path) -> Dict[str, str]:
        """Load color variables from the specified color file"""
        if not color_file.exists():
            logger.error(f"Color file not found: {color_file}")
            return {}
            
        color_vars = {}
        with open(color_file, "r") as f:
            for line in f:
                line = line.strip()
                if line.startswith("#") or not line:
                    continue
                    
                if "=" in line:
                    var, value = line.split("=", 1)
                    var_name = var.strip().lstrip("$")
                    var_value = value.strip()
                    
                    # Remove comments at the end of the line
                    if "#" in var_value:
                        var_value = var_value.split("#", 1)[0].strip()
                        
                    color_vars[var_name] = var_value
                    
        return color_vars
        
    def create_backup(self, path: Path) -> Path:
        """Create a backup of the specified file or directory"""
        if not path.exists():
            return None
            
        backup_path = self.backup_dir / path.relative_to(Path.home())
        backup_path.parent.mkdir(parents=True, exist_ok=True)
        
        if path.is_dir():
            shutil.copytree(path, backup_path)
        else:
            shutil.copy2(path, backup_path)
            
        logger.info(f"Created backup of {path} at {backup_path}")
        return backup_path
        
    def create_symlink(self, source: Path, target: Path):
        """Create a symlink with backup of existing file"""
        if target.exists() or target.is_symlink():
            self.create_backup(target)
            target.unlink(missing_ok=True)
            
        target.parent.mkdir(parents=True, exist_ok=True)
        target.symlink_to(source)
        logger.info(f"Created symlink from {source} to {target}")
        
    def install_component(self, component_name: str, color_vars: Dict[str, str], args: Any) -> bool:
        """Install a specific component"""
        if component_name not in self.components:
            logger.error(f"Component {component_name} not found")
            return False
            
        component = self.components[component_name]
        try:
            # Create component context with helper functions
            context = {
                "repo_root": self.repo_root,
                "config_dir": self.config_dir,
                "colors_dir": self.colors_dir,
                "backup_dir": self.backup_dir,
                "color_vars": color_vars,
                "create_backup": self.create_backup,
                "create_symlink": self.create_symlink,
                "logger": logger,
                "args": args
            }
            
            # Call the component's install function
            result = component.install(context)
            if result:
                logger.info(f"Successfully installed component: {component_name}")
            else:
                logger.warning(f"Component {component_name} installation returned False")
                
            return result
        except Exception as e:
            logger.error(f"Error installing component {component_name}: {e}")
            return False
            
    def run(self, args: Any) -> int:
        """Run the installer with the specified arguments"""
        # Create backup directory
        self.backup_dir.mkdir(parents=True, exist_ok=True)
        logger.info(f"Created backup directory: {self.backup_dir}")
        
        # Load component installers
        if not self.load_component_installers():
            logger.error("No component installers found")
            return 1
            
        # Load color variables
        color_file = self.colors_dir / "default.conf"
        if args.theme:
            theme_file = self.colors_dir / f"{args.theme}.conf"
            if theme_file.exists():
                color_file = theme_file
                logger.info(f"Using theme: {args.theme}")
            else:
                logger.warning(f"Theme file not found: {theme_file}")
                logger.info(f"Falling back to default theme")
                
        self.color_vars = self.load_color_variables(color_file)
        if not self.color_vars:
            logger.error("Failed to load color variables")
            return 1
            
        # Determine which components to install
        components_to_install = []
        if args.components:
            # Install specific components
            for component in args.components:
                if component in self.components:
                    components_to_install.append(component)
                else:
                    logger.warning(f"Component not found: {component}")
        else:
            # Install all components
            components_to_install = list(self.components.keys())
            
        if not components_to_install:
            logger.error("No components to install")
            return 1
            
        # Install each component
        success_count = 0
        for component in components_to_install:
            if self.install_component(component, self.color_vars, args):
                success_count += 1
                
        # Print summary
        logger.info(f"Installation summary: {success_count}/{len(components_to_install)} components installed successfully")
        
        return 0 if success_count == len(components_to_install) else 1

def main():
    """Main entry point"""
    import time
    
    parser = argparse.ArgumentParser(description="HyprNova Theme Installer")
    parser.add_argument("--theme", "-t", help="Theme to install (default: default)")
    parser.add_argument("--components", "-c", nargs="+", help="Specific components to install")
    parser.add_argument("--list", "-l", action="store_true", help="List available components")
    parser.add_argument("--verbose", "-v", action="store_true", help="Enable verbose logging")
    args = parser.parse_args()
    
    # Set log level
    if args.verbose:
        logger.setLevel(logging.DEBUG)
    
    # Determine repo root
    repo_root = Path(__file__).parent
    
    # Create installer
    installer = HyprNovaInstaller(repo_root)
    
    # List components if requested
    if args.list:
        installer.load_component_installers()
        print("Available components:")
        for component in installer.components:
            print(f"  - {component}")
        return 0
    
    # Run installer
    return installer.run(args)

if __name__ == "__main__":
    sys.exit(main())
