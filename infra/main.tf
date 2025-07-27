terraform {
  required_version = "~> 1.8"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.5.0"
    }
    null_resource = {
      source  = "hashicorp/null"
      version = "3.1.0"
    }
    archive_file = {
      source  = "hashicorp/archive"
      version = "3.1.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = "dev"
      Project     = "Central Environment Management System"
      Owner       = "demo"
      Terraform   = "true"
    }
  }
}

module "lambda_functions" {
  source   = "./modules/lambda_function"
  for_each = toset(var.lambda_functions)

  function_name = each.value.name
}
