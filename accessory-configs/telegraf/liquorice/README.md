# liquorice

This configuration can be used to setup an enpoint using `influxdb_listener`, which listens for requests sent according to the [InfluxDB HTTP API](https://docs.influxdata.com/influxdb/v1.8/guides/write_data/). The incoming requests can be then routed to two different outputs: `http` and `influxdb`.

# Requirements

Using this configuration on your system requires you to fill in some information specific to your use. 

## Files

There are some files included in this configuration which you need to transfer to your system before being able to actually running this configuration. 

The next table shows all the files that you need to transfer to your system, this can be done easily using the `telegraf-installer.sh` script.

| Filename | Description | Default Target Path |
|---|---|---|
| `telegraf.conf` | Agent-configuration | `/etc/telegraf/` |
| `inputs.conf` | Configuration for input-plugins | `/etc/telegraf/telegraf.d/` |
| `outputs.conf` | Configuration for output-plugins | `/etc/telegraf/telegraf.d/` |
| `telegraf` | File for setting environment variables  | `/etc/default/` |
| `telegraf.service` | Service unit file (requires systemd-230 or newer)  | `/lib/systemd/system/` |

> Notice that the included service-unit requires `systemd-230` or newer. If you are using older systemd version you need to change the `StartLimitIntervalSec` to `StartLimitInterval`.

## Environment variables

These are the variables that are necessary to define before you can start running this  configuration.

> You can start `Telegraf` with this configuration without making any changes to environment variables, but remember to adjust the variables before using this in production.

These variables are referenced in the configurations and they will be replaced with the defined values during the startup. Check out [Configuration](#configuration) for more information.

| VARIABLE  	| Description  	| Type  	|
|---	        |---	        |---	    |
| HTTP_OUTPUT1_ALIAS  	| Name for first HTTP-output, only used for logging and debugging	| string  	|
| HTTP_OUTPUT1_URL  	| URL where metrics are sent if `$database_tag == $DEST_DB1`	| string  	|
| DEST_DB1  	| Name of the first destination database where metrics are routed locally	| string  	|
| HTTP_OUTPUT2_ALIAS  	| Name for second HTTP-output, only used for logging and debugging	| string  	|
| HTTP_OUTPUT2_URL  	| URL where metrics are sent if `$database_tag == $DEST_DB2`	| string  	|
| DEST_DB2  	| Name of the second destination database where metrics are routed locally	| string  	|

### Configuration

This configuration uses environment variables to allow for easier deployment for multiple systems. For production use you need to define the necessary variables before starting Telegraf. You should define the variables in the default location to enable them to be interpreted each time you start Telegraf. You can read more about environment variables here: https://docs.influxdata.com/telegraf/v1.26/configuration/#set-environment-variables.

- The default file-path where you want to define the environment variables is:

    ```bash
    /etc/default/telegraf
    ```

- In that file you need to define values to the required variables. You can see the table of required environment variables here: [Required Environment Variables](#environment-variables).
- Here is an exmple of how the environment variables file could look like, same file can be seen [here](telegraf):

    ```bash
    HTTP_OUTPUT1_ALIAS="machine1"
    HTTP_OUTPUT1_URL="https://your-url-here.com/machine1-api-key-here"
    DEST_DB1="dbMachine1"
    HTTP_OUTPUT2_ALIAS="machine2"
    HTTP_OUTPUT2_URL="https://your-url-here.com/machine2-api-key-here"
    DEST_DB2="dbMachine2"
    ```

- After changing your information to the file you can proceed to start Telegraf normally.



# Description

This is the description for this configuration. This description briefly explains what plugins are used and how they the metrics are routed/filtered to output-plugins. 

## Plugins included

**Inputs:**
- 1 x `influxdb_listener`

**Outputs:**
- 2 x `http`
- 1 x `influxdb` 

## Agent

Agent-configuration can be found in: [telegraf.conf](telegraf.conf).

- Agent configuration manages flushing and buffering metrics.
- Controlling the inputs is unnecessary, since here the `inputs.influxdb_listener` is service input, which means that it will be listening for incoming metrics constantly.

## Inputs

Input-plugins can be found in: [inputs.conf](inputs.conf).

### inputs.influxdb_listener

- The `inputs.influxdb_listener` plugin listens for incoming requests sent according to the `InfluxDB HTTP API`.
- Incoming metrics are additionally tagged with their original destination-database, this is used to route metrics to different outputs.
- Added database-tag is excluded from the written metrics.

## Outputs

Output-plugins can be found in: [outputs.conf](outputs.conf).

### outputs.http

- The `outputs.http` uses JSON-transformation to format and then output the metrics to user defined HTTP-endpoint. 
- Metrics are routed to two different HTTP-endpoints and filtering is done by interpreting the `database_tag`.

### outputs.influxdb

- The `outputs.influxdb` is used to output incoming metrics to local `InfluxDB v1.8` database. 
- For this to work make sure that you can reach the local InfluxDB-database using this URL: `http://127.0.0.1:8086`. You can also change this URL manually if it doesn't match your setup.


## Filtering and routing

This configuration uses some filtering to route metrics to multiple outputs. It is important to understand that the `inputs.influxdb_listener` reads the destination-database from the incoming requests and tags the metric with that information.

Incoming metrics are routed to local databases with the same names as the destination-databases. This mechanic can be simplified as simple data-transfer from one system to another, some could call this replication.

Incoming metrics are also routed to another output: `outputs.http`. There are two of these outputs in the configuration and they are identical apart from the URLs. These outputs sends metrics to two different HTTP-endpoints depending on the `database_tag`.


