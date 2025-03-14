from datetime import datetime
from airflow.decorators import dag, task
from airflow.providers.amazon.aws.operators.emr import (
    EmrCreateJobFlowOperator,
    EmrAddStepsOperator,
    EmrTerminateJobFlowOperator
)
# EMR cluster configuration
JOB_FLOW_OVERRIDES = {
    "Name": "MovieLens Data Processing",
    "ReleaseLabel": "emr-6.10.0",
    "Applications": [{"Name": "Spark"}],
    "Instances": {
        "InstanceGroups": [
            {
                "Name": "Primary node",
                "Market": "ON_DEMAND",
                "InstanceRole": "MASTER",
                "InstanceType": "m5.xlarge",
                "InstanceCount": 1,
            }
        ],
        "KeepJobFlowAliveWhenNoSteps": True,
        "TerminationProtected": False,
    },
    "JobFlowRole": "EMR_EC2_DefaultRole",
    "ServiceRole": "EMR_DefaultRole",
}

# Spark steps configuration
SPARK_STEPS = [
    {
        "Name": "Process Raw to Staged Data",
        "ActionOnFailure": "CONTINUE",
        "HadoopJarStep": {
            "Jar": "command-runner.jar",
            "Args": [
                "spark-submit",
                "--master", "yarn",
                "--deploy-mode", "cluster",
                "s3://your-bucket/emr/modules/jobs/job_processed_data.py",
                "--job", "process_raw_to_staged",
                "--input", "s3://your-bucket/raw/",
                "--output", "s3://your-bucket/staged/"
            ],
        },
    },
    {
        "Name": "Process Staged to Curated Data",
        "ActionOnFailure": "TERMINATE_JOB_FLOW",
        "HadoopJarStep": {
            "Jar": "command-runner.jar",
            "Args": [
                "spark-submit",
                "--master", "yarn",
                "--deploy-mode", "cluster",
                "s3://your-bucket/emr/modules/jobs/job_processed_data.py",
                "--job", "process_staged_to_curated",
                "--input", "s3://your-bucket/staged/",
                "--output", "s3://your-bucket/curated/"
            ],
        },
    }
]

@dag(
    default_args={
        'owner': 'airflow',
        'depends_on_past': False,
        'email_on_failure': False,
        'email_on_retry': False,
    },
    description='DAG for MovieLens data processing using EMR',
    schedule_interval=None,
    start_date=datetime(2024, 1, 1),
    tags=['emr', 'spark', 'movielens'],
)
def dag_emr_movielens():
    
    # Create EMR cluster
    create_emr_cluster = EmrCreateJobFlowOperator(
        task_id='create_emr_cluster',
        job_flow_overrides=JOB_FLOW_OVERRIDES,
        aws_conn_id='aws_default',
    )
    
    # Add Spark steps to the EMR cluster individually
    add_steps_tasks = []
    for idx, step in enumerate(SPARK_STEPS):
        add_step = EmrAddStepsOperator(
            task_id=f'add_step_{idx}',
            job_flow_id=create_emr_cluster.output,
            aws_conn_id='aws_default',
            steps=[step],  # Pass single step as a list
        )
        add_steps_tasks.append(add_step)
    
    # Terminate EMR cluster
    terminate_emr_cluster = EmrTerminateJobFlowOperator(
        task_id='terminate_emr_cluster',
        job_flow_id=create_emr_cluster.output,
        aws_conn_id='aws_default',
    )
    
    # Define task dependencies
    # Chain the tasks: create_cluster >> step1 >> step2 >> terminate
    create_emr_cluster >> add_steps_tasks[0]
    for i in range(len(add_steps_tasks)-1):
        add_steps_tasks[i] >> add_steps_tasks[i+1]
    add_steps_tasks[-1] >> terminate_emr_cluster

dag = dag_emr_movielens()