resource "aws_lambda_permission" "static-analysis-reception-trigger" {
  statement_id  = "AllowExecutionFromS3Bucket"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.static_analysis_s3_to_sqs_ecs_lambda.arn}"
  principal     = "s3.amazonaws.com"
  source_arn    = "${aws_s3_bucket.static_analysis_reception.arn}"
}
