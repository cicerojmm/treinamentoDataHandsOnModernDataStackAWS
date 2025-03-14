import sys
from pyspark.sql import SparkSession
from delta.tables import DeltaTable
from pyspark.sql.functions import col


def convert_timestamp_to_datetime(timestamp):
    return str(datetime.fromtimestamp(int(timestamp)))


def process_raw_to_staged(
    spark, input_path, delta_table_path, primary_key, save_mode="append"
):
    input_df = (
        spark.read.option("header", "true")
        .option("inferSchema", "true")
        .csv(input_path)
    )

    if not DeltaTable.isDeltaTable(spark, delta_table_path):
        input_df.write.format("delta").mode("overwrite").save(delta_table_path)
    else:
        delta_table = DeltaTable.forPath(spark, delta_table_path)

        merge_condition = f"target.{primary_key} = source.{primary_key}"

        (
            delta_table.alias("target")
            .merge(input_df.alias("source"), merge_condition)
            .whenMatchedUpdate(
                set={"name": col("source.name"), "value": col("source.value")}
            )
            .whenNotMatchedInsertAll()
            .execute()
        )

    print("Processo concluído com sucesso!")


def process_staged_to_curated(spark, input_path, output_path, save_mode="append"):
    pass
