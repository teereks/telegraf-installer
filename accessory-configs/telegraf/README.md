# Accessory-configs for Telegraf

Telegraf can be configured to use many different types of plugins to perform the monitoring and data-collection tasks that the user desires. These plugins can be devided into four different types by their designed use. According to the targeted use, a plugin can as one of these types:

1. Input plugin
2. Output plugin
3. Processor plugin
4. Aggregator plugin

List of all the available plugins and their documentation can be found here: https://docs.influxdata.com/telegraf/v1.26/plugins/.

## Table of specifications

In this table you can find specifications for all the configurations included in this repository. Table shows what plugins are used in each of the configurations, but notice that these can be modified and extended as needed. 

These configurations use multi-file appoach to configure Telegraf, which means that used plugin-configurations are separated to multiple files by their type. Separating configuration this way can result in a maximum of five different configuration files, one for each of the plugin-types and one additional file for agent-configuration. Telegraf can be configured using many different strategies so this might not always be the most efficient, nor convenient method.

### Configuration specifications

| Name | Inputs | Outputs | Processors | Aggregators |
|---|:---:|:---:|:---:|:---:|
| [liquorice](liquorice) | 1 x `influxdb_listener` | 2 x `http`, 1 x `influxdb` | - | - |
