# Source log group for AWS Kinesis Data Stream
resource "aws_cloudwatch_log_subscription_filter" "log_filter" {

  depends_on = [aws_kinesis_stream.this]

  name            = format("%s-%s-log-filter", var.module_resource_prefix, var.cloudwatch_source_log_group_name)
  log_group_name  = data.aws_cloudwatch_log_group.source.name
  filter_pattern  = ""
  distribution    = "ByLogStream"
  destination_arn = aws_kinesis_stream.this.arn
  role_arn        = aws_iam_role.cloudwatch_to_kinesis.arn
}

# Firehose log group for error logging
resource "aws_cloudwatch_log_group" "firehose" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  name              = format("/aws/kinesisfirehose/%s", var.firehose_stream_name)
  retention_in_days = var.firehose_cloudwatch_log_group_retention_in_days
}

resource "aws_cloudwatch_log_stream" "firehose" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  name           = var.firehose_cloudwatch_log_stream_name
  log_group_name = aws_cloudwatch_log_group.firehose.name
}
