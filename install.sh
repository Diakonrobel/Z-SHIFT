#!/bin/bash

# =============================================================================
#  ███████╗      ███████╗██╗  ██╗██╗███████╗████████╗
#  ╚══███╔╝      ██╔════╝██║  ██║██║██╔════╝╚══██╔══╝
#    ███╔╝ █████╗███████╗███████║██║█████╗     ██║   
#   ███╔╝  ╚════╝╚════██║██╔══██║██║██╔══╝     ██║   
#  ███████╗      ███████╗██║  ██║██║██║        ██║   
#  ╚══════╝      ╚══════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   
# =============================================================================
#  Z-SHIFT: High-Performance Zsh + Starship + Zinit installation script
# =============================================================================

# Exit immediately if a command exits with a non-zero status
set -e

# --- GLOBAL VARIABLES & CLEANUP TRAP ---
TEMP_DIR=""

cleanup() {
    # This runs automatically on script exit, interruption, or termination
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

# --- CONFIGURATION ---
ZSHRC_URL="${ZSHIFT_CUSTOM_URL:-https://raw.githubusercontent.com/0xdilshan/Z-SHIFT/main/.zshrc}"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${CYAN}>>> Initiating Z-Shift Environment Deployment...${NC}"

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

# Helper function to install packages silently based on distro
install_pkg() {
    local pkgs=("$@")
    echo -e "${YELLOW}Installing: ${pkgs[*]}...${NC}"

    case $DISTRO in
        ubuntu|debian|pop|kali|linuxmint)
            export DEBIAN_FRONTEND=noninteractive
            sudo apt-get update -qq -y > /dev/null
            sudo apt-get install -qq -y "${pkgs[@]}" > /dev/null
            ;;
        arch|manjaro|endeavouros)
            sudo pacman -Sy --quiet --noconfirm --needed "${pkgs[@]}" > /dev/null
            ;;
        fedora|rhel|centos)
            sudo dnf install -q -y "${pkgs[@]}" > /dev/null
            ;;
        opensuse*|suse)
            sudo zypper install -q -y "${pkgs[@]}" > /dev/null
            ;;
        macos)
            brew install -q "${pkgs[@]}" > /dev/null
            ;;
        *)
            echo -e "${RED}Unsupported distribution: $DISTRO${NC}"
            exit 1
            ;;
    esac
}

# =============================================================================
# 1. PRE-REQUISITES (Homebrew for MacOS)
# =============================================================================
if [[ "$OS_TYPE" == "macos" ]]; then
    if ! command -v brew &> /dev/null; then
        echo -e "${YELLOW}Homebrew not found. Installing Homebrew (this may take a while)...${NC}"
        # Silencing homebrew installation logs but keeping stderr
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" > /dev/null
        
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        elif [ -f "/usr/local/bin/brew" ]; then
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
fi

# =============================================================================
# 2. SYSTEM DEPENDENCIES
# =============================================================================
echo -e "${YELLOW}Installing base dependencies...${NC}"

# Define dependencies as an array to prevent word-splitting issues
COMMON_DEPS=(git curl unzip zsh)

if [[ "$OS_TYPE" == "macos" ]]; then
    install_pkg git curl wget unzip zsh
else
    # Linux specific checks: using 'gnupg' for cross-distro compatibility
    install_pkg wget gnupg "${COMMON_DEPS[@]}"
fi

# =============================================================================
# 3. INSTALL STANDALONE TOOLS (Eza)
# =============================================================================
echo -e "${YELLOW}Installing Eza (ls replacement)...${NC}"

if command -v eza &> /dev/null; then
    echo -e "${GREEN}:: Eza is already installed. Skipping.${NC}"
