locals {
  api_domain = "${aws_apigatewayv2_api.http_api.id}.execute-api.${var.region}.amazonaws.com"
}

# CloudFront function to rewrite /api/* paths to /* for API Gateway
resource "aws_cloudfront_function" "api_path_rewrite" {
  name    = "${var.project}-api-path-rewrite"
  runtime = "cloudfront-js-1.0"
  code    = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;
    
    // Debug: Log the original URI
    console.log('Original URI: ' + uri);
    
    // Rewrite /api/* to /* for API Gateway (strip /api prefix)
    // Query string is automatically preserved in the request object
    if (uri.startsWith('/api/')) {
        var newUri = uri.substring(4); // Remove '/api' prefix (4 characters)
        request.uri = newUri;
        console.log('Rewritten URI: ' + newUri);
    } else if (uri === '/api') {
        request.uri = '/';
        console.log('Rewritten URI: /');
    }
    
    return request;
}
EOT
  publish = true
}

resource "aws_cloudfront_function" "spa_router" {
  name    = "${var.project}-spa-router"
  runtime = "cloudfront-js-1.0"
  code    = <<-EOT
function handler(event) {
    var request = event.request;
    var uri = request.uri;

    // Leave API requests alone
    if (uri.startsWith('/api/') || uri === '/api') {
        return request;
    }

    // Serve the SPA shell for any non-file path
    if (!uri.includes('.') && !uri.endsWith('/index.html')) {
        request.uri = '/index.html';
    }

    return request;
}
EOT
  publish = true
}


# CloudFront OAI (origin access identity)
resource "aws_cloudfront_origin_access_identity" "oai" {
  comment = "OAI for ${local.bucket_name}"
}

# Allow CloudFront OAI to access S3 bucket
resource "aws_s3_bucket_policy" "site_bucket_policy" {
  bucket = aws_s3_bucket.site_bucket.id
  policy = data.aws_iam_policy_document.site_bucket_policy.json
}

data "aws_iam_policy_document" "site_bucket_policy" {
  statement {
    sid = "AllowCloudFrontServicePrincipalReadOnly"
    principals {
      type        = "AWS"
      identifiers = [aws_cloudfront_origin_access_identity.oai.iam_arn]
    }
    actions = ["s3:GetObject"]
    resources = [
      "${aws_s3_bucket.site_bucket.arn}/*"
    ]
  }
}

# CloudFront distribution
resource "aws_cloudfront_distribution" "cdn" {
  enabled = true
  comment = "CDN for ${aws_s3_bucket.site_bucket.id}"

  origin {
    domain_name = aws_s3_bucket.site_bucket.bucket_regional_domain_name
    origin_id   = "S3Origin"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  origin {
    domain_name = "${aws_apigatewayv2_api.http_api.id}.execute-api.${var.region}.amazonaws.com"
    origin_id   = "APIGatewayOrigin"
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "https-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }

    custom_header {
      name  = "Host"
      value = local.api_domain
    }
  }


#whitespace
  default_cache_behavior {
    target_origin_id       = "S3Origin"
    viewer_protocol_policy = "redirect-to-https"

    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]

    cache_policy_id          = "658327ea-f89d-4fab-a63d-7e88639e58f6"

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.spa_router.arn
    }
  }

  ordered_cache_behavior {
    path_pattern     = "/api/*"
    target_origin_id = "APIGatewayOrigin"

    viewer_protocol_policy = "redirect-to-https"
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD"]

    cache_policy_id          = "4135ea2d-6df8-44a3-9df3-4b5a84be39ad" # CachingDisabled
    origin_request_policy_id = "216adef6-5c7f-47e4-b989-5492eafa07d3" # AllViewerExceptHostHeader

    function_association {
      event_type   = "viewer-request"
      function_arn = aws_cloudfront_function.api_path_rewrite.arn
    }
  }


  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn = aws_acm_certificate.cert.arn
    ssl_support_method  = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }

  aliases = [local.full_domain]

  # Enable CloudFront logging for debugging
  logging_config {
    bucket          = aws_s3_bucket.logs_bucket.bucket_domain_name
    include_cookies = false
    prefix          = "cloudfront-access/"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }

  default_root_object = "index.html"

}