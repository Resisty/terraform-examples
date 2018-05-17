resource "aws_ecr_repository" "static_analysis_updater" {
  name = "${var.module_name}_static_analysis_updater"
}

resource "dockerimage_local" "static_analysis_updater" {
  dockerfile_path = "${path.module}/static_analysis_updater"
  tag             = "${aws_ecr_repository.static_analysis_updater.name}:${var.static_analysis_updater_tag}"
}

resource "dockerimage_remote" "static_analysis_updater" {
  tag      = "${aws_ecr_repository.static_analysis_updater.name}:${var.static_analysis_updater_tag}"
  registry = "${aws_ecr_repository.static_analysis_updater.registry_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  image_id = "${dockerimage_local.static_analysis_updater.id}"
}
