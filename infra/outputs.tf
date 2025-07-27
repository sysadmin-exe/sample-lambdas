output "lambda_function_arns" {
  description = "ARNs of all deployed Lambda functions."
  value       = { for k, v in module.lambda_functions : k => v.lambda_function_arn }
}

output "lambda_function_names" {
  description = "Names of all deployed Lambda functions."
  value       = { for k, v in module.lambda_functions : k => v.lambda_function_name }
}

output "environment_s3_arns" {
  description = "S3 ARNs of the Lambda deployment packages."
  value       = { for k, v in module.lambda_functions : k => v.environment_s3_arn }
}
