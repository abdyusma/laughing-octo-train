provider "azurerm" {
  features {}
}

locals {
  tags = {
    environment = "test"
  }
}

data "azurerm_resource_group" "main" {
  name = "cmydevops"
}

data "azurerm_virtual_network" "main" {
  name                = "cmydevopsVNET"
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
    subnet_id                     = data.azurerm_subnet.main.id
  }
}

resource "azurerm_private_dns_zone" "main" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = data.azurerm_resource_group.main.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "main" {
  name                = "6i2dd5veyofay"
  resource_group_name = data.azurerm_resource_group.main.name
  virtual_network_id  = data.azurerm_virtual_network.main.id

  tags = local.tags
}

resource "azurerm_storage_account" "main" {
  name                     = "cmydevops"
  resource_group_name      = data.azurerm_resource_group.main.name
  location                 = data.azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  min_tls_version = "TLS1_0"

  tags = local.tags
}

resource "azurerm_private_endpoint" "main" {
  name                = "cmyendpoint"
  resource_group_name = data.azurerm_resource_group.main.name
  location            = data.azurerm_resource_group.main.location
  subnet_id           = data.azurerm_subnet.main.id

  custom_network_interface_name = azurerm_network_interface.main.name

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.main.id]
  }

  private_service_connection {
    name                           = "cmyendpoint"
    private_connection_resource_id = azurerm_storage_account.main.id
    is_manual_connection           = false
    subresource_names = [
      "blob"
    ]
  }
  tags = local.tags
}

resource "azurerm_private_dns_a_record" "main" {
  name                = "cmydevops"
  resource_group_name = data.azurerm_resource_group.main.name
  zone_name           = azurerm_private_dns_zone.main.name
  ttl                 = "10"
  records             = [azurerm_network_interface.main.private_ip_address]
}
