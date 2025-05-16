# Kinesis Stream Module

resource "aws_kinesis_stream" "this" {
  name             = var.name
  shard_count      = var.shard_count
  retention_period = var.retention_period

  stream_mode_details {
    stream_mode = var.stream_mode
  }

  encryption_type = var.encryption_type
  kms_key_id      = var.kms_key_id

}

# CloudWatch Alarm para monitoramento de throughput
resource "aws_cloudwatch_metric_alarm" "write_throughput_exceeded" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.name}-write-throughput-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Write throughput has been exceeded for ${var.name} Kinesis stream"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

resource "aws_cloudwatch_metric_alarm" "read_throughput_exceeded" {
  count               = var.create_alarms ? 1 : 0
  alarm_name          = "${var.name}-read-throughput-exceeded"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "1"
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = "300"
  statistic           = "Sum"
  threshold           = "0"
  alarm_description   = "Read throughput has been exceeded for ${var.name} Kinesis stream"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# IAM Role para acesso ao Kinesis (opcional)
resource "aws_iam_role" "kinesis_access" {
  count = var.create_iam_role ? 1 : 0
  name  = "${var.name}-access-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = var.trusted_services
        }
      }
    ]
  })

}

resource "aws_iam_policy" "kinesis_access" {
  count       = var.create_iam_role ? 1 : 0
  name        = "${var.name}-access-policy"
  description = "Policy for accessing ${var.name} Kinesis stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards",
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Effect   = "Allow"
        Resource = aws_kinesis_stream.this.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "kinesis_access" {
  count      = var.create_iam_role ? 1 : 0
  role       = aws_iam_role.kinesis_access[0].name
  policy_arn = aws_iam_policy.kinesis_access[0].arn
}