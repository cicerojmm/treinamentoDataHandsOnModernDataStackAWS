import json
import boto3
from time import sleep
from fake_web_events import Simulation


kinesis_client = boto3.client('kinesis', region_name='us-east-1')
stream_name = 'datahandson-mds-analytics-stream' 


def send_to_kinesis(data):
    try:
        response = kinesis_client.put_record(
            StreamName=stream_name,
            Data=json.dumps(data),
            PartitionKey="event_type"
        )
        print(f"Data sent to Kinesis: {response['SequenceNumber']}")
    except Exception as e:
        print(f"Failed to send data to Kinesis: {str(e)}")


def generate_and_send_events():
    simulation = Simulation(user_pool_size=1000, sessions_per_day=100000)
    events = simulation.run(duration_seconds=180)

    for event in events:
        #catprint(event)
        send_to_kinesis(event)
        
        sleep(5)

generate_and_send_events()
