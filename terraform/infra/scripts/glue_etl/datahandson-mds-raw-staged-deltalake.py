# import sys
# from pyspark.sql import SparkSession
# from delta.tables import DeltaTable
# from pyspark.sql.functions import col
# from awsglue.utils import getResolvedOptions

# spark = (SparkSession.builder
#     .appName("Glue Delta Merge")
#     .getOrCreate())

# args = getResolvedOptions(sys.argv, ['input_path', 'delta_table_path', 'primary_key'])

# input_path = args["input_path"] #"s3://cjmm-datalake-raw/movielens/tags/"
# delta_table_path = args["delta_table_path"]  #"s3://cjmm-datalake-staged/movielens_delta_glue/tags/"
# primary_key = args["primary_key"]  #"userId"


# #input_df = spark.read.option("header", "true").option("inferSchema", "true").csv(input_path)
# input_df = spark.read.parquet(input_path)


# if not DeltaTable.isDeltaTable(spark, delta_table_path):
#     input_df.write.format("delta").mode("overwrite").save(delta_table_path)
# else:
#     delta_table = DeltaTable.forPath(spark, delta_table_path)

#     primary_key_columns = primary_key.split(',')
    
#     merge_condition = " AND ".join([f"target.{col} = source.{col}" for col in primary_key_columns])
#     input_df = input_df.dropDuplicates(primary_key_columns)
    
#     (delta_table.alias("target")
#         .merge(input_df.alias("source"), merge_condition)
#         .whenMatchedUpdate(set={c: col(f"source.{c}") for c in input_df.columns})
#         .whenNotMatchedInsertAll()
#         .execute())

# print("Processo concluído com sucesso!")

import sys
from pyspark.sql import SparkSession
from delta.tables import DeltaTable
from pyspark.sql.functions import col
from awsglue.utils import getResolvedOptions


def get_args():
    return getResolvedOptions(sys.argv, ['input_path', 'delta_table_path', 'primary_key'])


def init_spark():
    return (
        SparkSession.builder
        .appName("Glue Delta Merge")
        .getOrCreate()
    )


def read_input_data(spark, input_path):
    return spark.read.parquet(input_path)


def initialize_delta_table(spark, delta_table_path, input_df):
    input_df.write.format("delta").mode("overwrite").save(delta_table_path)
    return DeltaTable.forPath(spark, delta_table_path)


def get_merge_condition(primary_keys):
    return " AND ".join([f"target.{col} = source.{col}" for col in primary_keys])


def perform_merge(spark, input_df, delta_table_path, primary_keys):
    if not DeltaTable.isDeltaTable(spark, delta_table_path):
        return initialize_delta_table(spark, delta_table_path, input_df)

    delta_table = DeltaTable.forPath(spark, delta_table_path)
    input_df = input_df.dropDuplicates(primary_keys)
    merge_condition = get_merge_condition(primary_keys)

    (
        delta_table.alias("target")
        .merge(input_df.alias("source"), merge_condition)
        .whenMatchedUpdate(set={c: col(f"source.{c}") for c in input_df.columns})
        .whenNotMatchedInsertAll()
        .execute()
    )


def main():
    args = get_args()
    spark = init_spark()
    input_df = read_input_data(spark, args["input_path"])

    primary_keys = [key.strip() for key in args["primary_key"].split(",")]

    perform_merge(spark, input_df, args["delta_table_path"], primary_keys)
    print("Processo concluído com sucesso!")


if __name__ == "__main__":
    main()
