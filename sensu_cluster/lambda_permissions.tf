resource "aws_lambda_permission" "ansible_kick_reception_trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.ansible_kick_lambda_notifier.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.sensu_cluster_bucket.arn}"
}
