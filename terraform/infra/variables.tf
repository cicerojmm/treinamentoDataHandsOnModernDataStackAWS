variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Região AWS onde os recursos serão criados"
  type        = string
  default     = "us-east-1"
}

variable "s3_bucket_raw" {
  description = "Nome do bucket S3 para armazenar dados brutos"
  type        = string
}

variable "s3_bucket_scripts" {
  description = "Nome do bucket S3 para armazenar scripts"
  type        = string
}

variable "s3_bucket_curated" {
  description = "Nome do bucket S3 para armazenar dados processados"
  type        = string
  default     = ""
}

variable "opensearch_domain_name" {
  description = "Nome do domínio OpenSearch"
  type        = string
  default     = ""
}

variable "opensearch_domain_arn" {
  description = "ARN do domínio OpenSearch"
  type        = string
  default     = ""
}