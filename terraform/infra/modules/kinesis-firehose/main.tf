# Kinesis Firehose Module

# IAM Role para o Firehose
resource "aws_iam_role" "firehose_role" {
  name = "${var.delivery_stream_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

# IAM Policy para o Firehose acessar o Kinesis Stream (se configurado)
resource "aws_iam_policy" "firehose_kinesis_policy" {
  count       = var.kinesis_source_configuration != null ? 1 : 0
  name        = "${var.delivery_stream_name}-kinesis-policy"
  description = "Permite que o Firehose leia do Kinesis Stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ]
        Effect   = "Allow"
        Resource = var.kinesis_source_configuration.kinesis_stream_arn
      }
    ]
  })
}

# IAM Policy para o Firehose acessar o OpenSearch Serverless (se configurado)
resource "aws_iam_policy" "firehose_opensearch_policy" {
  count       = var.opensearchserverless_configuration != null ? 1 : 0
  name        = "${var.delivery_stream_name}-opensearch-policy"
  description = "Permite que o Firehose escreva no OpenSearch Serverless"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "aoss:APIAccessAll",
          "aoss:BatchGetCollection",
          "aoss:CreateIndex",
          "aoss:WriteDocument"
        ]
        Effect   = "Allow"
        Resource = var.opensearchserverless_configuration.collection_arn
      }
    ]
  })
}

# IAM Policy para o Firehose usar o S3 para backup
resource "aws_iam_policy" "firehose_s3_policy" {
  name        = "${var.delivery_stream_name}-s3-policy"
  description = "Permite que o Firehose escreva no S3 para backup"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          var.s3_configuration.bucket_arn,
          "${var.s3_configuration.bucket_arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy para o Firehose usar o CloudWatch Logs
resource "aws_iam_policy" "firehose_cloudwatch_policy" {
  name        = "${var.delivery_stream_name}-cloudwatch-policy"
  description = "Permite que o Firehose escreva logs no CloudWatch"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy para o Firehose usar o Lambda (se configurado)
resource "aws_iam_policy" "firehose_lambda_policy" {
  count       = var.lambda_processor_arn != null ? 1 : 0
  name        = "${var.delivery_stream_name}-lambda-policy"
  description = "Permite que o Firehose invoque a função Lambda"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "lambda:InvokeFunction",
          "lambda:GetFunctionConfiguration"
        ]
        Effect   = "Allow"
        Resource = var.lambda_processor_arn
      }
    ]
  })
}

# Anexar as políticas à role do Firehose
resource "aws_iam_role_policy_attachment" "firehose_kinesis_attachment" {
  count      = var.kinesis_source_configuration != null ? 1 : 0
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_kinesis_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "firehose_opensearch_attachment" {
  count      = var.opensearchserverless_configuration != null ? 1 : 0
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_opensearch_policy[0].arn
}

resource "aws_iam_role_policy_attachment" "firehose_s3_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_s3_policy.arn
}

resource "aws_iam_role_policy_attachment" "firehose_cloudwatch_attachment" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_cloudwatch_policy.arn
}

resource "aws_iam_role_policy_attachment" "firehose_lambda_attachment" {
  count      = var.lambda_processor_arn != null ? 1 : 0
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_lambda_policy[0].arn
}

# CloudWatch Log Group para Firehose
resource "aws_cloudwatch_log_group" "firehose_log_group" {
  name              = "/aws/kinesisfirehose/${var.delivery_stream_name}"
  retention_in_days = var.log_retention_days
}

resource "aws_cloudwatch_log_stream" "firehose_log_stream" {
  name           = "${var.delivery_stream_name}-delivery"
  log_group_name = aws_cloudwatch_log_group.firehose_log_group.name
}

# Kinesis Firehose Delivery Stream
resource "aws_kinesis_firehose_delivery_stream" "this" {
  name        = var.delivery_stream_name
  destination = var.opensearchserverless_configuration != null ? "opensearchserverless" : "extended_s3"

  # Configuração de origem do Kinesis (opcional)
  dynamic "kinesis_source_configuration" {
    for_each = var.kinesis_source_configuration != null ? [var.kinesis_source_configuration] : []
    content {
      kinesis_stream_arn = kinesis_source_configuration.value.kinesis_stream_arn
      role_arn           = aws_iam_role.firehose_role.arn
    }
  }

  # Configuração do OpenSearch Serverless (opcional)
  dynamic "opensearchserverless_configuration" {
    for_each = var.opensearchserverless_configuration != null ? [var.opensearchserverless_configuration] : []
    content {
      index_name          = opensearchserverless_configuration.value.index_name
      role_arn            = aws_iam_role.firehose_role.arn
      collection_endpoint = opensearchserverless_configuration.value.collection_endpoint
      buffering_interval  = lookup(opensearchserverless_configuration.value, "buffering_interval", 300)
      buffering_size      = lookup(opensearchserverless_configuration.value, "buffering_size", 5)

      s3_backup_mode = opensearchserverless_configuration.value.s3_backup_mode

      # Configuração do processador Lambda (opcional)
      dynamic "processing_configuration" {
        for_each = var.lambda_processor_arn != null ? [1] : []
        content {
          enabled = true

          processors {
            type = "Lambda"

            parameters {
              parameter_name  = "LambdaArn"
              parameter_value = var.lambda_processor_arn
            }
          }
        }
      }

      # Configuração do S3 para backup
      s3_configuration {
        role_arn           = aws_iam_role.firehose_role.arn
        bucket_arn         = var.s3_configuration.bucket_arn
        prefix             = var.s3_configuration.prefix
        buffering_size     = var.s3_configuration.buffering_size
        buffering_interval = var.s3_configuration.buffering_interval
        compression_format = var.s3_configuration.compression_format

        cloudwatch_logging_options {
          enabled         = true
          log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
          log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
        }
      }

      # Configuração de logs CloudWatch
      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
        log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
      }
    }
  }

  # Configuração do S3 estendido (se não for OpenSearch)
  dynamic "extended_s3_configuration" {
    for_each = var.opensearchserverless_configuration == null ? [var.s3_configuration] : []
    content {
      role_arn           = aws_iam_role.firehose_role.arn
      bucket_arn         = extended_s3_configuration.value.bucket_arn
      prefix             = extended_s3_configuration.value.prefix
      buffering_size     = extended_s3_configuration.value.buffering_size
      buffering_interval = extended_s3_configuration.value.buffering_interval
      compression_format = extended_s3_configuration.value.compression_format

      # Configuração do processador Lambda (opcional)
      dynamic "processing_configuration" {
        for_each = var.lambda_processor_arn != null ? [1] : []
        content {
          enabled = true

          processors {
            type = "Lambda"

            parameters {
              parameter_name  = "LambdaArn"
              parameter_value = var.lambda_processor_arn
            }
          }
        }
      }

      cloudwatch_logging_options {
        enabled         = true
        log_group_name  = aws_cloudwatch_log_group.firehose_log_group.name
        log_stream_name = aws_cloudwatch_log_stream.firehose_log_stream.name
      }
    }
  }


  depends_on = [
    aws_iam_role_policy_attachment.firehose_kinesis_attachment,
    aws_iam_role_policy_attachment.firehose_opensearch_attachment,
    aws_iam_role_policy_attachment.firehose_s3_attachment,
    aws_iam_role_policy_attachment.firehose_cloudwatch_attachment,
    aws_iam_role_policy_attachment.firehose_lambda_attachment
  ]
}