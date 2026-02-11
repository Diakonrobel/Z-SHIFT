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
# Added OMZP::extract here
zinit wait lucid for \
    OMZP::extract \
    OMZP::sudo \
    OMZP::git \
    MichaelAquilina/zsh-you-should-use

# C) Zoxide (Smarter cd)
# Note: --cmd cd replaces the standard 'cd' command automatically
zinit ice wait lucid from"gh-r" as"program" \
    atload'eval "$(zoxide init zsh --cmd cd)"'
zinit light ajeetdsouza/zoxide

# D) TLDR (Tealdeer - Fast Rust version)
# Downloads binary, renames it to 'tldr', and adds to path
zinit ice wait lucid as"command" from"gh-r" \
    mv"tealdeer* -> tldr" \
    pick"tldr"
zinit light tealdeer-rs/tealdeer

# E) EZA (Smarter ls)
zinit ice wait lucid as"completion" \
    has"eza" \
    id-as"eza-completions" \
    atclone"cp completions/zsh/_eza _eza" \
    atpull"%atclone" \
    blockf
zinit light eza-community/eza

# F) Syntax Highlighting & Autosuggestions
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
# 'cd' is handled by zoxide (see Plugin section C)
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
# Update Zinit, clean cache, and update TLDR database
alias zup='zinit self-update && zinit update --parallel && zinit cclear && tldr --update'

# --- Eza (The ls replacement) ---
if command -v eza &> /dev/null; then
    alias ls='eza --icons --group-directories-first --git'
    alias l='eza -lh --icons --git --group-directories-first'
    alias ll='eza -l --icons --git --group-directories-first'
    alias la='eza -lah --icons --git --group-directories-first'
    alias lt='eza --tree --level=2 --icons'
else
    # Fallbacks if eza is missing
    alias ls='ls --color=auto'
    alias ll='ls -lah'
    alias lt='ls --tree --level=2'
fi

# --- The Modern Toolset (bat, rg, tldr) ---

# cat -> bat (using -pp to mimic plain cat behavior)
if command -v bat &> /dev/null; then
    alias cat='bat -pp'
elif command -v batcat &> /dev/null; then
    alias cat='batcat -pp'
fi

# grep -> rg
if command -v rg &> /dev/null; then
    alias grep='rg'
else
    alias grep='grep --color=auto'
fi

# Help Aliases
alias h='tldr'
alias hup='tldr --update'

# Smart Help Function
# Usage: 'help tar' -> Tries tldr first, falls back to man
help() {
    tldr "$@" || man "$@"
}

# =============================================================================
# 6. KEYBINDINGS
# =============================================================================
bindkey -e
bindkey '^[[A' up-line-or-search
bindkey '^[[B' down-line-or-search