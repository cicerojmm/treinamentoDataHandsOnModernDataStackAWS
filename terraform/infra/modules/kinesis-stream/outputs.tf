output "stream_id" {
  description = "ID do Kinesis Stream"
  value       = aws_kinesis_stream.this.id
}

output "stream_name" {
  description = "Nome do Kinesis Stream"
  value       = aws_kinesis_stream.this.name
}

output "stream_arn" {
  description = "ARN do Kinesis Stream"
  value       = aws_kinesis_stream.this.arn
}

output "stream_shard_count" {
  description = "Número de shards do Kinesis Stream"
  value       = aws_kinesis_stream.this.shard_count
}

output "iam_role_arn" {
  description = "ARN da IAM Role para acesso ao Kinesis Stream (se criada)"
  value       = var.create_iam_role ? aws_iam_role.kinesis_access[0].arn : null
}

output "iam_role_name" {
  description = "Nome da IAM Role para acesso ao Kinesis Stream (se criada)"
  value       = var.create_iam_role ? aws_iam_role.kinesis_access[0].name : null
}