aws_region = "eu-south-1"
env        = "prod"

tags = {
  CreatedBy   = "Terraform"
  Environment = "prod"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-signalhub-deployment"
}

eks_cluster_name = "signalhub-eks-cluster-prod"

sns_topic_name = "signalhub-platform-alarms-prod"

cloudwatch_log_group_name = "/aws/eks/signalhub-eks-cluster-prod/application"
