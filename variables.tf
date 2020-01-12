variable "access_key" {}
variable "secret_key" {}
variable "cw_access_key" {}
variable "cw_secret_key" {}
variable "github_token" {}

variable "rem_account_name" {}
variable "rem_permission_name" {}
variable "rem_public_key" {}
variable "rem_private_key" {}
variable "rem_eth_wss_provider" {}
variable "rem_cryptocompare_api_key" {}

variable "hyperion_user" {}
variable "hyperion_pass" {}

variable "benchmark_db" {}
variable "benchmark_table" {}
variable "benchmark_user" {}
variable "benchmark_pass" {}
variable "benchmark_db_port" {}
variable "benchmark_private_key" {}
variable "benchmark_wallet_name" {}
variable "benchmark_wallet_pass" {}

variable "alert_db" {}
variable "telegram_table" {}
variable "alert_user" {}
variable "alert_pass" {}
variable "alert_db_port" {}

variable "discord_channel" {}

variable "eon_domain" {
  description = "Primary domain of Eon, LLC"
  default     = "https://eon.llc"
}

variable "region" {
  description = "Region for the VPC"
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR for the private subnet"
  default     = "10.0.3.0/24"
}

variable "rem_peer_address" {
  description = "IP Address of Remme Peer"
  default     = "167.71.88.152:9877"
}
