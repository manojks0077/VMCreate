provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "example" {
  name     = "MKS-ResourcesGroup"
  location = "West Europe"
}

resource "azurerm_virtual_network" "example" {
  name                = "MKS-Network"
  address_space       = ["10.10.0.0/16"]
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
}

resource "azurerm_subnet" "internal" {
  count                = 5
  name                 = "subnet-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.example.name
  virtual_network_name = azurerm_virtual_network.example.name
  address_prefixes     = ["10.10.${count.index}.0/24"]
}

resource "azurerm_public_ip" "example" {
  count                = 10
  name                 = "MKS-public-ip-${count.index}"
  location             = azurerm_resource_group.example.location
  resource_group_name  = azurerm_resource_group.example.name
  allocation_method    = "Dynamic"
}

resource "azurerm_network_interface" "example" {
  count               = 10
  name                = "MKS-nic-${count.index}"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.internal[count.index % 2].id
# If the VM needs to get IP automatically
    private_ip_address_allocation = "Dynamic"
# If the VM needs to get IP Assigned.
    private_ip_address_allocation = "Static"
    private_ip_address            = "10.0.${count.index % 2}.4"

    public_ip_address_id          = azurerm_public_ip.example[count.index].id
  }
}

resource "azurerm_windows_virtual_machine" "example" {
  count               = 10
  name                = "MKS-machine-${count.index}"
  resource_group_name = azurerm_resource_group.example.name
  location            = azurerm_resource_group.example.location
  network_interface_ids = [azurerm_network_interface.example[count.index].id]
  size                = "Standard_F2"
  admin_username      = "adminuser"
  admin_password      = "P@$$w0rd1234!"

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2016-Datacenter"
    version   = "latest"
  }

}