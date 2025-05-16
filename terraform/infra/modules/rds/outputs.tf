output "rds_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
}

output "rds_reader_endpoint" {
  value = aws_rds_cluster.aurora_cluster.reader_endpoint
  description = "Endpoint de leitura do cluster Aurora"
}

output "rds_secret_arn" {
  value = aws_secretsmanager_secret.rds_secret.arn
}

output "rds_security_group_id" {
  value = aws_security_group.rds_sg.id
}

output "rds_subnet_group_name" {
  value = aws_db_subnet_group.rds_subnet_group.name
}

output "rds_username" {
  description = "Usuário mestre do banco RDS"
  value       = var.username
}

output "rds_password" {
  description = "Senha gerada para o usuário mestre do RDS"
  value       = random_password.rds_password.result
  sensitive   = true
}