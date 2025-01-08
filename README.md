# microservice_log_analysis

## Project Summary:

   - User uploads a log file via a web app.
   - The file is stored in S3.
   - An SQS FIFO Queue triggers a Python service in EKS.
   - The Python service analyzes the log file for errors.
   - Results are stored in DynamoDB.
   - The user receives an email notification with a summary of the results.

### Key Components: EKS, SQS (FIFO), S3, DynamoDB, SES, Python.