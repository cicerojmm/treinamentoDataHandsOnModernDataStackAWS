import pandas as pd
from sqlalchemy import create_engine
import boto3
from io import StringIO

# Informações de conexão com o PostgreSQL
DB_USER = "datahandsonmds"
DB_PASSWORD = "Gz[S<r-Q(=OQe5Qh"
DB_HOST = "database-datahandson-mds.cykfubzsemsi.us-east-1.rds.amazonaws.com"
DB_PORT = "5432"
DB_NAME = "movielens_database"

# Criar a conexão com o PostgreSQL
engine = create_engine(
    f"postgresql://{DB_USER}:{DB_PASSWORD}@{DB_HOST}:{DB_PORT}/{DB_NAME}"
)

# Informações do S3
S3_BUCKET = "cjmm-datalake-raw"
S3_PATH = "movielens"

# Criar um cliente S3
s3_client = boto3.client('s3')

# Lista dos arquivos CSV
csv_files = ["ratings", "tags", "movies", "links"]

# Para cada arquivo CSV no S3
for csv_name in csv_files:
    # Construir o caminho completo do arquivo no S3
    file_key = f"{S3_PATH}/{csv_name}/{csv_name}.csv"

    # Baixar o arquivo do S3
    obj = s3_client.get_object(Bucket=S3_BUCKET, Key=file_key)
    
    # Ler o conteúdo do arquivo CSV no pandas diretamente da resposta do S3
    df = pd.read_csv(obj['Body'])
    
    # Inserir os dados no PostgreSQL
    df.to_sql(csv_name, engine, if_exists="replace", index=False)
    
    print(f"Tabela '{csv_name}' criada e dados inseridos com sucesso!")
