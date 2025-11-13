# Explicit CloudWatch Log Group for Lambda with a retention policy
resource "aws_cloudwatch_log_group" "lambda_log" {
  name              = "/aws/lambda/${var.project}-backend-${random_id.suffix.hex}"
  retention_in_days = 14
}

# Lambda function (expects a zip at terraform/lambda/backend.zip)
resource "aws_lambda_function" "backend" {
  filename         = var.lambda_zip_path
  function_name    = "${var.project}-backend"
  source_code_hash = filebase64sha256("${var.lambda_zip_path}")
  role             = aws_iam_role.lambda_role.arn
  handler          = var.lambda_handler
  runtime          = var.lambda_runtime
  timeout          = 15
  environment {
    variables = {
      PHOTOS_TABLE = aws_dynamodb_table.photos_table.name
      S3_BUCKET    = aws_s3_bucket.site_bucket.id
      REGION       = var.region
      ENVIRONMENT  = var.environment
    }
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}

# Allow the API Gateway v2 to invoke the Lambda
resource "aws_lambda_permission" "apigw_invoke" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.backend.function_name
  principal     = "apigateway.amazonaws.com"
  # source_arn can be restricted to the API Gateway ARN after creation
}

# HTTP API (API Gateway v2)
resource "aws_apigatewayv2_api" "http_api" {
  name          = "${var.project}-http-api-${random_id.suffix.hex}"
  protocol_type = "HTTP"
}

# Integration Lambda
resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.http_api.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.backend.invoke_arn
  integration_method     = "POST"
  payload_format_version = "2.0"
}

# Route to forward all requests to Lambda (you can change to specific route)
resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.http_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

# Stage
resource "aws_apigatewayv2_stage" "prod" {
  api_id      = aws_apigatewayv2_api.http_api.id
  name        = "$default"
  auto_deploy = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.apigw_logs.arn
    format = jsonencode({
      requestId       = "$context.requestId",
      ip              = "$context.identity.sourceIp",
      routeKey        = "$context.routeKey",
      status          = "$context.status",
      protocol        = "$context.protocol",
      responseLatency = "$context.responseLatency"
    })
  }

  default_route_settings {
    throttling_burst_limit = 5000
    throttling_rate_limit  = 10000
  }
}

# CloudWatch Log Group for API Gateway access logs
resource "aws_cloudwatch_log_group" "apigw_logs" {
  name              = "/aws/apigateway/${aws_apigatewayv2_api.http_api.id}"
  retention_in_days = 30
}

# Give API Gateway permission to write logs by attaching the role
resource "aws_iam_role_policy_attachment" "apigw_logging_attach" {
  role       = aws_iam_role.apigw_logging_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}
