aws_region = "eu-south-1"
env        = "dev"

tags = {
  CreatedBy   = "Terraform"
  Environment = "dev"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-signalhub-deployment"
}

eks_cluster_name = "signalhub-eks-cluster-dev"