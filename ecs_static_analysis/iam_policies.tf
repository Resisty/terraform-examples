# S3 Notification Policy
data "aws_iam_policy_document" "static_analysis_s3_to_sqs_ecs_execution_policy_doc" {
  statement {
    effect    = "Allow"
    actions   = [
      "logs:*",
    ],
    resources = [
      "arn:aws:logs:*:*:*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "lambda:invokeFunction",
    ],
    resources = [
      "${aws_lambda_function.static_analysis_s3_to_sqs_ecs_lambda.arn}",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "sqs:*",
    ],
    resources = [
      "${aws_sqs_queue.static_analysis_queue.arn}",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "ecs:RunTask",
      "ecs:StartTask",
    ],
    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.update_es_from_static_analysis.family}",
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.update_es_from_static_analysis.family}:*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "ecs:Submit*",
      "ecs:DeregisterContainerInstance",
      "ecs:RegisterContainerInstance",
    ],
    resources = [
      "${aws_ecs_cluster.update_es_from_static_analysis_cluster.arn}",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "ecr:GetAuthorizationToken",
      "ecs:DiscoverPollEndpoint",
      "ecs:Poll",
      "ecs:StartTelemetrySession",
    ],
    resources = [
      "*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchGetImage",
    ],
    resources = [
      "${aws_ecr_repository.static_analysis_updater.arn}",
    ]
  }
	statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      "${aws_s3_bucket.static_analysis_reception.arn}",
      "${aws_s3_bucket.static_analysis_reception.arn}/*",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "ses:SendEmail",
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
      "${var.es_endpoint_arn}",
      "${var.es_endpoint_arn}/*",
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
      "${aws_iam_role.static_analysis_s3_to_sqs_ecs_execute_role.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "static_analysis_s3_to_sqs_ecs_execution_policy" {
  name   = "${var.module_name}-static_analysis_s3_to_sqs_ecs_execution_policy"
  role   = "${aws_iam_role.static_analysis_s3_to_sqs_ecs_execute_role.id}"
  policy = "${data.aws_iam_policy_document.static_analysis_s3_to_sqs_ecs_execution_policy_doc.json}"
}
