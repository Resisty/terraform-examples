resource "aws_cloudwatch_event_rule" "every_day_0100" {
    name = "every-day-0100"
    description = "Fires every day at 0100 hours"
    schedule_expression = "cron(0 1 * * ? *)"
}
