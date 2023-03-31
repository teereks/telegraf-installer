
# Telegraf-Installer

This script enables user to install `Telegraf` on Debian and Ubuntu using simple and effective text-based user interface (TUI) using `whiptail`.

> **Note:**
> Parts of this script are borrowed directly from the `Install Telegraf` -section offered by the official Telegraf Documentation so make sure to follow or atleast check the official documentation before running this script, since there is no guarantee that this script will be updated regularly.
>
> Find the official documentation for `Telegraf v1.26.0` here: [Telegraf 1.26 documentation](https://docs.influxdata.com/telegraf/v1.26/)

## Limitations & Requirements

- Script currently only supports native installation. If you want to run Telegraf using i.e. Docker container please refer to the following instuctions: https://hub.docker.com/_/telegraf and follow the steps instructed there.
- This script was originally developed for `Telegraf v1.26.0`, so if the latest release version is newer this script might not funtion as expected. 
- This script uses statically coded checksums so i.e. if `InfluxData` rotates public GPG-keys for their repositories, you need to make sure that the updated checksum is available in this script.
- Script offers dialog to user using `whiptail` so your system needs to have it installed. If `whiptail` is not found on the system, script will make an attempt to install it using `apt-get`.
- Downloading and updating packages from public sources requires working Internet-connection so this script has limited functionality when run on offline-systems.

## Usage

1. Download this script and necessary files to your target machine.

    **Using `git clone`:**
    ```bash
    git clone https://github.com/teereks/telegraf-installer.git
    ```

    **Using `wget`:**
    ```bash
    wget https://raw.githubusercontent.com/teereks/telegraf-installer/main/telegraf-installer.sh
    ```

    **Using `curl`:**
    ```bash
    curl -OJ https://raw.githubusercontent.com/teereks/telegraf-installer/main/telegraf-installer.sh
    ``` 

2. (optional) - If you used `git clone` to download script in the previous step, you can set your active path to downloaded repository with command:

    ```bash
    cd telegraf-installer/
    ```

3. Make the downloaded script executable.

    ```bash
    chmod +x telegraf-installer.sh
    ```

4. Run the script to start the installer.

    ```bash
    ./telegraf-installer.sh
    ```



