variable "collection_name" {
  description = "Nome da coleção OpenSearch Serverless"
  type        = string
}

variable "collection_description" {
  description = "Descrição da coleção OpenSearch Serverless"
  type        = string
  default     = "OpenSearch Serverless Collection"
}

variable "collection_type" {
  description = "Tipo da coleção OpenSearch Serverless: SEARCH, TIMESERIES, ou VECTORSEARCH"
  type        = string
  default     = "SEARCH"
  validation {
    condition     = contains(["SEARCH", "TIMESERIES", "VECTORSEARCH"], var.collection_type)
    error_message = "O tipo da coleção deve ser SEARCH, TIMESERIES ou VECTORSEARCH."
  }
}

variable "standby_replicas" {
  description = "Se deve habilitar réplicas em standby para alta disponibilidade"
  type        = bool
  default     = false
}

variable "max_indexing_capacity" {
  description = "Capacidade máxima em OCUs (OpenSearch Compute Units)"
  type        = number
  default     = 2
}

variable "max_search_capacity" {
  description = "Capacidade máxima de pesquisa em OCUs (OpenSearch Compute Units) - não usado diretamente"
  type        = number
  default     = 2
}

variable "use_aws_owned_key" {
  description = "Se deve usar chave KMS gerenciada pela AWS para criptografia"
  type        = bool
  default     = true
}

variable "collection_permissions" {
  description = "Lista de permissões para a coleção"
  type        = list(string)
  default     = ["aoss:*"]
}

variable "index_permissions" {
  description = "Lista de permissões para os índices"
  type        = list(string)
  default     = ["aoss:*"]
}

variable "principal_list" {
  description = "Lista de ARNs de principais que podem acessar a coleção (não usado diretamente, mantido para compatibilidade)"
  type        = list(string)
  default     = []
}

variable "create_network_policy" {
  description = "Se deve criar uma política de rede"
  type        = bool
  default     = false
}

variable "allow_from_public" {
  description = "Se deve permitir acesso público à coleção"
  type        = bool
  default     = false
}

variable "vpc_endpoint_config" {
  description = "Configuração do VPC Endpoint para a coleção"
  type = object({
    security_group_ids = list(string)
    subnet_ids         = list(string)
    vpc_id             = string
  })
  default = null
}

variable "environment" {
  description = "Ambiente de implantação (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "create_iam_role" {
  description = "Se deve criar uma IAM Role para acesso à coleção OpenSearch Serverless"
  type        = bool
  default     = false
}

variable "trusted_services" {
  description = "Lista de serviços AWS que podem assumir a IAM Role"
  type        = list(string)
  default     = ["lambda.amazonaws.com", "firehose.amazonaws.com"]
}