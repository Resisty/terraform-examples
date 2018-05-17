resource "aws_iam_user" "logs-pusher" {
  name = "logs-pusher"
}

resource "aws_iam_user" "docker-rw" {
  name = "docker-rw"
}
