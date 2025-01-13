aws_region = "eu-south-1"
env        = "att"

tags = {
  CreatedBy   = "Terraform"
  Environment = "att"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-signalhub-deployment"
}

eks_cluster_name = "signalhub-eks-cluster-att"

sns_topic_name = "signalhub-platform-alarms-att"

cloudwatch_log_group_name = "/aws/eks/signalhub-eks-cluster-att/application"
