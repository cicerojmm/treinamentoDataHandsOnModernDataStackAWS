resource "aws_lambda_function" "python_lambda" {
  function_name    = var.function_name
  description      = var.description
  role             = aws_iam_role.lambda_role.arn
  timeout          = var.timeout
  memory_size      = var.memory_size
  
  # Use container image instead of zip deployment
  package_type     = "Image"
  image_uri        = var.image_uri

  # Configure ephemeral storage
  ephemeral_storage {
    size = var.ephemeral_storage_size
  }

  environment {
    variables = var.environment_variables
  }

}

# Function URL for Lambda
resource "aws_lambda_function_url" "lambda_url" {
  count              = var.create_function_url ? 1 : 0
  function_name      = aws_lambda_function.python_lambda.function_name
  authorization_type = var.function_url_auth_type
  
  cors {
    allow_credentials = true
    allow_origins     = ["*"]
    allow_methods     = ["GET"]
    allow_headers     = ["*"]
    expose_headers    = ["*"]
    max_age           = 86400
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

}

# Basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# S3 access policy for Lambda
resource "aws_iam_policy" "s3_access_policy" {
  name        = "${var.function_name}-s3-access-policy"
  description = "Policy for Lambda to access S3 and S3tables"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:ListBucket",
          "s3:DeleteObject",
          "s3tables:*"
        ]
        Resource = [
          "*",
        ]
      }
    ]
  })
}

# Attach S3 access policy to Lambda role
resource "aws_iam_role_policy_attachment" "s3_policy_attachment" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.s3_access_policy.arn
}

# Additional policy attachments can be added here
resource "aws_iam_role_policy_attachment" "additional_policies" {
  for_each   = toset(var.additional_policy_arns)
  role       = aws_iam_role.lambda_role.name
  policy_arn = each.value
}

# CloudWatch Log Group for Lambda
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.function_name}"
  retention_in_days = var.log_retention_days
}