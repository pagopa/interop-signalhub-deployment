module "log_streaming_bucket" {
  source  = "terraform-aws-modules/s3-bucket/aws"
  version = "3.15.1"

  bucket = format("%s-log-streaming-s3-bucket-%s", var.module_resource_prefix, var.env)

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true

  versioning = {
    enabled = true
  }

  tags = var.s3_bucket_tags
}