# Integração Kinesis Stream → Firehose → OpenSearch Serverless

# Gerador de sufixo aleatório para nomes únicos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Kinesis Stream
module "kinesis_stream" {
  source = "./modules/kinesis-stream"

  name             = "datahandson-mds-analytics-stream"
  shard_count      = 1
  retention_period = 24
  stream_mode      = "PROVISIONED"
  environment      = var.environment
  create_iam_role  = true
}

# OpenSearch Serverless
module "opensearch_serverless" {
  source = "./modules/opensearch-serverless"

  collection_name        = "datahandson-mds-analytics"
  collection_description = "Coleção para análise de dados em tempo real"
  collection_type        = "SEARCH"
  standby_replicas       = false
  max_indexing_capacity  = 2  # 2 OCUs para indexação
  max_search_capacity    = 2  # 2 OCUs para pesquisa
  use_aws_owned_key      = true
  create_network_policy  = true
  allow_from_public      = true  # Configurado para permitir acesso público
  environment            = var.environment
  create_iam_role        = true
}

# Kinesis Firehose
module "kinesis_firehose" {
  source = "./modules/kinesis-firehose"

  delivery_stream_name = "datahandson-mds-analytics-delivery-stream"
  
  kinesis_source_configuration = {
    kinesis_stream_arn = module.kinesis_stream.stream_arn
  }
  
  opensearchserverless_configuration = {
    index_name          = "datahandson-mds-analytics"
    collection_endpoint = module.opensearch_serverless.collection_endpoint
    collection_arn      = module.opensearch_serverless.collection_arn
    s3_backup_mode      = "AllDocuments"
    buffering_interval  = 30  # 30 segundos para o buffer do OpenSearch
    buffering_size      = 5   # 5 MB para o buffer do OpenSearch
  }
  
  s3_configuration = {
    bucket_arn         = "arn:aws:s3:::${var.s3_bucket_raw}"
    prefix             = "kinesis-stream/mds-web-events"
    buffering_size     = 5
    buffering_interval = 60
    compression_format = "GZIP"
  }
  
  environment = var.environment
}