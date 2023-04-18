
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

2. (Optional) - If you used `git clone` to download script in the previous step, you can set your active path to downloaded repository with command:

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

    *Note:* The script requires you to run it as `root` -user (EUID must be 0) to make any changes on the system.

5. At the beginning of the script user will be offered "Start Menu" which allows for some common tasks to be performed. You might need to run the script multiple times if you want to perform more than one of these tasks in one go. Start menu will give following user the options:
![startmenu.png](/media/startmenu.PNG "Start Menu ")
    - **Install and update programs** allows user to install new programs and update existing ones.
    - **Import bundled configurations** allows user to deploy configurations (per program) that are included in the repository itself.
    - **Manage program configurations** enables user to checkout and modify currently deployed configurations (per program) as well as make modifications to the contents.

6. (Optional) - If you made changes to the `Systemd Units` remember to reload systemd manager configuration by running:

    ```bash
    systemctl daemon-reload
    ```

    And then restart your service by running:

    ```bash
    systemctl restart <your-service>
    ```
    
    Verify that your service started succesfully with command:

    ```bash
    systemctl status <your-service>
    ```