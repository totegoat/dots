#!/usr/bin/env bash

#-----------------------------------------------------------------------------#
# base.sh (github.com/totegoat/toter)
# 
# This script contains common functions (reusable), as well as functions for 
# bootstrapping a fresh system with base packages, the toter repo, and 
# configuration required to run toter.sh.
#
# The base packages are installed utilizing distro-specific package managers.
#
#-----------------------------------------------------------------------------#

set -e

# Toter configuration directory
config_dir=~/.config/toter

# In-path bin directory
bin_dir=~/.local/bin

# Toter data directory
data_dir=~/.local/share/toter

# Local copy of the Toter git repo
local_data=$data_dir/repo

# Toter git repository
git_remote=https://github.com/totegoat/toter

# Symmetric encryption passphrase -- used to encrypt/decrypt secrets
pass_file=$config_dir/passfile

# Toter required packages
base_packages="git gpg curl"

# Git default binary
git_tool=git

# Run privileged commands with sudo by default
sudo="sudo"

# Output modifiers
bold=$(tput bold)
norm=$(tput sgr0)

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
}

#
# Install packages with distro's package manager
#
install_packages() {
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
        pkgmgr_update="$sudo dnf update -y"
        pkgmgr_install="$sudo dnf install -y "

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

    echo
    echo "Identified as a ${bold}$distro ${norm}distro."
    echo

    # Update package managers
    $pkgmgr_update

    # Install packages
    echo "Installing required packages ${bold}($base_packages)${norm} for Toter..."
    # for pkg in "${base_packages[@]}"; do
    #    $pkgmgr_install $pkg
    # done
    $pkgmgr_install $base_packages
    
    # If GitHub CLI is enabled, setup the package repos for it.
    #
    # Linux installation docs:
    #     https://github.com/cli/cli/blob/trunk/docs/install_linux.md
    #
    # MacOS installation docs:
    # https://github.com/cli/cli#installation
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
        echo "${bold}Be sure to put your symmetric passphrase in $pass_file.${norm}"

    else
        echo
        echo "Passphrase file alread exists at $pass_file. Continuing..."
    fi
    chmod 600 $pass_file
}

#
# Clone Toter git repository or copy from local source
#
clone_repo() {
    if [ ! -d $local_data ]; then
        echo
        echo "Cloning Toter repo..."
        mkdir -p $data_dir
        $git_tool clone $git_remote $local_data

    else
        echo
        echo "$local_data already exists. Skipping Toter clone..."
    fi
}

#
# Setup Toter "executable" in path
#
setup_toter() {
    if [ ! -e $bin_dir/toter ]; then
        mkdir -p $bin_dir
        ln -s $local_data/toter.sh $bin_dir/toter
    fi

    # check if $bin_dir is in path, if not, add it

    # output done and some instructions for running toter
}

#
# Print usage instructions
#
print_usage() {
    echo
    echo "Usage: base.sh [command]"
    echo
    echo "Commands:"
    echo "         bootstrap (configures fresh system to run toter)"
    echo "              Options: --gh (use GitHub CLI to clone toter repo)"
    echo "                       --nosudo (disable sudo, eg. running as root)"
    echo 
    echo "Supported Distros (Package Managers):"
    echo "         Debian (also Ubuntu)"
    #echo "         RHEL   (also CentOS, Fedora, Rocky)"
    #echo "         Amazon (ie. Amazon Linux 2) "
    #echo "         Slackware"
    #echo "         MacOS"
    echo
}

#
# Main: Check arguments & run
#
if [ -n "$1" ]; then
    if [ "$1" = "bootstrap" ]; then
        if [ ! -z "$2" ] && [ "$2" = "--gh" ]; then
            git_tool="gh repo"

        elif [ ! -z "$2" ] && [ "$2" = "--nosudo" ]; then
            sudo=""

        else
            echo "Error: $2 is not a valid option."    
            print_usage
            exit 1
        fi

        install_packages
        clone_repo        
        passphrase_file
        setup_toter

    else
        echo "Error: $1 is not a valid command."
        print_usage
        exit 1
    fi

else
    print_usage
fi
