aws_region = "eu-south-1"
env        = "vapt"

tags = {
  CreatedBy   = "Terraform"
  Environment = "Vapt"
  Owner       = "PagoPA"
  Source      = "https://github.com/pagopa/interop-signalhub-deployment"
}

eks_cluster_name = "signalhub-eks-cluster-vapt"
