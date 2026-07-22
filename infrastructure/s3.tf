

resource "aws_s3_bucket" "medicore_data" {
  bucket = "medicore-clinical-data-${data.aws_caller_identity.current.account_id}"

  force_destroy = true

  tags = {
    Name               = "medicore-clinical-data"
    Environment        = "Development"
    DataClassification = "Confidential"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "medicore_data" {
  bucket = aws_s3_bucket.medicore_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "medicore_data" {
  bucket = aws_s3_bucket.medicore_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}