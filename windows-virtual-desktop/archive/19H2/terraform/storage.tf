################################################### Windows Virtual Desktop ################################################

## This storage account will host a file share used to store all users profiles
resource "azurerm_storage_account" "wvd" {
  name                      = var.wvd_storage_account_name
  location                  = azurerm_resource_group.wvd.location
  resource_group_name       = azurerm_resource_group.wvd.name
  account_tier              = "Standard"
  account_replication_type  = "LRS"
}

## This file share will be used to store all users profiles 
resource "azurerm_storage_share" "wvd" {
  name                 = "profiles"
  storage_account_name = azurerm_storage_account.wvd.name
  quota                = 5120
}