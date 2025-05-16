from pyspark.sql import SparkSession
from pyspark.sql.functions import count
from awsglue.utils import getResolvedOptions
import sys


def get_args():
    return getResolvedOptions(sys.argv, [
        'tags_table',
        'output_table',
        's3_tables_bucket_arn',
        'namespace_destino'
    ])


def init_spark(s3_tables_bucket_arn):
    return SparkSession.builder \
        .appName("CuratedUserTagsIceberg") \
        .config("spark.sql.extensions", "org.apache.iceberg.spark.extensions.IcebergSparkSessionExtensions") \
        .config("spark.sql.defaultCatalog", "s3tablesbucket") \
        .config("spark.sql.catalog.s3tablesbucket", "org.apache.iceberg.spark.SparkCatalog") \
        .config("spark.sql.catalog.s3tablesbucket.catalog-impl", "software.amazon.s3tables.iceberg.S3TablesCatalog") \
        .config("spark.sql.catalog.s3tablesbucket.warehouse", s3_tables_bucket_arn) \
        .getOrCreate()


def read_tags_table(spark, tags_table):
    return spark.sql(f"SELECT * FROM {tags_table}")


def transform_user_tags(tags_df):
    return tags_df.groupBy("userid", "tag").agg(count("*").alias("tag_count"))


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
    df.createOrReplaceTempView("user_tags_view")
    spark.sql(f"""
        INSERT OVERWRITE {namespace}.{table_name}
        SELECT * FROM user_tags_view
    """)


def main():
    args = get_args()
    spark = init_spark(args['s3_tables_bucket_arn'])

    tags_df = read_tags_table(spark, args['tags_table'])
    user_tags_df = transform_user_tags(tags_df)

    create_namespace_if_not_exists(spark, args['namespace_destino'])
    create_output_table_if_not_exists(spark, user_tags_df, args['namespace_destino'], args['output_table'])
    write_output_table(spark, user_tags_df, args['namespace_destino'], args['output_table'])


if __name__ == "__main__":
    main()
