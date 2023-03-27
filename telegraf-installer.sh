#!/bin/bash

##########################################################################
# Script Name    : Telegraf Installer
# Description    : Download and install Telegraf natively on Debian/Ubuntu
# Creation Date  : 2023/20/13
# Author         : teereks
# Email          : 47917519+teereks@users.noreply.github.com
##########################################################################

# Variable declaration
prerequisite_pkgs=("whiptail")
temp_directory="/tmp/telegraf-installer"

# Verify that script is run as root
function verify_root() {
    if [[ $EUID -ne 0 ]]; then
        echo "ERROR: This script needs to be run as root!" >&2
        echo "Tip: Switch to root by running command \"su -\" before running this script again."
        exit 1
    fi
}

# Check that commands are available on this system. Accepts array of commands as an argument.
function check_command_availability() {
    cmds=("$@")
    local status_code=0
    for cmd in "${cmds[@]}"; do
        if ! command -v $cmd &>/dev/null; then
            echo "Could not find command: $cmd" >&2
            status_code=1
        fi
    done
    return $status_code
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
    # Check if temporary directory exists
    if [[ ! -d $temp_directory ]]; then
        # Create temporary directory to work in
        mkdir -p $temp_directory && cd "$_"
        echo "Created temporary directory: $temp_directory"
    fi

    # Download GPG-key
    if [ wget -q https://repos.influxdata.com/influxdata-archive_compat.key ]; then
        echo "GPG-key downloaded using wget"
    elif [ curl -s https://repos.influxdata.com/influxdata-archive_compat.key ] >influxdata-archive_compat.key; then
        echo "GPG-key downloaded using curl"
    else
        echo "ERROR: Could not download the Influxdata GPG-key." >&2
        return 1
    fi

    # Trust the key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg >/dev/null

    # Add Influxdata-repo as a package source
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list
}

verify_root

check_command_availability "${prerequisite_pkgs[@]}"
if [ $? -ne 0 ]; then
    echo "Could not find the required commands on the system, trying to install missing packages."
    install_packages "${prerequisite_pkgs[@]}"
    check_command_availability "${prerequisite_pkgs[@]}"
    if [ $? -ne 0 ]; then echo "ERROR: Failed to install prerequisites." >&2 && exit 1; fi
fi


# add_influxdata_upstream
# if [ $? -ne 0 ]; then
#     echo "ERROR: Could not add InfluxData-reposity as a package source." >&2
# fi