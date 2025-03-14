#--conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore
# --datalake-formats delta
# --additional-python-modules delta-spark==3.2.1

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, avg

spark = SparkSession.builder \
    .appName("CuratedLayer") \
    .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
    .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
    .getOrCreate()
    

movies_path = "s3://cjmm-datalake-staged/movielens_delta_glue/movies/"
ratings_path = "s3://cjmm-datalake-staged/movielens_delta_glue/ratings/"
curated_path = "s3://cjmm-datalake-curated/movielens_delta_glue/movie_ratings/"

movies_df = spark.read.format("delta").load(movies_path)
ratings_df = spark.read.format("delta").load(ratings_path)

ratings_agg = ratings_df.groupBy("movieid").agg(avg("rating").alias("avg_rating"))

movies_ratings_df = movies_df.join(ratings_agg, "movieid", "left")

movies_ratings_df.write.format("delta").mode("overwrite").save(curated_path)

print("Tabela curated_movie_ratings criada com sucesso!")
