resource "aws_sqs_queue" "account_dead_queue" {
  # Deadletter queue for account
  name                      = "${data.aws_caller_identity.current.account_id}-accountwide-deadletter-queue"
  message_retention_seconds = 86400
}
