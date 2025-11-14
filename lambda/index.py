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

def handler(event, context):
    # Handle HTTP API v2 event format
    request_context = event.get("requestContext", {})
    http_info = request_context.get("http", {})
    
    # Get method - HTTP API v2 uses requestContext.http.method
    method = http_info.get("method") or event.get("httpMethod")
    
    # Get path - HTTP API v2 uses rawPath
    path = event.get("rawPath") or event.get("path", "")
    
    # Debug logging (remove in production or use proper logging)
    print(f"Method: {method}, Path: {path}, Event keys: {list(event.keys())}")
    
    if method == "POST" and path.endswith("/upload"):
        return handle_upload(event)
    elif method == "GET" and path.endswith("/images"):
        return handle_list(event)
    else:
        return {
            "statusCode": 404,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": "Not Found", "method": method, "path": path})
        }

def handle_upload(event):
    try:
        # For simplicity, assume base64 encoded files in JSON array: {"folder": "...", "files": [{"filename": "...", "content": "..."}]}
        body_str = event.get("body") or "{}"
        body = json.loads(body_str)
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
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps({"uploaded": uploaded})
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(e)})
        }

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
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
                "Access-Control-Allow-Headers": "Content-Type"
            },
            "body": json.dumps(resp.get("Items", []))
        }

    except Exception as e:
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({"error": str(e)})
        }
