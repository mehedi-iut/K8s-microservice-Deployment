variable "public_subnet_id" {
  description = "Public Subnet ID"
}

variable "private_subnet_id" {
  description = "Private Subnet ID"
}

variable "security_group_id" {
  description = "Security Group ID"
}

variable "number_of_public_vm" {}

variable "number_of_private_vm" {}

variable "instance_type_public" {}

variable "instance_type_private" {}

variable "ami" {}

variable "public_vm_tags" {
  type = list(string)
  description = "tag value of public vm"
}

variable "private_vm_tags"{
  type = list(string)
  description = "tag value of private vm"
}

# variable "tag_to_public_ip_map" {
#   type = map(string)
# }