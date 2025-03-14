from modules.jobs import job_processed_data
from modules.utils.logger_utils import get_logger
from modules.utils.spark_utils import create_spark_session

jobs = {
    'raw_to_staged': job_processed_data.process_raw_to_staged,
    'staged_to_curated': job_processed_data.process_staged_to_curated
}

def run(parameters):
    logger = get_logger()

    for parameter, value in parameters.items():
        logger.info('Param {param}: {value}'.format(param=parameter, value=value))

    spark = create_spark_session()

    job_name = parameters['job_name']

    process_function = jobs[job_name]
    process_function(
        spark=spark,
        input_path=parameters['input_path'],
        output_path=parameters['output_path'],
        primary_key=parameters['primary_key'],
        save_mode='append'
    )
