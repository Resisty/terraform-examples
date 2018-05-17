data "archive_file" "streaming_failures_analytics" {
  count       = "${var.create_alerts}"
  type        = "zip"
  source_dir  = "${path.module}/lambdas/notifyfailures"
  output_path = "notifyfailures.zip"
}

resource "aws_lambda_function" "failures_notify_lambda" {
  count       = "${var.create_alerts}"
  filename         = "notifyfailures.zip"
  source_code_hash = "${data.archive_file.streaming_failures_analytics.output_base64sha256}"
  function_name    = "${var.module_name}_streaming_failures_analytics"
  role             = "${aws_iam_role.lambda_analytics_role.arn}"
  description      = "Lambda function to create a PagerDuty incident from failures captured in Kinesis Analytics for ${var.module_name} project."
  handler          = "notifyfailures.lambda_handler"
  runtime          = "python3.6"
  environment {
    variables {
      severity           = "${var.severity}"
      pd_api_key         = "${var.pd_api_key}"
      test_pd_api_key    = "${var.test_pd_api_key}"
			kibana_proxy       = "${var.devops_kibana_proxy}"
			email_addresses    = "${var.offhours_lambda_email_addresses}"
			registered_address = "${var.offhours_lambda_registered_address}"
			default_tz         = "${var.default_lambda_timezone}"
			enable_offhours    = "${var.enable_offhours}"
    }
  }
}
