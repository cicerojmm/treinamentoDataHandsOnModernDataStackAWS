output "rds_endpoint" {
  value = aws_rds_cluster.aurora_cluster.endpoint
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