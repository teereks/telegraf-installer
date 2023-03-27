#!/bin/bash

##########################################################################
# Script Name    : Telegraf Installer
# Description    : Download and install Telegraf natively on Debian/Ubuntu
# Creation Date  : 2023/20/13
# Author         : teereks
# Email          : 47917519+teereks@users.noreply.github.com
##########################################################################

# Verify that script is run as root
function verify_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "This script needs to be run as root!"
        exit 1
    fi
}

# Check that commands are available on this system. Accepts array of commands as an argument.
function check_command_availability() {
    cmds=("$@")
    for cmd in "${cmds[@]}"; do
        if ! command -v $cmd &>/dev/null; then
            echo "Could not find command: $cmd"
        fi
    done
}

# Install given packages. Accepts package-names in an array as argument.
function install_packages() {
    pkgs=("$@")
    apt-get update
    apt-get -y --ignore-missing install "${pkgs[@]}"
}

# Remove InfluxData related GPG-keys and listed sources from system
function remove_influxdata_upstream() {
    # Array of files to be deleted
    files=("/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg" "/etc/apt/sources.list.d/influxdata.list")

    # Iterate files, delete if it exists
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            rm "$file"
        fi
    done
}

# Add InfluxData related GPG-keys and listed sources to system
function add_influxdata_upstream() {
    # Create temporary directory to work in
    mkdir /tmp/telegraf-installer && cd "$_"

    # Download PGP-key
    if [ wget -q https://repos.influxdata.com/influxdata-archive_compat.key ]; then
        echo PGP-key downloaded using wget
    elif [ curl -s https://repos.influxdata.com/influxdata-archive_compat.key ] >influxdata-archive_compat.key; then
        echo PGP-key downloaded using curl
    else
        echo ERROR: Could not download the Influxdata PGP-key. Exiting...
        exit 1
    fi

    # Trust the key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg >/dev/null

    # Add Influxdata-repo as a package source
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
}

# Update sources and install Telegraf
sudo apt-get update && sudo apt-get install telegraf -y

