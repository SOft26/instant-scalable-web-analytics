terraform {
  backend "s3" {
    bucket         = "plausible-terraform-state-prod"  # your S3 bucket
    key            = "eks/terraform.tfstate"           # path within the bucket
    region         = "us-east-1"                       # your region
    dynamodb_table = "terraform-locks"                 # for locking
    encrypt        = true                              # enable SSE encryption
  }
}
