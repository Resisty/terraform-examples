resource "aws_elasticsearch_domain" "es" {
  domain_name           = "${var.elasticsearch_domain_name}"
  elasticsearch_version = "${var.elasticsearch_version}"
  cluster_config {
    instance_type = "${var.elasticsearch_instance_type}"
    instance_count = "${var.elasticsearch_instance_count}"
  }
  ebs_options {
    ebs_enabled = true
    volume_type = "${var.elasticsearch_ebs_type}"
    volume_size = "${var.elasticsearch_ebs_size}"
  }

  advanced_options {
    "rest.action.multi.allow_explicit_index" = "true"
  }

  snapshot_options {
    automated_snapshot_start_hour = 23
  }

  tags {
    Domain = "${var.elasticsearch_domain_name}"
  }
}
