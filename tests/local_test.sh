#!/bin/bash
# tests/local_test.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo "Running Z-Shift Local Tests (repo root: $REPO_ROOT)..."

# Check required files exist
REQUIRED_FILES=("install.sh" ".zshrc" "README.md" "theme.sh" "uninstall.sh")
for file in "${REQUIRED_FILES[@]}"; do
    if [ -f "$REPO_ROOT/$file" ]; then
        echo -e "[${GREEN}PASS${NC}] File $file exists"
    else
        echo -e "[${RED}FAIL${NC}] File $file missing"
        exit 1
    fi
done

# Zsh syntax check
if command -v zsh >/dev/null; then
    if zsh -n "$REPO_ROOT/.zshrc"; then
        echo -e "[${GREEN}PASS${NC}] .zshrc syntax is valid"
    else
        echo -e "[${RED}FAIL${NC}] .zshrc contains syntax errors"
        exit 1
    fi
else
    echo -e "[${RED}WARN${NC}] zsh not installed, skipping syntax check"
fi

# Shellcheck (Bash)
# from the repo root automatically, keeping rules in sync with CI.
if command -v shellcheck >/dev/null; then
    FAILED=0
    for script in install.sh theme.sh uninstall.sh; do
        if shellcheck "$REPO_ROOT/$script"; then
            echo -e "[${GREEN}PASS${NC}] $script passed shellcheck"
        else
            echo -e "[${RED}FAIL${NC}] $script failed shellcheck"
            FAILED=1
        fi
    done
    [ "$FAILED" -eq 1 ] && exit 1
else
    echo -e "[${RED}WARN${NC}] shellcheck not installed, skipping linting"
fi

echo "All local checks passed."