variable "function_name" {
  description = "Name of the Lambda function."
  type        = string
}

variable "s3_key" {
  description = "S3 key for Lambda code zip."
  type        = string
  default     = "my_lambda_key.zip"
}

variable "handler" {
  description = "Lambda handler (e.g., lambda_function.lambda_handler)."
  type        = string
  default     = "lambda_function.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime (e.g., python3.12, java11)."
  type        = string
  default     = "python3.12"
}

variable "environment" {
  description = "Environment variables for Lambda."
  type        = map(string)
  default     = {}
}
