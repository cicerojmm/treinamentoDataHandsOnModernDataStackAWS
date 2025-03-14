#--conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore
# --datalake-formats delta
# --additional-python-modules delta-spark==3.2.1

from pyspark.sql import SparkSession
from pyspark.sql.functions import count, avg

spark = SparkSession.builder \
    .appName("CuratedLayer") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .enableHiveSupport() \
    .getOrCreate()

tags_path = "s3://cjmm-datalake-staged/movielens_delta_glue/tags/"
curated_user_tags_path = "s3://cjmm-datalake-curated/movielens_delta_glue/user_tags/"

tags_df = spark.read.format("delta").load(tags_path)

user_tags_df = tags_df.groupBy("userid", "tag").agg(count("*").alias("tag_count"))

user_tags_df.write.format("delta").mode("overwrite").save(curated_user_tags_path)

print("Tabela curated_user_tags criada com sucesso!")
