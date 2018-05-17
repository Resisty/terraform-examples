data "aws_iam_policy_document" "escleanup_lambda_execution_policy_doc" {
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
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "es:*",
    ]
    resources = [
      "${var.es_domain_arn}",
      "${var.es_domain_arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "escleanup_lambda_execution_policy" {
  name = "escleanup_lambda_execution_policy" 
  role = "${aws_iam_role.escleanup_lambda_exec_role.id}"
  policy = "${data.aws_iam_policy_document.escleanup_lambda_execution_policy_doc.json}"
}
