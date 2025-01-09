import boto3
import requests

sqs = boto3.client('sqs')
# extractor_service_url = 

def send_message():
    try:
        response = sqs.send_message(
           QueueUrl=queue_url,
           DelaySeconds=10,
            
        )