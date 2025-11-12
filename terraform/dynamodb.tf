resource "aws_dynamodb_table" "photos_table" {
  name         = "${var.project}-photos-${random_id.suffix.hex}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    Project     = var.project
    Environment = var.environment
  }
}
