aws_region = "eu-south-1"
env        = "uat"

tags = {
  CreatedBy   = "Terraform"
  Environment = "uat"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-signalhub-deployment"
}

eks_cluster_name = "signalhub-eks-cluster-uat"

sns_topic_name = "signalhub-platform-alarms-uat"

cloudwatch_log_group_name = "/aws/eks/signalhub-eks-cluster-uat/application"
