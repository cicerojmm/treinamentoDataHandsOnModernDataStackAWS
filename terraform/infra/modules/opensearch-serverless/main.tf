# OpenSearch Serverless Module

# Obtém informações sobre a identidade atual
data "aws_caller_identity" "current" {}

# Gerador de sufixo aleatório para nomes únicos
resource "random_string" "suffix" {
  length  = 8
  special = false
  upper   = false
}

# Política de segurança para criptografia
resource "aws_opensearchserverless_security_policy" "encryption_policy" {
  name        = "encrypt-policy-${random_string.suffix.result}"
  type        = "encryption"
  description = "Encryption policy for ${var.collection_name} collection"
  policy = jsonencode({
    Rules = [
      {
        ResourceType = "collection",
        Resource     = ["collection/${var.collection_name}"]
      }
    ],
    AWSOwnedKey = var.use_aws_owned_key
  })
}

# Política de acesso aos dados
resource "aws_opensearchserverless_access_policy" "access_policy" {
  name        = "access-policy-${random_string.suffix.result}"
  type        = "data"
  description = "Access policy for ${var.collection_name} collection"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection",
          Resource     = ["collection/${var.collection_name}"],
          Permission   = var.collection_permissions
        },
        {
          ResourceType = "index",
          Resource     = ["index/${var.collection_name}/*"],
          Permission   = var.index_permissions
        }
      ],
      Principal = ["${data.aws_caller_identity.current.arn}"]
    }
  ])
}

# Política de rede (opcional) - Configurada para acesso público
resource "aws_opensearchserverless_security_policy" "network_policy" {
  count       = var.create_network_policy ? 1 : 0
  name        = "net-policy-${random_string.suffix.result}"
  type        = "network"
  description = "Network policy for ${var.collection_name} collection"
  policy = jsonencode([
    {
      Rules = [
        {
          ResourceType = "collection",
          Resource     = ["collection/${var.collection_name}"]
        },
        {
          ResourceType = "dashboard",
          Resource     = ["collection/${var.collection_name}"]
        }
      ],
      AllowFromPublic = var.allow_from_public
    }
  ])
}

# Coleção OpenSearch Serverless
resource "aws_opensearchserverless_collection" "this" {
  name        = var.collection_name
  description = var.collection_description
  type        = var.collection_type

  # Configuração de réplicas em standby
  standby_replicas = var.standby_replicas ? "ENABLED" : "DISABLED"


  depends_on = [
    aws_opensearchserverless_security_policy.encryption_policy,
    aws_opensearchserverless_access_policy.access_policy,
    aws_opensearchserverless_security_policy.network_policy
  ]
}

# VPC Endpoint para OpenSearch Serverless (opcional)
# Criado como um recurso separado em vez de um bloco aninhado
resource "aws_opensearchserverless_vpc_endpoint" "this" {
  count              = var.vpc_endpoint_config != null ? 1 : 0
  name               = "${var.collection_name}-vpc-endpoint"
  vpc_id             = var.vpc_endpoint_config.vpc_id
  subnet_ids         = var.vpc_endpoint_config.subnet_ids
  security_group_ids = var.vpc_endpoint_config.security_group_ids
}

# IAM Role para acesso ao OpenSearch Serverless (opcional)
resource "aws_iam_role" "opensearch_access" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.collection_name}-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.trusted_services
        }
      }
    ]
  })

}

resource "aws_iam_policy" "opensearch_access" {
  count       = var.create_iam_role ? 1 : 0
  name        = "${var.collection_name}-access-policy"
  description = "Policy for accessing ${var.collection_name} OpenSearch Serverless collection"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aoss:APIAccessAll",
          "aoss:BatchGetCollection",
          "aoss:CreateIndex",
          "aoss:WriteDocument",
          "aoss:ReadDocument",
          "aoss:DeleteIndex",
          "aoss:UpdateIndex"
        ]
        Effect   = "Allow"
        Resource = aws_opensearchserverless_collection.this.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "opensearch_access" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.opensearch_access[0].name
  policy_arn = aws_iam_policy.opensearch_access[0].arn
}