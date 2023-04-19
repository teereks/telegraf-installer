# Included Program Binaries

- This directory contains program-binaries that can be installed on target system without internet-connection.
- Using the included binaries is suggested only for Offline-systems and other "non-compatible" operating systems which cannot install programs using the Online-installer part of the script.
- The binaries are stored under their related program and versions should be clearly visible in the filenames.
> *Note:* The installation script currently does not verify the authenticity of the binaries during the installation, so make sure that you install binaries only if you trust them. You can also bring your own binaries (that you have verified) to the system and install them manually using i.e. command:
>```bash
> dpkg -i <your-package.deb>
>```

- *Reminder:* Installing programs manually does not enable those programs to be automatically updated using package managers like `apt`. To update manually installed packages and binaries, you need to provide new versions yourself.

## Programs containing binaries

- This table shows all the programs that contain atleast one included binary- or package-file in this repository.

| Program | Description |
|---|---|
| [telegraf](telegraf) | Debian packages (.deb) for manually installing `Telegraf` on your system. | 