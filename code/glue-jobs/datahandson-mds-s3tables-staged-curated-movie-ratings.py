from pyspark.sql import SparkSession
from pyspark.sql.functions import avg
from awsglue.utils import getResolvedOptions
import sys


def get_args():
    return getResolvedOptions(sys.argv, [
        'movies_table', 
        'ratings_table', 
        'output_table', 
        's3_tables_bucket_arn', 
        'namespace_destino'
    ])


def init_spark(s3_tables_bucket_arn):
    return SparkSession.builder \
        .appName("CuratedLayerIceberg") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.defaultCatalog", "s3tablesbucket") \
        .config("spark.sql.catalog.s3tablesbucket", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.s3tablesbucket.catalog-impl", "software.amazon.s3tables.iceberg.S3TablesCatalog") \
        .config("spark.sql.catalog.s3tablesbucket.warehouse", s3_tables_bucket_arn) \
        .getOrCreate()


def read_tables(spark, movies_table, ratings_table):
    movies_df = spark.sql(f"SELECT * FROM {movies_table}")
    ratings_df = spark.sql(f"SELECT * FROM {ratings_table}")
    return movies_df, ratings_df


def transform_data(movies_df, ratings_df):
    ratings_agg = ratings_df.groupBy("movieid").agg(avg("rating").alias("avg_rating"))
    return movies_df.join(ratings_agg, "movieid", "left")


def create_namespace_if_not_exists(spark, namespace):
    spark.sql(f"CREATE NAMESPACE IF NOT EXISTS s3tablesbucket.{namespace}")


def create_output_table_if_not_exists(spark, df, namespace, table_name):
    ddl = ", ".join([f"{c} {t}" for c, t in df.dtypes])
    spark.sql(f"""
        CREATE TABLE IF NOT EXISTS {namespace}.{table_name} (
            {ddl}
        )
    """)


def write_output_table(spark, df, namespace, table_name):
    df.createOrReplaceTempView("curated_view")
    spark.sql(f"""
        INSERT OVERWRITE {namespace}.{table_name}
        SELECT * FROM curated_view
    """)


def main():
    args = get_args()
    spark = init_spark(args['s3_tables_bucket_arn'])

    movies_df, ratings_df = read_tables(spark, args['movies_table'], args['ratings_table'])
    curated_df = transform_data(movies_df, ratings_df)

    create_namespace_if_not_exists(spark, args['namespace_destino'])
    create_output_table_if_not_exists(spark, curated_df, args['namespace_destino'], args['output_table'])
    write_output_table(spark, curated_df, args['namespace_destino'], args['output_table'])


if __name__ == "__main__":
    main()
