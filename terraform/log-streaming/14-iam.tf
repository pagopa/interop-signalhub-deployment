# Cloudwatch source log group IAM resources
data "aws_iam_policy_document" "cloudwatch_to_kinesis" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logs.${data.aws_region.current}.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "cloudwatch_to_kinesis" {
  name               = format("%s_cloudwatch_to_kinesis_role_%s", var.module_resource_prefix, var.env)
  assume_role_policy = data.aws_iam_policy_document.cloudwatch_to_kinesis.json
}


resource "aws_iam_policy" "cloudwatch_to_kinesis" {

  depends_on = [aws_kinesis_stream.this]

  name        = format("%s_cloudwatch_to_kinesis_policy_%s", var.module_resource_prefix, var.env)
  description = "Allows CloudWatch Logs to send data to Kinesis Data Stream"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kinesis:PutRecord",
          "kinesis:PutRecords"
        ]
        Resource = aws_kinesis_stream.this.arn
      },
      {
        Effect = "Allow"
        Action = "logs:PutSubscriptionFilter"
        Resource = [
          "arn:aws:logs:${data.aws_region.current}:${data.aws_caller_identity.current.account_id}:log-group:*",
          aws_kinesis_stream.this.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cloudwatch_to_kinesis" {
  role       = aws_iam_role.cloudwatch_to_kinesis.name
  policy_arn = aws_iam_policy.cloudwatch_to_kinesis.arn
}


# Firehose IAM resources
data "aws_iam_policy_document" "firehose_assume_role" {
  version = "2012-10-17"
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["firehose.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "firehose_role" {
  name               = format("%s_log_stream_firehose_role_%s", var.module_resource_prefix, var.env)
  assume_role_policy = data.aws_iam_policy_document.firehose_assume_role.json
}

resource "aws_iam_policy" "firehose_policy" {
  name        = format("%s_log_stream_firehose_policy_%s", var.module_resource_prefix, var.env)
  description = "Policy to allow Firehose to read from Kinesis Data Stream and write to S3 bucket"

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Action = [
          "kinesis:DescribeStream",
          "kinesis:GetShardIterator",
          "kinesis:GetRecords",
          "kinesis:ListShards"
        ],
        Resource = aws_kinesis_stream.this.arn
      },
      {
        Effect = "Allow",
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ],
        Resource = [
          module.log_streaming_bucket.s3_bucket_arn,
          format("%s/*", module.log_streaming_bucket.s3_bucket_arn)
        ]
      },
      {
        Effect = "Allow",
        Action = [
          "logs:PutLogEvents"
        ],
        Resource = [
          format("%s:log-stream:*", aws_cloudwatch_log_group.firehose.arn)
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "firehose_policy_attach" {
  role       = aws_iam_role.firehose_role.name
  policy_arn = aws_iam_policy.firehose_policy.arn
}
