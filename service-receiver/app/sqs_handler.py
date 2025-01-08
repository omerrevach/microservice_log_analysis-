import boto3
import os

sqs = boto3.client('sqs')
queue_url = os.environ.get('SQS_QUEUE_URL')

def get_message():
    try:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            AttributeNames=['All'], # To fetch all the attributes
            MaxNumberOfMessages=1, # Because this is a FIFO then only 1
            WaitTimeSeconds=10 # 10 seconds that the call waits for a message to arrive
        )
        if "Messages" in response:
            
            # Tp Iterate over the messages and process them
            message = response['Messages'][0] # I use 0 here because its FIFO
            receipt_handle = message['ReceiptHandle']
            
            print(f"Received Message: {message['Body']}")
            print(f"Message Attributes: {message.get('Attributes')}")
            
            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=receipt_handle
            )
            print('Message was received and deleted sucecessfully')
        else:
            print('No Messages in queue')
    
    except Exception as e:
        print(f'Error receiving the message: {e}')
    