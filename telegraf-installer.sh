#!/bin/bash

##########################################################################
# Script Name    : Telegraf Installer
# Description    : Download and install Telegraf natively on Debian/Ubuntu
# Creation Date  : 2023/20/13
# Author         :
# Email          :
##########################################################################

# Verify that script is run as root
if [[ $EUID -ne 0 ]]; then
    echo "This script needs to be run as root"
    exit 1
fi

# Create
mkdir /tmp/telegraf-installer && cd "$_"

# Download GPG-key
if [ wget -q https://repos.influxdata.com/influxdata-archive_compat.key ]; then
    echo GPG-key downloaded using wget
elif [ curl -s https://repos.influxdata.com/influxdata-archive_compat.key ] >influxdata-archive_compat.key; then
    echo GPG-key downloaded using curl
else
    echo ERROR: Could not download the Influxdata GPG-key. Exiting
    exit 1
fi

# Trust the key
echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg >/dev/null

# Add Influxdata-repo as a package source
echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | sudo tee /etc/apt/sources.list.d/influxdata.list

# Update sources and install Telegraf
sudo apt update && sudo apt install telegraf -y

if [ ! telegraf --version ]; then
    echo ERROR: Telegraf was not installed successfully
    exit 1
else
    echo Successfully installed:
    telegraf --version
fi
