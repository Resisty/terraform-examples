resource "aws_sqs_queue" "static_analysis_queue" {
  name                      = "${var.module_name}_static_analysis_queue"
  message_retention_seconds = 86400
  redrive_policy            = "{\"deadLetterTargetArn\":\"${var.account_dead_queue}\",\"maxReceiveCount\":4}"
}
