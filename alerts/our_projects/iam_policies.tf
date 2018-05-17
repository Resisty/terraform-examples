data "aws_iam_policy_document" "kinesis-analytics-execution-policy-doc" {
  count = "${var.create_alerts}"
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords"
    ]
    resources = [
      "${aws_kinesis_stream.input.arn}",
      "${aws_kinesis_stream.input.arn}/*",
    ]
  }
  statement {
    effect = "Allow",
    actions = [
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
      "kinesis:PutRecord",
      "kinesis:PutRecords"
    ]
    resources = [
      "${aws_kinesis_stream.analytics-stream-output.arn}",
      "${aws_kinesis_stream.analytics-stream-output.arn}/*",
    ]
  }
}

resource "aws_iam_role_policy" "kinesis_analytics_execution_policy" {
  count = "${var.create_alerts}"
  name = "kinesis_analytics_execution_policy" 
  role = "${aws_iam_role.kinesis_analytics_role.id}"
  policy = "${data.aws_iam_policy_document.kinesis-analytics-execution-policy-doc.json}"
}

data "aws_iam_policy_document" "lambda-analytics-execution-policy-doc" {
  count = "${var.create_alerts}"
  statement {
    effect = "Allow"
    actions = [
      "kinesis:DescribeStream",
      "kinesis:ListStreams",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords"
    ]
    resources = [
      "${aws_kinesis_stream.analytics-stream-output.arn}",
      "${aws_kinesis_stream.analytics-stream-output.arn}/*",
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
      "ses:SendEmail",
      "ses:SendRawEmail"
    ]
    resources = [
      "*",
    ]
  }
}

resource "aws_iam_role_policy" "lambda_analytics_execution_policy" {
  count = "${var.create_alerts}"
  name = "lambda_analytics_execution_policy" 
  role = "${aws_iam_role.lambda_analytics_role.id}"
  policy = "${data.aws_iam_policy_document.lambda-analytics-execution-policy-doc.json}"
}

data "aws_iam_policy_document" "kinesis-to-kfh-execution-policy-doc" {
  statement {
    effect = "Allow"
    actions = [
      "s3:AbortMultipartUpload",
      "s3:GetBucketLocation",
      "s3:GetObject",
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads",
      "s3:PutObject",
    ]
    resources = [
      "${aws_s3_bucket.kinesis_firehose.arn}",
      "${aws_s3_bucket.kinesis_firehose.arn}/*",
    ]
  }
  statement {
    effect = "Allow",
    actions = [
      "lambda:InvokeFunction",
      "lambda:GetFunctionConfiguration"
    ]
    resources = [
      "arn:aws:lambda:::function:%FIREHOSE_DEFAULT_FUNCTION%:%FIREHOSE_DEFAULT_VERSION%",
    ]
  }
  statement {
    effect = "Allow",
    actions = [
      "es:DescribeElasticsearchDomain",
      "es:DescribeElasticsearchDomains",
      "es:DescribeElasticsearchDomainConfig",
      "es:ESHttpPost",
      "es:ESHttpPut",
      "es:ESHttpGet",
    ]
    resources = [
      "${var.es_domain_arn}",
      "${var.es_domain_arn}/*",
    ]
  }
  statement {
    effect = "Allow",
    actions = [
      "logs:PutLogEvents",
    ]
    resources = [
      "${aws_cloudwatch_log_stream.kinesis_firehose_logstream.arn}",
    ]
  }
  statement {
    effect = "Allow",
    actions = [
      "kinesis:DescribeStream",
      "kinesis:GetShardIterator",
      "kinesis:GetRecords",
    ]
    resources = [
      "${aws_kinesis_stream.input.arn}",
    ]
  }
}

resource "aws_iam_role_policy" "kinesis_to_kfh_execution_policy" {
  name = "${var.module_name}_kinesis_to_kfh_execution_policy" 
  role = "${aws_iam_role.kinesis_to_kfh_execution_role.id}"
  policy = "${data.aws_iam_policy_document.kinesis-to-kfh-execution-policy-doc.json}"
}
