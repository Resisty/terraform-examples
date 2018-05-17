# S3 Notification Policy
data "aws_iam_policy_document" "nexus_repository_ecs_execution_policy_doc" {
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
      "ecs:RunTask",
      "ecs:StartTask",
    ],
    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.nexus_repository.family}",
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:task-definition/${aws_ecs_task_definition.nexus_repository.family}:*",
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
      "${aws_ecs_cluster.nexus_repository_cluster.arn}",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
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
      "ec2:Describe*",
      "elasticloadbalancing:Describe*",
      "elasticloadbalancing:DeregisterInstancesFromLoadBalancer",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:RegisterInstancesWithLoadBalancer",
      "elasticloadbalancing:RegisterTargets"
    ]
    resources = [
      "*",
    ]
  }
  statement {
    effect    = "Allow"
    actions   = [
      "ec2:AuthorizeSecurityGroupIngress",
    ]
    resources = [
      "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:security-group/${aws_security_group.nexus_lb_sg.id}",
    ]
  }
  statement {
    effect = "Allow"
    actions = [
      "elasticfilesystem:CreateFileSystem",
      "elasticfilesystem:CreateMountTarget",
    ]
    resources = [
      "arn:aws:ecs:${var.aws_region}:${data.aws_caller_identity.current.account_id}:file-system/${aws_efs_file_system.nexus_persist_storage.id}",
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
      "${aws_iam_role.nexus_repository_ecs_execute_role.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "nexus_repository_ecs_execution_policy" {
  name   = "${var.module_name}-ecs-execution_policy"
  role   = "${aws_iam_role.nexus_repository_ecs_execute_role.id}"
  policy = "${data.aws_iam_policy_document.nexus_repository_ecs_execution_policy_doc.json}"
}
