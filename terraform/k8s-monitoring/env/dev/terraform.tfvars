aws_region = "eu-south-1"
env        = "dev"

tags = {
  CreatedBy   = "Terraform"
  Environment = "dev"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-signlahub-deployment"
}

eks_cluster_name = "signalhub-eks-cluster-dev"

sns_topic_name = "signalhub-platform-alarms-dev"

cloudwatch_log_group_name = "/aws/eks/signalhub-eks-cluster-dev/application"