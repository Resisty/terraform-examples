resource "aws_kinesis_firehose_delivery_stream" "stream_to_kfh" {
  name        = "${var.module_name}_stream_to_kfh"
  destination = "elasticsearch"

  kinesis_source_configuration { 
    role_arn = "${aws_iam_role.kinesis_to_kfh_execution_role.arn}"
    kinesis_stream_arn = "${aws_kinesis_stream.input.arn}"
  }

  s3_configuration {
    role_arn           = "${aws_iam_role.kinesis_to_kfh_execution_role.arn}"
    bucket_arn         = "${aws_s3_bucket.kinesis_firehose.arn}"
    buffer_size        = 10
    buffer_interval    = 400
    compression_format = "GZIP"
  }

  elasticsearch_configuration {
    domain_arn     = "${var.es_domain_arn}"
    role_arn       = "${aws_iam_role.kinesis_to_kfh_execution_role.arn}"
    index_name     = "${var.module_name}"
    type_name      = "${var.module_name}"
    s3_backup_mode = "AllDocuments"
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = "${aws_cloudwatch_log_group.kinesis_firehose_loggroup.name}"
      log_stream_name = "${aws_cloudwatch_log_stream.kinesis_firehose_logstream.name}"
    }
  }
}
