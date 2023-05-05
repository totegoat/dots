#!/bin/bash

#-----------------------------------------------------------------------------#
# toter.sh (github.com/totegoat/toter)
#
# This script utilizes Git to easily bootstrap a fresh system with or 
# replicate dotfiles across multiple hosts or containers.
#
# - Symlinks are used for local dotfiles so that changes can be immediately 
#   registered in Git.
# 
# - Packages are installed utilizing distro-specific package managers.
#
# - Dotfiles can be configured from any Git repo containing a Toterfile. 
#
# - Supports encrypting/decrypting "secrets" before they are pushed to Git.
#
#-----------------------------------------------------------------------------#

set -e

# Local configuration directory
config_dir=$HOME/.config/toter

# In-path bin directory
bin_dir=$HOME/.local/bin

# Local application directory
app_dir=$HOME/.local/share/toter

# Local copy of the toter repo
local_copy=$app_dir/repo

# Remote toter git repository 
git_remote=https://github.com/totegoat/toter

# Symmetric encryption passphrase -- used to encrypt/decrypt secrets
pass_file=$config_dir/passfile

# Toter required packages
base_packages="git gpg curl"

# Git default binary
git_tool=git

# Do not run privileged commands with sudo by default
sudo=""

# Output modifiers
# tput is not installed everywhere, also requires TERM be set -- this is 
# problematic on minimal containers.
bold=$'\033[1m'
norm=$'\033[0m'

#
# Distro Discovery
#
discover_distro() {
    distro=unknown

    if [ -f "/etc/debian_version" ]; then
        distro=debian

    elif [ -f "/etc/yum.repos.d/amzn2-core.repo" ]; then
        distro=amazon

    elif [ -f "/etc/centos-release" ] ||
         [ -f "/etc/rocky-release" ] ||
         [ -f "/etc/fedora-release" ]; then
        distro=rhel

    elif [ -f "/etc/slackware-version" ]; then
        distro=slackware

    elif [ "$(uname -s 2> /dev/null)" = "Darwin" ]; then
        distro=macos
    fi

    echo
    echo "Distro identified as ${bold}$distro${norm}."
    echo
}

#
# Install base packages with distro's package manager
#
install_base_packages() {
    discover_distro

    if [ "$distro" == "unknown" ]; then
        echo "${bold}Unknown distro.${norm} See supported distros below. Exiting..."
        print_usage
        exit 1

    # Select the distro-specific package tool commands
    elif [ "$distro" == "debian" ]; then
        pkgmgr_update="$sudo apt update"
        pkgmgr_install="$sudo apt install -y "

    elif [ "$distro" == "rhel" ]; then
        # minimal containers use dnf5/microdnf
        if [ -f /usr/bin/microdnf ]; then 
            dnf_tool=microdnf
            pkgmgr_update=""
        else 
            dnf_tool=dnf
            pkgmgr_update="$sudo $dnf_tool update -y"
        fi
        pkgmgr_install="$sudo $dnf_tool install -y "

    elif [ "$distro" == "amazon" ]; then
        pkgmgr_update="$sudo yum update -y"
        pkgmgr_install="$sudo yum install -y "

    elif [ "$distro" == "slackware" ]; then
        pkgmgr_update="TBD"
        pkgmgr_install="TBD"

    elif [ "$distro" == "macos" ]; then
        pkgmgr_update="brew update"
        pkgmgr_install="brew install "
    fi

    # Update package managers
    $pkgmgr_update

    # Install packages
    echo "Installing required packages ${bold}($base_packages)${norm} for Toter..."
    # for pkg in "${base_packages[@]}"; do
    #    $pkgmgr_install $pkg
    # done
    $pkgmgr_install $base_packages
    
    # If GitHub CLI has been flagged, setup the GH repos.
    #
    # Linux installation docs:
    #     https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    #
    # macOS installation docs:
    #     https://github.com/cli/cli#installation
    #
    if [ "$git_tool" = "gh repo" ] && [ "$distro" = "debian" ]; then
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | $sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg \
        && $sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | $sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null 
        $pkgmgr_update
        $pkgmgr_install gh

    elif [ "$git_tool" = "gh repo" ] && [ "$distro" = "rhel" ]; then
        # $pkgmgr_install 'dnf-command(config-manager)'
        # $sudo dnf config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo 
        #
        # Install from the community repository instead
        $pkgmgr_install gh

    elif [ "$git_tool" = "gh repo" ] && [ "$distro" = "amazon" ]; then
        $pkgmgr_install yum-utils
        $sudo yum-config-manager --add-repo https://cli.github.com/packages/rpm/gh-cli.repo
        $pkgmgr_install gh

    elif [ "$git_tool" = "gh repo" ] && [ "$distro" = "slackware" ]; then
        # place holder
        echo

    elif [ "$git_tool" = "gh repo" ] && [ "$distro" = "macos" ]; then
        $pkgmgr_install gh

    fi
}

