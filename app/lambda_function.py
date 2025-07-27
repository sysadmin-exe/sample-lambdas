import json
import boto3
import os
from datetime import datetime, timezone

def lambda_handler(event, context):
    """
    Expects event to contain:
      - environment: str (e.g., 'prod', 'dev', 'customer1')
      - config: dict (the configuration data)
      - bucket: str (S3 bucket name)
      - [optional] key_prefix: str (S3 key prefix)
    """
    environment = event.get('environment')
    config = event.get('config')
    bucket = event.get('bucket')
    key_prefix = event.get('key_prefix', 'env-configs')

    if not environment or not config or not bucket:
        return {
            'status': 'error',
            'message': 'Missing required parameters: environment, config, bucket.'
        }

    s3 = boto3.client('s3')
    timestamp = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ')
    key = f"{key_prefix}/{environment}-config-{timestamp}.json"

    try:
        s3.put_object(
            Bucket=bucket,
            Key=key,
            Body=json.dumps(config, indent=2),
            ContentType='application/json'
        )
        return {
            'status': 'success',
            's3_path': f's3://{bucket}/{key}'
        }
    except Exception as e:
        return {
            'status': 'error',
            'message': str(e)
        }
