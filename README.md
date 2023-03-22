
# Telegraf-Installer

Install `Telegraf` natively on Debian using this simple and effective Bash-script. Some parts are borrowed directly from the `Install Telegraf` -section offered by `InfluxData` so make sure to follow or atleast check the official documentation before running this script.

You can find the official documentation for `Telegraf 1.26.0` here: [InfluxData Documentation: Install Telegraf v.1.26](https://docs.influxdata.com/telegraf/v1.26/install/)


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

2. Make the downloaded script executable.

    ```bash
    chmod +x telegraf-installed.sh
    ```

3. Run the script to start the installer.

    ```bash
    ./telegraf-installer.sh
    ```


## Requirements & Limitations

- This script has been developed for `Telegraf 1.26.0`, so if the latest release version is newer this script might not work. If the installation mechanism doesn't change in future versions this shouldn't be problem.
- This script uses statically coded checksums so i.e. if `InfluxData` rotates public PGP-keys for their repositories, you need to make sure that the updated checksum is available in this script.
- Script offers dialog-options to user using `whiptail` so your machine needs to have it installed. If `whiptail` is not already installed the script will offer you to install it automatically.
