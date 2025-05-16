output "database_name" {
  description = "Nome da database do Glue criada"
  value       = aws_glue_catalog_database.delta_database.name
}

output "database_id" {
  description = "ID da database do Glue"
  value       = aws_glue_catalog_database.delta_database.id
}

output "crawler_name" {
  description = "Nome do crawler criado"
  value       = aws_glue_crawler.delta_crawler.name
}

output "crawler_arn" {
  description = "ARN do crawler"
  value       = aws_glue_crawler.delta_crawler.arn
}

output "crawler_role_arn" {
  description = "ARN da role IAM usada pelo crawler"
  value       = aws_iam_role.glue_crawler_role.arn
}

output "crawler_role_name" {
  description = "Nome da role IAM usada pelo crawler"
  value       = aws_iam_role.glue_crawler_role.name
}

output "s3_target_path" {
  description = "Caminho S3 configurado como alvo do crawler"
  value       = var.s3_target_path
}