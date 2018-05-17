resource "aws_s3_bucket" "remote_state" {
  bucket = "${var.remote_state_bucket}"
  region = "${var.aws_region}"
  acl    = "private"

  versioning {
    enabled = true
  }
}

variable "remote_state_bucket" {}
