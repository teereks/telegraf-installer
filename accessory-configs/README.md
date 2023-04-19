# Accessory-Configurations

This directory contains some configurations which can be used to get you started with some applications. Configurations are bundled in this repository to enable easy and quick deployment, but remember that usually you need to supply some additional information yourself to fully utilize these configurations.

These configurations do not contain any personal of sensitive information, but if you do need to supply some information using i.e. environment variables make sure to backup or store that information securely somewhere else.

Configurations are categorized by host program. If you are planning to use any of these configurations on your applications, please read the related documentation carefully.

## Requirements

All the included configurations for each of the programs should have necessary documentation included. Relevant information varies from program to program, but the documentation should always include instructions on how to get the application up and running with the included configuration.

It is also helpful to include additional information in the instructions like:
- Suggested default locations for configuration files (or default `service unit` -file contents if available)
- Systemd (or other System and Service manager) related file locations
- Links to official documentation if available 

## Using systemd

Telegraf configurations in this repository might include service-unit files for `Telegraf` which are meant to replace the automatically generated default file. The default file does not allow service to be restarted for forever, so these slightly modified service-unit files can be used to replace the original.

Read the documentation of the configuration which and check the file before importing it to system to verify that it is suitable for your use.

> *Note:* The service unit files might not be compatible for your system depending on the `systemd` version that is used. There are some relevant changes for `systemd-230` and newer versions compared to pre `systemd-230`.

### Available programs and applications

This table lists all the programs that have configurations included in this repository.

| Program | Description |
|---|---|
| [telegraf](telegraf) | Server-based agent for collecting and sending all metrics and events from databases, systems, and IoT sensors. | 