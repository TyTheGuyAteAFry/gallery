locals {
  bucket_name      = "${var.project}-site-${random_id.suffix.hex}"
  logs_bucket_name = "${var.project}-logs-${random_id.suffix.hex}"
}

# Bucket to store the static site build (frontend)
resource "aws_s3_bucket" "site_bucket" {
  bucket = local.bucket_name

  logging {
    target_bucket = aws_s3_bucket.logs_bucket.id
    target_prefix = "s3-access-logs/"
  }

  force_destroy = false

  tags = {
    Name        = local.bucket_name
    Project     = var.project
    Environment = var.environment
  }
}

# Bucket to store logs (S3 + CloudFront logs)
resource "aws_s3_bucket" "logs_bucket" {
  bucket = local.logs_bucket_name

  force_destroy = false

  tags = {
    Name        = local.logs_bucket_name
    Project     = var.project
    Environment = var.environment
  }
}

# Block public access on both buckets
resource "aws_s3_bucket_public_access_block" "site_block" {
  bucket = aws_s3_bucket.site_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs_block" {
  bucket = aws_s3_bucket.logs_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption applied via separate resource
resource "aws_s3_bucket_server_side_encryption_configuration" "site_bucket_sse" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "logs_bucket_sse" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_acl" "site_bucket_acl" {
  bucket = aws_s3_bucket.site_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_acl" "logs_bucket_acl" {
  bucket = aws_s3_bucket.logs_bucket.id
  acl    = "log-delivery-write"
}
