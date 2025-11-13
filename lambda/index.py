import json
import os
import uuid
import boto3
from urllib.parse import parse_qs

# AWS clients
s3 = boto3.client("s3")
dynamodb = boto3.resource("dynamodb")

BUCKET = os.environ["S3_BUCKET"]
TABLE_NAME = os.environ["PHOTOS_TABLE"]

table = dynamodb.Table(TABLE_NAME)

def lambda_handler(event, context):
    method = event.get("httpMethod")
    path = event.get("rawPath") or event.get("path")  # API Gateway v2 vs v1

    if method == "POST" and path.endswith("/upload"):
        return handle_upload(event)
    elif method == "GET" and path.endswith("/images"):
        return handle_list(event)
    else:
        return {"statusCode": 404, "body": "Not Found"}

def handle_upload(event):
    try:
        # For simplicity, assume base64 encoded files in JSON array: {"folder": "...", "files": [{"filename": "...", "content": "..."}]}
        body = json.loads(event["body"])
        folder = body.get("folder", "Default")
        files = body.get("files", [])

        uploaded = []

        for f in files:
            file_content = bytes(f["content"], "utf-8")  # if you base64 encode, decode first
            filename = f"{uuid.uuid4()}-{f['filename']}"
            s3_key = f"{folder}/{filename}"

            s3.put_object(Bucket=BUCKET, Key=s3_key, Body=file_content)
            
            # Save record in DynamoDB
            table.put_item(Item={
                "id": str(uuid.uuid4()),
                "folder": folder,
                "url": f"https://{BUCKET}.s3.amazonaws.com/{s3_key}"
            })

            uploaded.append(s3_key)

        return {
            "statusCode": 200,
            "body": json.dumps({"uploaded": uploaded})
        }

    except Exception as e:
        return {"statusCode": 500, "body": str(e)}

def handle_list(event):
    try:
        query = event.get("queryStringParameters") or {}
        folder = query.get("folder", "Default")

        # DynamoDB scan by folder (better: use secondary index)
        resp = table.scan(
            FilterExpression="folder = :f",
            ExpressionAttributeValues={":f": folder}
        )

        return {
            "statusCode": 200,
            "body": json.dumps(resp.get("Items", []))
        }

    except Exception as e:
        return {"statusCode": 500, "body": str(e)}
