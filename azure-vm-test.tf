#Provider Init
terraform {
backend "azurerm" {
    resource_group_name = "SHW-INT-VIGCICD-RG"
    storage_account_name = "tsateblobviginter"
    container_name = "lintfstate"
    key = "/zrc1Zo4tldgDnT2nrJlro52d+9DMJurRrx/Np7nMzpzN4Qpcrn8ASWHgBdhzF0NBoyC35oeVYA59M9BKwXDNA=="
    
 }
}
#Provider Init
provider "azurerm" {
  version = ">= 1.0"
}

#Data Reference of Virtual network/Subnet used to create VM data "azurerm_subnet" "subnet" {

data "azurerm_subnet" "subnet" {
  name = "shaw-auth-vigno-cicd-t-sn"
  virtual_network_name = "SHAW-AUTH-VIGNO-CICD-T-vnet"
  resource_group_name = "SHAWAUTH-VIGNO-CICD-T-RG"
} 

data "azurerm_storage_account" "bootstorage" {
  name = "sysbootdiag"
  resource_group_name = "SHW-INT-VIGCICD-RG"
}


data "azurerm_key_vault" "keyvault" {
  name = "shwvignointervault"
  resource_group_name = "SHW-INT-VIGCICD-RG"
  
}

data "azurerm_key_vault_secret" "serveradminpwd" {
  name = "serveradminpwd"
  key_vault_id = "${data.azurerm_key_vault.keyvault.id}"  
}

#Create Resource Group
resource "azurerm_resource_group" "deployrg" {
    name = "app-terraform"
    location = "Central Us"
}

#Create NIC
resource "azurerm_network_interface" "nic" {
  count = "${var.count_of_VMs}"
  name = "${var.vm_name}.${count.index}-nic"
  location = "${azurerm_resource_group.deployrg.location}"
  resource_group_name = "${azurerm_resource_group.deployrg.name}"
  ip_configuration {
    name = "ipconfig"
    subnet_id = "${data.azurerm_subnet.subnet.id}"
    private_ip_address_allocation = "Dynamic"
  }
}

#Create Availability Set
resource "azurerm_availability_set" "avset" {
  name = "${var.vm_name}-avset"
  location = "${azurerm_resource_group.deployrg.location}"
  resource_group_name = "${azurerm_resource_group.deployrg.name}"
  platform_fault_domain_count = 2
  platform_update_domain_count = 2
  managed = true
}

#Create Managed Disks
resource "azurerm_managed_disk" "mdisk" {
  count = "${var.count_of_VMs}"
  name = "${var.vm_name}-${count.index}-datadisk"
  location = "${azurerm_resource_group.deployrg.location}"
  resource_group_name = "${azurerm_resource_group.deployrg.name}"
  storage_account_type = "Standard_LRS"
  create_option = "Empty"
  disk_size_gb = "1023"  
}


#Create Windows Virtual Machine
resource "azurerm_virtual_machine" "Windows_VM" { 
  count = "${var.OS_Image_Publisher == "MicrosoftWindowsServer" ? var.count_of_VMs : 0 }"
  name = "${var.vm_name}-${count.index}"
  resource_group_name = "${azurerm_resource_group.deployrg.name}"
  availability_set_id = "${azurerm_availability_set.avset.id}"
  location = "${azurerm_resource_group.deployrg.location}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  vm_size = "${var.vm_size}"

  storage_image_reference{
    publisher = "${var.OS_Image_Publisher}"
    offer = "${var.OS_Image_Offer}"
    sku = "${var.OS_Image_Sku}"
    version = "latest"
  }
  storage_os_disk{
    name = "${var.vm_name}-${count.index}-osdisk"
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  storage_data_disk {
    name = "${element(azurerm_managed_disk.mdisk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.mdisk.*.id, count.index)}"
    create_option = "Attach"
    lun = 1
    disk_size_gb = "${element(azurerm_managed_disk.mdisk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name = "${var.vm_name}-${count.index}"
    admin_username = "rxadmin"
    admin_password = "${data.azurerm_key_vault_secret.serveradminpwd.value}"
  }

  boot_diagnostics {
    enabled = true
    storage_uri = "${data.azurerm_storage_account.bootstorage.primary_blob_endpoint}"
  }
  os_profile_windows_config {
    provision_vm_agent = true
  }
}

#Custom Extension Script for Windows

    
#Chef Provisioner for Windows 


#Create Linux Virtual Machine
resource "azurerm_virtual_machine" "Linux_VM" { 
  count = "${var.OS_Image_Publisher != "MicrosoftWindowsServer" ? var.count_of_VMs : 0 }"
  name = "${var.vm_name}-${count.index}"
  resource_group_name = "${azurerm_resource_group.deployrg.name}"
  availability_set_id = "${azurerm_availability_set.avset.id}"
  location = "${azurerm_resource_group.deployrg.location}"
  network_interface_ids = ["${element(azurerm_network_interface.nic.*.id, count.index)}"]
  vm_size = "${var.vm_size}"

  storage_image_reference{
    publisher = "${var.OS_Image_Publisher}"
    offer = "${var.OS_Image_Offer}"
    sku = "${var.OS_Image_Sku}"
    version = "latest"
  }
  storage_os_disk{
    name = "${var.vm_name}-${count.index}-osdisk"
    caching = "ReadWrite"
    managed_disk_type = "Standard_LRS"
    create_option = "FromImage"
  }

  storage_data_disk {
    name = "${element(azurerm_managed_disk.mdisk.*.name, count.index)}"
    managed_disk_id = "${element(azurerm_managed_disk.mdisk.*.id, count.index)}"
    create_option = "Attach"
    lun = 1
    disk_size_gb = "${element(azurerm_managed_disk.mdisk.*.disk_size_gb, count.index)}"
  }

  os_profile {
    computer_name = "${var.vm_name}-${count.index}"
    admin_username = "rxadmin"
    admin_password = "${data.azurerm_key_vault_secret.serveradminpwd.value}"
  }

  boot_diagnostics {
    enabled = true
    storage_uri = "${data.azurerm_storage_account.bootstorage.primary_blob_endpoint}"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }

}
