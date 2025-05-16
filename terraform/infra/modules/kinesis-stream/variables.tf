variable "name" {
  description = "Nome do Kinesis Stream"
  type        = string
}

variable "shard_count" {
  description = "Número de shards para o Kinesis Stream"
  type        = number
  default     = 1
}

variable "retention_period" {
  description = "Período de retenção em horas para o Kinesis Stream"
  type        = number
  default     = 24
}

variable "stream_mode" {
  description = "Modo do stream: PROVISIONED ou ON_DEMAND"
  type        = string
  default     = "PROVISIONED"
  validation {
    condition     = contains(["PROVISIONED", "ON_DEMAND"], var.stream_mode)
    error_message = "O modo do stream deve ser PROVISIONED ou ON_DEMAND."
  }
}

variable "encryption_type" {
  description = "Tipo de criptografia para o Kinesis Stream: NONE, KMS"
  type        = string
  default     = "NONE"
  validation {
    condition     = contains(["NONE", "KMS"], var.encryption_type)
    error_message = "O tipo de criptografia deve ser NONE ou KMS."
  }
}

variable "kms_key_id" {
  description = "ID da chave KMS para criptografia (se encryption_type = KMS)"
  type        = string
  default     = null
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  default     = "dev"
}


variable "create_alarms" {
  description = "Se deve criar alarmes CloudWatch para o Kinesis Stream"
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "Lista de ARNs de ações para alarmes CloudWatch"
  type        = list(string)
  default     = []
}

variable "ok_actions" {
  description = "Lista de ARNs de ações para resolução de alarmes CloudWatch"
  type        = list(string)
  default     = []
}

variable "create_iam_role" {
  description = "Se deve criar uma IAM Role para acesso ao Kinesis Stream"
  type        = bool
  default     = false
}

variable "trusted_services" {
  description = "Lista de serviços AWS que podem assumir a IAM Role"
  type        = list(string)
  default     = ["lambda.amazonaws.com", "firehose.amazonaws.com"]
}