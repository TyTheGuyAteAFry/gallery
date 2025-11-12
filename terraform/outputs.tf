output "cloudfront_domain" {
  description = "CloudFront distribution domain"
  value       = aws_cloudfront_distribution.cdn.domain_name
}

output "s3_site_bucket" {
  description = "S3 bucket name for site"
  value       = aws_s3_bucket.site_bucket.id
}

output "s3_logs_bucket" {
  description = "S3 bucket name for logs (S3/CloudFront)"
  value       = aws_s3_bucket.logs_bucket.id
}

output "api_endpoint" {
  description = "HTTP API endpoint"
  value       = aws_apigatewayv2_api.http_api.api_endpoint
}

output "lambda_name" {
  description = "Lambda function name"
  value       = aws_lambda_function.backend.function_name
}

output "dynamodb_table" {
  description = "DynamoDB table name"
  value       = aws_dynamodb_table.photos_table.name
}
