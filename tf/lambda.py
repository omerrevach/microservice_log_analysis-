import boto3
import json
import os

sqs = boto3.client('sqs')
queue_url = f"https://sqs.{os.getenv('region')}.amazonaws.com/{os.getenv('account_id')}/log-processing-queue.fifo"

def lambda_handler(event, context):
    """Triggered by S3, sends a message to SQS."""
    for record in event['Records']:
        bucket_name = record['s3']['bucket']['name']
        file_key = record['s3']['object']['key']

        # Prepare message payload for SQS
        message_body = {
            "s3_bucket": bucket_name,
            "file_key": file_key
        }

        # Send message to SQS FIFO queue
        response = sqs.send_message(
            QueueUrl=queue_url,
            MessageBody=json.dumps(message_body),
            MessageGroupId="log-processing-group"
        )
        
    return {"status": "Message sent to SQS successfully"}

