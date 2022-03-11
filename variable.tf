variable "subscription_id" {}
variable "tenant_id" {}
variable "VMuser" {}
variable "VMpassword" {}
variable "resource_group_name" {
    default = "TaaviRG"
}
variable "location" {
    default = "westeurope"
}
variable "network_security_group_name" {
    default = "taaviNSG1"
}
variable "network_interface_name" {
    default = "taaviNIC01"
}
variable "linux_virtual_machine_name" {
    default = "taaviLS01"
}
/*
variable "storage_account_name" {
    default = "taavistorage01"
}
variable "storage_container_name" {
    default = "taaviblob01"
}

} */