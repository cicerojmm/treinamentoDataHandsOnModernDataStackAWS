output "source_endpoint_arn" {
  description = "ARN of the source endpoint"
  value       = aws_dms_endpoint.aurora_source.endpoint_arn
}

output "target_endpoint_arn" {
  description = "ARN of the target endpoint"
  value       = aws_dms_endpoint.s3_target.endpoint_arn
}

output "dms_security_group_id" {
  description = "ID of the security group used by DMS"
  value       = aws_security_group.dms_sg.id
}