##############################
# Terraform configuration for AWS Lambda function
##############################
resource "null_resource" "clone_lambda_repo" {
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/${var.function_name}
      git clone https://github.com/${var.function_name}.git ${path.module}/${var.function_name}
    EOT
  }
}

data "archive_file" "lambda_zip" {
  depends_on  = [null_resource.clone_lambda_repo]
  type        = "zip"
  source_file = "${path.module}/${var.function_name}/app/*"
  output_path = "${path.module}/${var.function_name}/function.zip"
}

resource "null_resource" "remove_lambda_repo" {
  depends_on = [ null_resource.clone_lambda_repo, data.archive_file.lambda_zip, aws_lambda_function.this]
  provisioner "local-exec" {
    command = <<EOT
      rm -rf ${path.module}/${var.function_name}
    EOT
  }
}

resource "aws_lambda_function" "this" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.function_name
  role             = aws_iam_role.this.arn
  handler          = var.handler
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256

  runtime = var.runtime

  tags = {
    Application = var.function_name
  }
}


###############################
# S3 Bucket for Lambda results
###############################
resource "aws_s3_bucket" "this" {
  bucket = var.function_name

  tags = {
    Name = var.function_name
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
  bucket = aws_s3_bucket.this.id

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
  name               = "${var.function_name}-lambda-exec"
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
  name   = "${var.function_name}-lambda-s3-write"
  policy = data.aws_iam_policy_document.lambda_s3_write.json
}

resource "aws_iam_role_policy_attachment" "lambda_s3_write" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_s3_write.arn
}
