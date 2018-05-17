resource "null_resource" "pip_install_deadletter" {
  provisioner "local-exec" {
    command = "cd lambdas/cloudwatch_sqs_notify; pip install -t . -r requirements.txt"
  }
}

data "archive_file" "deadletter_cloudwatch_lambda_notifier_zip" {
  type        = "zip"
  source_dir  = "./lambdas/cloudwatch_sqs_notify"
  output_path = "deadletter_cloudwatch_lambda_notifier.zip"
  depends_on  = ["null_resource.pip_install_deadletter"]
}

resource "aws_lambda_function" "deadletter_cloudwatch_lambda_notifier" {
  filename    = "deadletter_cloudwatch_lambda_notifier.zip"
  source_code_hash = "${data.archive_file.deadletter_cloudwatch_lambda_notifier_zip.output_base64sha256}"
  function_name    = "deadletter_cloudwatch_lambda_notifier"
  role             = "${aws_iam_role.deadletter_cloudwatch_lambda_execution_role.arn}"
  description      = "Lambda function to notify Slack when CloudWatch metrics for account-wide deadletter queue hits the threshold."
  handler          = "deadletter.lambda_handler"
  runtime          = "python3.6"
  timeout          = 300
  memory_size      = 256
  environment {
    variables {
      SQS_QUEUE = "${aws_sqs_queue.account_dead_queue.id}"
      SLACK_TOKEN = "${data.aws_kms_secret.static_analysis_slack_tokens.devops_slack_token}"
      SLACK_CHANNEL = "#devops_bot"
    }
  }
}

resource "aws_lambda_permission" "allow_lambda_sns_to_slack" {
  statement_id  = "AllowSNSToSlackExecution"
  action        = "lambda:invokeFunction"
  function_name = "${aws_lambda_function.deadletter_cloudwatch_lambda_notifier.arn}"
  principal     = "sns.amazonaws.com"
  source_arn    = "${aws_sns_topic.cloudwatch_metrics_deadletter_topic.arn}"
}
