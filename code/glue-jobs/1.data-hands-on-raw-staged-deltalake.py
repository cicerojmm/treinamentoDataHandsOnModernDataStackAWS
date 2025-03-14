#--conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore
# --datalake-formats delta
# --additional-python-modules delta-spark==3.2.1

import sys
from pyspark.sql import SparkSession
from delta.tables import DeltaTable
from pyspark.sql.functions import col
from awsglue.utils import getResolvedOptions

spark = (SparkSession.builder
    .appName("Glue Delta Merge")
    .getOrCreate())

args = getResolvedOptions(sys.argv, ['input_path', 'delta_table_path', 'primary_key'])

input_path = args["input_path"] #"s3://cjmm-datalake-raw/movielens/tags/"
delta_table_path = args["delta_table_path"]  #"s3://cjmm-datalake-staged/movielens_delta_glue/tags/"
primary_key = args["primary_key"]  #"userId"


#input_df = spark.read.option("header", "true").option("inferSchema", "true").csv(input_path)
input_df = spark.read.parquet(input_path)


if not DeltaTable.isDeltaTable(spark, delta_table_path):
    input_df.write.format("delta").mode("overwrite").save(delta_table_path)
else:
    delta_table = DeltaTable.forPath(spark, delta_table_path)

    primary_key_columns = primary_key.split(',')
    
    merge_condition = " AND ".join([f"target.{col} = source.{col}" for col in primary_key_columns])
    input_df = input_df.dropDuplicates(primary_key_columns)
    
    (delta_table.alias("target")
        .merge(input_df.alias("source"), merge_condition)
        .whenMatchedUpdate(set={c: col(f"source.{c}") for c in input_df.columns})
        .whenNotMatchedInsertAll()
        .execute())

print("Processo concluído com sucesso!")
