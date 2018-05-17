data "aws_iam_policy_document" "static_analysis_pusher_policy_doc" {
  statement {
    actions = [
      "s3:ListAllMyBuckets",
    ]
    effect = "Allow"
    resources = [
      "arn:aws:s3:::*",
    ]
  }
  statement {
    actions = [
      "s3:PutObject",
      "s3:PutObjectAcl",
      "s3api:CreateMultipartUpload",
    ]
    effect = "Allow"
    resources = [
      "${aws_s3_bucket.static_analysis_reception.arn}",
      "${aws_s3_bucket.static_analysis_reception.arn}/*",
    ]
  }
}
resource "aws_iam_user_policy" "static_analysis_pusher_policy" {
  name = "static-analysis-pusher-policy"
  user = "${aws_iam_user.static-analysis-pusher.name}"
  policy = "${data.aws_iam_policy_document.static_analysis_pusher_policy_doc.json}"
}
