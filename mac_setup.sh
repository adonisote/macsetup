#!/bin/bash
# Tells the system to run this script using bash

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

echo "🚀 Starting fully automated Mac setup..."

# ============================================
# ARM: Pre-load Homebrew into PATH if it
# exists but isn't on PATH yet.
# Handles the case where brew is already
# installed but the shell hasn't sourced
# ~/.zprofile yet (e.g. fresh terminal run).
# ============================================
if [[ $(uname -m) == 'arm64' ]] && [ -f /opt/homebrew/bin/brew ]; then
    eval "$(/opt/homebrew/bin/brew shellenv zsh)"
elif [ -f /usr/local/bin/brew ]; then
    eval "$(/usr/local/bin/brew shellenv zsh)"
fi


# ============================================
# XCODE COMMAND LINE TOOLS
# ============================================
echo "📦 Checking Xcode Command Line Tools..."

if ! xcode-select -p &> /dev/null; then
    xcode-select --install 2>/dev/null || true
    # '|| true' prevents set -e from killing the script
    # if the popup is already open or tools are mid-install

    echo "⏳ Waiting for Command Line Tools installation..."

    until xcode-select -p &> /dev/null; do
        sleep 5
    done

    echo "✅ Command Line Tools installed"
else
    echo "✅ Command Line Tools already installed"
fi


# ============================================
# HOMEBREW
# ============================================
echo "🍺 Checking Homebrew..."

if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew - you may be asked for your password..."

    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # NONINTERACTIVE=1 prevents the installer from asking questions

    if [[ $(uname -m) == 'arm64' ]]; then
        if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
            echo >> ~/.zprofile
            echo 'eval "$(/opt/homebrew/bin/brew shellenv zsh)"' >> ~/.zprofile
        fi
        eval "$(/opt/homebrew/bin/brew shellenv zsh)"
    else
        if ! grep -q 'brew shellenv' ~/.zprofile 2>/dev/null; then
            echo >> ~/.zprofile
            echo 'eval "$(/usr/local/bin/brew shellenv zsh)"' >> ~/.zprofile
        fi
        eval "$(/usr/local/bin/brew shellenv zsh)"
    fi

    echo "✅ Homebrew installed"
else
    echo "✅ Homebrew already installed ($(brew --version | head -1))"
fi


# ============================================
# BREWFILE
# ============================================
echo "📥 Installing packages from Brewfile..."

if [ ! -f ./Brewfile ]; then
    echo "❌ Error: Brewfile not found in current directory"
    echo "Make sure you're running this script from the same folder as your Brewfile."
    exit 1
fi

brew bundle --file=./Brewfile


# ============================================
# POST-INSTALLATION CONFIGURATION
# ============================================
echo ""
echo "⚙️  Configuring installed tools..."


# ── Starship ────────────────────────────────
if command -v starship &> /dev/null; then
    echo "🎨 Configuring Starship prompt..."
    if ! grep -q 'starship init zsh' ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
        echo "✅ Starship configured in ~/.zshrc"
    else
        echo "✅ Starship already configured"
    fi
fi


# ── fnm + Node.js ───────────────────────────
if command -v fnm &> /dev/null; then
    echo "📦 Configuring fnm..."
    if ! grep -q 'fnm env' ~/.zshrc 2>/dev/null; then
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
        echo "✅ fnm configured in ~/.zshrc"
    else
        echo "✅ fnm already configured"
    fi

    # Load fnm for this session
    eval "$(fnm env --use-on-cd)"

    echo "📦 Installing Node.js LTS..."
    fnm install --lts

    # Get the actual installed LTS version and set it as default
    LTS_VERSION=$(fnm list | grep lts | tail -1 | awk '{print $2}')
    fnm default "$LTS_VERSION"

    echo "✅ Node.js $(node -v) installed and set as default"
fi


# ── Python (uv) ─────────────────────────────
if command -v uv &> /dev/null; then
    echo "🐍 Installing latest Python via uv..."
    uv python install
    # uv automatically makes the installed version available

    # Add uv's bin dir to PATH (uses $HOME, not hardcoded username)
    if ! grep -q '\.local/bin' ~/.zshrc 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc
        echo "✅ Python PATH configured in ~/.zshrc"
    fi

    export PATH="$HOME/.local/bin:$PATH"

    PYTHON_VERSION=$(uv run python --version 2>&1 | awk '{print $2}')
    echo "✅ Python $PYTHON_VERSION installed"
fi


# ── fzf keybindings ─────────────────────────
if command -v fzf &> /dev/null; then
    echo "🔍 Configuring fzf keybindings..."
    if ! grep -q 'fzf --zsh' ~/.zshrc 2>/dev/null; then
        echo 'source <(fzf --zsh)' >> ~/.zshrc
        echo "✅ fzf configured in ~/.zshrc"
    else
        echo "✅ fzf already configured"
    fi
fi


# ── Colima (Docker runtime) ─────────────────
if command -v colima &> /dev/null; then
    echo "🐳 Starting Colima..."
    if ! colima status &> /dev/null 2>&1; then
        colima start --cpu 4 --memory 8 --disk 60
        echo "✅ Colima started (4 CPU, 8GB RAM, 60GB disk)"
    else
        echo "✅ Colima already running"
    fi
fi


# ── Docker CLI plugins (buildx, compose) ────
# Homebrew's docker-buildx/docker-compose formulas install standalone
# binaries; Docker only picks them up as `docker buildx`/`docker compose`
# subcommands if they're symlinked into ~/.docker/cli-plugins/.
mkdir -p ~/.docker/cli-plugins

if command -v docker-buildx &> /dev/null; then
    echo "🐳 Linking docker-buildx as a Docker CLI plugin..."
    if [ ! -e ~/.docker/cli-plugins/docker-buildx ]; then
        ln -sfn "$(command -v docker-buildx)" ~/.docker/cli-plugins/docker-buildx
        echo "✅ docker-buildx linked into ~/.docker/cli-plugins/"
    else
        echo "✅ docker-buildx already linked"
    fi
fi

if command -v docker-compose &> /dev/null; then
    echo "🐳 Linking docker-compose as a Docker CLI plugin..."
    if [ ! -e ~/.docker/cli-plugins/docker-compose ]; then
        ln -sfn "$(command -v docker-compose)" ~/.docker/cli-plugins/docker-compose
        echo "✅ docker-compose linked into ~/.docker/cli-plugins/"
    else
        echo "✅ docker-compose already linked"
    fi
fi


# ── GitHub CLI hint ─────────────────────────
if command -v gh &> /dev/null; then
    echo ""
    echo "💡 Tip: Authenticate with GitHub CLI by running: gh auth login"
fi


# ============================================
# DONE
# ============================================
echo ""
echo "✨ Setup complete!"
echo ""
echo "📝 Manual steps remaining:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Set your terminal font to 'JetBrainsMono Nerd Font':"
echo "     • iTerm2:  Settings → Profiles → Text → Font"
echo "     • VS Code: settings.json → \"terminal.integrated.fontFamily\": \"JetBrainsMono Nerd Font\""
echo "     • VS Code: settings.json → \"editor.fontFamily\": \"JetBrainsMono Nerd Font\""
echo "  3. Authenticate with GitHub: gh auth login"
echo ""
echo "📊 After restarting terminal, verify:"
echo "  node --version"
echo "  python --version"
echo "  docker --version"
echo "  starship --version"
echo ""
echo "🎉 Your Mac is ready for development!"