output "collection_id" {
  description = "ID da coleção OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.this.id
}

output "collection_name" {
  description = "Nome da coleção OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.this.name
}

output "collection_arn" {
  description = "ARN da coleção OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.this.arn
}

output "collection_endpoint" {
  description = "Endpoint da coleção OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.this.collection_endpoint
}

output "dashboard_endpoint" {
  description = "Endpoint do dashboard OpenSearch Serverless"
  value       = aws_opensearchserverless_collection.this.dashboard_endpoint
}

output "iam_role_arn" {
  description = "ARN da IAM Role para acesso à coleção OpenSearch Serverless (se criada)"
  value       = var.create_iam_role ? aws_iam_role.opensearch_access[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM Role para acesso à coleção OpenSearch Serverless (se criada)"
  value       = var.create_iam_role ? aws_iam_role.opensearch_access[0].name : null
}