resource "aws_cloudwatch_metric_alarm" "deadletter_queue_alarm" {
  alarm_name          = "accountwide-deadletter-queue-alarm"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = "2"
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = "120"
  statistic           = "Average"
  threshold           = "1"
  alarm_description   = "This metric monitors the total number of messages sent to the account's dead letter queue"

  dimensions {
    QueueName = "${data.aws_caller_identity.current.account_id}-accountwide-deadletter-queue"
  }

  alarm_actions     = ["${aws_sns_topic.cloudwatch_metrics_deadletter_topic.arn}"]
}
