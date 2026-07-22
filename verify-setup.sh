#!/bin/bash

# ===========================================
# Dev Setup Verification Script
# Run this after brew bundle to check what
# is installed AND properly configured.
# Usage: bash verify-setup.sh
# ===========================================

PASS="✅"
FAIL="❌"
WARN="⚠️ "

pass() { echo "  $PASS $1"; }
fail() { echo "  $FAIL $1"; }
warn() { echo "  $WARN $1"; }
header() { echo ""; echo "── $1 ──────────────────────────────"; }

echo ""
echo "╔══════════════════════════════════════╗"
echo "║       Dev Setup Verification         ║"
echo "╚══════════════════════════════════════╝"

# ─────────────────────────────────────────
header "CLI TOOLS (installed?)"
# ─────────────────────────────────────────

tools=(wget tree jq yq rg bat eza fzf tldr btop mas gh nvim starship fnm uv docker docker-compose colima kubectl helm terraform)

for tool in "${tools[@]}"; do
  if command -v "$tool" &>/dev/null; then
    pass "$tool"
  else
    fail "$tool — not found (brew install $tool)"
  fi
done

# ─────────────────────────────────────────
header "SHELL CONFIG (~/.zshrc)"
# ─────────────────────────────────────────

ZSHRC="$HOME/.zshrc"

if [ ! -f "$ZSHRC" ]; then
  fail "~/.zshrc does not exist"
else
  # Starship
  if grep -q "starship init zsh" "$ZSHRC"; then
    pass "starship init is in ~/.zshrc"
  else
    fail "starship init missing — add: eval \"\$(starship init zsh)\""
  fi

  # fnm
  if grep -q "fnm env" "$ZSHRC"; then
    pass "fnm env is in ~/.zshrc"
  else
    fail "fnm env missing — add: eval \"\$(fnm env --use-on-cd)\""
  fi

  # fzf (modern style — source <(fzf --zsh))
  if grep -q "fzf --zsh" "$ZSHRC"; then
    pass "fzf keybindings in ~/.zshrc"
  else
    warn "fzf keybindings not set — add: source <(fzf --zsh)"
  fi

  # eza aliases
  if grep -q "eza" "$ZSHRC"; then
    pass "eza alias found in ~/.zshrc"
  else
    warn "no eza alias — add: alias ls=\"eza --icons\" to ~/.zshrc"
  fi
fi

# ─────────────────────────────────────────
header "GIT CONFIGURATION"
# ─────────────────────────────────────────

GIT_NAME=$(git config --global user.name 2>/dev/null || echo "")
GIT_EMAIL=$(git config --global user.email 2>/dev/null || echo "")
GIT_EDITOR=$(git config --global core.editor 2>/dev/null || echo "")

if [ -n "$GIT_NAME" ]; then
  pass "git user.name = \"$GIT_NAME\""
else
  fail "git user.name not set — run: git config --global user.name \"Your Name\""
fi

if [ -n "$GIT_EMAIL" ]; then
  pass "git user.email = \"$GIT_EMAIL\""
else
  fail "git user.email not set — run: git config --global user.email \"you@example.com\""
fi

if [ -n "$GIT_EDITOR" ]; then
  pass "git core.editor = \"$GIT_EDITOR\""
else
  warn "git core.editor not set — run: git config --global core.editor \"code --wait\""
fi

# ─────────────────────────────────────────
header "NODE (fnm)"
# ─────────────────────────────────────────

if command -v fnm &>/dev/null; then
  NODE_VER=$(fnm current 2>/dev/null)
  if [ -n "$NODE_VER" ] && [ "$NODE_VER" != "none" ]; then
    pass "Node active via fnm: $NODE_VER"
  else
    fail "fnm installed but no Node version active — run: fnm install --lts && fnm use lts-latest"
  fi
else
  fail "fnm not found"
fi

# ─────────────────────────────────────────
header "PYTHON (uv)"
# ─────────────────────────────────────────

if command -v uv &>/dev/null; then
  PYTHON_VER=$(uv run python --version 2>/dev/null | awk '{print $2}')
  if [ -n "$PYTHON_VER" ]; then
    pass "Python $PYTHON_VER available via uv"
  else
    fail "uv installed but no Python version found — run: uv python install"
  fi
else
  fail "uv not found"
fi

# ─────────────────────────────────────────
header "DOCKER / COLIMA"
# ─────────────────────────────────────────

if command -v colima &>/dev/null; then
  COLIMA_STATUS=$(colima status 2>&1)
  if echo "$COLIMA_STATUS" | grep -q "running"; then
    pass "colima is running"
    # Only check docker daemon if colima is up
    if docker info &>/dev/null 2>&1; then
      pass "docker daemon is reachable"
    else
      warn "colima running but docker not responding — try: colima stop && colima start"
    fi
  else
    warn "colima is not running (this is fine — start it when you need Docker: colima start)"
  fi
else
  fail "colima not found"
fi

# ─────────────────────────────────────────
header "FONTS"
# ─────────────────────────────────────────

# Use system_profiler on macOS (fc-list is Linux only)
if system_profiler SPFontsDataType 2>/dev/null | grep -qi "JetBrainsMono"; then
  pass "JetBrains Mono Nerd Font installed"
else
  fail "JetBrains Mono Nerd Font not found — run: brew install --cask font-jetbrains-mono-nerd-font"
fi

if system_profiler SPFontsDataType 2>/dev/null | grep -qi "FiraCode"; then
  pass "Fira Code Nerd Font installed"
else
  fail "Fira Code Nerd Font not found — run: brew install --cask font-fira-code-nerd-font"
fi

# ─────────────────────────────────────────
header "GUI APPS (casks)"
# ─────────────────────────────────────────

check_app() {
  local name="$1"
  local path="$2"
  if [ -d "$path" ]; then
    pass "$name"
  else
    fail "$name not found at $path"
  fi
}

check_app "Visual Studio Code"  "/Applications/Visual Studio Code.app"
check_app "iTerm2"              "/Applications/iTerm.app"
check_app "Raycast"             "/Applications/Raycast.app"
check_app "Rectangle"           "/Applications/Rectangle.app"
check_app "AppCleaner"          "/Applications/AppCleaner.app"
check_app "The Unarchiver"      "/Applications/The Unarchiver.app"
check_app "Notion"              "/Applications/Notion.app"
check_app "Postman"             "/Applications/Postman.app"
check_app "Insomnia"            "/Applications/Insomnia.app"
check_app "Brave Browser"       "/Applications/Brave Browser.app"
check_app "Figma"               "/Applications/Figma.app"

# ─────────────────────────────────────────
echo ""
echo "══════════════════════════════════════"
echo "  Done. Fix any ❌ items above."
echo "  ⚠️  items work but aren't fully set up."
echo "══════════════════════════════════════"
echo ""
