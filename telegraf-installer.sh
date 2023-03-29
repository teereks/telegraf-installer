#!/bin/bash

##########################################################################
# Script Name    : Telegraf Installer
# Description    : Download and install Telegraf natively on Debian/Ubuntu
# Creation Date  : 2023/20/13
# Author         : teereks
# Email          : 47917519+teereks@users.noreply.github.com
##########################################################################

# Variable declaration
PREREQUISITES=("whiptail" "wget")
INFLUXDATA_KEYPATH="/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg"
INFLUXDATA_SRCPATH="/etc/apt/sources.list.d/influxdata.list"

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

# Remove InfluxData-repository related GPG-key and listed source from system
function remove_influxdata_upstream() {
    # Array of files to be deleted
    local files=("$INFLUXDATA_KEYPATH" "$INFLUXDATA_SRCPATH")

    if (whiptail --title "Warning" --yesno "Removing current InfluxData-repository source and GPG-key will disable Telegraf-updates from upstream.\nOther InfluxData-products might be affected as well, if they use the same sources. The following files will be deleted:\n--> $INFLUXDATA_SRCPATH\n--> $INFLUXDATA_KEYPATH\n\nDo you want to remove these files?" 16 78); then
        echo "User selected Yes, exit status was $?."
        # Iterate files, delete if it exists
        for file in "${files[@]}"; do
            if [ -f "$file" ]; then
                rm "$file"
            fi
        done
    else
        echo "User selected No, exit status was $?."
        return
    fi
}

# Add InfluxData related GPG-keys and listed sources to system
function add_influxdata_upstream() {
    TITEMPDIR=$(whiptail --inputbox "Select temporary file-path to store InfluxData GPG-key:" 10 78 /tmp/telegraf-installer --title "Temporary file-path" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        echo "User selected Ok and entered " $TITEMPDIR
    else
        echo "User selected Cancel."
        return
    fi

    # Check if temporary directory already exists
    if [[ -d $TITEMPDIR ]]; then
        if (whiptail --title "Warning" --yesno "$TITEMPDIR already exists and continuing might overwrite files located in that directory.\n\nDo you want to continue?" 12 78); then
            echo "User selected Yes, exit status was $?."
        else
            echo "User selected No, exit status was $?."
            return
        fi
    fi

    # Create temporary directory
    mkdir -p $TITEMPDIR && cd "$_"
    echo "Created temporary directory: $TITEMPDIR"

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
    cd -
}

# Check status of given options on this machine
function installeroptions() {
    choices=()
    for key in "${!checkboxes[@]}"; do
        spacer=$(for i in $(seq 1 54); do echo -n " "; done)
        if ! [ -x "$(command -v ${checkboxes[$key]})" ]; then
            choices+=("${key}" "${spacer}" "OFF")
        else
            choices+=("${key}" "${spacer}" "ON")
        fi
    done
}

# Present given options
function selectoptions() {
    result=$(whiptail --title "$title" --checklist "$text" 22 78 8 "${choices[@]}" 3>&2 2>&1 1>&3-)
}

# Install selected options
function exitorinstall() {
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        programs=$(echo $result | sed 's/" /\n/g' | sed 's/"//g')
        echo $programs
        if [[ "${programs[*]}" =~ "telegraf" ]]; then
            telegrafwarning
        fi
        apt-get -y --ignore-missing install $programs || echo "ERROR: Installation failed. Could not install selected programs." >&2
    else
        echo "User selected Cancel."
    fi
}

# Present warning for changing Telegraf-files
function telegrafwarning() {
    if (whiptail --title "Telegraf - Warning" --yesno "You selected Telegraf to be installed OR it is already installed on this machine. Continuing might have effect on Telegraf and Telegraf-related files on this system if they already exist.\n\nDo you want to continue?" 12 78); then
        echo "User selected Yes, exit status was $?."
        telegrafmenu
    else
        echo "User selected No, exit status was $?."
        exit 1
    fi
}

# Hold/Unhold updates for program
function definehold() {
    local holdresult="N/A"
    while [ 1 ]; do
        HOLDCHOICE=$(
            whiptail --title "Hold/Unhold - $1" --menu "Select 'Finish' to return to previous menu." 14 78 6 \
                "1)" "<-- Return to previous menu" \
                "2)" "Hold $1" \
                "3)" "Unhold $1" 3>&2 2>&1 1>&3
        )
        exitstatus=$?
        [[ $exitstatus = 1 ]] && return

        echo "choise is: $HOLDCHOICE"
        case $HOLDCHOICE in
        "1)")
            return
            ;;
        "2)")
            holdresult=$(apt-mark hold $1)
            whiptail --title "Hold/Unhold - $1" --msgbox "$holdresult" 8 78

            ;;
        "3)")
            holdresult=$(apt-mark unhold $1)
            whiptail --title "Hold/Unhold - $1" --msgbox "$holdresult" 8 78
            ;;
        esac
    done
}

