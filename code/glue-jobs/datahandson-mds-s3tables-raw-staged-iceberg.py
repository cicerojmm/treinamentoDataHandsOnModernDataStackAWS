import sys
from pyspark.sql import SparkSession
from awsglue.utils import getResolvedOptions

def create_spark_session(s3_warehouse_arn: str) -> SparkSession:
    return (SparkSession.builder.appName("glue-s3-tables-merge")
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions")
        .config("spark.sql.defaultCatalog", "s3tablesbucket")
        .config("spark.sql.catalog.s3tablesbucket", "org.apache.iceberg.spark.SparkCatalog")
        .config("spark.sql.catalog.s3tablesbucket.catalog-impl", "software.amazon.s3tables.iceberg.S3TablesCatalog")
        .config("spark.sql.catalog.s3tablesbucket.warehouse", s3_warehouse_arn)
        .getOrCreate())

def read_input_data(spark: SparkSession, input_path: str, primary_key: str):
    df = spark.read.parquet(input_path)
    df = df.toDF(*[c.lower() for c in df.columns])
    df = df.dropDuplicates(primary_key.split(","))
    df.createOrReplaceTempView("source_view")
    return df

def ensure_namespace_exists(spark: SparkSession, namespace: str):
    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS s3tablesbucket.{namespace}")

def create_table_if_not_exists(spark: SparkSession, namespace: str, table: str, schema: list):
    schema_str = ", ".join([f"{col_name} {col_type}" for col_name, col_type in schema])
    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {namespace}.{table} (
            {schema_str}
        )
    """)

def merge_into_table(spark: SparkSession, namespace: str, table: str, primary_key: str, columns: list):
    pk_cols = primary_key.split(",")
    merge_condition = " AND ".join([f"target.{col} = source.{col}" for col in pk_cols])
    set_clause = ", ".join([f"{col} = source.{col}" for col in columns])

    spark.sql(f"""
        MERGE INTO {namespace}.{table} AS target
        USING source_view AS source
        ON {merge_condition}
        WHEN MATCHED THEN UPDATE SET {set_clause}
        WHEN NOT MATCHED THEN INSERT *
    """)

def main():
    args = getResolvedOptions(sys.argv, [
        'input_path', 
        'iceberg_table', 
        'primary_key', 
        's3_tables_bucket_arn', 
        'namespace'
    ])

    spark = create_spark_session(args['s3_tables_bucket_arn'])

    df = read_input_data(spark, args['input_path'], args['primary_key'])
    ensure_namespace_exists(spark, args['namespace'])
    create_table_if_not_exists(spark, args['namespace'], args['iceberg_table'], df.dtypes)
    merge_into_table(spark, args['namespace'], args['iceberg_table'], args['primary_key'], df.columns)

    spark.sql(f"SELECT * FROM {args['namespace']}.{args['iceberg_table']} LIMIT 10").show()

if __name__ == "__main__":
    main()
