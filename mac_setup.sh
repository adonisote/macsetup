#!/bin/bash
# Tells the system to run this script using bash

set -e  # Exit on error
set -u  # Exit on undefined variable
set -o pipefail  # Exit on pipe failure

echo "🚀 Starting fully automated Mac setup..."
# Print a message to the screen

# Install Xcode Command Line Tools (non-interactive)
echo "📦 Installing Xcode Command Line Tools..."

if ! xcode-select -p &> /dev/null; then
# Check if Command Line Tools are NOT installed
# 'xcode-select -p' checks if tools exist
# '!' means NOT (reverses the result)
# '&> /dev/null' hides all output
# Together: "if tools are NOT installed, then..."

    xcode-select --install
    # Trigger the installation popup
    
    echo "⏳ Waiting for Command Line Tools installation..."
    
    until xcode-select -p &> /dev/null; do
    # Loop until tools are installed (keep checking every 5 seconds)
    
        sleep 5
        # Wait 5 seconds before checking again
        
    done
    
    echo "✅ Command Line Tools installed"
    
else
# If tools are already installed
    echo "✅ Command Line Tools already installed"
fi

# Install Homebrew (non-interactive)
echo "🍺 Installing Homebrew..."

if ! command -v brew &> /dev/null; then
# Check if brew command does NOT exist
# 'command -v brew' checks if brew is available
# '!' means NOT
# Together: "if brew is NOT installed, then..."

    echo "Installing Homebrew - you'll be asked for your password to allow the installation" 

    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Download and run Homebrew installer without prompts
    # 'NONINTERACTIVE=1' tells installer not to ask questions
    # 'curl -fsSL' downloads the installer script
    # '$()' runs the downloaded script
    
    if [[ $(uname -m) == 'arm64' ]]; then
    	# Apple Silicon - add to PATH if not already there
    	if ! grep -q 'eval "$(/opt/homebrew/bin/brew shellenv)"' ~/.zprofile 2>/dev/null; then
        echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
    	fi
    	eval "$(/opt/homebrew/bin/brew shellenv)"
    else
    	# Intel Mac - add to PATH if not already there
    	if ! grep -q 'eval "$(/usr/local/bin/brew shellenv)"' ~/.zprofile 2>/dev/null; then
        	echo 'eval "$(/usr/local/bin/brew shellenv)"' >> ~/.zprofile
    	fi
    	eval "$(/usr/local/bin/brew shellenv)"
    fi


    
    echo "✅ Homebrew installed"
    
else
    echo "✅ Homebrew already installed"
fi


# Install packages from Brewfile
echo "📥 Installing packages from Brewfile..."
# Before brew bundle line (line 87), add:
if [ ! -f ~/Brewfile ]; then
    echo "❌ Error: Brewfile not found at ~/Brewfile"
    echo "Please create a Brewfile first."
    exit 1
fi


brew bundle --file=~/Brewfile
# Read Brewfile from home directory and install all listed apps
# '~' means your home folder
# '--file=' specifies which Brewfile to use

# ============================================
# POST-INSTALLATION CONFIGURATION
# ============================================
echo ""
echo "⚙️  Configuring installed tools..."

# Configure Starship
if command -v starship &> /dev/null; then
    echo "🎨 Configuring Starship prompt..."
    
    # Add to .zshrc if not already present
    if ! grep -q 'starship init zsh' ~/.zshrc 2>/dev/null; then
        echo 'eval "$(starship init zsh)"' >> ~/.zshrc
        echo "✅ Starship configured in ~/.zshrc"
    else
        echo "✅ Starship already configured"
    fi
fi


# Configure fnm and install Node.js
if command -v fnm &> /dev/null; then
    echo "📦 Configuring fnm..."
    if ! grep -q 'fnm env' ~/.zshrc 2>/dev/null; then
        echo 'eval "$(fnm env --use-on-cd)"' >> ~/.zshrc
        echo "✅ fnm configured"
    else
        echo "✅ fnm already configured"
    fi
    
    # Source fnm for current session
    eval "$(fnm env --use-on-cd)"
    
    # Install latest LTS Node.js
    echo "📦 Installing Node.js LTS..."
    fnm install --lts
    fnm default lts-latest
    echo "✅ Node.js $(node -v) installed"
fi

# Install Python with uv
if command -v uv &> /dev/null; then
    echo "🐍 Installing latest Python..."
    uv python install --default
    # Use python --version instead of parsing uv output
    PYTHON_VERSION=$(python --version 2>&1 | awk '{print $2}')
    echo "✅ Python $PYTHON_VERSION installed and set as default"
fi


# Configure fzf keybindings
if command -v fzf &> /dev/null; then
    echo "🔍 Configuring fzf keybindings..."
    if ! grep -q 'fzf --zsh' ~/.zshrc 2>/dev/null; then
        echo 'source <(fzf --zsh)' >> ~/.zshrc
        echo "✅ fzf configured"
    else
        echo "✅ fzf already configured"
    fi
fi


# Start Colima
if command -v colima &> /dev/null; then
    echo "🐳 Starting Colima..."
    if ! colima status &> /dev/null; then
        colima start --cpu 4 --memory 8 --disk 60
        echo "✅ Colima started (4 CPU, 8GB RAM, 60GB disk)"
    else
        echo "✅ Colima already running"
    fi
fi


# Prompt for GitHub CLI authentication
if command -v gh &> /dev/null; then
    echo ""
    echo "💡 Tip: Authenticate with GitHub CLI by running: gh auth login"
fi



# ============================================
# FINAL STEPS
# ============================================
echo ""
echo "✨ Setup complete!"
echo ""
echo "📝 Manual steps remaining:"
echo "  1. Restart your terminal or run: source ~/.zshrc"
echo "  2. Set terminal font to 'JetBrainsMono Nerd Font':"
echo "     • iTerm2: Preferences → Profiles → Text → Font"
echo "     • VS Code: Add to settings.json:"
echo "       \"terminal.integrated.fontFamily\": \"JetBrainsMono Nerd Font\""
echo "  3. Authenticate with GitHub: gh auth login"
echo ""
echo "📊 Installed versions:"
echo "  Run: node --version"
echo "  Run: python --version"
echo ""
echo "🎉 Your Mac is ready for development!"
