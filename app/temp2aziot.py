#!/usr/bin/env python
import yaml
import time
import os
from datetime import datetime
import pytz
import iothub_client
# pylint: disable=E0611
from iothub_client import IoTHubClient, IoTHubClientError, IoTHubTransportProvider, IoTHubClientResult
from iothub_client import IoTHubMessage, IoTHubMessageDispositionResult, IoTHubError, DeviceMethodReturnValue
from socket import gethostname
from w1thermsensor import W1ThermSensor

# Read configuration file
current_dir = os.path.dirname(os.path.realpath(__file__))
config_file_path = current_dir + '/config.yaml'
with open(config_file_path,"r") as f:
    config = yaml.load(f,yaml.SafeLoader)

# Constants
CONST_CONNECTION_STRING = config["connection_string"]
CONST_SEND_INTERVAL = config["send_interval"]
CONST_HOST_NAME = gethostname()
CONST_MSG_TEXT = "{\"device\":\"%s\",\"temp\":%.2f,\"datetime\":\"%s\"}"
CONST_IOT_PROTOCOL = IoTHubTransportProvider.MQTT
CONST_MAX_SEND_ERRORS = config["max_send_errors"]
CONST_STR_OK = "OK"

SEND_CALLBACKS = 0
SEND_ERRORS = 0


def iothub_client_init():
    client = IoTHubClient(CONST_CONNECTION_STRING,CONST_IOT_PROTOCOL)
    return client

def get_temp():
    sensor = W1ThermSensor()
    temperature = sensor.get_temperature(W1ThermSensor.DEGREES_F)
    return temperature

def send_confirmation_callback(message, result, user_context):
    global SEND_ERRORS
    result_str = "%s" % result
    if result_str == "OK":
        SEND_ERRORS = 0
        log ( "IoT Hub responded to message with status: %s" % (result) ) 
    else:
        SEND_ERRORS += 1
        log("IoTHub responed with error status: %s. Current error count is %i." % (result,SEND_ERRORS))


    if (SEND_ERRORS > CONST_MAX_SEND_ERRORS):
        log ("Maxium consecutive send error count (%i) exceeded. Program will now exit." % CONST_MAX_SEND_ERRORS)
        exit(1)

def log(message):
    formatted_datetime = datetime.utcnow().replace(tzinfo=pytz.utc).strftime("%Y-%m-%dT%H:%m:%S%z")
    print("[%s]\t%s" % (formatted_datetime,message))

while True:
    client = iothub_client_init()
    temp = get_temp()

    formatted_datetime = datetime.utcnow().replace(tzinfo=pytz.utc).strftime("%Y-%m-%dT%H:%m:%S%z")
    formatted_msg = CONST_MSG_TEXT % (CONST_HOST_NAME,temp,formatted_datetime)
    hub_msg = IoTHubMessage(formatted_msg)

    log("Sending message: %s" % hub_msg.get_string())
    client.send_event_async(hub_msg,send_confirmation_callback,None)

    time.sleep(CONST_SEND_INTERVAL)
