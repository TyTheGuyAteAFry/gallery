terraform {
  backend "s3" {
    bucket         = "terraform-state-bucket-gallery-app"
    key            = "gallery/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}
