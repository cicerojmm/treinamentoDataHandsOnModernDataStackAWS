# from pyspark.sql import SparkSession
# from pyspark.sql.functions import count, avg

# spark = SparkSession.builder \
#     .appName("CuratedLayer") \
#     .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
#     .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
#     .enableHiveSupport() \
#     .getOrCreate()

# tags_path = "s3://cjmm-datalake-mds-staged/movielens_delta_glue/tags/"
# curated_user_tags_path = "s3://cjmm-datalake-mds-curated/movielens_delta_glue/user_tags/"

# tags_df = spark.read.format("delta").load(tags_path)

# user_tags_df = tags_df.groupBy("userid", "tag").agg(count("*").alias("tag_count"))

# user_tags_df.write.format("delta").mode("overwrite").save(curated_user_tags_path)

# print("Tabela curated_user_tags criada com sucesso!")

from pyspark.sql import SparkSession
from pyspark.sql.functions import count


def init_spark():
    return SparkSession.builder \
        .appName("CuratedLayerUserTags") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .enableHiveSupport() \
        .getOrCreate()


def read_tags_table(spark, tags_path: str):
    return spark.read.format("delta").load(tags_path)


def transform_user_tags(tags_df):
    return tags_df.groupBy("userid", "tag").agg(count("*").alias("tag_count"))


def write_curated_user_tags(df, output_path: str):
    df.write.format("delta").mode("overwrite").save(output_path)


def main():
    tags_path = "s3://cjmm-datalake-mds-staged/movielens_delta_glue/tags/"
    curated_user_tags_path = "s3://cjmm-datalake-mds-curated/movielens_delta_glue/user_tags/"

    spark = init_spark()
    tags_df = read_tags_table(spark, tags_path)
    user_tags_df = transform_user_tags(tags_df)
    write_curated_user_tags(user_tags_df, curated_user_tags_path)

    print("Tabela curated_user_tags criada com sucesso!")


if __name__ == "__main__":
    main()
