################################################### Hub ################################################
# This peering to the hub virtual network will allow domain controllers to communicate with all session hosts
resource "azurerm_virtual_network_peering" "hub_peering" {
  name                      = var.hub_virtual_network["peering_name"]
  resource_group_name       = var.hub_resource_group_name
  virtual_network_name      = var.hub_virtual_network["name"]
  remote_virtual_network_id = azurerm_virtual_network.wvd.id
  allow_gateway_transit     = "true"
}

################################################### Windows Virtual Desktop ################################################

## This virtual network will host all session hosts
resource "azurerm_virtual_network" "wvd" {
  name                      = var.wvd_virtual_network["name"]
  address_space             = [var.wvd_virtual_network["address_space"]]
  location                  = azurerm_resource_group.wvd.location
  resource_group_name       = azurerm_resource_group.wvd.name
  dns_servers               = [var.wvd_virtual_network["dns_servers"]]
}

## This peering to the hub virtual network will allow session hosts to communicate with the domain controllers
resource "azurerm_virtual_network_peering" "wvd_peering" {
  name                      = var.wvd_virtual_network["peering_name"]
  resource_group_name       = azurerm_resource_group.wvd.name
  virtual_network_name      = azurerm_virtual_network.wvd.name
  remote_virtual_network_id = data.azurerm_virtual_network.hub.id
  use_remote_gateways       = "true"
  allow_forwarded_traffic   = "true"
}

## This subnet will host all Windows 10 session hosts
resource "azurerm_subnet" "wvd_clients" {
  name                 = var.wvd_virtual_network["clients_subnet_name"]
  resource_group_name  = azurerm_resource_group.wvd.name
  virtual_network_name = azurerm_virtual_network.wvd.name
  address_prefixes     = [var.wvd_virtual_network["clients_subnet_address_prefix"]]
}

## This subnet will host the Azure Bastion instance
resource "azurerm_subnet" "wvd_bastion" {
  name                 = var.wvd_virtual_network["bastion_subnet_name"]
  resource_group_name  = azurerm_resource_group.wvd.name
  virtual_network_name = azurerm_virtual_network.wvd.name
  address_prefixes     = [var.wvd_virtual_network["bastion_subnet_address_prefix"]]
}

## This public ip will be assigned to the Azure Bastion instance
resource "azurerm_public_ip" "wvd_bastion" {
  name                = var.wvd_public_ip_name
  location            = azurerm_resource_group.wvd.location
  resource_group_name = azurerm_resource_group.wvd.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

## Each session host will have a single network interface
resource "azurerm_network_interface" "wvd_hosts" {
  for_each                  = {for s in local.session_hosts : format("%s-%02d-01", s.vm_prefix, s.index+1) => s}
  name                      = "nic-${each.key}"
  location                  = azurerm_resource_group.wvd.location
  resource_group_name       = azurerm_resource_group.wvd.name

  ip_configuration {
    name                          = "ipc-${each.key}"
    subnet_id                     = azurerm_subnet.wvd_clients.id
    private_ip_address_allocation = "dynamic"
  }
}