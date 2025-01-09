import boto3

sqs = boto3.client('sqs')
queue_url = "https://sqs.eu-north-1.amazonaws.com/590183919160/log-processing-queue.fifo"

def send_message():
    try:
        response = sqs.send_message(
           QueueUrl=queue_url,
           DelaySeconds=10,
            
        )