else
    case "$DISTRO" in
        ubuntu|debian|pop|kali|linuxmint)
            export DEBIAN_FRONTEND=noninteractive
            sudo mkdir -p /etc/apt/keyrings
            wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
                | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg > /dev/null 2>&1 || true

            echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
                | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null

            sudo chmod 644 /etc/apt/keyrings/gierens.gpg \
                /etc/apt/sources.list.d/gierens.list

            sudo apt-get update -qq -y > /dev/null && sudo apt-get install -qq -y eza > /dev/null
            ;;

        fedora)
            FEDORA_VERSION=$(rpm -E %fedora)

            if [ "$FEDORA_VERSION" -ge 42 ]; then
                echo -e "${YELLOW}:: Fedora $FEDORA_VERSION detected. Downloading binary...${NC}"

                ARCH=$(uname -m)
                case "$ARCH" in
                    x86_64)  BINARY_ARCH="x86_64-unknown-linux-gnu" ;;
                    aarch64) BINARY_ARCH="aarch64-unknown-linux-gnu" ;;
                    armv7l)  BINARY_ARCH="arm-unknown-linux-gnueabihf" ;;
                    *)
                        echo -e "${RED}Unsupported arch: $ARCH${NC}"
                        exit 1
                        ;;
                esac

                FILENAME="eza_${BINARY_ARCH}.tar.gz"
                URL="https://github.com/eza-community/eza/releases/latest/download/${FILENAME}"

                # Download silently (-sS) and extract
                curl -sSL "$URL" | tar -xz -C /tmp

                if [ -f "/tmp/eza" ]; then
                    sudo mv /tmp/eza /usr/local/bin/eza
                    sudo chmod +x /usr/local/bin/eza
                    echo -e "${GREEN}:: eza installed successfully to /usr/local/bin/eza${NC}"
                else
                    echo -e "${RED}Error: Binary 'eza' not found in archive.${NC}"
                    exit 1
                fi
            else
                sudo dnf install -q -y eza > /dev/null
            fi
            ;;

        *)
            install_pkg eza
            ;;
    esac
fi

# =============================================================================
# 4. CONFIGURATION (Themes & Starship)
# =============================================================================
echo -e "${YELLOW}Setting up Configuration...${NC}"

# --- Prepare Directories ---
rm -rf ~/.config/eza-themes
# Clone silently
git clone --quiet https://github.com/eza-community/eza-themes.git ~/.config/eza-themes > /dev/null 2>&1
mkdir -p ~/.config/eza
mkdir -p ~/.config

# --- Install Starship Binary if missing ---
if ! command -v starship &> /dev/null; then
    if [[ "$OS_TYPE" == "macos" ]]; then
        install_pkg starship
    else
        # Install starship silently
        curl -sS https://starship.rs/install.sh | sh -s -- -y > /dev/null
    fi
fi

# --- Theme Arrays ---
STARSHIP_THEMES=(
    "gruvbox-rainbow" "nerd-font-symbols" "no-nerd-font"
    "bracketed-segments" "plain-text-symbols" "no-runtime-versions"
    "no-empty-icons" "pure-preset" "pastel-powerline"
    "tokyo-night" "jetpack" "catppuccin-powerline"
)

EZA_THEMES=(
    "gruvbox-dark.yml" "black.yml" "catppuccin-frappe.yml"
    "catppuccin-latte.yml" "catppuccin-macchiato.yml" "catppuccin-mocha.yml"
    "default.yml" "dracula.yml" "frosty.yml" "gruvbox-light.yml"
    "one_dark.yml" "rose-pine-dawn.yml" "rose-pine-moon.yml"
    "rose-pine.yml" "solarized-dark.yml" "tokyonight.yml" "white.yml"
)

# --- Interactive Menu Logic ---
SELECTED_STARSHIP="gruvbox-rainbow"
SELECTED_EZA="gruvbox-dark.yml"

if [ "$CI_ENV" != "true" ]; then
    if [ ! -t 0 ]; then
        exec < /dev/tty
    fi

    echo -e "\n${CYAN}::: THEME SELECTION :::${NC}"
    echo "1) Default (Starship: Gruvbox-Rainbow | Eza: Gruvbox-Dark)"
    echo "2) Custom Selection"
    echo -ne "${YELLOW}Select option [1-2] (default: 1): ${NC}"
    read -r THEME_OPT

    if [[ "$THEME_OPT" == "2" ]]; then
        echo -e "\n${BLUE}:: Select Starship Prompt Theme ::${NC}"
        PS3="Enter number (1-${#STARSHIP_THEMES[@]}): "
        select s_theme in "${STARSHIP_THEMES[@]}"; do
            if [[ -n "$s_theme" ]]; then
                SELECTED_STARSHIP="$s_theme"
                break
            else
                echo -e "${RED}Invalid selection. Try again.${NC}"
            fi
        done

        echo -e "\n${BLUE}:: Select Eza (ls) Theme ::${NC}"
        PS3="Enter number (1-${#EZA_THEMES[@]}): "
        select e_theme in "${EZA_THEMES[@]}"; do
            if [[ -n "$e_theme" ]]; then
                SELECTED_EZA="$e_theme"
                break
            else
                echo -e "${RED}Invalid selection. Try again.${NC}"
            fi
        done
    else
        echo -e "${GREEN}>> Using Default Themes.${NC}"
    fi
