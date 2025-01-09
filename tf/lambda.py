import boto3
import os
import json

sqs = boto3.client('sqs')
queue_url = os.getenv('SQS_QUEUE_URL')

if not queue_url:
    raise ValueError("ERROR: SQS_QUEUE_URL is not set correctly!")

def lambda_handler(event, context):
    try:
        for record in event['Records']:
            bucket_name = record['s3']['bucket']['name']
            file_key = record['s3']['object']['key']

            message_body = {
                "s3_bucket": bucket_name,
                "file_key": file_key
            }

            response = sqs.send_message(
                QueueUrl=queue_url,
                MessageBody=json.dumps(message_body),
                MessageGroupId="log-processing-group",
                MessageDeduplicationId=f"{bucket_name}-{file_key}"
            )
            print(f"✅ Message Sent Successfully: {response['MessageId']}")

    except Exception as e:
        print(f"Error sending message to SQS: {e}")
        raise e
