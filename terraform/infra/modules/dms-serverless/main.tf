resource "aws_security_group" "dms_sg" {
  name        = "${var.project_name}-dms-security-group"
  description = "Security Group for DMS serverless replication"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# CloudWatch Log Group para DMS
resource "aws_cloudwatch_log_group" "dms_logs" {
  name              = "/aws/dms/${var.project_name}-dms-serverless"
  retention_in_days = var.log_retention_days
}

resource "aws_dms_replication_subnet_group" "this" {
  replication_subnet_group_id          = "${var.project_name}-dms-subnet-group"
  subnet_ids                           = var.dms_subnet_ids
  replication_subnet_group_description = "DMS subnet group"
}

# DMS Serverless Replication Configuration
resource "aws_dms_replication_config" "this" {
  replication_config_identifier = "${var.project_name}-dms-serverless"
  source_endpoint_arn           = aws_dms_endpoint.aurora_source.endpoint_arn
  target_endpoint_arn           = aws_dms_endpoint.s3_target.endpoint_arn
  replication_type              = "full-load"
  
  # Configuração simplificada para evitar problemas com TimestampColumnName
  replication_settings = jsonencode({
    "BeforeImageSettings": {
      "EnableBeforeImage": false,
      "ColumnFilter": "pk-only",
      "FieldName": "before-image"
    },
    "FullLoadSettings": {
      "TargetTablePrepMode": "DROP_AND_CREATE",
      "MaxFullLoadSubTasks": 8,
      "CommitRate": 10000
    },
    "Logging": {
      "EnableLogging": true,
      "LogLevel": "INFO"
      # Removidos CloudWatchLogGroup e CloudWatchLogStream pois são parâmetros somente leitura
    },
    "ControlTablesSettings": {
      "ControlSchema": "",
      "HistoryTimeslotInMinutes": 5,
      "HistoryTableEnabled": false,
      "StatusTableEnabled": true
    }
  })

  table_mappings = jsonencode({
    "rules": [
      {
        "rule-type": "selection",
        "rule-id": "1",
        "rule-name": "1",
        "object-locator": {
          "schema-name": "public",
          "table-name": "%"
        },
        "rule-action": "include"
      }
    ]
  })

  compute_config {
    replication_subnet_group_id = aws_dms_replication_subnet_group.this.replication_subnet_group_id
    vpc_security_group_ids      = [aws_security_group.dms_sg.id]
    max_capacity_units          = 8
    min_capacity_units          = 2
  }
}

resource "aws_dms_endpoint" "aurora_source" {
  endpoint_id   = "${var.project_name}-aurora-source"
  endpoint_type = "source"
  engine_name   = "aurora-postgresql"
  username      = var.aurora_username
  password      = var.aurora_password
  server_name   = var.aurora_reader_endpoint != "" ? var.aurora_reader_endpoint : var.aurora_endpoint
  port          = var.aurora_port
  database_name = var.aurora_db_name
  
  ssl_mode      = var.enable_ssl ? "require" : "none"
}

resource "aws_dms_endpoint" "s3_target" {
  endpoint_id = "${var.project_name}-s3-target"
  endpoint_type = "target"
  engine_name = "s3"
  s3_settings {
    bucket_name             = var.s3_bucket_name
    bucket_folder           = "movielens_rds_dms_serverless/"
    compression_type        = "GZIP"
    data_format             = "parquet"
    parquet_version         = "parquet-1-0"
    service_access_role_arn = aws_iam_role.dms_s3_access.arn
    timestamp_column_name   = "dms_timestamp_col"
  }
}
