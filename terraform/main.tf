provider azurerm {

}

provider aws {
  region = "us-east-2"
}

locals {
  deploymentName = "${var.deploymentName}-${terraform.workspace}"
}

resource azurerm_resource_group resourceGroup {
  name = "${var.region}-${local.deploymentName}"
  location = var.region
}

resource azurerm_iothub iotHub {
  resource_group_name = azurerm_resource_group.resourceGroup.name
  name = local.deploymentName  
  location = azurerm_resource_group.resourceGroup.location
  sku {
    capacity = var.environment[terraform.workspace].iotHub.capacity
    name = var.environment[terraform.workspace].iotHub.sku
    tier = var.environment[terraform.workspace].iotHub.tier
  }
  route {
    enabled = true
    endpoint_names = ["events"]
    name = "Default"
    source = "DeviceMessages"
  }
}

output iotHub {
  value = azurerm_iothub.iotHub
}

resource azurerm_iothub_consumer_group streamAnalyticsConsumer {
  name = "StreamAnalytics"
  iothub_name = azurerm_iothub.iotHub.name
  resource_group_name = azurerm_iothub.iotHub.resource_group_name
  eventhub_endpoint_name = "events"
}

# resource azurerm_iothub_shared_access_policy streamAnalyticsIotPolicy {
#   iothub_name = azurerm_iothub.iotHub.name
#   name = "StreamAnalytics"
#   service_connect = true
#   resource_group_name = azurerm_resource_group.resourceGroup.name
# }

# resource azurerm_stream_analytics_job streamAnalyticsJob {
#   name = local.deploymentName
#   resource_group_name = azurerm_resource_group.resourceGroup.name
#   location = azurerm_resource_group.resourceGroup.location

#   streaming_units = var.environment[terraform.workspace].streamAnalytics.units

#   transformation_query = <<QUERY
# SELECT * FROM [IOTHub];
# QUERY

# }

# resource azurerm_stream_analytics_stream_input_iothub streamAnalyticsInput {
#   name = "IOTHub"
#   endpoint = "messages/events"
#   eventhub_consumer_group_name = azurerm_iothub_consumer_group.streamAnalyticsConsumer.name
#   resource_group_name = azurerm_resource_group.resourceGroup.name
#   iothub_namespace = azurerm_iothub.iotHub.name
#   shared_access_policy_key = azurerm_iothub_shared_access_policy.streamAnalyticsIotPolicy.primary_key
#   shared_access_policy_name = azurerm_iothub_shared_access_policy.streamAnalyticsIotPolicy.name
#   stream_analytics_job_name = azurerm_stream_analytics_job.streamAnalyticsJob.name
#   serialization {
#     type = "Json"
#     encoding = "UTF8"
#   }
# }

# resource azurerm_cosmosdb_account cosmosdb {
  
# }