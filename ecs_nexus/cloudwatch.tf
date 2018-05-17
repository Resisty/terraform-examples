data "template_file" "nexus_repository_loggroupname" {
  template = "${var.module_name}-nexus-repository-logs"
}

resource "aws_cloudwatch_log_group" "nexus_repository_loggroup" {
  name = "${data.template_file.nexus_repository_loggroupname.rendered}"
  tags {
    Application = "NexusRepository"
  }
}

