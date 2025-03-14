resource "random_password" "rds_password" {
  length           = 16
  special          = true
  override_special = "!#$%^&*()-_=+{}[]:;<>,.?"
  upper            = true
  lower            = true
  number           = true
}


resource "aws_secretsmanager_secret" "rds_secret" {
  name = var.secret_name
}

resource "aws_secretsmanager_secret_version" "rds_secret_version" {
  secret_id     = aws_secretsmanager_secret.rds_secret.id
  secret_string = jsonencode({
    username = var.username
    password = random_password.rds_password.result
    host     = aws_rds_cluster.aurora_cluster.endpoint
    port     = aws_rds_cluster.aurora_cluster.port
    dbname   = var.db_name
  })
}

resource "aws_security_group" "rds_sg" {
  name_prefix = "${var.db_name}-sg"
  vpc_id      = var.vpc_id

  dynamic "ingress" {
    for_each = var.ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_db_subnet_group" "rds_subnet_group" {
  name       = "${var.db_name}-subnet-group"
  subnet_ids = var.subnet_ids
}

resource "aws_rds_cluster" "aurora_cluster" {
  #allocated_storage    = var.allocated_storage
  engine               = var.engine
  engine_version       = var.engine_version
  cluster_identifier   = var.db_name
  master_username      = var.username
  master_password      = random_password.rds_password.result
  #publicly_accessible  = var.publicly_accessible
  vpc_security_group_ids = [aws_security_group.rds_sg.id]
  db_subnet_group_name = aws_db_subnet_group.rds_subnet_group.name
}


# Instância de cluster Aurora
resource "aws_rds_cluster_instance" "aurora_instance" {
  cluster_identifier      = aws_rds_cluster.aurora_cluster.cluster_identifier
  instance_class          = var.instance_class 
  engine                  = var.engine
  publicly_accessible     = var.publicly_accessible  

  # Configuração de segurança
  #vpc_security_group_ids = [aws_security_group.rds_sg.id]
}