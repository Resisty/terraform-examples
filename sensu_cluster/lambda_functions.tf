resource "null_resource" "pip_zip_ansible_kick" {
  triggers {
    requirements_hash = "${base64sha256(file("${path.module}/lambdas/ansible_kick/requirements.txt"))}"
    buildscript_hash  = "${base64sha256(file("${path.module}/lambdas/ansible_kick/build_and_zip.sh"))}"
    pyscript_hash     = "${base64sha256(file("${path.module}/lambdas/ansible_kick/ansible_kick.py"))}"
  }
  provisioner "local-exec" {
    command = "docker run --rm -v $PWD:/build ubuntu /build/build_and_zip.sh"
    working_dir = "${path.module}/lambdas/ansible_kick"
  }
}

resource "aws_lambda_function" "ansible_kick_lambda_notifier" {
  filename         = "${path.module}/lambdas/ansible_kick/ansible_kick.zip"
  source_code_hash = "${md5(file("${path.module}/lambdas/ansible_kick/ansible_kick.zip"))}"
  function_name    = "ansible_kick_lambda_notifier"
  role             = "${aws_iam_role.sensu_cluster_instance_role.arn}"
  description      = "Lambda function to force EC2 instances to run ansible again when play is uploaded to S3."
  handler          = "ansible_kick.lambda_handler"
  runtime          = "python3.6"
  timeout          = 300
  memory_size      = 256
  environment {
    variables {
      ASG_NAME    = "${aws_autoscaling_group.sensu_cluster_asg.name}"
      REGION      = "${var.aws_region}"
      S3_OBJ_NAME = "${aws_s3_bucket_object.sensu_cluster_ansible_zip_object.id}"
    }
  }
  vpc_config {
    subnet_ids         = ["${aws_subnet.sensu_cluster_subnets.*.id}"]
    security_group_ids = ["${aws_security_group.sensu_cluster_instance_sg.id}"] 
  }
  depends_on  = ["null_resource.pip_zip_ansible_kick"]
}
