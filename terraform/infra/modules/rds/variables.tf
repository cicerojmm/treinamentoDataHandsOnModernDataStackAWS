variable "db_name" {
  description = "Database name"
  type        = string
}

variable "username" {
  description = "Master username"
  type        = string
}

variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
}

variable "allocated_storage" {
  description = "The amount of storage (in gigabytes) to allocate"
  type        = number
  default     = 20
}

variable "engine" {
  description = "The database engine to use"
  type        = string
  default     = "postgres"
}

variable "engine_version" {
  description = "The version of the database engine"
  type        = string
  default     = "14.5"
}

variable "instance_class" {
  description = "The instance type of the RDS instance"
  type        = string
  default     = "db.t3.micro"
}

variable "publicly_accessible" {
  description = "Whether the RDS instance is publicly accessible"
  type        = bool
  default     = false
}


variable "vpc_id" {
  description = "The ID of the VPC where the RDS will be deployed"
  type        = string
}

variable "subnet_ids" {
  description = "List of subnet IDs to use for the RDS Subnet Group"
  type        = list(string)
}

variable "allowed_cidr_blocks" {
  description = "List of CIDR blocks allowed to access the RDS instance"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "ingress_rules" {
  description = <<EOT
  List of ingress rules for the Security Group. 
  Each rule must have the structure:
  {
    from_port   = <port number>,
    to_port     = <port number>,
    protocol    = <protocol>,
    cidr_blocks = [<CIDR blocks>]
  }
  EOT
  type = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
  }))
  default = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}

