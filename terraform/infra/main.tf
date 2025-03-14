#terraform apply -var-file=envs/develop.tfvars -auto-aprove
#terraform init -backend-config="backends/develop.hcl"

data "aws_caller_identity" "current" {}

###############################################################################
#########             VPC E SUBNETS                               #############
###############################################################################
module "vpc_public" {
  source                = "./modules/vpc"
  vpc_name              = "data-handson-mds-vpc-${var.environment}"
  vpc_cidr              = "10.0.0.0/16"
  public_subnet_cidrs   = ["10.0.1.0/24", "10.0.2.0/24"]
  private_subnet_cidrs  = ["10.0.3.0/24", "10.0.4.0/24"]
  availability_zones    = ["us-east-1a", "us-east-1b"]
}


###############################################################################
#########             RDS - POSTGRES                              #############
###############################################################################
module "rds" {
  source = "./modules/rds"

  db_name              = "transactional"
  username             = "datahandsonmds"
  secret_name          = "datahandsonmds-database-${var.environment}"
  allocated_storage    = 300
  engine               = "aurora-postgresql"
  engine_version       = "16.4"
  instance_class       = "db.t4g.large"
  publicly_accessible  = true
  vpc_id               = module.vpc_public.vpc_id
  subnet_ids           = module.vpc_public.public_subnet_ids

  ingress_rules = [
    {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}


###############################################################################
#########             REDSHIFT                                    #############
###############################################################################
module "redshift" {
  source              = "./modules/redshift"

  cluster_identifier  = "data-handson-mds"
  database_name       = "datahandsonmds"
  master_username     = "admin"
  node_type           = "ra3.large"
  cluster_type        = "single-node"
  number_of_nodes     = 1
  publicly_accessible = true
  subnet_ids          = module.vpc_public.public_subnet_ids
  vpc_id              = module.vpc_public.vpc_id
  allowed_ips         = ["0.0.0.0/0"]
}

###############################################################################
#########             INSTANCIAS EC2                              #############
###############################################################################
module "ec2_instance" {
  source             =  "./modules/ec2"
  ami_id              = "ami-04b4f1a9cf54c11d0"
  instance_type       = "t3a.2xlarge"
  subnet_id           = module.vpc_public.public_subnet_ids[0]
  vpc_id              = module.vpc_public.vpc_id
  key_name            = "new-key-app-aws-cb"
  associate_public_ip = true
  instance_name       = "data-handson-mds-ec2-${var.environment}"

  ingress_rules = [
    {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]
}


###############################################################################
#########             AIRFLOW - MWAA                              #############
###############################################################################
module "mwaa" {
  source                = "./modules/mwaa"
  mwaa_env_name         = "datahandson-mds-mwaa"
  s3_bucket_arn         = "arn:aws:s3:::cjmm-airflow-dags"
  vpc_id                = module.vpc_public.vpc_id
  subnet_ids            = module.vpc_public.private_subnet_ids
  airflow_version       = "2.10.3"
  environment_class     = "mw1.small"
  min_workers           = 1
  max_workers           = 2
  webserver_access_mode = "PUBLIC_ONLY"
}

