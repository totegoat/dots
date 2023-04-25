#!/usr/bin/env bash
#
#-----------------------------------------------------------------------------#
# Filename:    base.sh
# 
# Description: This script contains common functions (reusable), as well as 
#              functions for bootstrapping a fresh system with base packages, 
#              the toter repo, and configuration required to run toter.sh.
#
#              The base packages are installed utilizing distro-specific 
#              package managers.
#
# Author:      github.com/totegoat/toter
#-----------------------------------------------------------------------------#

set -e

# Toter configuration directory
CONFIG_DIR=~/.config/toter

# In-path bin directory
BIN_DIR=~/.local/bin

# Toter data directory
DATA_DIR=~/.local/share/toter

# Local copy of the Toter git repo
LOCAL_DATA=$DATA_DIR/repo

# Toter git repository
GIT_REPO=https://github.com/totegoat/toter

# Symmetric encryption passphrase -- used to encrypt/decrypt secrets
PASS_FILE=$CONFIG_DIR/.passfile

# Toter required packages
PACKAGES="git curl gpg"

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
# Install packages with distro package manager
#
packages() {
    discover_distro

    if [ "$distro" == "unknown" ]; then
        echo "Unknown distro. Exiting..."
        exit 1

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

    # Update package managers
    $pkgmgr_update

    # Install packages
    for pkg in "${base_packages[@]}"; do
        $pkgmgr_install $pkg
    done
}

#
# Create passphrase file
#
passphrase_file() {
    if [ ! -f $PASS_FILE ]; then
        echo
        echo "Setting up passphrase file..."
        touch $PASS_FILE
        echo "${bold}Make sure to put your symmetric passphrase in $PASS_FILE.${norm}"

    else
        echo "Passphrase file alread exists at $PASS_FILE. Exiting..."
        exit 1
    fi
    chmod 600 $PASS_FILE
}

#
# Clone Toter git repository
#
clone_repo() {
    if [ ! -d $LOCAL_DATA ]; then
        echo "Cloning Toter repo..."
        mkdir -p $DATA_DIR
        git clone $GIT_REPO $LOCAL_DATA

    else
        echo "$LOCAL_DATA already exists. Exiting..."
        exit 1
    fi
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
# Main: Check arguments & Run
#
if [ -n "$1" ]; then
    if [ "$1" = "bootstrap" ]; then
        echo "Bootstrapping..."

    else
        echo "ERROR: $1 is not a valid command."
        echo
        print_usage
        exit 1
    fi
fi
