import boto3
import json

sqs = boto3.client('sqs')
queue_url = "https://sqs.eu-north-1.amazonaws.com/590183919160/log-processing-queue.fifo"


def get_message():
    try:
        response = sqs.receive_message(
            QueueUrl=queue_url,
            AttributeNames=['All'],
            MaxNumberOfMessages=1,
            WaitTimeSeconds=10
        )

        if "Messages" in response:
            # Extract message
            message = response['Messages'][0]
            receipt_handle = message['ReceiptHandle']
            message_body = message['Body']

            print(f"Received Message Body: {message_body}")
            print(f"Message Attributes: {message.get('Attributes')}")

            sqs.delete_message(
                QueueUrl=queue_url,
                ReceiptHandle=receipt_handle
            )
            print('Message successfully processed and deleted.')
        else:
            print('No messages available in the queue.')

    except Exception as e:
        print(f"Error while receiving message from SQS: {str(e)}")


# Run the function
get_message()
