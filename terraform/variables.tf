variable "project" {
  type        = string
  description = "Project name prefix for AWS resources"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "lambda_zip_path" {
  description = "Path to the Lambda deployment ZIP file"
  type        = string
  default     = "../lambda/backend.zip" # adjust to your actual path
}

variable "lambda_handler" {
  description = "Lambda function handler"
  type        = string
  default     = "index.handler"
}

variable "lambda_runtime" {
  description = "Lambda runtime"
  type        = string
  default     = "python3.11"
}

# Variables
variable "domain_name" {
  default = "tybierwagen.com"
}

variable "subdomain" {
  default = "gallery"
}

# Full domain
locals {
  full_domain = "${var.subdomain}.${var.domain_name}"
}

# Get existing hosted zone
data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# Request ACM certificate for domain
resource "aws_acm_certificate" "cert" {
  domain_name       = local.full_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

# Route53 validation records
resource "aws_route53_record" "cert_validation" {
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => dvo
  }

  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

# Validate ACM certificate
resource "aws_acm_certificate_validation" "cert_validation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for record in aws_route53_record.cert_validation : record.fqdn]
}

# Route53 alias record pointing subdomain to CloudFront
resource "aws_route53_record" "gallery_alias" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.full_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.cdn.domain_name
    zone_id                = aws_cloudfront_distribution.cdn.hosted_zone_id
    evaluate_target_health = false
  }
}
