variable "file_path" {
  description = "Path to the user-data file"
  default     = "../user-data"
}

variable "vpc_azs" {}
variable "vpc_name" {}
variable "vpc_cidr" {}
variable "vpc_public_subnets" {}
variable "vpc_enable_nat_gateway" {}
variable "vpc_enable_vpn_gateway" {}


# EC2 instance

variable "ec2_name" {}
variable "ec2_image" {}
variable "ec2_instance_type" {}
variable "ec2_key_name" {}
variable "ec2_monitoring" {}
