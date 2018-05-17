resource "aws_cloudwatch_metric_alarm" "kinesis_put_success_rate" {
  alarm_name                = "${var.module_name}-kinesis-put-success-rate"
  comparison_operator       = "LessThanOrEqualToThreshold"
  # 2 times in a row every five minutes => Affected for ten minutes
  evaluation_periods        = "2"
  period                    = "300"
  metric_name               = "PutRecords.Success"
  namespace                 = "AWS/Kinesis"
  statistic                 = "Average"
  # At least 95% success rate
  threshold                 = ".95"
  alarm_description         = "This metric monitors the success rate of PUTting records from ${var.module_name}'s input kinesis stream."
  # notBreaching is "good" - no records coming in mean nothing to PUT
  treat_missing_data        = "notBreaching"
  # This is a hardcoded var instead of a created resource
  # see variables.yaml for a note about why
  alarm_actions             = ["${var.logs_alarm_sub}"]
  ok_actions                = ["${var.logs_alarm_sub}"]


  dimensions {
    StreamName = "${aws_kinesis_stream.input.name}"
  }
}
