resource "aws_cloudwatch_log_group" "fluent-plugin-cloudwatch-test" {
  name              = "fluent-plugin-cloudwatch-test"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_group" "kinesis_firehose_loggroup" {
  name              = "/aws/kinesisfirehose/logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_test_logstream" {
  name           = "kinesis-firehose-test-logstream" 
  log_group_name = "${aws_cloudwatch_log_group.kinesis_firehose_loggroup.name}"
}
