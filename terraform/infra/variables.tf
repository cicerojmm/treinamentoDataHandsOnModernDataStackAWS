variable "global_tags" {
  type = map(string)
  default = {
    Projeto     = "DATA_HANDSON_MDS"
  }
  description = "Tags aplicadas globalmente a todos os recursos"
}

variable "environment" {
  description = "Nome do ambiente (ex: dev, prod)"
  type        = string
}


