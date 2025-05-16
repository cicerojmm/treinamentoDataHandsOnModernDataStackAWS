#terraform apply -var-file=envs/develop.tfvars
#terraform init -backend-config="backends/develop.hcl"

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

###############################################################################
#########             VPC E SUBNETS                               #############
###############################################################################
module "vpc_public" {
  source                = "./modules/vpc"
  project_name          = "data-handson-mds"
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

##############################################################################
########             INSTANCIAS EC2                              #############
##############################################################################
module "ec2_instance" {
  source             =  "./modules/ec2"
  ami_id              = "ami-04b4f1a9cf54c11d0"
  instance_type       = "t3a.2xlarge"
  subnet_id           = module.vpc_public.public_subnet_ids[0]
  vpc_id              = module.vpc_public.vpc_id
  key_name            = "conta-aws-mds"
  associate_public_ip = true
  instance_name       = "data-handson-mds-ec2-${var.environment}"
  
  user_data = templatefile("${path.module}/scripts/bootstrap/ec2_bootstrap.sh", {})

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


##############################################################################
########             AIRFLOW - MWAA                              #############
##############################################################################
module "mwaa" {
  source                = "./modules/mwaa"
  environment_name      = "datahandson-mds-mwaa"
  s3_bucket_arn         = "arn:aws:s3:::cjmm-datalake-mds-mwaa"
  airflow_version       = "2.10.3"
  environment_class     = "mw1.small"
  min_workers           = 1
  max_workers           = 2
  webserver_access_mode = "PUBLIC_ONLY"
}


###############################################################################
#########            DMS SERVERLESS                               #############
###############################################################################
module "dms" {
  source = "./modules/dms-serverless"

  project_name               = "data-handson-mds"
  aurora_endpoint            = module.rds.rds_endpoint
  aurora_reader_endpoint     = module.rds.rds_reader_endpoint
  aurora_port                = 5432
  aurora_username            = module.rds.rds_username
  aurora_password            = module.rds.rds_password
  aurora_db_name             = "movielens_database"
  s3_bucket_name             = var.s3_bucket_raw
  dms_subnet_ids             = module.vpc_public.public_subnet_ids
  
  enable_ssl                 = true

  vpc_id = module.vpc_public.vpc_id
}

###############################################################################
#########            GLUE JOBS                                   #############
###############################################################################
module "glue_jobs_etl" {
  source = "./modules/glue-job"

  project_name      = "data-handson-mds-deltalake-raw-curated"
  environment       = var.environment
  region            = var.region
  s3_bucket_scripts = var.s3_bucket_scripts
  s3_bucket_data    = var.s3_bucket_raw
  scripts_local_path = "scripts/glue_etl"
  
  job_scripts = {
    "datahandson-mds-raw-staged-deltalake" = "datahandson-mds-raw-staged-deltalake.py",
    "datahandson-mds-staged-curated-deltalake-user-tags" = "datahandson-mds-staged-curated-deltalake-user-tags.py",
    "datahandson-mds-staged-curated-deltalake-movie-ratings" = "datahandson-mds-staged-curated-deltalake-movie-ratings.py"
  }
  
  worker_type       = "G.1X"
  number_of_workers = 3
  timeout           = 60
  max_retries       = 1
  
  additional_python_modules = "delta-spark==3.2.1"
  
  additional_arguments = {
    "--enable-glue-datacatalog" = "true"
    "--conf"                    = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore"
    "--datalake-formats"        = "delta"
  }
}


module "glue_jobs_dq" {
  source = "./modules/glue-job"

  project_name      = "data-handson-mds-curated-dq"
  environment       = var.environment
  region            = var.region
  s3_bucket_scripts = var.s3_bucket_scripts
  s3_bucket_data    = var.s3_bucket_raw
  scripts_local_path = "scripts/glue_etl"
  
  job_scripts = {
    "datahandson-mds-deltalake-data-quality" = "datahandson-mds-deltalake-data-quality.py"
  }
  
  worker_type       = "G.1X"
  number_of_workers = 3
  timeout           = 60
  max_retries       = 1
  
  additional_python_modules = "great_expectations[spark]==0.16.5,delta-spark==3.2.1"
  
