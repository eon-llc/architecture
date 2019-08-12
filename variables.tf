variable "access_key" {}
variable "secret_key" {}
variable "github_token" {}

variable "region" {
  description = "Region for the VPC"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_a_cidr" {
  description = "CIDR for the public subnet a"
  default     = "10.0.1.0/24"
}

variable "public_subnet_b_cidr" {
  description = "CIDR for the public subnet b"
  default     = "10.0.2.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "10.0.3.0/24"
}

variable "amazon_linux_ami" {
  description = "Amazon Linux AMI"
  default     = "ami-0c6b1d09930fac512"
}

variable "ubuntu_18_ami" {
  description = "Amazon Linux AMI"
  default     = "ami-07d0cf3af28718ef8"
}

variable "ubuntu_16_ami" {
  description = "Amazon Linux AMI"
  default     = "ami-07b4156579ea1d7ba"
}
