# input
resource "aws_kinesis_stream" "input" {
  name                = "${var.module_name}"
  shard_count         = 10
  retention_period    = 48
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
  tags {
    Environment = "${var.module_name}"
  }
}

# output
resource "aws_kinesis_stream" "analytics-stream-output" {
  count               = "${var.create_alerts}"
  name                = "${var.module_name}-analytics-stream-output"
  shard_count         = 1
  retention_period    = 48
  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]
  tags {
    Environment = "${var.module_name}-analytics-stream-output"
  }
}
