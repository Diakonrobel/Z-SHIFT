#!/bin/bash

# =============================================================================
#  Z-SHIFT: Cleanup & Restoration Script (Final Hardened Version)
# =============================================================================

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>>> Starting Z-Shift Removal...${NC}"

# -----------------------------------------------------------------------------
# Helper: Detect current shell safely
# -----------------------------------------------------------------------------
get_current_shell() {
    if command -v getent >/dev/null 2>&1; then
        getent passwd "$USER" | cut -d: -f7
    else
        echo "$SHELL"
    fi
}

# -----------------------------------------------------------------------------
# 1. RESTORE PREVIOUS SHELL
# -----------------------------------------------------------------------------
if [[ "$OSTYPE" != "darwin"* ]]; then
    CURRENT_SHELL=$(get_current_shell)

    if [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
        BASH_PATH=$(command -v bash)

        if [ -n "$BASH_PATH" ]; then
            echo -e "${YELLOW}:: Reverting default shell to Bash...${NC}"
            # Try usermod first, fallback to chsh
            sudo usermod --shell "$BASH_PATH" "$USER" 2>/dev/null || chsh -s "$BASH_PATH"
            echo -e "${GREEN}✔ Default shell reverted to $BASH_PATH.${NC}"
        fi
    fi
else
    # On Mac, Zsh is the system default. We leave it as is.
    echo -e "${GREEN}:: macOS detected. Keeping Zsh as system default.${NC}"
fi

# -----------------------------------------------------------------------------
# 2. CLEANUP CONFIGURATIONS
# -----------------------------------------------------------------------------
echo -e "${YELLOW}:: Cleaning up configuration files...${NC}"

# Restore .zshrc backup if available, otherwise just delete the Z-Shift one
if [ -f "$HOME/.zshrc.bak" ]; then
    mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
    echo -e "${GREEN}✔ Restored previous .zshrc from backup.${NC}"
else
    rm -f "$HOME/.zshrc"
    echo -e "${YELLOW}:: No backup found. Removed Z-Shift .zshrc.${NC}"
fi

# Remove Z-Shift specific config files
rm -f "$HOME/.config/starship.toml"
rm -rf "$HOME/.config/eza"
rm -rf "$HOME/.config/eza-themes"

# Remove Zinit plugins and data
ZINIT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
rm -rf "$ZINIT_DIR"
echo -e "${GREEN}✔ Configuration and plugin data removed.${NC}"

# -----------------------------------------------------------------------------
# 3. OPTIONAL: REMOVE BINARIES
# -----------------------------------------------------------------------------
if [ "$CI_ENV" != "true" ]; then
    echo -ne "${CYAN}Do you want to uninstall the CLI tools (eza, bat, fd, etc.)? [y/N]: ${NC}"
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}:: Removing binaries...${NC}"

        if [[ "$OSTYPE" == "darwin"* ]]; then
            brew uninstall eza bat fd fzf ripgrep tealdeer zoxide starship 2>/dev/null || true
        elif [ -f /etc/debian_version ]; then
            sudo apt remove -y eza bat fd-find fzf ripgrep starship 2>/dev/null || true
        elif [ -f /etc/fedora-release ]; then
            sudo dnf remove -y eza bat fd fzf ripgrep starship 2>/dev/null || true
        elif [ -f /etc/arch-release ]; then
            sudo pacman -Rs --noconfirm eza bat fd fzf ripgrep starship 2>/dev/null || true
        fi

        # IMPORTANT: Remove manual script-installed binaries
        # These are often missed by package managers
        [ -f /usr/local/bin/eza ] && sudo rm -f /usr/local/bin/eza
        [ -f /usr/local/bin/starship ] && sudo rm -f /usr/local/bin/starship
        
        echo -e "${GREEN}✔ Binary cleanup complete.${NC}"
    fi
fi

# -----------------------------------------------------------------------------
# 4. OPTIONAL: REMOVE FONTS
# -----------------------------------------------------------------------------
if [ "$CI_ENV" != "true" ]; then
    echo -ne "${CYAN}Do you want to remove FiraCode Nerd Fonts? [y/N]: ${NC}"
    read -r REPLY
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}:: Removing fonts...${NC}"
        FONT_DIR="$HOME/.local/share/fonts"
        [[ "$OSTYPE" == "darwin"* ]] && FONT_DIR="$HOME/Library/Fonts"

        rm -f "$FONT_DIR"/FiraCode* 2>/dev/null

        # Refresh font cache if the tool exists
        if command -v fc-cache >/dev/null 2>&1; then
            fc-cache -f "$FONT_DIR" || true
        fi
        echo -e "${GREEN}✔ Fonts removed.${NC}"
    fi
fi

# -----------------------------------------------------------------------------
# 5. FINALIZATION
# -----------------------------------------------------------------------------
echo -e "\n${GREEN}✔ Z-Shift has been successfully uninstalled.${NC}"
echo -e "${BLUE}Please restart your terminal session to apply all changes.${NC}"