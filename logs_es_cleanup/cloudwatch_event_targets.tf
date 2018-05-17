resource "aws_cloudwatch_event_target" "target_logs_es_cleanup" {
    rule = "${aws_cloudwatch_event_rule.every_day_0100.name}"
    target_id = "logs_es_cleanup_target"
    arn = "${aws_lambda_function.logs_es_cleanup_lambda.arn}"
}
