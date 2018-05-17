resource "aws_s3_bucket" "kinesis_firehose" {
  bucket = "${var.module_name}-kinesis-firehose-${var.aws_region}"
  region = "${var.aws_region}"
  acl    = "private"

  versioning {
    enabled = true
  }
  lifecycle_rule {
      id      = "all"
      enabled = true
  
      prefix  = ""
      tags {
        "rule"    = "all"
        "project" = "${var.module_name}"
      }
  
      transition {
        days          = 364
        storage_class = "GLACIER"
      }
  
      expiration {
        days = 365
      }
  }
}
