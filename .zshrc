# =============================================================================
# 1. ZINIT INSTALLER
# =============================================================================
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi
source "${ZINIT_HOME}/zinit.zsh"

# =============================================================================
# 2. LOAD STARSHIP PROMPT
# =============================================================================
zinit ice as"command" from"gh-r" \
          atclone"./starship init zsh > init.zsh; ./starship completions zsh > _starship" \
          atpull"%atclone" \
          src"init.zsh" \
          pick"starship"
zinit light starship/starship

# =============================================================================
# 3. PLUGINS
# =============================================================================

# A) OMZ Libraries
zinit wait lucid for \
    OMZL::git.zsh \
    OMZL::history.zsh \
    OMZL::directories.zsh \
    OMZL::completion.zsh \
    OMZL::clipboard.zsh

# B) Utilities
zinit wait lucid for \
    OMZP::extract \
    OMZP::sudo \
    OMZP::git \
    MichaelAquilina/zsh-you-should-use

# --- BAT (Cat replacement) ---
zinit ice as"program" from"gh-r" mv"bat* -> bat" pick"bat/bat" wait lucid
zinit light sharkdp/bat

# --- EZA (Smarter ls) Completions from Release Assets
zinit ice wait lucid as"completion" \
    from"gh-r" \
    has"eza" \
    id-as"eza-completions" \
    bpick"completions*" \
    pick"zsh/_eza" \
    blockf
zinit light eza-community/eza

# --- FD (Find replacement) ---
# Installs 'fd' binary (fixes 'fdfind' name issue on Debian)
zinit ice as"program" from"gh-r" mv"fd* -> fd" pick"fd/fd" wait lucid
zinit light sharkdp/fd

# --- FZF (Fuzzy Finder) ---
# Integated with fd for respect of .gitignore
zinit ice as"program" from"gh-r" wait lucid \
    atload'source <(fzf --zsh); export FZF_DEFAULT_COMMAND="fd --type f --strip-cwd-prefix --hidden --follow --exclude .git"; export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"'
zinit light junegunn/fzf

# --- RIPGREP (Grep replacement) ---
zinit ice as"program" from"gh-r" mv"ripgrep* -> ripgrep" pick"ripgrep/rg" wait lucid
zinit light BurntSushi/ripgrep

# --- TLDR (Tealdeer - Fast Rust version)
zinit ice wait lucid as"command" from"gh-r" \
    mv"tealdeer* -> tldr" \
    pick"tldr"
zinit light tealdeer-rs/tealdeer

# --- Zoxide (Smarter cd)
zinit ice wait lucid from"gh-r" as"program" \
    atload'eval "$(zoxide init zsh --cmd cd)"'
zinit light ajeetdsouza/zoxide

# C) Syntax Highlighting & Autosuggestions
zinit wait lucid for \
    atinit"zicompinit; zicdreplay" \
        zdharma-continuum/fast-syntax-highlighting \
    atload"_zsh_autosuggest_start" \
        zsh-users/zsh-autosuggestions \
    blockf \
        zsh-users/zsh-completions

# =============================================================================
# 4. CONFIGURATION
# =============================================================================
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_DUPS
setopt HIST_EXPIRE_DUPS_FIRST
setopt SHARE_HISTORY
setopt AUTO_CD

# =============================================================================
# 5. ALIASES & FUNCTIONS
# =============================================================================

# --- Navigation ---
alias -- -='cd -'
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias md='mkdir -p'

# --- Quick Edits ---
alias zconf='nano ~/.zshrc'
alias sconf='nano ~/.config/starship.toml'
alias reload='source ~/.zshrc'

# --- Zinit & Maintenance ---
alias zini='zinit'
alias zup='zinit self-update && zinit update --parallel && zinit cclear && tldr --update'
alias zclean='zinit cclear && zinit delete --clean'

# --- Eza (The ls replacement) ---
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first --git'
    alias l='eza -lh --icons --git --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -lah --icons --git --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
else
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias lt='ls --tree --level=2'
fi

# --- The Modern Toolset ---
alias cat='bat -pp'
alias grep='rg'
alias find='fd' 

# Help Aliases
alias h='tldr'
alias hup='tldr --update'

# Smart Help Function
help() {
    tldr "$@" || man "$@"
}

# =============================================================================
# 6. KEYBINDINGS
# =============================================================================
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search

# =============================================================================
# Z-SHIFT SELF-MAINTENANCE
# =============================================================================

# --- Z-Shift Self-Updater ---
zshift-update() {
    local DATE_STAMP BACKUP_FILE TEMP_ZSHRC UPDATE_URL
    DATE_STAMP=$(date +%Y%m%d_%H%M%S)
    BACKUP_FILE="$HOME/.zshrc.zshift_${DATE_STAMP}.bak"
    TEMP_ZSHRC="$(mktemp)"
    UPDATE_URL="https://raw.githubusercontent.com/0xdilshan/Z-SHIFT/main/.zshrc"

    echo -e "${BLUE}:: Initiating Z-Shift Update...${NC}"

    if ! curl -fsSL -o "$TEMP_ZSHRC" "$UPDATE_URL"; then
        echo -e "${RED}Error: Failed to download update. Check your connection.${NC}"
        rm -f "$TEMP_ZSHRC"
        return 1
    fi

    # Validation: Ensure it's a real Z-Shift file and not a redirect/HTML
    if ! grep -q "ZINIT_INSTALLER" "$TEMP_ZSHRC"; then
        echo -e "${RED}Error: Downloaded file is invalid (Integrity Check Failed).${NC}"
        rm -f "$TEMP_ZSHRC"
        return 1
    fi

    if [ -f "$HOME/.zshrc" ]; then
        echo -e "${YELLOW}:: Backing up current config to: ${NC}$BACKUP_FILE"
        cp "$HOME/.zshrc" "$BACKUP_FILE"
    fi

    mv "$TEMP_ZSHRC" "$HOME/.zshrc"
    echo -e "${GREEN}:: Configuration file updated.${NC}"

    if command -v zinit >/dev/null 2>&1; then
        echo -e "${BLUE}:: Updating Zinit and Plugins...${NC}"
        # We run this in a subshell to prevent Zinit from killing the current function on error
        if ! (zinit self-update && zinit update --parallel); then
            echo -e "${RED}!! Plugin update failed. Rolling back configuration...${NC}"
            if [ -f "$BACKUP_FILE" ]; then
                mv "$BACKUP_FILE" "$HOME/.zshrc"
                echo -e "${YELLOW}:: Original .zshrc restored.${NC}"
            fi
            return 1
        fi
    fi

    echo -e "\n${GREEN}✔ Z-Shift Update Complete! Restarting shell...${NC}"
    # Refresh the shell to apply all changes instantly
    exec zsh
}

# =============================================================================
# LOCAL CUSTOMIZATIONS
# =============================================================================
# This allows users to add private/custom aliases in ~/.zshrc.local 
# without them being wiped out by the 'zshift-update' command.
if [ -f "$HOME/.zshrc.local" ]; then
    source "$HOME/.zshrc.local"
fi