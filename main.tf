# Configure the Microsoft Azure Provider
provider "azurerm" {

    subscription_id = "${var.subscription_id}"
    client_id       = "${var.client_id}"
    client_secret   = "${var.client_secret}"
    tenant_id       = "${var.tenant_id}"
}

# Create a resource group if it doesn’t exist
resource "azurerm_resource_group" "myterraformgroup" {
    name     = "myazResourceGroup"
    location = "eastus"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual network
resource "azurerm_virtual_network" "myterraformnetwork" {
    name                = "myazVnet"
    address_space       = ["10.0.0.0/16"]
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create subnet
resource "azurerm_subnet" "myterraformsubnet" {
    name                 = "myazSubnet"
    resource_group_name  = "${azurerm_resource_group.myterraformgroup.name}"
    virtual_network_name = "${azurerm_virtual_network.myterraformnetwork.name}"
    address_prefix       = "10.0.1.0/24"
}

# Create public IPs
resource "azurerm_public_ip" "myterraformpublicip" {
    name                         = "myPublicIP"
    location                     = "eastus"
    resource_group_name          = "${azurerm_resource_group.myterraformgroup.name}"
    allocation_method            = "Dynamic"

    tags = {
        environment = "Terraform Demo"
    }
 }
# Create Network Security Group and rule
resource "azurerm_network_security_group" "myterraformnsg" {
    name                = "myNetworkSecurityGroup"
    location            = "eastus"
    resource_group_name = "${azurerm_resource_group.myterraformgroup.name}"

    security_rule {
        name                       = "SSH"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "22"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }

	security_rule {
        name                       = "WebPort"
        priority                   = 1011
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "TCP"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
    }
    tags = {
        environment = "Terraform Demo"
    }
}

# Create network interface
resource "azurerm_network_interface" "myterraformnic" {
    name                      = "myNIC"
    location                  = "eastus"
    resource_group_name       = "${azurerm_resource_group.myterraformgroup.name}"
    network_security_group_id = "${azurerm_network_security_group.myterraformnsg.id}"

    ip_configuration {
        name                          = "myNicConfiguration"
        subnet_id                     = "${azurerm_subnet.myterraformsubnet.id}"
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "${azurerm_public_ip.myterraformpublicip.id}"
    }

    tags = {
        environment = "Terraform Demo"
    }
}

# Generate random text for a unique storage account name
resource "random_id" "randomId" {
    keepers = {
        # Generate a new ID only when a new resource group is defined
        resource_group = "${azurerm_resource_group.myterraformgroup.name}"
    }

    byte_length = 8
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "myazstorageaccount" {
    name                        = "diag${random_id.randomId.hex}"
    resource_group_name         = "${azurerm_resource_group.myterraformgroup.name}"
    location                    = "eastus"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

    tags = {
        environment = "Terraform Demo"
    }
}

# Create virtual machine
resource "azurerm_virtual_machine" "myterraformvm" {
    name                  = "myazVM"
    location              = "eastus"
    resource_group_name   = "${azurerm_resource_group.myterraformgroup.name}"
    network_interface_ids = ["${azurerm_network_interface.myterraformnic.id}"]
    vm_size               = "Standard_D2s_v3"

    storage_os_disk {
        name              = "myOsDisk"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Premium_LRS"
    }

    storage_image_reference {
        publisher = "Canonical"
        offer     = "UbuntuServer"
        sku       = "16.04-LTS"
        version   = "latest"
    }

    os_profile {
        computer_name  = "myazvm"
        admin_username = "Admin123"
        #admin_password = "Password1234!"
    }

    os_profile_linux_config {
     disable_password_authentication = true
       ssh_keys {
       path     = "/home/Admin123/.ssh/authorized_keys"
            key_data = "ssh-rsa AAAAB3NzaC1yc2EAAAABJQAAAQEAp7r/xcCbKwWOA+/WXBmGFTsFpykA930Eub+bgd32IB/09XDM4WAuFp1fesb4geH5/zLK66GvoM2VeSS26WVTOSf/X+V+lYNC0bv3Pyq00jZc+46K1Ki0VBaRqM8puYh13pDH7ka/rLSETNQBjPDRItrry1p/oLMmdPw4oA2qcyu5e62wMu9I30i8GlwuQ27nvtwIBGIu85THyT7GoLYeRrLZSv7+L6wCd+Xy48trPULLOZtEdEDnQFbAsVO39rMTtQAnUsCfXw5KXtBn5XzZNjjycLGJcBeGC12FpzvGEiBSz2em1ExkU4732vJJ47wnH4AYjhIiEegAcdyaw4PJrw=="
    }
     }
    boot_diagnostics {
        enabled = "true"
        storage_uri = "${azurerm_storage_account.myazstorageaccount.primary_blob_endpoint}"
    }

    tags = {
        environment = "Terraform Demo"
    }
        #custom_data = "${file("ssh.sh)}"
        
        }

  data "azurerm_public_ip" "myterraformpublicip" {
   name                = "${azurerm_public_ip.myterraformpublicip.name}"
   resource_group_name = "${azurerm_virtual_machine.myterraformvm.resource_group_name}"
  }

output "public_ip_address" {
value = "${data.azurerm_public_ip.myterraformpublicip.ip_address}"

}




 
 #resource "null_resource" "remote" {
  

  #provisioner "local-exec" {
   #      command = " ANSIBLE_HOST_KEY_CHECKING=False ansible -i hosts -u Admin123 --private-key /root/.ssh/divya.pem  all -m ping"
 # }
#}
