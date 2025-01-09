# ------------------------------
# S3 Bucket for Log Storage
# ------------------------------
resource "aws_s3_bucket" "bucket" {
  bucket = "store-users-log-files"
}

# S3 Event Notification to Trigger Lambda on File Upload
resource "aws_s3_bucket_notification" "aws_lambda_trigger" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

# ------------------------------
# Lambda Function Configuration
# ------------------------------
resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "S3ToSqsProcessor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda.lambda_handler"
  runtime       = "python3.12"
  timeout       = 15
  memory_size   = 1024

  environment {
    variables = {
      SQS_QUEUE_URL = aws_sqs_queue.log_processing_queue.id
    }
  }
}


# Lambda Permission for S3 to Trigger Lambda
resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

# ------------------------------
# SQS Queue Configuration
# ------------------------------
resource "aws_sqs_queue" "log_processing_queue" {
  name                        = "log-processing-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

# ------------------------------
# IAM Role for Lambda with SQS & S3 Permissions
# ------------------------------
resource "aws_iam_role" "lambda_execution_role" {
  name = "lambda_execution_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Service = "lambda.amazonaws.com"
      }
      Action = "sts:AssumeRole"
    }]
  })
}

# ------------------------------
# IAM Policy with Full Permissions (S3 + SQS + CloudWatch)
# ------------------------------
resource "aws_iam_policy" "lambda_sqs_s3_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # ✅ Allow sending and managing messages in SQS FIFO Queue
      {
        Effect = "Allow"
        Action = [
          "sqs:SendMessage",
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes",
          "sqs:GetQueueUrl"
        ]
        Resource = aws_sqs_queue.log_processing_queue.arn  # ✅ FIXED HERE (Resource instead of SQS_QUEUE_URL)
      },
      # ✅ Allow listing and reading from the S3 bucket
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:ListBucket"
        ]
        Resource = [
          "${aws_s3_bucket.bucket.arn}",
          "${aws_s3_bucket.bucket.arn}/*"
        ]
      },
      # ✅ Allow CloudWatch Logging for Lambda (Fixed Resource with Correct Account ID)
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${aws_lambda_function.lambda.function_name}:*"
      }
    ]
  })
}

# Attach IAM Policy to the Lambda Execution Role
resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sqs_s3_policy.arn
}

data "aws_caller_identity" "current" {}
variable "aws_region" {
  default = "eu-north-1"
}
