resource "aws_cloudwatch_log_group" "kinesis_firehose_loggroup" {
  name              = "/aws/kinesisfirehose/${var.module_name}/logs"
  retention_in_days = 365
}

resource "aws_cloudwatch_log_stream" "kinesis_firehose_logstream" {
  name           = "kinesis-firehose-${var.module_name}-logstream" 
  log_group_name = "${aws_cloudwatch_log_group.kinesis_firehose_loggroup.name}"
}
