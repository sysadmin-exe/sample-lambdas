variable "aws_region" {
  description = "AWS region to deploy resources in."
  type        = string
}

variable "lambda_functions" {
  description = "List of Lambda function"
  type        = list(string)
  default     = []
}
