# HyprNova - Modular Theme Manager

HyprNova is a comprehensive theme management system for Hyprland and associated applications. It provides a modular, extensible framework for applying consistent theming across your entire desktop environment.

## Features

- **Single Source of Truth**: All colors defined in one place
- **Modular Design**: Each component has its own installer
- **Extensible**: Easily add support for new applications
- **Theme Management**: Create and switch between themes
- **Backup System**: Automatically backs up existing configurations
- **Python-Powered**: Written in Python for improved maintainability

## Directory Structure

```
hyprnova/
├── colors/              # Color definitions
│   ├── default.conf     # Default color scheme
│   ├── nord.conf        # Nord theme variant
│   ├── dracula.conf     # Dracula theme variant
│   └── ...              # Other theme variants
├── components/          # Component-specific installers
│   ├── hyprland.py      # Hyprland installer
│   ├── waybar.py        # Waybar installer
│   ├── theme_generator.py # Theme generator component
│   └── ...              # Other component installers
├── hypr/                # Hyprland configurations
│   └── appearance.conf  # Hyprland appearance configuration
├── waybar/              # Waybar configurations
│   ├── config.jsonc.template # Waybar config template
│   ├── style.css.template # Waybar style template
│   └── modules/         # Individual Waybar module configurations
├── main.py              # Main installer script
└── README.md            # This file
```

## Getting Started

### Prerequisites

- Python 3.6+
- Hyprland
- Waybar (optional)
- Other tools you want to theme

### Installation

1. Clone this repository:
   ```bash
   git clone https://github.com/yourusername/hyprnova.git
   cd hyprnova
   ```

2. Install with default theme and all components:
   ```bash
   python main.py
   ```

3. To install specific components:
   ```bash
   python main.py --components hyprland waybar
   ```

4. To use a different theme:
   ```bash
   python main.py --theme nord
   ```

### Creating Your Own Theme

1. Create a new theme:
   ```bash
   python main.py --theme-create mytheme --primary "rgb(123, 45, 67)" --secondary "rgb(89, 10, 123)"
   ```

2. Apply your new theme:
   ```bash
   python main.py --theme mytheme
   ```

## Adding New Components

To add support for a new application:

1. Create a new file in the `components/` directory, e.g., `components/kitty.py`
2. Implement the `install` function that accepts a context dictionary
3. Use the provided context helpers for backups, symlinking, etc.

Example:

```python
def install(context):
    """Install Kitty terminal configuration"""
    logger = context["logger"]
    repo_root = context["repo_root"]
    config_dir = context["config_dir"]
    color_vars = context["color_vars"]
    
    # Implementation here
    
    return True
```

## Component Development Guidelines

When developing a new component:

1. **Keep it focused**: Each component should handle a single application
2. **Use provided helpers**: Use context functions for backups and symlinking
3. **Process templates**: Replace variables in templates with actual values
4. **Provide feedback**: Log progress and errors
5. **Return status**: Return True for success, False for failure

## License

This project is licensed under the MIT License - see the LICENSE file for details.
