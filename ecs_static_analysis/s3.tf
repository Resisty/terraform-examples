resource "aws_s3_bucket" "static_analysis_reception" {
  bucket = "${var.module_name}-zipped"
  region = "${var.aws_region}"
  acl    = "private"

  versioning {
    enabled = true
  }
}

resource "aws_s3_bucket_notification" "static_analysis_reception_notifier" {
  bucket = "${aws_s3_bucket.static_analysis_reception.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.static_analysis_s3_to_sqs_ecs_lambda.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".tar.gz"
  }
}
