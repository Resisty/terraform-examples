data "archive_file" "static_analysis_s3_to_sqs_ecs_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/sqs_notify"
  output_path = "static_analysis_s3_to_sqs_ecs.zip"
}

resource "aws_lambda_function" "static_analysis_s3_to_sqs_ecs_lambda" {
  filename    = "static_analysis_s3_to_sqs_ecs.zip"
  source_code_hash = "${data.archive_file.static_analysis_s3_to_sqs_ecs_zip.output_base64sha256}"
  function_name    = "${var.module_name}_static_analysis_s3_to_sqs_ecs"
  role             = "${aws_iam_role.static_analysis_s3_to_sqs_ecs_execute_role.arn}"
  description      = "Lambda function to notify SQS and ECS when static analysis results are available."
  handler          = "s3_to_sqs.lambda_handler"
  runtime          = "python3.6"
  timeout          = 300
  memory_size      = 256
  environment {
    variables {
      SQS_QUEUE               = "${aws_sqs_queue.static_analysis_queue.id}"
      ECS_TASK                = "${aws_ecs_task_definition.update_es_from_static_analysis.family}"
      ECS_CLUSTER             = "${aws_ecs_cluster.update_es_from_static_analysis_cluster.name}"
      S3_KEY_SUFFIX_WHITELIST = ".tar.gz"
    }
  }
}
