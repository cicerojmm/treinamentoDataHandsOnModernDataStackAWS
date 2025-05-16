output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.python_lambda.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.python_lambda.function_name
}

output "lambda_role_arn" {
  description = "ARN of the Lambda IAM role"
  value       = aws_iam_role.lambda_role.arn
}

output "lambda_invoke_arn" {
  description = "Invoke ARN of the Lambda function"
  value       = aws_lambda_function.python_lambda.invoke_arn
}

output "lambda_qualified_arn" {
  description = "Qualified ARN of the Lambda function"
  value       = aws_lambda_function.python_lambda.qualified_arn
}

output "lambda_function_url" {
  description = "The URL of the Lambda function (if function URL is enabled)"
  value       = var.create_function_url ? aws_lambda_function_url.lambda_url[0].function_url : null
}