  additional_arguments = {
    "--enable-glue-datacatalog" = "true"
    "--conf"                    = "spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore"
    "--datalake-formats"        = "delta"
  }
}


############################ s3 TABLES
module "glue_jobs_etl_s3tables" {
  source = "./modules/glue-job"

  project_name      = "data-handson-mds-s3-tables-raw-curated-iceberg"
  environment       = var.environment
  region            = var.region
  s3_bucket_scripts = var.s3_bucket_scripts
  s3_bucket_data    = var.s3_bucket_raw
  scripts_local_path = "scripts/glue_etl"
  
  job_scripts = {
    "datahandson-mds-s3tables-raw-staged-iceberg" = "datahandson-mds-s3tables-raw-staged-iceberg.py",
    "datahandson-mds-s3tables-staged-curated-user-tags" = "datahandson-mds-s3tables-staged-curated-user-tags.py",
    "datahandson-mds-s3tables-staged-curated-movie-ratings" = "datahandson-mds-s3tables-staged-curated-movie-ratings.py"
  }
  
  worker_type       = "G.1X"
  number_of_workers = 3
  timeout           = 60
  max_retries       = 1

  extra_jars = "s3://cjmm-datalake-mds-configs/jars/s3-tables-catalog-for-iceberg-runtime-0.1.5.jar"

  additional_arguments = {
    "--enable-glue-datacatalog" = "true"
    "--user-jars-first"         = "true"
    "--datalake-formats"        = "iceberg"
    "--s3_tables_bucket_arn"    = "arn:aws:s3tables:us-east-1:010840394859:bucket/datahandson-mds-s3tables"
  }
}


###############################################################################
#########            GLUE CRAWLER DELTA LAKE                      #############
###############################################################################
module "glue_crawler_delta" {
  source = "./modules/glue-crawler-delta"

  name_prefix    = "data-handson-mds"
  environment    = var.environment
  database_name  = "datahandson_mds_movielens_deltalake"
  s3_target_path = "s3://${var.s3_bucket_curated}/movielens_delta_glue/"

  # Opcional: configurar um agendamento para o crawler
  # crawler_schedule = "cron(0 12 * * ? *)"  # Executa diariamente ao meio-dia
  
  # Opcional: prefixo para as tabelas criadas pelo crawler
  #table_prefix   = "delta_"
  
}

###############################################################################
#########            STEP FUNCTIONS                               #############
###############################################################################
module "step_functions" {
  source = "./modules/step-functions"

  project_name = "data-handson-mds"
  environment  = var.environment
  region       = var.region
  
  # Definições das máquinas de estado
  state_machines = {
    "datahandson-mds-movielens-glue-etl" = {
      definition_file = "datahandson-mds-movielens-glue-etl.json"
      type            = "STANDARD"
    },
    "datahandson-mds-s3tables-movielens-glue-etl" = {
      definition_file = "datahandson-mds-s3tables-movielens-glue-etl.json"
      type            = "STANDARD"
    }
  }
  
  # Permissões adicionais para o Step Functions
  additional_iam_statements = [
    {
      Effect = "Allow"
      Action = [
        "glue:StartJobRun",
        "glue:GetJobRun",
        "glue:GetJobRuns",
        "glue:BatchStopJobRun"
      ]
      Resource = "*"
    }
  ]
  
  # Anexar políticas gerenciadas
  attach_glue_policy = true
  
  # Configurações de logging
  log_retention_days = 30
  include_execution_data = true
  logging_level = "ALL"
}


###############################################################################
#########            LAMBDA FUNCTION WITH DOCKER                  #############
###############################################################################
module "lambda_function" {
  source = "./modules/lambda"

  function_name = "datahandson-mds-s3tables-duckdb"
  description   = "Python Lambda function for querying S3 tables with DuckDB"
  
  # Docker image URI (replace with your actual ECR URI after running build_and_push.sh)
  image_uri     = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.region}.amazonaws.com/lambda-duckdb:latest"
  
  # Optional parameters
  timeout       = 900
  memory_size   = 2048
  ephemeral_storage_size = 2048
  
  # Function URL configuration
  create_function_url = true
  function_url_auth_type = "AWS_IAM"  # Use AWS IAM for authentication
  
  environment_variables = {
    ENV_VAR_1 = "value1"
  }
}
