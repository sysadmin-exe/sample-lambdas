# Sample Lambdas

This repository contains:
- A sample AWS Lambda function which works as a central environment management system
- Terraform code that deploys the lambda


## App
The `app` directory contains a Python AWS Lambda function that receives environment-specific configuration data (such as API URLs, feature flags, and themes) from a central management system. The Lambda processes this data and stores it in an S3 bucket as a JSON file, making it available for browser-based applications to fetch as needed. The Lambda returns feedback on the operation's success or failure, simulating interaction with the central management system. Delivery to the browser and management system implementation are out of scope.

### Testing the lambda
```json
{
    "environment": "customer1",
    "config": {
        "apiUrl": "https://api.customer1.example.com",
        "featureFlag": "True",
        "theme": "dark"
    },
    "bucket": "sysadmin-exe-sample-lambdas",
    "key_prefix": "env-configs"
}
```
The above is a sample of the format in which environment config is processed and stored. This can be passed in AWS console to test the lambda. 



## Infra
The `infra` directory contains Terraform code to provision the necessary AWS resources for the Lambda function. This includes:

- An S3 bucket for storing environment configuration JSON files.
- The Lambda function and its IAM role with permissions to read/write to the S3 bucket.
- (Optional) Additional resources such as CloudWatch log groups for Lambda monitoring.

Only one `tfvars` is used in this case. The only value needed to be passed is the lambda repo name like so `<org-name>/<repo-name>`.

```hcl
lambda_functions = [
  "sysadmin-exe/sample-lambdas"
]
```

The terraform module does the following 
- take the name and clones the repo
- creates the zip file for the lambda function
- creates all AWS resources (lambda, S3 for the application to store files, IAM for lambda to access S3)
- cleans up the cloned repo after lambda has been created
