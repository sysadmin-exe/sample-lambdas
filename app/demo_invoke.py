import json
from lambda_function import lambda_handler

# Simulate the central environment management system
if __name__ == "__main__":
    # Example configuration data
    event = {
        "environment": "customer1",
        "config": {
            "apiUrl": "https://api.customer1.example.com",
            "featureFlag": True,
            "theme": "dark"
        },
        "bucket": "your-s3-bucket-name",  # Replace with your S3 bucket
        "key_prefix": "env-configs"
    }
    # Context is not used in this example
    result = lambda_handler(event, None)
    print(json.dumps(result, indent=2))
