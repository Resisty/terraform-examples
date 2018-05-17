resource "aws_sns_topic" "cloudwatch_metrics_deadletter_topic" {
  name = "cloudwatch_metrics_deadletter_topic"
}

resource "aws_sns_topic_subscription" "cloudwatch_deadletter_lambda_to_slack" {
  topic_arn = "${aws_sns_topic.cloudwatch_metrics_deadletter_topic.arn}"
  protocol  = "lambda"
  endpoint  = "${aws_lambda_function.deadletter_cloudwatch_lambda_notifier.arn}"
}
