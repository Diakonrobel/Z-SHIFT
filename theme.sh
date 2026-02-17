#!/bin/bash

# =============================================================================
#  Z-SHIFT: Theme Switcher
# =============================================================================

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

echo -e "${CYAN}::: Z-SHIFT THEME MANAGER :::${NC}"

# 1. Check Dependencies
if ! command -v git &> /dev/null; then
    echo -e "${RED}Error: Git is required to fetch themes.${NC}"
    exit 1
fi

# 2. Ensure Theme Assets are Present
EZA_THEME_DIR="$HOME/.config/eza-themes"
if [ ! -d "$EZA_THEME_DIR" ]; then
    echo -e "${YELLOW}:: Downloading Eza themes...${NC}"
    git clone --quiet https://github.com/eza-community/eza-themes.git "$EZA_THEME_DIR"
else
    # Update existing repo to get latest themes
    git -C "$EZA_THEME_DIR" pull --quiet
fi

# 3. Define Theme Lists
STARSHIP_THEMES=(
    "gruvbox-rainbow"
    "nerd-font-symbols"
    "no-nerd-font"
    "bracketed-segments"
    "plain-text-symbols"
    "no-runtime-versions"
    "no-empty-icons"
    "pure-preset"
    "pastel-powerline"
    "tokyo-night"
    "jetpack"
    "catppuccin-powerline"
)

EZA_THEMES=(
    "gruvbox-dark.yml"
    "black.yml"
    "catppuccin-frappe.yml"
    "catppuccin-latte.yml"
    "catppuccin-macchiato.yml"
    "catppuccin-mocha.yml"
    "default.yml"
    "dracula.yml"
    "frosty.yml"
    "gruvbox-light.yml"
    "one_dark.yml"
    "rose-pine-dawn.yml"
    "rose-pine-moon.yml"
    "rose-pine.yml"
    "solarized-dark.yml"
    "tokyonight.yml"
    "white.yml"
)

# 4. Interactive Menu
PS3="Enter number: "
SELECTED_STARSHIP=""
SELECTED_EZA=""

echo -e "\n${BLUE}[1/2] Select Starship Prompt Theme:${NC}"
select s_theme in "${STARSHIP_THEMES[@]}"; do
    if [[ -n "$s_theme" ]]; then
        SELECTED_STARSHIP="$s_theme"
        break
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
done

echo -e "\n${BLUE}[2/2] Select Eza (ls) Theme:${NC}"
select e_theme in "${EZA_THEMES[@]}"; do
    if [[ -n "$e_theme" ]]; then
        SELECTED_EZA="$e_theme"
        break
    else
        echo -e "${RED}Invalid selection.${NC}"
    fi
done

# 5. Apply Configurations
echo -e "\n${YELLOW}:: Applying configurations...${NC}"

# Apply Starship
if command -v starship >/dev/null; then
    starship preset "$SELECTED_STARSHIP" -o ~/.config/starship.toml
    echo -e "${GREEN}✔ Starship set to: $SELECTED_STARSHIP${NC}"
else
    echo -e "${RED}✘ Starship not found. Skipping.${NC}"
fi

# Apply Eza
mkdir -p ~/.config/eza
ln -sf "$EZA_THEME_DIR/themes/$SELECTED_EZA" "$HOME/.config/eza/theme.yml"
echo -e "${GREEN}✔ Eza set to: $SELECTED_EZA${NC}"

echo -e "\n${GREEN}All done! Restart your shell or run 'source ~/.zshrc' to see changes.${NC}"