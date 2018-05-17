locals {
  image = "sonatype/nexus3"
  container_name = "${var.module_name}-RunNexusRepository" 
}

resource "aws_ecs_cluster" "nexus_repository_cluster" {
  name = "${var.module_name}-cluster"
}

data "template_file" "nexus_repository_json_document" {
  template = "${file("${path.module}/templates/nexus_repository.json")}"
  vars {
    image                  = "${jsonencode(local.image)}"
    container_name         = "${jsonencode(local.container_name)}"
    aws_region             = "${jsonencode(var.aws_region)}"
    hostport               = "${var.nexus_hostport}"
    containerport          = "${var.nexus_containerport}"
    awslogs_group          = "${jsonencode(data.template_file.nexus_repository_loggroupname.rendered)}"
  }
}

resource "aws_ecs_task_definition" "nexus_repository" {
  family                = "${local.container_name}"
  container_definitions = "${data.template_file.nexus_repository_json_document.rendered}"
  task_role_arn         = "${aws_iam_role.nexus_repository_ecs_execute_role.arn}"
  execution_role_arn    = "${aws_iam_role.nexus_repository_ecs_execute_role.arn}"
  volume {
    name      = "efs"
    host_path = "${var.efs_nexus_storage}"
  }
}

resource "aws_ecs_service" "nexus_repository_service" {
  name            = "${var.module_name}-service"
  cluster         = "${aws_ecs_cluster.nexus_repository_cluster.id}"
  task_definition = "${aws_ecs_task_definition.nexus_repository.arn}"
  desired_count   = 1
  iam_role        = "${aws_iam_role.nexus_repository_ecs_execute_role.arn}"
  depends_on      = ["aws_iam_role_policy.nexus_repository_ecs_execution_policy"]
  load_balancer   = {
    target_group_arn = "${aws_lb_target_group.nexus_web.arn}"
    container_name   = "${local.container_name}"
    container_port   = "${var.nexus_containerport}"
  }
}
