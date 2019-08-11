# Azure IOT Hub and Raspberry Pi Sample

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

1. Install the Azure IOT device client and other required packages for Python.

    ```bash
    sudo pip3 install azure-iothub-device-client pyyaml w1thermsensor
    sudo apt-get install libboost-python1.62.0