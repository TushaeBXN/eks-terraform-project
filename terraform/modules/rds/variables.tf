variable "cluster_name" {
  description = "Used to namespace RDS resources"
  type        = string
  default     = "eks-portfolio-cluster"
}

variable "vpc_id" {
  description = "VPC where the RDS instance will live"
  type        = string
}

variable "vpc_cidr" {
  description = "VPC CIDR — used to scope the RDS security group ingress"
  type        = string
  default     = "10.0.0.0/16"
}

variable "private_subnet_ids" {
  description = "Private subnets for the DB subnet group"
  type        = list(string)
}

variable "db_instance_class" {
  description = "RDS instance type"
  type        = string
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "Initial database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "Master username"
  type        = string
  default     = "dbadmin"
}

variable "db_password" {
  description = "Master password — pass via environment variable TF_VAR_db_password, never hardcode"
  type        = string
  sensitive   = true
}