# Present Telegraf-related operations
function telegrafmenu() {
    while [ 1 ]; do
        CHOICE=$(
            whiptail --title "Telegraf Operations" --menu "Select 'Finish' to continue installing previously selected programs." 14 78 6 \
                "1)" "Check Telegraf information" \
                "2)" "Hold/Unhold updates" \
                "3)" "Add InfluxData repository as source" \
                "4)" "Remove InfluxData repository from sources" \
                "5)" "Finish" 3>&2 2>&1 1>&3
        )
        exitstatus=$?
        [[ $exitstatus = 1 ]] && exit 1

        echo "choise is: $CHOISE"
        case $CHOICE in
        "1)")
            telegrafinfo
            ;;
        "2)")
            definehold "telegraf"
            ;;
        "3)")
            add_influxdata_upstream
            ;;
        "4)")
            remove_influxdata_upstream
            ;;
        "5)")
            return
            ;;
        esac
    done
}

# Show Telegraf-related information
function telegrafinfo() {
    local telegrafversion="N/A"
    local sourcepath="N/A"
    local keypath="N/A"
    local holdstatus="N/A"

    check_command_availability "telegraf"
    if [[ $? -eq 0 ]]; then
        telegrafversion="$(telegraf --version)"
    fi

    holdstatus=$(apt-mark showhold telegraf)
    if [[ -z "$holdstatus" ]]; then
        holdstatus="telegraf NOT ON HOLD"
    else
        holdstatus="telegraf SET ON HOLD"
    fi

    if [[ -f "/etc/apt/sources.list.d/influxdata.list" ]]; then
        sourcepath="Found: /etc/apt/sources.list.d/influxdata.list"
    fi

    if [[ -f "/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg" ]]; then
        keypath="Found: /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg"
    fi

    whiptail --title "Telegraf Information" --msgbox "Current Telegraf version:\n-->$telegrafversion \n\nTelegraf - apt-mark status:\n-->$holdstatus\n\nInfluxData-repository as source:\n-->$sourcepath \n\nInfluxData GPG-key:\n-->$keypath" 18 78
}

# Present programs to install
function packages() {
    title="Packages"
    text="Use Arrow-, Space- and Tab-keys to control the menu.\nSelect the programs which you want to install.\nPrograms marked with '*' are already found on the system, unselecting them in this menu will not uninstall them.\nIf selected programs are already installed, they will be updated to latest available version instead."
    local -A checkboxes
    checkboxes["wget"]="wget"
    checkboxes["curl"]="curl"
    checkboxes["tmux"]="tmux"
    checkboxes["telegraf"]="telegraf"

    installeroptions && selectoptions && exitorinstall
}

verify_root

echo "Checking prerequisites..."
check_command_availability "${PREREQUISITES[@]}"
if [ $? -ne 0 ]; then
    echo "Could not find the required commands on the system, trying to install missing packages."
    install_packages "${PREREQUISITES[@]}"
    check_command_availability "${PREREQUISITES[@]}"
    if [ $? -ne 0 ]; then echo "ERROR: Failed to install prerequisites." >&2 && exit 1; fi
    echo "Prerequisites installed succesfully!"
else
    echo "All prerequisites found!"
fi

whiptail --title "Telegraf-Installer" --msgbox "Welcome to Telegraf-Installer. Select OK to continue." 10 78

if (whiptail --title "Telegraf-Installer" --yesno "This script is mainly used to install Telegraf and other related packages on this machine. Installing packages using this script requires working Internet-connection, so make sure to verify this before advancing the installer.\n\nDo you want to continue?" 12 78 --no-button "Exit" --yes-button "Continue"); then
    echo "User selected Continue, exit status was $?."
else
    echo "User selected Exit, exit status was $?."
    exit 0
fi

packages
exitstatus=$?
[[ $exitstatus = 1 ]] && whiptail --title "Exit" --msgbox "You have exited the installer. Click OK to close this window." 8 78 && exit 1

whiptail --title "Finished" --msgbox "Installer has finished. Click OK exit." 8 78
