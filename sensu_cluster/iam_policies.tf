# S3 Notification Policy
data "aws_iam_policy_document" "sensu_cluster_instance_role_policy_doc" {
  statement {
    effect    = "Allow"
    actions = [
      "s3:ListBucket",
    ],
    resources = [
      "${aws_s3_bucket.sensu_cluster_bucket.arn}",
    ]
  }
  statement {
    effect    = "Allow"
    actions = [
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:GetObject",
    ],
    resources = [
      "${aws_s3_bucket.sensu_cluster_bucket.arn}/",
      "${aws_s3_bucket.sensu_cluster_bucket.arn}/*",
    ]
  }
  statement {
    effect    = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingInstances",
      "ec2:Describe*",
      "ec2:CreateNetworkInterface",
      "ec2:DeleteNetworkInterface",
    ],
    resources = [
      "*",
    ]
  }
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
      "lambda:InvokeFunction",
    ]
    resources = [
      "${aws_lambda_function.ansible_kick_lambda_notifier.arn}",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey"
    ]
    resources = [
      "${var.kms_key_arn}",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "iam:PassRole",
    ]
    resources = [
      "${aws_iam_role.sensu_cluster_instance_role.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "sensu_cluster_instance_role_policy" {
  name   = "${var.module_name}-sensu-cluster-instance-role-policy"
  role   = "${aws_iam_role.sensu_cluster_instance_role.id}"
  policy = "${data.aws_iam_policy_document.sensu_cluster_instance_role_policy_doc.json}"
}
