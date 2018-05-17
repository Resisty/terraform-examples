data "template_file" "kms_filters_py" {
  template = "${file("${path.module}/templates/filter_plugins/kms_filters.py.tpl")}"
  vars {
    region_name = "${var.aws_region}"
  }
}

resource "local_file" "kms_filters_py" {
  content  = "${data.template_file.kms_filters_py.rendered}"
  filename = "${path.module}/files/sensu_ansible/filter_plugins/kms_filters.py"
}

data "template_file" "nexus_http_check_sh" {
  template = "${file("${path.module}/templates/sensu_ansible/data/static/sensu/checks/sensu_masters/nexus-http-check.sh.tpl")}"
  vars {
    nexus_tag_name  = "${var.nexus_tag_name}"
    nexus_tag_value = "${var.nexus_tag_value}"
  }
}

resource "local_file" "nexus_http_check_sh" {
  content  = "${data.template_file.nexus_http_check_sh.rendered}"
  filename = "${path.module}/files/sensu_ansible/data/static/sensu/checks/sensu_masters/nexus-http-check.sh"
}


resource "aws_s3_bucket" "sensu_cluster_bucket" {
  bucket = "${var.module_name}-sensu-tarball"
  region = "${var.aws_region}"
  acl    = "private"
  versioning { 
    enabled = true
  }
}

resource "null_resource" "sensu_cluster_ansible_zip" {
  triggers {
    update_always = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = "zip -r ../../${var.ansible_bucket_object_key} *"
    working_dir = "${path.module}/files/sensu_ansible"
  }
  depends_on = ["local_file.kms_filters_py", "local_file.nexus_http_check_sh"]
}

resource "aws_s3_bucket_object" "sensu_cluster_ansible_zip_object" {
  bucket     = "${aws_s3_bucket.sensu_cluster_bucket.id}"
  key        = "${var.ansible_bucket_object_key}"
  source     = "${path.module}/${var.ansible_bucket_object_key}"
  depends_on = ["null_resource.sensu_cluster_ansible_zip"]
  etag       = "${md5(timestamp())}"
}

resource "null_resource" "rm_sensu_cluster_ansible_zip" {
  triggers {
    update_always = "${timestamp()}"
  }
  provisioner "local-exec" {
    command     = "rm ${path.module}/${var.ansible_bucket_object_key} || true"
  }
  depends_on = ["aws_s3_bucket_object.sensu_cluster_ansible_zip_object"]
}

resource "aws_s3_bucket_notification" "ansible_kick_reception_notifier" {
  bucket = "${aws_s3_bucket.sensu_cluster_bucket.id}"

  lambda_function {
    lambda_function_arn = "${aws_lambda_function.ansible_kick_lambda_notifier.arn}"
    events              = ["s3:ObjectCreated:*"]
    filter_suffix       = ".zip"
  }
}