#
# Create passphrase file for symmetric encryption of secrets
#
passphrase_file() {
    if [ ! -f $pass_file ]; then
        echo
        echo "Setting up passphrase file..."
        mkdir -p $config_dir
        touch $pass_file

    else
        echo
        echo "Passphrase file already exists at $pass_file. Continuing..."
    fi
    chmod 600 $pass_file
}

#
# Clone Toter git repository
#
clone_toter_repo() {
    if [ ! -d $local_copy ]; then
        echo
        echo "Cloning Toter repo..."
        mkdir -p $app_dir
        $git_tool clone $git_remote $local_copy

    else
        echo
        echo "$local_copy already exists. Skipping Toter clone..."
    fi
}

#
# Setup a Toter "executable" in path
#
setup_toter_exec() {
    if [ ! -L $bin_dir/toter ]; then
        echo "Setting up toter executable..."
        mkdir -p $bin_dir
        ln -s $local_copy/toter.sh $bin_dir/toter &> /dev/null

    else
        echo
        echo `ls -l $bin_dir/toter | rev | cut -d' ' -f1-3 | rev`
        echo "^^^ already exists. Continuing..."
    fi

    # Make sure bin_dir/toter symlink is in PATH
    if ! which toter &>/dev/null; then
        echo "Adding $bin_dir to PATH..."
        export PATH=$bin_dir:$PATH
    else
        echo "$bin_dir already in PATH."
    fi
}

#
# Print usage instructions
#
print_usage() {
    echo
    echo "Usage: base.sh COMMAND [OPTION]"
    echo
    echo "Commands:"
    echo "         bootstrap  Configures a fresh system to run toter."
    echo "                    --sudo  (enable sudo, eg. running as non-root)"
    echo
    echo "         source     Allows base.sh to bypass exec, ie. sourced only."
    echo 
    echo "Supported Distros (ie. package managers):"
    echo "         Debian (also Ubuntu)"
    echo "         RHEL   (also CentOS, Fedora, Rocky)"
    echo "         Amazon (ie. Amazon Linux 2) "
    #echo "         Slackware"
    #echo "         macOS"
    echo
}

#
# Main: Check arguments & run
#       $1 Command
#       $2 Option
#
if [ -z "$1" ]; then
    print_usage
    exit 0

elif [ "$1" != "source" ]; then
    if [ "$1" = "bootstrap" ]; then
        if [ -n "$2" ] && [ "$2" = "--sudo" ]; then
                sudo="sudo"

        elif [ -n "$2" ] && [ "$2" != "--sudo" ]; then
            echo "Error: $2 is not a valid option."    
            print_usage
            exit 1
        fi

        install_base_packages
        clone_toter_repo        
        passphrase_file
        setup_toter_exec

        echo
        echo "${bold}Done. ${norm} Run toter without any args for instructions."
        echo "${bold}Be sure to put your encryption passphrase in $pass_file.${norm}"

    else
        echo "Error: $1 is not a valid command."
        print_usage
        exit 1
    fi
fi
