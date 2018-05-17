data "aws_iam_policy_document" "logs_pusher_policy_doc" {
  statement {
    actions = [
      "kinesis:AddTagsToStream",
      "kinesis:CreateStream",
      "kinesis:DescribeStream",
      "kinesis:EnableEnhancedMonitoring",
      "kinesis:Get*",
      "kinesis:List*",
      "kinesis:MergeShards",
      "kinesis:Put*",
      "kinesis:SplitShard",
      "kinesis:UpdateShardCount"
    ]
    effect = "Allow"
    resources = [
      "arn:aws:kinesis:${var.aws_region}:${data.aws_caller_identity.current.account_id}:stream/*",
    ]
  }
}
resource "aws_iam_user_policy" "logs_pusher_policy" {
  name = "logs-pusher-policy"
  user = "${aws_iam_user.logs-pusher.name}"
  policy = "${data.aws_iam_policy_document.logs_pusher_policy_doc.json}"
}

data "aws_iam_policy_document" "docker_rw_policy_doc" {
  statement {
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadurlForLayer",
      "ecr:GetRepositoryPolicy",
      "ecr:DescribeRepositories",
      "ecr:ListImages",
      "ecr:DescribeImages",
      "ecr:BatchGetImage",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:ecr:${var.aws_region}:${data.aws_caller_identity.current.account_id}:repository/*",
    ]
  }
  statement {
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:CreateRepository",
      "ecr:DescribeRepositories",
    ]
    effect = "Allow"
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_user_policy" "docker_rw_policy" {
  name = "docker-rw-policy"
  user = "${aws_iam_user.docker-rw.name}"
  policy = "${data.aws_iam_policy_document.docker_rw_policy_doc.json}"
}
