data "template_file" "failures0" {
	template = "${file("${path.module}/../analytics_sql/failures0.sql")}"
	vars {
    gitfat_threshold   = "${var.gitfat_threshold}"
  }
}
resource "aws_cloudformation_stack" "analytics_stack" {
  count = "${var.create_alerts}"
  name  = "${var.module_name}-analytics-stack"

  parameters {
    InputStream       = "${aws_kinesis_stream.input.arn}"
    OutputStream      = "${aws_kinesis_stream.analytics-stream-output.arn}"
    ApplicationCode0  = "${data.template_file.failures0.rendered}"
    Role              = "${aws_iam_role.kinesis_analytics_role.arn}"
    StackAppName      = "${var.module_name}FailuresAnalyticsApplication"
  }

  template_body = "${file("${path.module}/../analytics_stacks/analytics.stack")}"
}
