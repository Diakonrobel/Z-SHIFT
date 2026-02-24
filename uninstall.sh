#!/bin/bash

# =============================================================================
#  Z-SHIFT: Cleanup & Restoration Script
# =============================================================================

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}>>> Initiating Z-Shift Environment Removal...${NC}"

# =============================================================================
# 0. OS & PACKAGE MANAGER DETECTION
# =============================================================================
OS_TYPE="unknown"
DISTRO="unknown"

if [[ "$OSTYPE" == "darwin"* ]]; then
    OS_TYPE="macos"
    DISTRO="macos"
elif [ -f /etc/os-release ]; then
    OS_TYPE="linux"
    # shellcheck disable=SC1091
    . /etc/os-release
    DISTRO="$ID"
fi

echo -e "${BLUE}Detected OS: ${OS_TYPE} (${DISTRO})${NC}"

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
if [[ "$OS_TYPE" != "macos" ]]; then
    CURRENT_SHELL=$(get_current_shell)

    if [[ "$CURRENT_SHELL" == *"zsh"* ]]; then
        BASH_PATH=$(command -v bash)

        if [ -n "$BASH_PATH" ]; then
            echo -e "${YELLOW}:: Reverting default shell to Bash...${NC}"
            if sudo usermod --shell "$BASH_PATH" "$USER" 2>/dev/null || chsh -s "$BASH_PATH"; then
                echo -e "${GREEN}✔ Default shell reverted to $BASH_PATH.${NC}"
            else
                echo -e "${RED}✘ Failed to revert default shell. You may need to do this manually.${NC}"
            fi
        else
            echo -e "${RED}✘ Bash not found in PATH. Cannot automatically revert shell.${NC}"
        fi
    fi
else
    echo -e "${GREEN}:: macOS detected. Keeping Zsh as system default.${NC}"
fi

# -----------------------------------------------------------------------------
# 2. CLEANUP CONFIGURATIONS
# -----------------------------------------------------------------------------
echo -e "${YELLOW}:: Cleaning up configuration files...${NC}"

# Restore .zshrc backup
if [ -f "$HOME/.zshrc.bak" ]; then
    mv "$HOME/.zshrc.bak" "$HOME/.zshrc"
    echo -e "${GREEN}✔ Restored previous .zshrc from backup.${NC}"
else
    rm -f "$HOME/.zshrc"
    echo -e "${YELLOW}:: No backup found. Removed Z-Shift .zshrc.${NC}"
fi

# Remove Z-Shift added line in .zshenv
if [ -f "$HOME/.zshenv" ]; then
    if grep -q "skip_global_compinit=1" "$HOME/.zshenv"; then
        grep -v "skip_global_compinit=1" "$HOME/.zshenv" > "$HOME/.zshenv.tmp" && mv "$HOME/.zshenv.tmp" "$HOME/.zshenv"
        echo -e "${GREEN}✔ Cleaned up ~/.zshenv.${NC}"
    fi
    [ ! -s "$HOME/.zshenv" ] && rm -f "$HOME/.zshenv"
fi

# Remove Z-Shift directories
rm -f "$HOME/.config/starship.toml"
rm -rf "$HOME/.config/eza"
rm -rf "$HOME/.config/eza-themes"

# Remove Zinit data
ZINIT_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zinit"
if [ -d "$ZINIT_DIR" ]; then
    rm -rf "$ZINIT_DIR"
    echo -e "${GREEN}✔ Plugin data removed.${NC}"
fi

# -----------------------------------------------------------------------------
# 3. OPTIONAL: REMOVE BINARIES
# -----------------------------------------------------------------------------
if [ "$CI_ENV" != "true" ]; then
    if [ ! -t 0 ]; then exec < /dev/tty; fi

    echo -ne "${CYAN}Do you want to uninstall the CLI tools (eza, starship)? [y/N]: ${NC}"
    read -r REPLY_BINS
    if [[ "$REPLY_BINS" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}:: Removing binaries...${NC}"

        case $DISTRO in
            ubuntu|debian|pop|kali|linuxmint)
                export DEBIAN_FRONTEND=noninteractive
                sudo apt-get remove -qq -y eza starship > /dev/null 2>&1 || echo -e "${RED}! Some packages could not be removed via APT.${NC}"
                
                sudo rm -f /etc/apt/sources.list.d/gierens.list
                sudo rm -f /etc/apt/keyrings/gierens.gpg
                sudo apt-get update -qq -y > /dev/null 2>&1 || true
                ;;
            arch|manjaro|endeavouros)
                sudo pacman -Rs --noconfirm eza starship > /dev/null 2>&1 || echo -e "${RED}! Some packages could not be removed via Pacman.${NC}"
                ;;
            fedora|rhel|centos)
                sudo dnf remove -q -y eza starship > /dev/null 2>&1 || echo -e "${RED}! Some packages could not be removed via DNF.${NC}"
                ;;
            macos)
                brew uninstall -q eza starship > /dev/null 2>&1 || echo -e "${RED}! Some packages could not be removed via Brew.${NC}"
                ;;
        esac

        # Manual binary removal for custom paths
        for bin in /usr/local/bin/eza /usr/local/bin/starship; do
            if [ -f "$bin" ]; then
                sudo rm -f "$bin" || echo -e "${RED}✘ Failed to remove $bin${NC}"
            fi
        done
        
        echo -e "${GREEN}✔ Binary cleanup attempt complete.${NC}"
    fi
fi

# -----------------------------------------------------------------------------
# 4. OPTIONAL: REMOVE FONTS
# -----------------------------------------------------------------------------
if [ "$CI_ENV" != "true" ]; then
    echo -ne "${CYAN}Do you want to remove FiraCode Nerd Fonts? [y/N]: ${NC}"
    read -r REPLY_FONTS
    if [[ "$REPLY_FONTS" =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}:: Removing fonts...${NC}"
        
        FONT_DIR="$HOME/.local/share/fonts"
        [[ "$OS_TYPE" == "macos" ]] && FONT_DIR="$HOME/Library/Fonts"

        if ls "$FONT_DIR"/FiraCode* >/dev/null 2>&1; then
            rm -f "$FONT_DIR"/FiraCode*
            if [[ "$OS_TYPE" == "linux" ]] && command -v fc-cache >/dev/null 2>&1; then
                fc-cache -f -q "$FONT_DIR" > /dev/null 2>&1 || true
            fi
            echo -e "${GREEN}✔ Fonts removed.${NC}"
        else
            echo -e "${YELLOW}:: No FiraCode fonts found in $FONT_DIR.${NC}"
        fi
    fi
fi

# -----------------------------------------------------------------------------
# 5. FINALIZATION
# -----------------------------------------------------------------------------
echo -e "\n${GREEN}✔ Z-Shift has been successfully uninstalled.${NC}"
echo -e "${BLUE}Please restart your terminal session to apply all changes.${NC}"