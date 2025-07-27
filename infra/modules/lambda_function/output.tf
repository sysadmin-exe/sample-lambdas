output "lambda_function_name" {
  description = "The name of the Lambda function"
  value       = aws_lambda_function.this.function_name
}

output "lambda_function_arn" {
  description = "The ARN of the Lambda function"
  value       = aws_lambda_function.this.arn
}

output "environment_s3_arn" {
  description = "The S3 ARN of the Lambda deployment package"
  value       = aws_s3_bucket.this.arn
}