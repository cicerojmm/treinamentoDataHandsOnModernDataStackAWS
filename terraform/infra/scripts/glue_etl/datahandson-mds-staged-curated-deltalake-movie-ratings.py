
# from pyspark.sql import SparkSession
# from pyspark.sql.functions import col, avg
# from awsglue.context import GlueContext
# from awsglue.dynamicframe import DynamicFrame

# # Criar SparkSession e GlueContext
# spark = SparkSession.builder \
#     .appName("CuratedLayer") \
#     .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
#     .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
#     .getOrCreate()

# glueContext = GlueContext(spark.sparkContext)
    

# movies_path = "s3://cjmm-datalake-mds-staged/movielens_delta_glue/movies/"
# ratings_path = "s3://cjmm-datalake-mds-staged/movielens_delta_glue/ratings/"
# curated_path = "s3://cjmm-datalake-mds-curated/movielens_delta_glue/movie_ratings/"

# movies_df = spark.read.format("delta").load(movies_path)
# ratings_df = spark.read.format("delta").load(ratings_path)

# ratings_agg = ratings_df.groupBy("movieid").agg(avg("rating").alias("avg_rating"))

# movies_ratings_df = movies_df.join(ratings_agg, "movieid", "left")

# movies_ratings_df.write.format("delta").mode("overwrite").save(curated_path)

# print("Tabela curated_movie_ratings criada com sucesso!")


from pyspark.sql import SparkSession
from pyspark.sql.functions import avg
from awsglue.context import GlueContext


def init_spark():
    spark = SparkSession.builder \
        .appName("CuratedLayerMovieRatings") \
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension") \
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog") \
        .getOrCreate()
    
    glue_context = GlueContext(spark.sparkContext)
    return spark, glue_context


def read_delta_tables(spark, movies_path: str, ratings_path: str):
    movies_df = spark.read.format("delta").load(movies_path)
    ratings_df = spark.read.format("delta").load(ratings_path)
    return movies_df, ratings_df


def transform_data(movies_df, ratings_df):
    ratings_agg = ratings_df.groupBy("movieid").agg(avg("rating").alias("avg_rating"))
    return movies_df.join(ratings_agg, on="movieid", how="left")


def write_curated_table(df, output_path: str):
    df.write.format("delta").mode("overwrite").save(output_path)


def main():
    # Caminhos de entrada e saída
    movies_path = "s3://cjmm-datalake-mds-staged/movielens_delta_glue/movies/"
    ratings_path = "s3://cjmm-datalake-mds-staged/movielens_delta_glue/ratings/"
    curated_path = "s3://cjmm-datalake-mds-curated/movielens_delta_glue/movie_ratings/"

    spark, _ = init_spark()
    movies_df, ratings_df = read_delta_tables(spark, movies_path, ratings_path)
    curated_df = transform_data(movies_df, ratings_df)
    write_curated_table(curated_df, curated_path)

    print("Tabela curated_movie_ratings criada com sucesso!")


if __name__ == "__main__":
    main()
