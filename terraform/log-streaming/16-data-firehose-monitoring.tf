# AWS Data Firehose Monitoring best practices - https://docs.aws.amazon.com/firehose/latest/dev/firehose-cloudwatch-metrics-best-practices.html
# AWS Data Firehose Cloudwatch Metrics - https://docs.aws.amazon.com/ru_ru/firehose/latest/dev/monitoring-with-cloudwatch-metrics.html
# AWS Data Firehose Quota & Limits - https://docs.aws.amazon.com/firehose/latest/dev/limits.html

# Actions involved:
# - Kinesis Data Stream receive data: kinesis:PutRecord, kinesis:PutRecords
# - Firehose attaches to Kinesis Data Stream: kinesis:DescribeStream, firehose:CreateDeliveryStream
# - Firehose Reads from Kinesis: kinesis:GetShardIterator, kinesis:GetRecords
# - Firehose delivers data to S3: firehose:PutRecord, firehose:PutRecordBatch
locals {

  # When dynamic partitioning on a Firehose stream is enabled, there is a default quota of 500 active partitions that can be created for that Firehose stream. 
  # The active partition count is the total number of active partitions within the delivery buffer.
  # Is it possible to request an increase of this quota up to 5000 active partitions per given Firehose stream
  firehose_active_partitions_limit              = 500
  firehose_bytes_per_second_per_partition_limit = 1073741824 # 1GB/s = 1,073,741,824 Bytes/s
}

# Monitor active partitions - limit 500
resource "aws_cloudwatch_metric_alarm" "firehose_partition_count" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-partitioncount-high-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 2
  metric_name         = "PartitionCount"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Maximum"
  threshold           = local.firehose_active_partitions_limit * var.firehose_active_partition_count_threshold
  alarm_description   = format("%s - Active partitions count is approaching the AWS quota (threshold)", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}
# Monitor PartitionCountExceeded metric, it indicates if you are exceeding the partition count limit.
# It emits 1 or 0 based on whether limit is breached or not.
resource "aws_cloudwatch_metric_alarm" "firehose_partition_count" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-partitioncount-exceeded-${var.env}"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "PartitionCountExceeded"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = format("%s - Active partitions count is exceeding the AWS quota", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

resource "aws_cloudwatch_metric_alarm" "firehose_partition_count_percentage" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-partitioncount-percentage-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = var.firehose_active_partition_count_percentage_threshold

  datapoints_to_alarm = 1
  alarm_description   = format("%s - Active partitions count approaching the AWS quota (%)", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [data.aws_sns_topic.this.arn]

  metric_query {
    id          = "partitioncountpercentage1"
    return_data = false

    metric {
      metric_name = "PartitionCount"
      namespace   = "AWS/Firehose"
      stat        = "Sum"
      period      = 60
    }
  }

  metric_query {
    id          = "partitioncountpercentage2"
    expression  = "(partitioncountpercentage1 / 60) / ${local.firehose_active_partitions_limit} * 100"
    label       = "PartitionCountPercentage"
    return_data = true
  }

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# DeliveryToS3.DataFreshness - Time taken to deliver data to S3 (track data freshness)
resource "aws_cloudwatch_metric_alarm" "firehose_data_freshness" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-datafreshness-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "DeliveryToS3.DataFreshness"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Average"
  threshold           = var.firehose_buffering_interval_seconds + 60

  datapoints_to_alarm = 1
  alarm_description   = format("%s - Firehose Data is getting delayed in delivery to S3", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [data.aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# Alarm for Firehose Throughput Exceeding 1 GB/s per Partition
resource "aws_cloudwatch_metric_alarm" "firehose_throughput_alarm" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-throughput-high-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  threshold           = local.firehose_bytes_per_second_per_partition_limit

  datapoints_to_alarm = 1
  alarm_description   = format("%s -  Firehose throughput is exceeding %s b/s per partition throughput limit", aws_kinesis_firehose_delivery_stream.this.name, local.firehose_bytes_per_second_per_partition_limit)
  alarm_actions       = [data.aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledRecords 
# The number of records that were throttled because data ingestion exceeded one of the Firehose stream limits.
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_records" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-records-throttled-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledRecords"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = var.firehose_throttled_records_threshold

  datapoints_to_alarm = 1
  alarm_description   = format("%s - High volume of throttled records", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [data.aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledDescribeStream 
# The total number of times the DescribeStream operation is throttled when the data source is a Kinesis data stream.
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_describe_stream" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-describestream-throttled-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledDescribeStream"
  namespace           = "AWS/Firehose"
  period              = 60
  statistic           = "Sum"
  threshold           = var.firehose_throttled_describe_stream_threshold

  datapoints_to_alarm = 1
  alarm_description   = format("%s - Describe stream API calls are throttled", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [data.aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledGetRecords
# The total number of times the GetRecords operation is throttled when the data source is a Kinesis data stream
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_get_records" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-getrecords-throttled-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledGetRecords"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = var.firehose_throttled_get_records_threshold

  datapoints_to_alarm = 1
  alarm_description   = format("%s - GetRecords API calls are throttled", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}

# ThrottledGetShardIterator
# The total number of times the GetShardIterator operation is throttled when the data source is a Kinesis data stream.
resource "aws_cloudwatch_metric_alarm" "firehose_throttled_get_shard_iterator" {

  depends_on = [aws_kinesis_firehose_delivery_stream.this]

  alarm_name          = "firehose-${var.module_resource_prefix}-getsharditerator-throttled-${var.env}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 1
  metric_name         = "ThrottledGetShardIterator"
  namespace           = "AWS/Kinesis"
  period              = 60
  statistic           = "Sum"
  threshold           = var.firehose_throttled_get_shard_iterator_threshold

  datapoints_to_alarm = 1
  alarm_description   = format("%s - GetShardIterator API calls are throttled", aws_kinesis_firehose_delivery_stream.this.name)
  alarm_actions       = [aws_sns_topic.this.arn]

  dimensions = {
    DeliveryStreamName = aws_kinesis_firehose_delivery_stream.this.name
  }
}