fi

# --- Apply Configuration ---
echo -e "${YELLOW}Applying Starship Preset: ${SELECTED_STARSHIP}...${NC}"
starship preset "$SELECTED_STARSHIP" -o ~/.config/starship.toml > /dev/null 2>&1 || \
    echo -e "${RED}Warning: Failed to load preset '$SELECTED_STARSHIP'. Check starship version.${NC}"

echo -e "${YELLOW}Applying Eza Theme: ${SELECTED_EZA}...${NC}"
ln -sf "$HOME/.config/eza-themes/themes/${SELECTED_EZA}" "$HOME/.config/eza/theme.yml"

# =============================================================================
# 5. FONTS (FiraCode Nerd Font)
# =============================================================================
if [ "$CI_ENV" = "true" ]; then
    echo -e "${YELLOW}>> CI Environment detected. Skipping Font Installation.${NC}"
else
    if [ ! -t 0 ]; then
        exec < /dev/tty
    fi

    echo -e "\n${CYAN}::: FONT INSTALLATION :::${NC}"
    echo -ne "${YELLOW}Install FiraCode Nerd Font? [Y/n] (default: Y): ${NC}"
    read -r FONT_OPT

    if [[ "$FONT_OPT" =~ ^[Nn]$ ]]; then
        echo -e "${BLUE}>> Skipping Font Installation.${NC}"
    else
        echo -e "${YELLOW}Installing FiraCode Nerd Font...${NC}"
        
        if [[ "$OS_TYPE" == "macos" ]]; then
            FONT_DIR="$HOME/Library/Fonts"
        else
            FONT_DIR="$HOME/.local/share/fonts"
        fi
        
        mkdir -p "$FONT_DIR"
        TEMP_DIR=$(mktemp -d)

        # Removed --show-progress to prevent progress bar spam, replacing it with quiet download
        wget -q -O "$TEMP_DIR/FiraCode.zip" "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
        unzip -q "$TEMP_DIR/FiraCode.zip" -d "$TEMP_DIR"
        find "$TEMP_DIR" -name "*.ttf" -exec mv -f {} "$FONT_DIR/" \; 2>/dev/null || true
        
        # Immediate cleanup via explicit call (Trap will also handle this if it fails before this line)
        [ -n "$TEMP_DIR" ] && rm -rf "$TEMP_DIR" && TEMP_DIR=""
        
        if [[ "$OS_TYPE" == "linux" ]] && command -v fc-cache &> /dev/null; then
            fc-cache -f -q "$FONT_DIR" > /dev/null 2>&1
        fi
        echo -e "${GREEN}✔ Font installation complete.${NC}"
    fi
fi

# =============================================================================
# 6. DOWNLOAD .ZSHRC
# =============================================================================
echo -e "${YELLOW}Downloading .zshrc from GitHub...${NC}"
[ -f ~/.zshrc ] && mv ~/.zshrc ~/.zshrc.bak

if curl -fsSL -o ~/.zshrc "$ZSHRC_URL"; then
    echo -e "${GREEN}Downloaded .zshrc successfully.${NC}"
else
    echo -e "${RED}Failed to download .zshrc!${NC}"
    [ -f ~/.zshrc.bak ] && mv ~/.zshrc.bak ~/.zshrc
    exit 1
fi

# =============================================================================
# 7. FINALIZE
# =============================================================================
ZSH_PATH=$(command -v zsh)

if [ "$CI_ENV" = "true" ]; then
    echo -e "\n${GREEN}✔ CI Environment detected. Installation Verified!${NC}"
    exit 0
fi

if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells > /dev/null
fi

if [ "$SHELL" != "$ZSH_PATH" ]; then
    if [[ "$OS_TYPE" == "macos" ]]; then
        chsh -s "$ZSH_PATH" > /dev/null 2>&1
    else
        sudo usermod --shell "$ZSH_PATH" "$USER" > /dev/null 2>&1 || chsh -s "$ZSH_PATH" > /dev/null 2>&1
    fi
fi

echo -e "\n${GREEN}✔ Z-Shift Installation Complete! Please restart your terminal.${NC}"