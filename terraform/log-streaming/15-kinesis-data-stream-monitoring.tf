
# AWS Kinesis Data Stream Alarms - https://docs.aws.amazon.com/streams/latest/dev/monitoring-with-cloudwatch.html
# AWS Kinesis Data Stream Quotas & Limits - https://docs.aws.amazon.com/streams/latest/dev/service-sizes-and-limits.html


locals {
  kinesis_data_stream_write_quota = 200000000 # 200 MB/s
  kinesis_data_stream_read_quota  = 400000000 # 400 MB/s
  kinesis_get_records_bytes_quota = 10000000  # 10 MB
}

# WriteProvisionedThroughputExceeded - Number of records rejected due to exceeding provisioned throughput
resource "aws_cloudwatch_metric_alarm" "kinesis_write_provision_exceeded" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-writeprovisionedthroughputexceeded-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "WriteProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = format("%s - Kinesis Data Stream Write Provisioning exceeded", aws_kinesis_stream.this.name)
  alarm_actions       = [data.aws_sns_topic.this.arn]
  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# ReadProvisionedThroughputExceeded - Number of records rejected due to exceeding provisioned throughput
resource "aws_cloudwatch_metric_alarm" "kinesis_write_provision_exceeded" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-readprovisionedthroughputexceeded-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ReadProvisionedThroughputExceeded"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = 1

  alarm_description = format("%s - Kinesis Data Stream Read Provisioning exceeded", aws_kinesis_stream.this.name)
  alarm_actions     = [data.aws_sns_topic.this.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# IteratorAgeMilliseconds - Age of the last record retrieved from the stream (latency indicator)
# Age is the difference between the current time and when the last record of the GetRecords call was written to the stream.
resource "aws_cloudwatch_metric_alarm" "kinesis_iterator_age" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-iteratorageexceeded-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.IteratorAgeMilliseconds"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Average"
  threshold           = var.data_stream_cw_iterator_age_millis # should be defined according to data stream consumer reading capacity

  alarm_description = format("%s - Kinesis consumer is lagging behind in data processing", aws_kinesis_stream.this.name)
  alarm_actions     = [data.aws_sns_topic.this.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}

# IncomingBytes - Monitor write throughput
# data streams with the on-demand capacity mode scale up to 200 MB/s of write and 400 MB/s read throughput (not all Regions).
resource "aws_cloudwatch_metric_alarm" "kinesis_incoming_bytes" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-kinesisincomingbyteshigh-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "IncomingBytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = local.kinesis_data_stream_write_quota * var.data_stream_write_provisioned_throughput_threshold_percentage # Warning before 200 MB/s limit - Threshold (30%)

  alarm_description = format("%s - Triggers when incoming data rate approaches quota", aws_kinesis_stream.this.name)
  alarm_actions     = [aws_sns_topic.this.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}


# OutgoingBytes - Monitor read throughput
# data streams with the on-demand capacity mode scale up to 200 MB/s of write and 400 MB/s read throughput (not all Regions).
resource "aws_cloudwatch_metric_alarm" "kinesis_outgoing_bytes" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-kinesisoutgoingbyteshigh-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "OutgoingBytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = local.kinesis_data_stream_read_quota * var.data_stream_read_provisioned_throughput_threshold_percentage # Warning before 400 MB/s limit (30%)

  alarm_description = format("%s - Triggers when outgoing data rate approaches quota", aws_kinesis_stream.this.name)
  alarm_actions     = [aws_sns_topic.this.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}


# GetRecords.Bytes - Monitor GetRecords Transaction Size
# GetRecords can retrieve up to 10 MB of data per call from a single shard, and up to 10,000 records per call. 
# Each call to GetRecords is counted as one read transaction. 
# Each shard can support up to five read transactions per second. 
# Each read transaction can provide up to 10,000 records with an upper quota of 10 MB per transaction.
resource "aws_cloudwatch_metric_alarm" "kinesis_get_records_bytes" {

  depends_on = [aws_kinesis_stream.this]

  alarm_name          = "datastream-${var.module_resource_prefix}-kinesisgetrecordsbyteshigh-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "GetRecords.Bytes"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Maximum"

  threshold         = local.kinesis_get_records_bytes_quota * var.data_stream_getrecord_bytes_threshold_percentage # Warning before 10 MB limit per call
  alarm_description = format("%s - Triggers when a single GetRecords call approaches size limit", aws_kinesis_stream.this.name)
  alarm_actions     = [aws_sns_topic.this.arn]

  dimensions = {
    StreamName = aws_kinesis_stream.this.name
  }
}
