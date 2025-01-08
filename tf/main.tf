resource "aws_s3_bucket" "bucket" {
  bucket = "store-users-log-files"
}

resource "aws_s3_bucket_notification" "aws_lambda_trigger" {
  bucket = aws_s3_bucket.bucket.id
  lambda_function {
    lambda_function_arn = aws_lambda_function.lambda.arn
    events              = ["s3:ObjectCreated:*"]
  }
}

resource "aws_lambda_function" "lambda" {
  filename      = "lambda.zip"
  function_name = "S3ToSqsProcessor"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.12"

  timeout     = 15
  memory_size = 1024
  environment {
    variables = {
      region     = "eu-north-1"
      account_id = "590183919160"
    }
  }
}

resource "aws_lambda_permission" "permission" {
  statement_id  = "AllowS3Invoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.lambda.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.bucket.arn
}

resource "aws_iam_policy" "lambda_sqs_policy" {
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["sqs:SendMessage"]
      Resource = aws_sqs_queue.log_processing_queue.arn
    }]
  })
}

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

resource "aws_iam_role_policy_attachment" "lambda_policy_attachment" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_sqs_policy.arn
}

resource "aws_sqs_queue" "log_processing_queue" {
  name                        = "log-processing-queue.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}