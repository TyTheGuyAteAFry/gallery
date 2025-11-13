import json
import boto3
import os

s3 = boto3.client("s3")
BUCKET = os.environ.get("GALLERY_BUCKET")  # Injected by Terraform

def handler(event, context):
    try:
        response = s3.list_objects_v2(Bucket=BUCKET, Prefix="")
        images = []
        if "Contents" in response:
            for obj in response["Contents"]:
                key = obj["Key"]
                if key.lower().endswith((".jpg", ".png", ".jpeg", ".gif")):
                    images.append(f"https://{BUCKET}.s3.amazonaws.com/{key}")

        return {
            "statusCode": 200,
            "headers": {"Content-Type": "application/json"},
            "body": json.dumps({"images": images}),
        }
    except Exception as e:
        return {
            "statusCode": 500,
            "body": json.dumps({"error": str(e)})
        }
