#--conf spark.sql.extensions=io.delta.sql.DeltaSparkSessionExtension --conf spark.sql.catalog.spark_catalog=org.apache.spark.sql.delta.catalog.DeltaCatalog --conf spark.delta.logStore.class=org.apache.spark.sql.delta.storage.S3SingleDriverLogStore
# --datalake-formats delta
# --additional-python-modules great_expectations[spark]==0.16.5,delta-spark==3.2.1

import great_expectations as ge
from great_expectations.core import ExpectationSuite
from great_expectations.core.batch import RuntimeBatchRequest
from great_expectations.core.yaml_handler import YAMLHandler
from great_expectations.validator.validator import Validator
from great_expectations.data_context.types.base import DataContextConfig
#from great_expectations.profile.basic_dataset_profiler import BasicDatasetProfiler
#from great_expectations.dataset.sparkdf_dataset import SparkDFDataset
from os.path import join
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from pyspark.sql import SparkSession

yaml = YAMLHandler()

datasource_yaml = f"""
    name: my_spark_datasource
    class_name: Datasource
    module_name: great_expectations.datasource
    execution_engine:
        module_name: great_expectations.execution_engine
        class_name: SparkDFExecutionEngine
    data_connectors:
        my_runtime_data_connector:
            class_name: RuntimeDataConnector
            batch_identifiers:
                - some_key_maybe_pipeline_stage
                - some_other_key_maybe_airflow_run_id
    """

suite_name_movies = 'suite_tests_movie_ratings'
suite_name_tags = 'suite_tests_user_tags'


def config_data_docs_site(context, output_path):
    data_context_config = DataContextConfig()

    data_context_config["data_docs_sites"] = {
        "s3_site": {
            "class_name": "SiteBuilder",
            "store_backend": {
                "class_name": "TupleS3StoreBackend",
                "bucket": output_path.replace("s3://", "")
            },
            "site_index_builder": {
                "class_name": "DefaultSiteIndexBuilder"
            }
        }
    }

    context._project_config["data_docs_sites"] = data_context_config["data_docs_sites"]


def create_context_ge(output_path):
    context = ge.get_context()
    context.add_expectation_suite(expectation_suite_name=suite_name_movies)
    context.add_expectation_suite(expectation_suite_name=suite_name_tags)

    context.add_datasource(**yaml.load(datasource_yaml))
    config_data_docs_site(context, output_path)

    return context

def create_validator(context, suite, df):
    runtime_batch_request = RuntimeBatchRequest(
        datasource_name="my_spark_datasource",
        data_connector_name="my_runtime_data_connector",
        data_asset_name="data_asset",
        runtime_parameters={"batch_data": df},
        batch_identifiers={
            "some_key_maybe_pipeline_stage": "ingestion",
            "some_other_key_maybe_airflow_run_id": "run_001",
        },
    )
    return context.get_validator(batch_request=runtime_batch_request, expectation_suite=suite)

def add_tests_movie_ratings(df_validator):
    df_validator.expect_table_columns_to_match_ordered_list([
        "movieid", "title", "genres", "avg_rating"
    ])
    df_validator.expect_column_values_to_be_unique("movieid")
    df_validator.expect_column_values_to_not_be_null("movieid")
    df_validator.expect_column_values_to_be_between("avg_rating", min_value=0, max_value=5)
    df_validator.save_expectation_suite(discard_failed_expectations=False)
    return df_validator

def add_tests_user_tags(df_validator):
    df_validator.expect_table_columns_to_match_ordered_list([
        "userid", "tag", "tag_count"
    ])
    df_validator.expect_column_values_to_not_be_null("userid")
    df_validator.expect_column_values_to_be_between("tag_count", min_value=0, max_value=1000)
    df_validator.save_expectation_suite(discard_failed_expectations=False)
    return df_validator

def process_suite_ge(spark, input_path, output_path):
    context = create_context_ge(output_path)
    
    # Processando movie_ratings
    df_movie = spark.read.format("delta").load(f'{input_path}/movie_ratings/')
    suite_movies = context.get_expectation_suite(expectation_suite_name=suite_name_movies)
    df_validator_movies = create_validator(context, suite_movies, df_movie)
    df_validator_movies = add_tests_movie_ratings(df_validator_movies)
    
    # Processando user_tags
    df_tags = spark.read.format("delta").load(f'{input_path}/user_tags/')
    suite_tags = context.get_expectation_suite(expectation_suite_name=suite_name_tags)
    df_validator_tags = create_validator(context, suite_tags, df_tags)
    df_validator_tags = add_tests_user_tags(df_validator_tags)

    # results = df_validator.validate(expectation_suite=suite)

    # if results['success']:
    #     print("A suite de testes foi executada com sucesso: " +
    #           str(results['success']))
    #     print("Ação de validação caso seja necessário")

    
    # Gerando Data Docs
    context.build_data_docs(site_names=["s3_site"])
    print("Validação finalizada e Data Docs gerados")

if __name__ == "__main__":
    input_path = 's3://cjmm-datalake-curated/movielens_delta_glue'
    output_path = 's3://datadocs-greatexpectations.cjmm'
    
    spark = (SparkSession.builder
        .appName("CuratedLayer")
        .config("spark.sql.extensions", "io.delta.sql.DeltaSparkSessionExtension")
        .config("spark.sql.catalog.spark_catalog", "org.apache.spark.sql.delta.catalog.DeltaCatalog")
        .getOrCreate())
        
        
    process_suite_ge(spark, input_path, output_path)
