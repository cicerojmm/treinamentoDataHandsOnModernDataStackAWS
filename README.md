# Treinamento Data Hands-On Modern Data Stack AWS

Este repositório contém o código e a infraestrutura para um projeto de Modern Data Stack implementado na AWS, utilizando o dataset MovieLens para demonstrar diferentes técnicas de processamento de dados.

## Estrutura do Projeto

### 📁 code/
Contém todos os códigos de aplicação para processamento de dados.

#### 📁 dbt/
Implementação do dbt (data build tool) para transformação de dados no Redshift.

- **airflow_dags/**: DAGs do Airflow para orquestração do dbt
  - `dag_movielens_dbt_redshift_mwaa.py`: DAG para execução do dbt no MWAA (Amazon Managed Workflows for Apache Airflow)
  - `dag_movielens_dbt_redshift.py`: DAG para execução do dbt no Redshift
  - `requirements.txt`: Dependências necessárias
  - `startup-script-mwaa.sh`: Script de inicialização para o MWAA

- **movielens_redshift/**: Projeto dbt para transformação de dados do MovieLens
  - `models/`: Modelos dbt organizados em camadas
    - `staging/`: Modelos de staging para ingestão inicial
    - `intermediate/`: Modelos intermediários
    - `analytics/`: Modelos finais para análise

#### 📁 emr/
Código para processamento de dados usando Amazon EMR (Elastic MapReduce).

- **modules/**: Módulos Python para processamento Spark
  - `jobs/`: Definições de jobs Spark
  - `utils/`: Utilitários para logging e operações Spark
- `bootstrap.sh`: Script de bootstrap para clusters EMR
- `dag_emr_movielens.py`: DAG do Airflow para orquestração de jobs EMR
- `main.py`: Ponto de entrada principal

#### 📁 glue-jobs/
Scripts AWS Glue para ETL de dados.

- `jars/`: JARs necessários para os jobs Glue
- Scripts para processamento de dados em diferentes formatos:
  - Delta Lake: `datahandson-mds-*-deltalake-*.py`
  - Apache Iceberg: `datahandson-mds-s3tables-*-iceberg-*.py`

#### 📁 insert-data-postgres/
Scripts para inserção de dados no PostgreSQL.

- `script-python-insert-csv-postgres.py`: Script Python para inserção de dados
- `script-spark-insert-csv-postgres.py`: Script Spark para inserção de dados

#### 📁 kinesis-firehose/
Scripts para envio de eventos para o Amazon Kinesis Firehose.

- `script-send-events-kinesis.py`: Script para envio de eventos

#### 📁 lambda_code_ecr/
Código para funções Lambda usando contêineres ECR.

- `Dockerfile`: Definição do contêiner
- `lambda_handler.py`: Código da função Lambda
- `build_and_push.sh`: Script para build e push da imagem

#### 📁 sfn-orchestration-glue-jobs/
Definições de fluxos de trabalho do AWS Step Functions para orquestração de jobs Glue.

- `datahandson-mds-movielens-glue-etl.json`: Definição para ETL do MovieLens
- `datahandson-mds-s3tables-movielens-glue-etl.json`: Definição para ETL usando S3 Tables

### 📁 data/
Contém os dados de entrada para o projeto.

- `ml-latest-small.zip`: Dataset MovieLens em formato compactado

### 📁 terraform/
Código de infraestrutura como código (IaC) usando Terraform.

#### 📁 infra/
Definições de infraestrutura AWS.

- **backends/**: Configurações de backend do Terraform
- **envs/**: Variáveis de ambiente para diferentes ambientes
- **modules/**: Módulos Terraform reutilizáveis
  - `dms-serverless/`: AWS Database Migration Service Serverless
  - `ec2/`: Instâncias EC2
  - `glue-crawler-delta/`: Crawlers Glue para Delta Lake
  - `glue-job/`: Jobs AWS Glue
  - `kinesis-firehose/`: Kinesis Firehose
  - `kinesis-stream/`: Kinesis Data Streams
  - `lambda/`: Funções Lambda
  - `mwaa/`: Amazon Managed Workflows for Apache Airflow
  - `opensearch-serverless/`: Amazon OpenSearch Serverless
  - `rds/`: Amazon RDS (Relational Database Service)
  - `redshift/`: Amazon Redshift
  - `step-functions/`: AWS Step Functions
  - `vpc/`: Amazon VPC (Virtual Private Cloud)
- **scripts/**: Scripts auxiliares para a infraestrutura

## Fluxo de Dados

Este projeto implementa um pipeline de dados completo:

1. **Ingestão**: Dados são ingeridos via Kinesis ou carregados diretamente do dataset MovieLens
2. **Armazenamento**: Os dados são armazenados em diferentes formatos (Delta Lake, Iceberg) no S3
3. **Processamento**: Transformações são realizadas usando AWS Glue, EMR e dbt
4. **Análise**: Os dados processados são disponibilizados para análise no Redshift
5. **Orquestração**: O fluxo é orquestrado usando Airflow (MWAA) e Step Functions

## Tecnologias Utilizadas

- **Armazenamento**: Amazon S3, Delta Lake, Apache Iceberg
- **Processamento**: AWS Glue, Amazon EMR, Apache Spark
- **Data Warehouse**: Amazon Redshift
- **Banco de Dados**: Amazon RDS (PostgreSQL)
- **Streaming**: Amazon Kinesis Data Streams, Kinesis Firehose
- **Orquestração**: Amazon MWAA (Airflow), AWS Step Functions
- **Computação Serverless**: AWS Lambda
- **Busca e Análise**: Amazon OpenSearch Serverless
- **Infraestrutura como Código**: Terraform
- **Transformação de Dados**: dbt (data build tool)

## Como Começar

1. Configure suas credenciais AWS
2. Navegue até o diretório `terraform/infra`
3. Execute:
   ```bash
   terraform init -backend-config=backends/develop.hcl
   terraform plan -var-file=envs/develop.tfvars
   terraform apply -var-file=envs/develop.tfvars
   ```
4. Após a criação da infraestrutura, execute os pipelines de dados conforme necessário