resource "aws_lambda_permission" "cwl_call_logs_es_cleanup" {
    statement_id = "AllowExecutionFromCloudWatch"
    action = "lambda:InvokeFunction"
    function_name = "${aws_lambda_function.logs_es_cleanup_lambda.function_name}"
    principal = "events.amazonaws.com"
    source_arn = "${aws_cloudwatch_event_rule.every_day_0100.arn}"
}
