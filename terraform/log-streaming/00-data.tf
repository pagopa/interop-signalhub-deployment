# SNS Target topic for Kinesis and Firehose alerts
data "aws_sns_topic" "this" {
  name = var.sns_topic_name
}

data "aws_cloudwatch_log_group" "source" {
  name = var.cloudwatch_source_log_group_name
}