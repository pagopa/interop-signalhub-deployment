resource "aws_kinesis_stream" "this" {
  name            = var.datastream_stream_name
  encryption_type = "KMS"

  # The retention period is the length of time that data records are accessible after they are added to the stream. 
  # A stream’s retention period is set to a default of 24 hours after creation. 
  # You can increase the retention period up to 8760 hours (365 days)
  retention_period = var.datastream_stream_retention_period

  # shard count is managed dynamically since stream mode is ON DEMAND
  stream_mode_details {
    stream_mode = "ON_DEMAND"
  }

  tags = var.datastream_tags
}