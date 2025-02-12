resource "aws_kinesis_firehose_delivery_stream" "this" {

  depends_on = [
    aws_kinesis_stream.this,
    module.log_streaming_bucket,
    aws_cloudwatch_log_group.this,
    aws_cloudwatch_log_stream.this
  ]

  name        = var.firehose_stream_name
  tags        = var.firehose_stream_tags
  destination = "extended_s3"

  server_side_encryption {
    enabled = true
  }
  extended_s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = module.log_streaming_bucket.s3_bucket_arn

    buffering_size     = var.firehose_buffering_size_mb
    buffering_interval = var.firehose_buffering_interval_seconds
    compression_format = "GZIP"
    custom_time_zone   = "UTC"

    prefix              = "firehose-output/namespace=!{partitionKeyFromQuery:namespace}/app=!{partitionKeyFromQuery:app}/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/"
    error_output_prefix = "firehose-errors/year=!{timestamp:yyyy}/month=!{timestamp:MM}/day=!{timestamp:dd}/hour=!{timestamp:HH}/!{firehose:error-output-type}/"

    # s3 backup mode - NO
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.firehose.name
      log_stream_name = aws_cloudwatch_log_stream.firehose.name
    }

    dynamic_partitioning_configuration {
      enabled        = "true"
      retry_duration = 300
    }

    processing_configuration {
      enabled = "true"

      processors {
        type = "Decompression"
        parameters {
          parameter_name  = "CompressionFormat"
          parameter_value = "GZIP"
        }
      }

      processors {
        type = "RecordDeAggregation"
        parameters {
          parameter_name  = "SubRecordType"
          parameter_value = "JSON"
        }
      }

      processors {
        type = "CloudWatchLogProcessing"
        parameters {
          parameter_name  = "DataMessageExtraction"
          parameter_value = "true"
        }
      }

      processors {
        type = "AppendDelimiterToRecord"
      }

      # JQ processor example
      processors {
        type = "MetadataExtraction"
        parameters {
          parameter_name  = "JsonParsingEngine"
          parameter_value = "JQ-1.6"
        }
        parameters {
          parameter_name  = "MetadataExtractionQuery"
          parameter_value = "{namespace:.pod_namespace,app:.pod_app}"
        }
      }
    }
  }
}