variable "env" {
  type        = string
  description = "Environment name"
}

variable "module_resource_prefix" {
  type        = string
  description = "Prefix for the module resources"
}

# Metrics and alarms configuration
variable "sns_topic_name" {
  description = "Value of the sns topic name used to deliver the alarms"
  type        = string
}

# Cloudwatch source log group configuration for AWS Kinesis Data Stream
variable "cloudwatch_source_log_group_name" {
  description = "Cloudwatch source log group name"
  type        = string
}

# Cloudwatch log group configuration for AWS Data Firehose 

variable "firehose_cloudwatch_log_stream_name" {
  description = "Firehose Cloudwatch log stream name"
  type        = string
}

variable "firehose_cloudwatch_log_group_retention_in_days" {
  description = "Firehose Cloudwatch log group logs retention in days"
  type        = number
  default     = 14
}

# AWS Kinesis Data Stream configuration
variable "datastream_stream_name" {
  type        = string
  description = "AWS Kinesis Data stream name"
}

variable "datastream_stream_retention_period" {
  type        = string
  description = "AWS Kinesis Data stream data retention period"
  default     = 720
}

variable "datastream_tags" {
  type        = map(string)
  description = "AWS Kinesis Data stream tags"
  default     = {}
}

# AWS Kinesis Data Stream monitoring configuration

variable "data_stream_cw_iterator_age_millis" {
  type        = number
  description = "Kinesis Data Stream Cloudwatch iterator age in milliseconds"
  default     = 30000
}

variable "data_stream_write_provisioned_throughput_threshold_percentage" {
  type        = number
  description = "Kinesis Data Stream write provisioned throughput exceeded threshold percentage"
  default     = 0.3
}

variable "data_stream_read_provisioned_throughput_threshold_percentage" {
  type        = number
  description = "Kinesis Data Stream read provisioned throughput exceeded threshold percentage"
  default     = 0.3

}

variable "data_stream_getrecord_bytes_threshold_percentage" {
  type        = number
  description = "Kinesis Data Stream get record bytes exceeded threshold percentage"
  default     = 0.3
}

# AWS Data Firehose configuration
variable "firehose_stream_name" {
  type        = string
  description = "AWS Data Firehose stream name"
  default     = "terraform-kinesis-firehose-extended-s3-test-stream"
}

variable "firehose_buffering_size_mb" {
  type        = number
  description = "AWS Data Firehose stream buffering size in MB"
  default     = 5
}

variable "firehose_buffering_interval_seconds" {
  type        = number
  description = "AWS Data Firehose stream buffering interval in seconds"
  default     = 300
}

variable "firehose_stream_tags" {
  type        = map(string)
  description = "AWS Data Firehose stream tags"
  default     = {}
}


# AWS Data Firehose monitoring configuration
variable "firehose_active_partition_count_threshold" {
  description = "Firehose active partition count threshold"
  type        = number
  default     = 0.7
}
variable "firehose_active_partition_count_percentage_threshold" {
  description = "Firehose active partition count percentage threshold"
  type        = number
  default     = 400
}
variable "firehose_active_data_freshness_threshold_seconds" {
  description = "Firehose active data freshness threshold, based on buffering interval"
  type        = number
  default     = 300
}
variable "firehose_incoming_bytes_bytespersecondlimit_threshold_percentage" {
  description = "Firehose incoming bytes bytes per second limit threshold"
  type        = number
  default     = 30
}

variable "firehose_throttled_records_threshold" {
  description = "Firehose throttled records threshold"
  type        = number
  default     = 10
}
variable "firehose_throttled_describe_stream_threshold" {
  description = "Firehose throttled describe stream threshold"
  type        = number
  default     = 1
}

variable "firehose_throttled_get_records_threshold" {
  description = "Firehose throttled get records threshold"
  type        = number
  default     = 1
}

variable "firehose_throttled_get_shard_iterator_threshold" {
  description = "Firehose throttled get shard iterator threshold"
  type        = number
  default     = 1
}

# AWS S3 target bucket configuration
variable "s3_bucket_name" {
  type        = string
  description = "AWS target S3 bucket name"
}

variable "s3_bucket_tags" {
  type        = map(string)
  description = "AWS target S3 bucket tags"
  default     = {}
}

