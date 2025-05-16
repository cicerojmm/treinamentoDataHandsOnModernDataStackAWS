variable "delivery_stream_name" {
  description = "Nome do Kinesis Firehose Delivery Stream"
  type        = string
}

variable "kinesis_source_configuration" {
  description = "Configuração da origem do Kinesis Stream"
  type = object({
    kinesis_stream_arn = string
  })
  default = null
}

variable "opensearchserverless_configuration" {
  description = "Configuração do destino OpenSearch Serverless"
  type = object({
    index_name          = string
    collection_endpoint = string
    collection_arn      = string
    s3_backup_mode      = string
    buffering_interval  = optional(number, 300)
    buffering_size      = optional(number, 5)
  })
  default = null
}

variable "s3_configuration" {
  description = "Configuração do S3 para backup ou destino principal"
  type = object({
    bucket_arn         = string
    prefix             = string
    buffering_size     = number
    buffering_interval = number
    compression_format = string
  })
}

variable "lambda_processor_arn" {
  description = "ARN da função Lambda para processamento de dados (opcional)"
  type        = string
  default     = null
}

variable "log_retention_days" {
  description = "Número de dias para retenção de logs no CloudWatch"
  type        = number
  default     = 14
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  default     = "dev"
}
