output "delivery_stream_id" {
  description = "ID do Kinesis Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.this.id
}

output "delivery_stream_name" {
  description = "Nome do Kinesis Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.this.name
}

output "delivery_stream_arn" {
  description = "ARN do Kinesis Firehose Delivery Stream"
  value       = aws_kinesis_firehose_delivery_stream.this.arn
}

output "firehose_role_arn" {
  description = "ARN da IAM Role do Firehose"
  value       = aws_iam_role.firehose_role.arn
}

output "firehose_role_name" {
  description = "Nome da IAM Role do Firehose"
  value       = aws_iam_role.firehose_role.name
}