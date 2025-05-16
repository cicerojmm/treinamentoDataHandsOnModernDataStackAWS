variable "name_prefix" {
  description = "Prefixo para nomear os recursos"
  type        = string
}

variable "environment" {
  description = "Ambiente (dev, staging, prod)"
  type        = string
}

variable "database_name" {
  description = "Nome da database do Glue que será criada"
  type        = string
}

variable "database_description" {
  description = "Descrição da database do Glue"
  type        = string
  default     = "Database criada pelo Terraform para armazenar tabelas Delta Lake"
}

variable "s3_target_path" {
  description = "Caminho S3 onde estão os arquivos Delta Lake (formato: s3://bucket-name/prefix/)"
  type        = string
}

variable "crawler_description" {
  description = "Descrição do crawler"
  type        = string
  default     = "Crawler para arquivos Delta Lake"
}

variable "crawler_schedule" {
  description = "Expressão cron para agendamento do crawler (deixe vazio para execução manual)"
  type        = string
  default     = ""
}

variable "table_prefix" {
  description = "Prefixo para as tabelas criadas pelo crawler"
  type        = string
  default     = ""
}


variable "delta_options" {
  description = "Configurações específicas para o formato Delta Lake"
  type        = map(string)
  default = {
    "connectionName" = ""  # Opcional: nome da conexão se necessário
    "readRatio"      = "0.1" # Taxa de leitura para otimização
  }
}