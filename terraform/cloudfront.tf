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
    origin_id   = "s3-${aws_s3_bucket.site_bucket.id}"

    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.oai.cloudfront_access_identity_path
    }
  }

  default_cache_behavior {
    allowed_methods  = ["GET", "HEAD", "OPTIONS"]
    cached_methods   = ["GET", "HEAD"]
    target_origin_id = "s3-${aws_s3_bucket.site_bucket.id}"

    viewer_protocol_policy = "redirect-to-https"

    forwarded_values {
      query_string = false
      cookies {
        forward = "none"
      }
    }

    min_ttl     = 0
    default_ttl = 3600
    max_ttl     = 86400
  }

  # Logging to S3 logs bucket
  logging_config {
    include_cookies = false
    bucket          = aws_s3_bucket.logs_bucket.bucket_domain_name
    prefix          = "cloudfront/"
  }

  price_class = "PriceClass_100"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
