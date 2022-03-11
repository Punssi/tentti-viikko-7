terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 2.65"
    }
  }

  required_version = ">= 1.1.0"
}

provider "azurerm" {
  features {}
  subscription_id     = var.subscription_id
  tenant_id           = var.tenant_id
}

#Create a resource group
resource "azurerm_resource_group" "rg" {
  name                = var.resource_group_name
  location            = var.location
}

# Create a virtual network
resource "azurerm_virtual_network" "vnet" {
    name                = "taavi-checkpoint7-vnet"
    address_space       = ["10.0.0.0/16"]
    location            = var.location
    resource_group_name = var.resource_group_name
}

#Creat a Subnet
resource "azurerm_subnet" "subnet01" {
    name           = "taavi-subnet01"
    resource_group_name  = var.resource_group_name
    virtual_network_name = azurerm_virtual_network.vnet.name
    address_prefixes     = ["10.0.1.0/24"]
}

#Create a Network Security Group
resource "azurerm_network_security_group" "nsg" {
  name                = var.network_security_group_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

    security_rule {
        name                       = "SSH"
        priority                   = 100
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

    security_rule {
        name                       = "HTTP"
        priority                   = 150
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "*"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
  }
}

#Creat a Public Ip
resource "azurerm_public_ip" "pip" {
    name                = var.public_ip_name
    location            = var.location
    resource_group_name = var.resource_group_name
    allocation_method   = "Dynamic"
}

#Create a Network Interface
resource "azurerm_network_interface" "nic" {
  name                = var.network_interface_name
  location            = var.location
  resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
    name                          = "taavipip01"
    subnet_id                     = azurerm_subnet.subnet01.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id           = azurerm_public_ip.pip.id
  }
}

# Associate NIC and NSG
resource "azurerm_network_interface_security_group_association" "main" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

/* # Bootstrapping Template File
data "template_file" "nginx-vm-cloud-init" {
  template = file("install-nginx.sh")
} */

# Create Linux Nginx Virtual Machine
resource "azurerm_linux_virtual_machine" "vm" {

  depends_on            =[azurerm_network_interface.nic]
  name                  = var.linux_virtual_machine_name
  location              = var.location
  resource_group_name   = var.resource_group_name
  network_interface_ids = [azurerm_network_interface.nic.id]
  size                  = "Standard_DS1_v2"
  source_image_reference {
    publisher = "Canonical"
    offer = "UbuntuServer"
    sku = "16.04-LTS"
    version = "latest"
  }

   os_disk {
    name = "taaviosdisk01"
    caching = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  computer_name  = "hostname"
  admin_username = var.VMuser
  admin_password = var.VMpassword
  disable_password_authentication = false
  #custom_data = base64encode(data.template_file.nginx-vm-cloud-init.rendered)
}

resource "azurerm_virtual_machine_extension" "vme" {
  name                 = "nginx"
  virtual_machine_id   = azurerm_linux_virtual_machine.vm.id
  publisher            = "Microsoft.Azure.Extensions"
  type                 = "CustomScript"
  type_handler_version = "2.0"

  settings = <<SETTINGS
    {
        "commandToExecute": "sudo apt-get update && sudo apt install nginx -y && curl -H Metadata:true --noproxy '*' 'http://169.254.169.254/metadata/instance/network/interface/0?api-version=2021-01-01' | sudo tee /var/www/html/index.html"
    }
SETTINGS
}