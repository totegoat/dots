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

# Local configuration directory
config_dir=~/.config/toter

# In-path bin directory
bin_dir=~/.local/bin

# Local application directory
app_dir=~/.local/share/toter

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
        # minimal containers use dnf5/microdnf
        if [ -f /usr/bin/dnf5 ]; then 
            dnf_tool=dnf5
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
setup_toter() {
    if [ ! -e $bin_dir/toter ]; then
        mkdir -p $bin_dir
        ln -s $local_copy/toter.sh $bin_dir/toter
    fi

    echo
    echo "${bold}Done. ${norm} Run toter without any options for instructions."
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
    #echo "         macOS"
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
