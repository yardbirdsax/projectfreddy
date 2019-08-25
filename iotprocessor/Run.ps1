[CmdletBinding()]
param 
(
  # Storage Account Name
  [Parameter(Mandatory)]
  [String]
  $StorageAccountName,

  # Storage Account Key
  [Parameter(Mandatory)]
  [String]
  $StorageAccountKey,

  # Event Hub Name
  [Parameter(Mandatory)]
  [String]
  $EventHubName,

  # Event Hub Connection String
  [Parameter(Mandatory)]
  [string]
  $EventHubConnectionString,

  # Storage Account Container Name
  [Parameter(Mandatory)]
  [String]
  $StorageAccountContainerName,

  [Switch]
  $Run
)

Set-StrictMode -Version Latest;

[System.Environment]::SetEnvironmentVariable("iotprocessor.event_hub_connection_string",$EventHubConnectionString)
[System.Environment]::SetEnvironmentVariable("iotprocessor.event_hub_name",$EventHubName)
[System.Environment]::SetEnvironmentVariable("iotprocessor.storage_container_name",$StorageAccountContainerName)
[System.Environment]::SetEnvironmentVariable("iotprocessor.storage_account_name",$StorageAccountName)
[System.Environment]::SetEnvironmentVariable("iotprocessor.storage_account_key",$StorageAccountKey)

if ($Run)
{
  & dotnet.exe run
}