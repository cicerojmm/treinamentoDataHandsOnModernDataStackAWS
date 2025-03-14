from airflow.decorators import dag
from airflow.operators.dummy_operator import DummyOperator

from cosmos import DbtTaskGroup, ProjectConfig, ProfileConfig, RenderConfig, ExecutionConfig
from cosmos.profiles import RedshiftUserPasswordProfileMapping
from cosmos.constants import TestBehavior

from pendulum import datetime

import os

CONNECTION_ID = "redshift_default"
DB_NAME = "analytics_zero_etl"
SCHEMA_NAME = "public"

ROOT_PATH = '/usr/local/airflow/dags'
DBT_PROJECT_PATH = f"{ROOT_PATH}/movielens_redshift"

profile_config = ProfileConfig(
    profile_name="movielens_redshift",
    target_name="dev",
    profile_mapping=RedshiftUserPasswordProfileMapping(
        conn_id=CONNECTION_ID,
        profile_args={"schema": SCHEMA_NAME},
    )
)

execution_config = ExecutionConfig(
    dbt_executable_path=f"{os.environ['AIRFLOW_HOME']}/dbt_venv/bin/dbt",
)


@dag(
    start_date=datetime(2023, 10, 14),
    schedule=None,
    catchup=False
)
def dag_dbt_movielens_zeroetl_cosmos():

    start_process = DummyOperator(task_id='start_process')

    transform_data = DbtTaskGroup(
        group_id="transform_data",
        project_config=ProjectConfig(DBT_PROJECT_PATH),
        profile_config=profile_config,
        execution_config=execution_config,
        # operator_args={
        #     "vars": '{"optional_params_for_dbt_models": {{ params.my_param }} }',
        # },
        render_config=RenderConfig(
            test_behavior=TestBehavior.NONE,
        ),
        default_args={"retries": 2},
    )

    start_process >> transform_data


dag_dbt_movielens_zeroetl_cosmos()