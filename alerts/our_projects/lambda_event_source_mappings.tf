resource "aws_lambda_event_source_mapping" "analytics_output_to_notifyfailures_lambda" {
  count             = "${var.create_alerts}"
  batch_size        = 1
  event_source_arn  = "${aws_kinesis_stream.analytics-stream-output.arn}"
  enabled           = true
  function_name     = "${aws_lambda_function.failures_notify_lambda.arn}"
  starting_position = "LATEST"
}
