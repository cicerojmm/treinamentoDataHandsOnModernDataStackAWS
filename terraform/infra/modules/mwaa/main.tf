resource "aws_security_group" "mwaa_sg" {
  name_prefix = "mwaa-sg-"
  description = "Security Group para MWAA"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_iam_role" "mwaa_role" {
  name = "MWAA-Execution-Role-NEW"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "airflow-env.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "mwaa_custom_policy" {
  name        = "MWAA-Custom-Policy"
  description = "Permissões personalizadas para MWAA acessar S3, EMR e Glue"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:*"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["glue:*"]
        Resource = ["*"]
      },
      {
        Effect   = "Allow"
        Action   = ["elasticmapreduce:*"]
        Resource = ["*"]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "mwaa_custom_policy_attach" {
  policy_arn = aws_iam_policy.mwaa_custom_policy.arn
  role       = aws_iam_role.mwaa_role.name
}

resource "aws_mwaa_environment" "mwaa_env" {
  name                  = var.mwaa_env_name
  airflow_version       = var.airflow_version
  environment_class     = var.environment_class
  execution_role_arn    = aws_iam_role.mwaa_role.arn
  source_bucket_arn     = var.s3_bucket_arn
  dag_s3_path           = "dags/"
  requirements_s3_path  = "requirements/requirements.txt"
  min_workers           = var.min_workers
  max_workers           = var.max_workers
  webserver_access_mode = var.webserver_access_mode

  network_configuration {
    security_group_ids = [aws_security_group.mwaa_sg.id]
    subnet_ids         = var.subnet_ids
  }
}
