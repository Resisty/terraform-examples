data "archive_file" "logs_es_cleanup_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambdas/escleanup"
  output_path = "escleanup.zip"
}

resource "aws_lambda_function" "logs_es_cleanup_lambda" {
  filename         = "escleanup.zip"
  source_code_hash = "${data.archive_file.logs_es_cleanup_zip.output_base64sha256}"
  function_name    = "logs_es_cleanup"
  role             = "${aws_iam_role.escleanup_lambda_exec_role.arn}"
  description      = "Lambda function to clean up older indices from ORGANIZATION Logs' ElasticSearch domain"
  handler          = "es_cleanup.lambda_handler"
  runtime          = "python2.7"
  timeout          = 300
  environment {
    variables {
      es_endpoint  = "${var.es_endpoint}"
      index        = "all"
      delete_after = "14"
    }
  }
}
