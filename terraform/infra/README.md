# Modern Data Stack AWS - Terraform Infrastructure

Este repositório contém a infraestrutura como código (IaC) para implementar uma Modern Data Stack na AWS usando Terraform. O projeto configura diversos serviços AWS para processamento, armazenamento e análise de dados.

## Estrutura do Projeto

```
terraform/infra/
├── backends/              # Configurações de backend do Terraform
├── envs/                  # Arquivos de variáveis por ambiente
├── modules/               # Módulos Terraform reutilizáveis
│   ├── dms-serverless/    # AWS Database Migration Service
│   ├── ec2/               # Instâncias EC2
│   ├── glue-crawler-delta/ # AWS Glue Crawlers para Delta Lake
│   ├── glue-job/          # AWS Glue Jobs
│   ├── kinesis-firehose/  # Kinesis Firehose
│   ├── kinesis-stream/    # Kinesis Data Streams
│   ├── lambda/            # AWS Lambda Functions
│   │   └── package/       # Código fonte e Dockerfile para Lambda
│   ├── mwaa/              # Managed Workflows for Apache Airflow
│   ├── opensearch-serverless/ # Amazon OpenSearch Serverless
│   ├── rds/               # Amazon RDS (PostgreSQL)
│   ├── redshift/          # Amazon Redshift
│   ├── step-functions/    # AWS Step Functions
│   └── vpc/               # Amazon VPC
├── scripts/               # Scripts auxiliares
│   ├── bootstrap/         # Scripts de bootstrap para EC2
│   ├── glue_etl/          # Scripts ETL para AWS Glue
│   ├── lambda_code_ecr/   # Código fonte do Lambda
│   └── step-functions-definitions/ # Definições de Step Functions
├── main.tf                # Arquivo principal do Terraform
├── variables.tf           # Definição de variáveis
└── terraform.tf           # Configuração do provider Terraform
```

## Componentes Principais

- **VPC e Networking**: Configuração de VPC, subnets públicas e privadas
- **RDS PostgreSQL**: Banco de dados relacional para dados transacionais
- **Redshift**: Data warehouse para análises
- **AWS Glue**: Jobs ETL para processamento de dados
- **Lambda com DuckDB**: Função serverless para consultas em dados no S3 Tables
- **Step Functions**: Orquestração de fluxos de trabalho
- **S3 Tables**: Armazenamento de dados em formato Iceberg

## Pré-requisitos

- AWS CLI configurado
- Terraform v1.0.0+
- Docker (para build da imagem Lambda)

## Configuração

### 1. Buckets S3

Antes de executar o Terraform, você precisa substituir os nomes dos buckets S3 nos arquivos de variáveis:

Edite o arquivo `envs/develop.tfvars` e substitua:
```
s3_bucket_raw = "seu-bucket-raw"
s3_bucket_scripts = "seu-bucket-scripts"
s3_bucket_curated = "seu-bucket-curated"
```

### 2. Build e Push da Imagem Docker do Lambda

Para construir e enviar a imagem Docker do Lambda para o ECR:

```bash
cd modules/lambda/package
./build_and_push.sh
```

Este script:
1. Cria um repositório ECR se não existir
2. Faz login no ECR
3. Constrói a imagem Docker
4. Envia a imagem para o ECR

### 3. Inicialização do Terraform

```bash
terraform init -backend-config="backends/develop.hcl"
```

### 4. Aplicação da Infraestrutura

```bash
terraform apply -var-file=envs/develop.tfvars
```

## Lambda Function URL

A função Lambda DuckDB está configurada com um Function URL que permite consultas via HTTP. Para usar:

1. Obtenha a URL da função nos outputs do Terraform
2. Faça uma requisição GET com os parâmetros:
   - `catalog_arn`: ARN do catálogo S3 Tables
   - `query`: Consulta SQL a ser executada

Exemplo:
```
https://[function-url]?catalog_arn=arn:aws:s3tables:us-east-1:ACCOUNT_ID:bucket/BUCKET_NAME&query=SELECT * FROM s3_tables_db.schema.table LIMIT 10
```

## Notas Importantes

- O repositório está configurando para ambiente de desenvolvimento e testes, se for prover para produção, revisar as configurações de recursos computacionais, segurança e acessos.

## Limpeza

Para destruir a infraestrutura:

```bash
terraform destroy -var-file=envs/develop.tfvars
```