locals {
  function_name = replace(var.function_name, "/", "-")
  repo_name     = element(split("/", var.function_name), length(split("/", var.function_name)) - 1)
  zip_file_name = "${local.repo_name}.zip"
  clone_dir     = "${path.root}/${local.repo_name}"
}
##############################
# Logic to clone the repository and create a ZIP file for the Lambda function
##############################
resource "null_resource" "create_temp_dir" {
  provisioner "local-exec" {
    command = "mkdir -p ${dirname(local.clone_dir)}"
  }

  triggers = {
    function_name = local.function_name
  }
}
resource "null_resource" "clone_repo" {
  depends_on = [null_resource.create_temp_dir]

  provisioner "local-exec" {
    command = <<-EOT
      # Remove existing directory if it exists
      rm -rf ${local.clone_dir}
      
      # Clone the repository
      git clone --depth 1 https://github.com/${var.function_name}.git ${local.clone_dir}

      # Remove .git directory to reduce size
      rm -rf ${local.clone_dir}/.git
    EOT
  }

  triggers = {
    function_name = local.function_name
    always_run    = timestamp()
  }
}

# Create ZIP file
data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.clone_repo]
  type        = "zip"
  source_file = "${local.clone_dir}/app/lambda_function.py"
  output_path = "${local.clone_dir}/function.zip"
}

# Clean up temporary files
resource "null_resource" "cleanup" {
  depends_on = [aws_lambda_function.this]

  provisioner "local-exec" {
    command = <<-EOT
      # Remove existing directory if it exists
      if [ -d "${local.clone_dir}" ]; then
        rm -rf ${local.clone_dir}
      fi
    EOT
  }

  triggers = {
    function_name = local.function_name
    always_run    = timestamp()
  }
}

##############################
# Terraform configuration for AWS Lambda function
##############################

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = local.function_name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = var.runtime
  logging_config {
    log_format       = "JSON"
    system_log_level = "WARN"
  }
  tags = {
    Application = local.function_name
  }

  # depends_on = [ aws_cloudwatch_log_group.this ]
}

resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${aws_lambda_function.this.function_name}"
  retention_in_days = 1
  tags = {
    Application = local.function_name
  }
}

###############################
# S3 Bucket for Lambda results
###############################
resource "aws_s3_bucket" "this" {
  bucket = local.function_name

  tags = {
    Name = local.function_name
  }
}


resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "this" {
  depends_on = [aws_s3_bucket_ownership_controls.this]
  bucket     = aws_s3_bucket.this.id

  acl = "private"
}

###############################
# IAM Role for Lambda Function
###############################
data "aws_iam_policy_document" "lambda_s3_write" {
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl"
    ]
    resources = [
      "${aws_s3_bucket.this.arn}/*"
    ]
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.function_name}-lambda-exec"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role.json
}

data "aws_iam_policy_document" "lambda_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "lambda_s3_write" {
  name   = "${local.function_name}-lambda-s3-write"
  policy = data.aws_iam_policy_document.lambda_s3_write.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_write" {
  role       = aws_iam_role.this.name
  policy_arn = aws_iam_policy.lambda_s3_write.arn
}
