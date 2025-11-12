# random id to ensure unique S3 bucket names
resource "random_id" "suffix" {
  byte_length = 4
}
