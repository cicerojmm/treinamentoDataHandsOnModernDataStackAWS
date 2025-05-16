resource "aws_glue_catalog_database" "delta_database" {
  name        = var.database_name
  description = var.database_description
  
  parameters = {
    "classification" = "delta"
  }
}

# IAM Role para o Glue Crawler
resource "aws_iam_role" "glue_crawler_role" {
  name = "${var.name_prefix}-${var.environment}-glue-crawler-role"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "glue.amazonaws.com"
        }
      }
    ]
  })
}

# Política para o Glue Crawler acessar o S3 e o Glue Data Catalog
resource "aws_iam_policy" "glue_crawler_policy" {
  name        = "${var.name_prefix}-${var.environment}-glue-crawler-policy"
  description = "Política para o Glue Crawler acessar o S3 e o Glue Data Catalog"
  
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "glue:*",
          "s3:GetBucketLocation",
          "s3:ListBucket",
          "s3:GetObject",
          "s3:GetObjectVersion",
          "s3:PutObject"
        ],
        Resource = [
          "*",
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ],
        Resource = [
          "arn:aws:logs:*:*:/aws-glue/*"
        ]
      }
    ]
  })
  
}

# Anexar a política à role
resource "aws_iam_role_policy_attachment" "glue_crawler_policy_attachment" {
  role       = aws_iam_role.glue_crawler_role.name
  policy_arn = aws_iam_policy.glue_crawler_policy.arn
}

resource "aws_glue_crawler" "delta_crawler" {
  name          = "${var.name_prefix}-${var.environment}-delta-crawler"
  description   = var.crawler_description
  database_name = aws_glue_catalog_database.delta_database.name
  role          = aws_iam_role.glue_crawler_role.arn
  
  schedule = var.crawler_schedule != "" ? var.crawler_schedule : null
  
  delta_target {
    delta_tables = [var.s3_target_path]
    write_manifest = true
    
    connection_name = var.delta_options["connectionName"] != "" ? var.delta_options["connectionName"] : null
  }
  
  configuration = jsonencode({
    Version = 1.0
    CrawlerOutput = {
      Tables = { 
        AddOrUpdateBehavior = "MergeNewColumns"
        TableThreshold = 1
      }
    }
    Grouping = {
      TableGroupingPolicy = "CombineCompatibleSchemas"
    }
  })
  
  schema_change_policy {
    delete_behavior = "LOG"
    update_behavior = "UPDATE_IN_DATABASE"
  }
  
  lineage_configuration {
    crawler_lineage_settings = "ENABLE"
  }

}