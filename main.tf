provider "azurerm" {
  features {}
}

data "azurerm_resource_group" "main" {
  name = "cmydevops"
}

data "azurerm_virtual_network" "main" {
  name                = "cmydevopsVNET"
  resource_group_name = data.azurerm_resource_group.main.name
}

resource "azurerm_storage_account" "main" {
  name                     = "cmydevops"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "GRS"

  tags = {
    environment = "test"
  }
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "main" {
  name                 = "cmydevopsSubnet"
  resource_group_name  = data.azurerm_resource_group.main.name
  virtual_network_name = data.azurerm_virtual_network.main.name
}

resource "azurerm_network_interface" "main" {
  name                = "cmyendpoint-nic"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location

  ip_configuration {
    name                          = "privateEndpointIpConfig.06e48e88-f1a7-4c7c-8604-1b07d0d8c5ba"
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_private_endpoint" "main" {
  name                = "cmyendpoint"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = data.azurerm_subnet.main.id

  private_service_connection {
    name                           = "main-privateserviceconnection"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
  }
}
