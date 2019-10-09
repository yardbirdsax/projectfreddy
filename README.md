# Azure IOT Hub and Raspberry Pi Sample

[![Build Status](https://dev.azure.com/yardbirdsax/projectfreddy/_apis/build/status/yardbirdsax.projectfreddy?branchName=dev)](https://dev.azure.com/yardbirdsax/projectfreddy/_build/latest?definitionId=3&branchName=dev)

This folder contains some sample code on how to read temperature data from a DS18B20 sensor and send to Azure IOT hubs.

## Pre-requisites

1. You must have an active Azure subscription.
1. You must have a working Raspberry Pi (this was tested on a 3B+, your mileage may vary on other models).
1. You must have the Azure CLI installed.
1. You must have the Azure CLI IOT extension installed.

    ```bash
    az extension add --name azure-cli-iot-ext
    ```

1. You must have a resource group to deploy the IOT hub in. I would recommend creating an empty one to make clean-up easy.

    ```bash
    az group create -n <resource group name> --location <location>
    ```

## Deploying the IOT hub

1. Download a copy of the [azureparameters.json](azureparameters.json) file.
1. In a text editor, replace parameter values as required. At a minimum, you must change the value of the IOT hub name (iotHubName) parameters, otherwise your deployment will almost certainly fail since it's using the current name of my lab. :)
1. Execute the following command in your command prompt interface:

    ```bash
    az group deployment create -g <resource group name> --template-uri https://github.com/yardbirdsax/pi-lab/az-iot-temp/azuredeploy.json --parameters @<path to parameters file>
    ```

    >**NOTE:** If you are running the Azure CLI under Windows, you must escape the '@' character in the above command by using the backtick (`) character.

## Provisioning your Pi device

1. Provision a new device identity.

    ```bash
    az iot hub device-identity create --hub-name <IOT Hub Name> --device-id <device name>
    ```

1. Get a connection string for your device.

    ```bash
    az iot hub device-identity show-connection-string --hub-name <IOT Hub Name> --device-id <device name> --output table
    ```

    Save the connection string for later use.

## Preparing the Raspberry Pi device

1. Install Docker.

    ```bash
    curl -sSL https://get.docker.com | sudo sh
    ```

## Running the container

To run the container, use this command:

```bash
sudo docker run -e temp2aziot.connection_string="<IOT hub connection string>" -d -h ${HOSTNAME} --name temp2aziot yardbirdsax/temp2aziot:latest
sudo docker logs temp2aziot -f
```

You should see something like this in the output.

```
[2019-08-11T14:08:04+0000]      Sending message: {"device":"terrariumpi","temp":94.33,"datetime":"2019-08-11T14:08:04+0000"}
[2019-08-11T14:08:05+0000]      IoT Hub responded to message with status: OK
```

There are two additional optional configuration variables available:

| Variable Name                 | Description                                       | Default Value |
|-------------------------------|---------------------------------------------------|---------------|
| temp2aziot.send_interval      | The interval, in seconds, that data will be collected sent to the IOT hub.  | 10
| temp2aziot.max_send_errors    | The maximum number of send errors that can be captured before the process will exit. | 100

When running the Docker container, use additional `-e` flags to set these. For example:

```bash
sudo docker run -e temp2aziot.send_interval=30 -e temp2aziot.max_send_errors=10 -e temp2aziot.connection_string="<IOT hub connection string>" -d -h ${HOSTNAME} --name temp2aziot yardbirdsax/temp2aziot:latest
```
