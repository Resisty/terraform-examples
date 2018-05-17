data "template_file" "update_es_from_static_analysis_loggroupname" {
  template = "${var.module_name}-static-analysis-ecs-logs"
}

resource "aws_cloudwatch_log_group" "update_es_from_static_analysis_loggroup" {
  name = "${data.template_file.update_es_from_static_analysis_loggroupname.rendered}"
  tags {
    Application = "StaticAnalysis"
  }
}
