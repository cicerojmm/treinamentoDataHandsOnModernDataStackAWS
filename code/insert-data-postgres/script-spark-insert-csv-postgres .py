
import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job
from awsglue.dynamicframe import DynamicFrame
  
sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)


# Parâmetros passados para o job
args = {'JOB_NAME': '', 
        'S3_INPUT_PATH': 'cjmm-datalake-raw', 
        'RDS_HOST': 'database-datahandson-mds.cykfubzsemsi.us-east-1.rds.amazonaws.com', 
        'RDS_PORT': '5432', 
        'RDS_USER': 'datahandsonmds', 
        'RDS_PASSWORD': 'Gz[S<r-Q(=OQe5Qh', 
        'RDS_DB_NAME': 'movielens_database'}

# Inicia o contexto do Spark e Glue
#sc = SparkContext()
#glueContext = GlueContext(sc)
#spark = glueContext.spark_session

for table in ["movies", "ratings", "tags", "links"]:
    # Leitura do arquivo no S3
    df_s3 = spark.read.format("csv").option("header", "true").load(f"s3://{args['S3_INPUT_PATH']}/movielens/{table}/{table}.csv")

    # Convertendo para DynamicFrame (recomendado para Glue)
    dynamic_frame_s3 = DynamicFrame.fromDF(df_s3, glueContext, "dynamic_frame_s3")

    # Configuração para conexão com RDS PostgreSQL
    connection_options = {
        "url" : f"jdbc:postgresql://{args['RDS_HOST']}:{args['RDS_PORT']}/{args['RDS_DB_NAME']}",  # Substitua com seu endpoint RDS e o nome do banco de dados
        "user" : args['RDS_USER'],  # Substitua com o seu usuário
        "password" : args['RDS_PASSWORD'],  # Substitua com a sua senha
        "dbtable" : table,  # Substitua com o nome da tabela no RDS
        "database" : args['RDS_DB_NAME']# Substitua com o nome do banco de dados
    }


    # Gravação no RDS PostgreSQL
    glueContext.write_dynamic_frame.from_options(dynamic_frame_s3, connection_type="postgresql", connection_options=connection_options)

print("ETL completo e dados gravados no RDS PostgreSQL.")

job.commit()