variable "mwaa_env_name" {
  description = "Nome do ambiente MWAA"
  type        = string
}

variable "s3_bucket_arn" {
  description = "ARN do bucket S3 para armazenar DAGs"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de subnets para MWAA"
  type        = list(string)
}

variable "airflow_version" {
  description = "Versão do Apache Airflow"
  type        = string
  default     = "2.5.1"
}

variable "environment_class" {
  description = "Classe do ambiente MWAA"
  type        = string
  default     = "mw1.medium"
}

variable "min_workers" {
  description = "Número mínimo de workers"
  type        = number
  default     = 1
}

variable "max_workers" {
  description = "Número máximo de workers"
  type        = number
  default     = 5
}

variable "webserver_access_mode" {
  description = "Modo de acesso ao WebServer"
  type        = string
  default     = "PUBLIC_ONLY"
}

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

