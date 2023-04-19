# Accessory-Configurations for Telegraf

Telegraf can be configured to use many different types of plugins to perform the monitoring and data-collection tasks that the user desires. These plugins can be devided into four different types by their designed use. According to the targeted use, a plugin can as one of these types:

1. Input plugin
2. Output plugin
3. Processor plugin
4. Aggregator plugin

List of all the available plugins and their documentation can be found here: https://docs.influxdata.com/telegraf/v1.26/plugins/.

## Default file locations

- When installing `Telegraf` natively on Debian (or Ubuntu) some configuration files and directory structures are automatically generated. You can modify these generated files or you can replace them with your own configurations to make deploying them easy.
- Please check the official documentation for more useful information here: [https://docs.influxdata.com/telegraf/v1.26/configuration/](https://docs.influxdata.com/telegraf/v1.26/configuration/)



| Description | Use | Default Path |
|---|---|---|
| Single-file configuration | File that will be read by `Telegraf` during it's startup. This can contain the whole configuration, but if you split your configuration this file is usually used to hold the `agent` configuration. | `/etc/telegraf/telegraf.conf` |
| Additional configurations | Directory used to store any other configurations in addition to `/etc/telegraf/telegraf.conf`.  | `/etc/telegraf/telegraf.d/` |
| Environmental Variables | If you use environmental variables to hide secrets or other sensitive information in your configurations, this is the file where you can define the values for those variables. Check documentation for for information here: [Setting Environmental Variables](https://docs.influxdata.com/telegraf/v1.26/configuration/#set-environment-variables). | `/etc/default/telegraf` |
| Service Unit | Configures the service unit for `Telegraf`.   | `/lib/systemd/system/telegraf.service` |

## Table of specifications

In this table you can find specifications for all the configurations included in this repository. Table shows what plugins are used in each of the configurations, but notice that these can be modified and extended as needed. 

These configurations use multi-file appoach to configure Telegraf, which means that used plugin-configurations are separated to multiple files by their type. Separating configuration this way can result in a maximum of five different configuration files, one for each of the plugin-types and one additional file for agent-configuration. Telegraf can be configured using many different strategies so this might not always be the most efficient, nor convenient method.

### Configuration specifications

| Name | Inputs | Outputs | Processors | Aggregators |
|---|:---:|:---:|:---:|:---:|
| [liquorice](liquorice) | 1 x `influxdb_listener` | 2 x `http`, 1 x `influxdb` | - | - |
