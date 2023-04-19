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

    if (whiptail --title "Warning" --yesno "Removing current InfluxData-repository source and GPG-key will disable Telegraf-updates from upstream.\nOther InfluxData-products might be affected as well, if they use these sources. The following files will be deleted:\n--> $INFLUXDATA_SRCPATH\n--> $INFLUXDATA_KEYPATH\n\nDo you want to remove these files?" 16 78 --no-button "Return"); then
        echo "[influx-upstream-remove]: User selected Yes, exit status was $?."
        # Iterate files, delete if it exists
        for file in "${files[@]}"; do
            if [ -f "$file" ]; then
                rm "$file"
            fi
        done
        whiptail --title "InfluxData-Repository" --msgbox "InfluxData-repository source and/or GPG-key deleted." 10 78
    else
        echo "[influx-upstream-remove]: User selected Return, exit status was $?."
        return 1
    fi
}

# Add InfluxData related GPG-keys and listed sources to system
function add_influxdata_upstream() {

    if [[ -f "$INFLUXDATA_KEYPATH" ]] || [[ -f "$INFLUXDATA_SRCPATH" ]]; then
        if (whiptail --title "Warning" --yesno "InfluxData related files (GPG-key and/or source-repository) are found on this system. If you proceed these files will be overwritten.\n\nDo you want to continue?" 12 78 --no-button "Return"); then
            echo "[influxdata-upstream-add (overwrite)]: User selected Yes, exit status was $?."
            [[ -f "$TITEMPDIR/influxdata-archive_compat.key" ]] && rm "$TITEMPDIR/influxdata-archive_compat.key"
        else
            echo "[influxdata-upstream-add (overwrite)]: User selected Return, exit status was $?."
            return 1
        fi
    fi

    TITEMPDIR=$(whiptail --inputbox "Select temporary file-path to store InfluxData GPG-key:" 10 78 /tmp/telegraf-installer --title "Temporary file-path" --cancel-button "Return" 3>&1 1>&2 2>&3)
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        echo "[influxdata-upstream (path)]: User selected Ok and entered " $TITEMPDIR
    else
        echo "[influxdata-upstream (path)]: User selected Return, exit status was $?."
        return 1
    fi

    # Check if temporary directory already exists
    if [[ -d $TITEMPDIR ]]; then
        if (whiptail --title "Warning" --yesno "$TITEMPDIR already exists and continuing might overwrite files located in that directory.\n\nDo you want to continue?" 12 78 --no-button "Return"); then
            echo "[influxdata-upstream-add (overwrite)]: User selected Yes, exit status was $?."
            [[ -f "$TITEMPDIR/influxdata-archive_compat.key" ]] && rm "$TITEMPDIR/influxdata-archive_compat.key"
        else
            echo "[influxdata-upstream-add (overwrite)]: User selected No, exit status was $?."
            return 1
        fi
    fi

    # Create temporary directory
    mkdir -p $TITEMPDIR && cd "$_"
    echo "Created temporary directory: $TITEMPDIR"

    # Download GPG-key
    if [[ $(wget -q https://repos.influxdata.com/influxdata-archive_compat.key) -eq 0 ]]; then
        echo "[influxdata-upstream]: GPG-key downloaded using wget."
    elif [[ $(curl -s https://repos.influxdata.com/influxdata-archive_compat.key >influxdata-archive_compat.key) -eq 0 ]]; then
        echo "[influxdata-upstream]: GPG-key downloaded using curl."
    else
        echo "ERROR: Could not download the Influxdata GPG-key." >&2
        return 1
    fi

    # Trust the key
    echo '393e8779c89ac8d958f81f942f9ad7fb82a25e133faddaf92e15b16e6ac9ce4c influxdata-archive_compat.key' | sha256sum -c && cat influxdata-archive_compat.key | gpg --dearmor | tee /etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg >/dev/null
    # Add Influxdata-repo as a package source
    echo 'deb [signed-by=/etc/apt/trusted.gpg.d/influxdata-archive_compat.gpg] https://repos.influxdata.com/debian stable main' | tee /etc/apt/sources.list.d/influxdata.list
    cd -

    whiptail --title "InfluxData-Repository" --msgbox "Repository added to sources." 10 78
}

# Check status of given options on this machine
function installeroptions() {
    choices=()
    for key in "${!checkboxes[@]}"; do
        if ! [ -x "$(command -v ${checkboxes[$key]})" ]; then
            choices+=("${key}" "$(printf '%-54s' "${pkgdescriptions[$key]}")" "OFF")
        else
            choices+=("${key}" "$(printf '%-54s' "${pkgdescriptions[$key]}")" "ON")
        fi
    done
}

# Present given options
function selectoptions() {
    result=$(whiptail --title "$title" --checklist "$text" 22 78 8 --cancel-button "Exit" "${choices[@]}" 3>&2 2>&1 1>&3-)
    exitstatus=$?
    [[ $exitstatus -ne 0 ]] && installerexit
    return 0
}

# Install selected options
function exitorinstall() {
    exitstatus=$?
    if [ $exitstatus = 0 ]; then
        programs=$(echo $result | sed 's/" /\n/g' | sed 's/"//g')
        echo "[package-options]: User selected: $programs"
        [[ -z $programs ]] && echo "[install-update]: No programs selected." && return
        [[ "${programs[*]}" =~ "telegraf" ]] && telegrafwarning
        apt-get update && apt-get -y --ignore-missing install $programs || echo "ERROR: Installation failed. Could not install selected programs." >&2
    else
        echo "[package-options]: User selected Cancel."
    fi
}

# Present warning for changing Telegraf-files
function telegrafwarning() {
    if (whiptail --title "Telegraf - Warning" --yesno "You selected Telegraf to be installed OR it is already installed on this machine. Continuing might have effect on Telegraf and Telegraf-related files on this system if they already exist.\n\nDo you want to continue?" 12 78 --no-button "Exit"); then
        echo "[telegraf-warning]: User selected Yes, exit status was $?."
        telegrafmenu
    else
        echo "[telegraf-warning]: User selected Exit, exit status was $?."
        installerexit
    fi
}

# Hold/Unhold updates for program
function definehold() {
    local holdresult="N/A"
    while [ 1 ]; do
        HOLDCHOICE=$(
            whiptail --title "Hold/Unhold - $1" --menu "Select 'Finish' to return to previous menu." 14 78 6 --cancel-button "Return" \
                "1)" "<-- Return to previous menu" \
                "2)" "Hold $1" \
                "3)" "Unhold $1" 3>&2 2>&1 1>&3
        )
        exitstatus=$?
        [[ $exitstatus -ne 0 ]] && echo "[hold-menu]: User selection, exit status was $exitstatus." && return

        echo "[hold-menu]: User selected: $HOLDCHOICE"
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
            whiptail --title "Telegraf Operations" --menu "Here you can check the status of Telegraf and perform some operations related to it. After performing necessary operations select 'Finish' to continue installing/updating other selected programs." 16 78 6 --cancel-button "Exit" \
                "1)" "Check Telegraf information" \
                "2)" "Hold/Unhold updates" \
                "3)" "Add InfluxData repository as source" \
                "4)" "Remove InfluxData repository from sources" \
                "5)" "Finish" 3>&2 2>&1 1>&3
        )
        [[ $? -ne 0 ]] && installerexit

        echo "[telegraf-menu]: User selected: $CHOICE"
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

    whiptail --title "Telegraf Information" --msgbox "Current Telegraf version:\n-->$telegrafversion \n\nTelegraf - apt-mark status:\n-->$holdstatus\n\nInfluxData-repository as source:\n-->$sourcepath \n\nInfluxData GPG-key:\n-->$keypath" 18 78 --ok-button "Return"
}

# Present programs to install
function packages() {
    title="Packages"
    text="Select the programs which you want to install. Use Arrow-, Space- and Tab-keys to control the menu. Programs marked with '*' are already found on the system, unselecting them in this menu will not uninstall them.\n\nIf selected programs are already installed, they will be updated to latest available version instead."
    local -A checkboxes
    local -A pkgdescriptions
    checkboxes["curl"]="curl"
    pkgdescriptions["curl"]="tool to transfer data from or to a server"
    checkboxes["fzf"]="fzf"
    pkgdescriptions["fzf"]="command-line fuzzy finder"
    checkboxes["git"]="git"
    pkgdescriptions["git"]="distributed version control system"
    checkboxes["telegraf"]="telegraf"
    pkgdescriptions["telegraf"]="server-based agent for collecting & sending metrics"
    checkboxes["tmux"]="tmux"
    pkgdescriptions["tmux"]="terminal multiplexer"
    checkboxes["wget"]="wget"
    pkgdescriptions["wget"]="non-interactive network downloader"

    installeroptions && selectoptions && exitorinstall
}

# Check dependencies
function precheck() {
    echo "[precheck]: Checking prerequisites..."
    check_command_availability "${PREREQUISITES[@]}"
    if [ $? -ne 0 ]; then
        echo "[precheck]: Could not find the required commands on the system, trying to install missing packages."
        install_packages "${PREREQUISITES[@]}"
        check_command_availability "${PREREQUISITES[@]}"
        if [ $? -ne 0 ]; then echo "ERROR: Failed to install prerequisites." >&2 && exit 1; fi
        echo "[precheck]: Prerequisites installed succesfully!"
    else
        echo "[precheck]: All prerequisites found!"
    fi
    return 0
}

# Install and update programs
function installprograms() {
    if (whiptail --title "Install and Update Programs" --yesno "This part of the script is used to install and update programs on this machine. Installing programs using this script requires working Internet-connection, so make sure to verify this before advancing the installer.\n\nDo you want to continue?" 12 78 --no-button "Exit" --yes-button "Continue"); then
        echo "[verify-inet]: User selected Continue, exit status was $?."
    else
        echo "[verify-inet]: User selected Exit, exit status was $?."
        installerexit
    fi

    packages
    [[ $? -ne 0 ]] && installerexit

    whiptail --title "Finished" --msgbox "Installer has finished. Click OK exit." 8 78
}

# Manage bundled configurations
function importconfigs() {
    # Select program for which you want to deploy configuration
    declare -a programs
    PROGRAMPATHS=($(ls -d accessory-configs/*/))

    # List programs with configurations in the repo
    for progpath in "${PROGRAMPATHS[@]}"; do
        dir=$(echo $progpath | awk -F "/" '{print $(NF-1)}')
        programs+=("$dir")
        programs+=("")
    done
    echo "[import-configs]: Found bundled configs for programs: ${programs[@]}"

    PROGRAM=$(whiptail --title "Select program" --menu "Select programs for which you want to deploy bundled configuration." 16 78 6 --cancel-button "Exit" "${programs[@]}" 3>&2 2>&1 1>&3)
    [[ $? -ne 0 ]] && installerexit
    echo "[import-configs]: User selected program: $PROGRAM"

    # Select target configuration from included configs
    declare -a configs
    CONFIGPATHS=($(ls -d accessory-configs/$PROGRAM/*/))

    # List availablle configurations for selected program
    for configpath in "${CONFIGPATHS[@]}"; do
        dir=$(echo $configpath | awk -F "/" '{print $(NF-1)}')
        configs+=("$dir")
        configs+=("")
    done
    echo "[import-configs]: Found bundled configs for $PROGRAM: ${configs[@]}"

    CONFIG=$(whiptail --title "Select configuration" --menu "Select configuration which you want to deploy on this system. Please refer to the documentation for more information about available configurations." 18 78 6 --cancel-button "Exit" "${configs[@]}" 3>&2 2>&1 1>&3)
    [[ $? -ne 0 ]] && installerexit
    echo "[import-configs]: User selected configuration: $CONFIG"

    # List avalable files for selected configuration (ignore markdown-files)
    declare -a configurationfiles
    CONFIGFILES=($(ls accessory-configs/$PROGRAM/$CONFIG/ | grep -v ".md"))

    for configfile in "${CONFIGFILES[@]}"; do
        file=$(echo $configfile | awk -F "/" '{print $(NF-1)}')
        configurationfiles+=("$file")
        configurationfiles+=("")
    done
    echo "[import-configs]: Found bundled files for $CONFIG: ${configurationfiles[@]}"

    # Set default path-offerings
    defaultagentpath="/etc/telegraf/"
    defaultpluginpath="/etc/telegraf/telegraf.d/"
    defaultenvpath="/etc/default/"

    # Menu for user to handle configuration file one at a time
    while [ 1 ]; do
        CONFIGFILE=$(whiptail --title "Select file" --menu "Select file which you want handle next. Please refer to the documentation for more information about these files." 18 78 6 --cancel-button "Finish" "${configurationfiles[@]}" 3>&2 2>&1 1>&3)
        [[ $? -ne 0 ]] && break
        echo "[import-configs]: User selected file: $CONFIGFILE"

        if [[ "$CONFIGFILE" == "telegraf.conf" ]]; then
            suggestedpath=$defaultagentpath
        elif [[ "$CONFIGFILE" == "telegraf" ]]; then
            suggestedpath=$defaultenvpath
        else
            suggestedpath=$defaultpluginpath
        fi

        # Ask user for destination path and offer previously defined default-value
        destinationpath=$(whiptail --inputbox "Insert absolute (full) file path where you want to copy this file (remember to end path with '/' since it should be directory instead of file):\n\n->$CONFIGFILE" 14 78 $suggestedpath --title "File path" --cancel-button "Return" 3>&1 1>&2 2>&3)
        if [[ $? -eq 0 ]]; then
            if (whiptail --title "Warning" --yesno "Do you want to transfer: $CONFIGFILE to $destinationpath?\nIf file already exists with the same name, it will be overwritten." 12 78 --no-button "Return"); then
                echo "[import-configs]: User selected Continue, exit status was $?."
                # Write file to target location
                cat accessory-configs/$PROGRAM/$CONFIG/$CONFIGFILE >"$destinationpath$CONFIGFILE"
            else
                echo "[import-configs]: User selected Return, exit status was $?."
            fi
        fi
    done

    # Offer user to start configuration-management
    if (whiptail --title "Manage programs" --yesno "You have finished importing configurations to your system.\n\nDo you want to start managing program configurations now?" 12 78 --no-button "Exit"); then
        echo "[import-configs]: User selected Yes to manage programs, exit status was $?."
        manageconfigs
    else
        echo "[import-configs]: User selected Exit, exit status was $?."
        installerexit
    fi

    installerexit
}

# Manage and modify configuration files for programs
function manageconfigs() {
    CHOICE=$(
        whiptail --title "Select Program" --menu "Select program for which you want make modifications to:" 14 78 6 --cancel-button "Exit" \
            "1)" "Telegraf" \
            "2)" "Exit" 3>&2 2>&1 1>&3
    )
    exitstatus=$?
    [[ $exitstatus -ne 0 ]] && echo "[manage-configs]: User selection, exit status was $exitstatus." && installerexit
    echo "[manage-configs]: User selected: $CHOICE"

    case $CHOICE in
    "1)")
        manageprogram="telegraf"
        ;;
    "2)")
        installerexit
        ;;
    esac
    echo "[manage-configs]: User selected to manage program: $manageprogram"

    # Fetch all related configs on the system
    declare -a systemprogramfiles
    if [[ $manageprogram == "telegraf" ]]; then
        #list all related directories here and offer the files included in them later to user to use nano
        declare -a configurationfiles
        defaultagentpath="/etc/telegraf/"
        defaultpluginpath="/etc/telegraf/telegraf.d/"
        defaultenvpath="/etc/default/telegraf"
        defaultservicepath="/lib/systemd/system/telegraf.service"
        AGENTCONFIGS=($(find $defaultagentpath -maxdepth 1 -not -type d))
        PLUGINCONFIGS=($(find $defaultpluginpath -maxdepth 1 -not -type d))
        #ENVCONFIGS=($(find $defaultenvpath -maxdepth 1 -not -type d))

        # echo "defaultagentpath: $defaultagentpath"
        # echo "defaultpluginpath: $defaultpluginpath"
        # echo "defaultenvpath: $defaultenvpath"

        for configfile in "${AGENTCONFIGS[@]}"; do
            systemprogramfiles+=("$configfile")
            systemprogramfiles+=("")
        done
        for configfile in "${PLUGINCONFIGS[@]}"; do
            systemprogramfiles+=("$configfile")
            systemprogramfiles+=("")
        done
        # for configfile in "${ENVCONFIGS[@]}"; do
        #     systemprogramfiles+=("$configfile")
        #     systemprogramfiles+=("")
        # done

        systemprogramfiles+=($(find $defaultenvpath -maxdepth 1 -not -type d))
        systemprogramfiles+=("")
        systemprogramfiles+=($(find $defaultservicepath -maxdepth 1 -not -type d))
        systemprogramfiles+=("")
    fi

    # Offer all program related configuration files here
    while [ 1 ]; do
        modifyconfig=$(whiptail --title "Select file" --menu "Select file which you want handle next.\n\nSelecting file will open it using text-editor (nano). After modifications use key-combination: 'Ctrl + x' to exit the editor, press key: 'y' to allow saving modifications and then accept filewrite using key: 'Enter'.\n\nAfter you are done modifying files select 'Finish' to exit." 26 78 10 --cancel-button "Finish" "${systemprogramfiles[@]}" 3>&2 2>&1 1>&3)
        [[ $? -ne 0 ]] && break
        echo "[manage-configs]: User selected to open file: $modifyconfig"

        nano $modifyconfig
    done

}

# Inital Start-menu
function startmenu() {
    CHOICE=$(
        whiptail --title "Start" --menu "Please select what operations you want to perform." 16 78 6 --cancel-button "Exit" \
            "1)" "Install and update programs" \
            "2)" "Import bundled configurations" \
            "3)" "Manage program configurations" \
            "4)" "Exit" 3>&2 2>&1 1>&3
    )
    [[ $? -ne 0 ]] && installerexit

    echo "[start-menu]: User selected: $CHOICE"
    case $CHOICE in
    "1)")
        installprograms
        ;;
    "2)")
        importconfigs
        ;;
    "3)")
        manageconfigs
        ;;
    "4)")
        installerexit
        ;;
    esac
}

# Exit notice
function installerexit() {
    whiptail --title "Exit" --msgbox "You have exited the installer. Click OK to close this window." 8 78 && exit 1
}

verify_root
precheck

whiptail --title "Telegraf-Installer" --msgbox "Welcome to Telegraf-Installer. Select OK to continue." 10 78
[[ $? -ne 0 ]] && installerexit

startmenu
