variable "project_name" {
  type = string
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aurora_endpoint" {
  type = string
  description = "Writer endpoint do cluster Aurora PostgreSQL"
}

variable "aurora_reader_endpoint" {
  type = string
  description = "Reader endpoint do cluster Aurora PostgreSQL"
  default = ""  # Será usado o endpoint principal se não for fornecido
}

variable "aurora_port" {
  type    = number
  default = 5432
}

variable "aurora_username" {
  type = string
}

variable "aurora_password" {
  type      = string
  sensitive = true
}

variable "aurora_db_name" {
  type = string
}

variable "s3_bucket_name" {
  type = string
}

variable "dms_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "enable_ssl" {
  type    = bool
  default = true
  description = "Habilitar conexão SSL com o Aurora PostgreSQL"
}

variable "log_retention_days" {
  description = "Número de dias para reter os logs do CloudWatch"
  type        = number
  default     = 14
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
  default     = "dev"
}
