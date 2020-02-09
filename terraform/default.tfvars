region = "eastus2"
deploymentName = "projectfreddy"
environment = {
  "development" = {
    iotHub = {
      sku = "F1"
      tier = "Free"
      capacity = 1
    }
    # streamAnalytics = {
    #   units = 1
    # }
  }
}