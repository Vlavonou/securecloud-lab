variable "aws_region" {
  description = "Region AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR block du VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "my_ip" {
  description = "Mon IP publique pour accès SSH"
  type        = string
}

variable "key_pair_name" {
  description = "Nom de la paire de clés SSH"
  type        = string
}
