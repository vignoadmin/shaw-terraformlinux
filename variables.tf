variable "vm_name" {
    description = "Enter desired name of VM"
    type = "string"
}

variable "vm_size" {
  description = "Enter the Size of VMs"
  default = "Standard_B1ls"
}

variable "count_of_VMs" {
  description = "Number of VMs you want to create as part of this deployment"
  #type = "string"
  default = 3
}
variable "OS_Image_Publisher" {
  description = "Give OS image with which you need to create virtual machines"
  type = "string"
  default = "Canonical"
}
variable "OS_Image_Offer" {
  description = "Provide the name of offer for the given publisher"
  type= "string"
  default = "UbuntuServer"
}
variable "OS_Image_Sku" {
  description = "Provide the version of sku. Ex:- 2019-Datacenter"
  type = "string"
  default = "16.04.0-LTS"
}

