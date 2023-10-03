
# Telegraf-Installer

This script enables user to install `Telegraf` on Debian and Ubuntu systems with the help of simple and effective text-based user interface (TUI) using `whiptail`.

> *Note:* Parts of this script are borrowed directly from the `Install Telegraf` -section offered by the official Telegraf Documentation so make sure to follow or atleast check the official documentation before running this script, since there is no guarantee that this script will be updated regularly.
>
> Find the official documentation for `Telegraf v1.26.0` here: [Telegraf 1.26 documentation](https://docs.influxdata.com/telegraf/v1.26/)

## Limitations & Requirements

- Script currently only supports installation using `apt`, but if you want to run Telegraf using i.e. Docker container please refer to the following instuctions: https://hub.docker.com/_/telegraf and follow the steps instructed there.
- This script was originally developed for `Telegraf v1.26.0`, so if the latest release version is newer this script might not funtion as expected. 
- This script uses statically coded checksums so i.e. if `InfluxData` rotates public GPG-keys for their repositories, you need to make sure that the updated checksum is available in this script.
- Script offers dialog to user using `whiptail` so your system needs to have it installed. If `whiptail` is not found on the system, this script will make an attempt to install it using `apt-get`.
- Downloading and updating packages from public sources requires working Internet-connection so this script has limited functionality when run on offline-systems. You need to bundle your own packages/binaries if you want to install anything on completely offline-system.

## Usage

1. Download this script and necessary files to your target machine. Using `git clone` is suggested since it also download all the included configs, binaries and documentation to your system in one go. 

    **Using `git clone`:**
    ```bash
    git clone https://github.com/teereks/telegraf-installer.git
    ```

    **Using `wget`**: *this downloads only the script, not the included configs, binaries or documentation*

    ```bash
    wget https://raw.githubusercontent.com/teereks/telegraf-installer/main/telegraf-installer.sh
    ```

    **Using `curl`**: *this downloads only the script, not the included configs, binaries or documentation*
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

5. At the beginning of the script user will be offered "Start Menu" which allows for some common tasks to be performed. You might need to run the script multiple times if you want to perform more than one of these tasks concurrently. Start menu will give following user the options:
![startmenu.png](/media/startmenu.PNG "Start Menu ")
    - **Install and update programs**: allows user to install new programs and update existing ones. Programs can be installed from public sources or included packages can be installed manually even without internet-connection.
    - **Import bundled configurations**: allows user to deploy configurations that are included in the downloaded repository itself.
    - **Manage program configurations**: enables user to check and modify currently deployed configurations.

6. (Optional) - If you made changes to the `Systemd Units` remember to reload systemd manager configuration by running:

    ```bash
    systemctl daemon-reload
    ```

7. Finally you likely need to restart your service(s) that you have modified by running:

    ```bash
    systemctl restart <your-service>
    ```
    
    Verify that your service started succesfully with command:

    ```bash
    systemctl status <your-service>
    ```