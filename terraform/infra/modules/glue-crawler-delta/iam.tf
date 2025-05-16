# Este arquivo contém um exemplo de política IAM que pode ser usada pelo crawler
# Você pode usar este exemplo ou criar sua própria role IAM e passar o ARN como parâmetro

/*
# Exemplo de como criar uma role IAM para o Glue Crawler
# Descomente este código se quiser usar

resource "aws_iam_role" "glue_crawler_role" {
  count = var.role_arn == "" ? 1 : 0
  
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
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-${var.environment}-glue-crawler-role"
      Environment = var.environment
    }
  )
}

resource "aws_iam_policy" "glue_crawler_policy" {
  count = var.role_arn == "" ? 1 : 0
  
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
          "arn:aws:glue:*:*:catalog",
          "arn:aws:glue:*:*:database/${var.database_name}",
          "arn:aws:glue:*:*:table/${var.database_name}/*",
          "arn:aws:s3:::${split("/", replace(var.s3_target_path, "s3://", ""))[0]}",
          "${var.s3_target_path}*"
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
  
  tags = merge(
    var.tags,
    {
      Name        = "${var.name_prefix}-${var.environment}-glue-crawler-policy"
      Environment = var.environment
    }
  )
}

resource "aws_iam_role_policy_attachment" "glue_crawler_policy_attachment" {
  count = var.role_arn == "" ? 1 : 0
  
  role       = aws_iam_role.glue_crawler_role[0].name
  policy_arn = aws_iam_policy.glue_crawler_policy[0].arn
}
*/