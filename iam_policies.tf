# CloudWatch Notification Policy
data "aws_iam_policy_document" "deadletter_cloudwatch_lambda_execution_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = [
      "lambda:invokeFunction",
    ],
    resources = [
      "${aws_lambda_function.deadletter_cloudwatch_lambda_notifier.arn}",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:Get*",
      "sqs:ReceiveMessage",
    ],
    resources = [
      "${aws_sqs_queue.account_dead_queue.arn}",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams",
    ]
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "${aws_iam_role.deadletter_cloudwatch_lambda_execution_role.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "deadletter_cloudwatch_lambda_execution_policy" {
  name   = "account-wide-deadletter-cloudwatch-lambda-execution-policy"
  role   = "${aws_iam_role.deadletter_cloudwatch_lambda_execution_role.id}"
  policy = "${data.aws_iam_policy_document.deadletter_cloudwatch_lambda_execution_policy_doc.json}"
}
