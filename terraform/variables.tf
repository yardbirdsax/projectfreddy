variable deploymentName {
  type = string
  default = "projectfreddy"
}

variable region {
  type = string
  default = "eastus2"
}

variable environment {
  type = map(object({
    iotHub = object({
      sku = string
      tier = string
      capacity = number
    })
    # streamAnalytics = object({
    #   units = number
    # })
  }))
}