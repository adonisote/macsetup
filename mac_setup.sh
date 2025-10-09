#!/bin/bash
# Tells the system to run this script using bash

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




