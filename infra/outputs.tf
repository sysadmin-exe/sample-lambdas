output "lambda_function_arns" {
  description = "ARNs of all deployed Lambda functions."
  value       = { for k, v in module.lambda_functions : k => v.aws_lambda_function_arn }
}
