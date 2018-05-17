resource "aws_ecs_cluster" "update_es_from_static_analysis_cluster" {
  name = "${var.module_name}-update_es_from_static_analysis_cluster"
}

locals {
  full_image_string = "${aws_ecr_repository.static_analysis_updater.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com/${aws_ecr_repository.static_analysis_updater.name}:${var.static_analysis_updater_tag}"
}

data "template_file" "update_es_from_static_analysis_json_document" {
  template = "${file("${path.module}/templates/update_es_from_static_analysis.json")}"
  vars {
    image                  = "${jsonencode(local.full_image_string)}"
    aws_region             = "${jsonencode(var.aws_region)}"
    report_pat             = "${jsonencode(var.report_pattern)}"
    cppcheck_pat           = "${jsonencode(var.cppcheck_pattern)}"
    email_pat              = "${jsonencode(var.email_pattern)}"
    slack_pat              = "${jsonencode(var.slack_pattern)}"
    slack_team             = "${jsonencode(var.slack_team)}"
    slack_bot              = "${jsonencode(var.slack_bot)}"
    slack_token            = "${jsonencode(var.slack_token)}"
    es_endpoint            = "${jsonencode(var.es_endpoint)}"
    chunk_size             = "${jsonencode(var.chunk_size)}"
    ses_registered_address = "${jsonencode(var.ses_registered_address)}"
    sqs_queue              = "${jsonencode(aws_sqs_queue.static_analysis_queue.id)}"
    awslogs_group          = "${jsonencode(data.template_file.update_es_from_static_analysis_loggroupname.rendered)}"
  }
}

resource "aws_ecs_task_definition" "update_es_from_static_analysis" {
  family                = "UpdateElasticSearchFromTarball"
  container_definitions = "${data.template_file.update_es_from_static_analysis_json_document.rendered}"
  task_role_arn         = "${aws_iam_role.static_analysis_s3_to_sqs_ecs_execute_role.arn}"
  execution_role_arn    = "${aws_iam_role.static_analysis_s3_to_sqs_ecs_execute_role.arn}"
}
