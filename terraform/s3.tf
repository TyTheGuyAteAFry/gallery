locals {
  bucket_name      = "${var.project}-site-${random_id.suffix.hex}"
  logs_bucket_name = "${var.project}-logs-${random_id.suffix.hex}"
}

# Bucket to store the static site build (frontend
resource "aws_s3_bucket" "site_bucket" {
  bucket        = local.bucket_name
  force_destroy = false

  tags = {
    Name        = local.bucket_name
    Project     = var.project
    Environment = var.environment
  }
}

resource "aws_s3_bucket_ownership_controls" "site_bucket_ownership" {
  bucket = aws_s3_bucket.site_bucket.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

# Bucket to store logs (S3 + CloudFront logs)
resource "aws_s3_bucket" "logs_bucket" {
  bucket        = local.logs_bucket_name
  force_destroy = false

  tags = {
    Name        = local.logs_bucket_name
    Project     = var.project
    Environment = var.environment
  }

}

resource "aws_s3_bucket_ownership_controls" "logs_bucket_ownership" {
  bucket = aws_s3_bucket.logs_bucket.id

  rule {
    object_ownership = "ObjectWriter"
  }
}

# Block public access on both buckets
resource "aws_s3_bucket_public_access_block" "site_block" {
  bucket                  = aws_s3_bucket.site_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_public_access_block" "logs_block" {
  bucket                  = aws_s3_bucket.logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Server-side encryption
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

# Use aws_s3_bucket_logging instead of deprecated logging block
resource "aws_s3_bucket_logging" "site_bucket_logging" {
  bucket        = aws_s3_bucket.site_bucket.id
  target_bucket = aws_s3_bucket.logs_bucket.id
  target_prefix = "cloudfront/"
}

resource "aws_s3_bucket" "state_bucket" {
  bucket = "terraform-state-bucket-gallery-app"
}