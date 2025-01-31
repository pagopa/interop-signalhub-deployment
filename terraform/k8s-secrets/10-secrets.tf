data "aws_secretsmanager_secrets" "signal_store_users" {
  filter {
    name   = "tag-key"
    values = ["EKSClusterName"]
  }
}

data "aws_secretsmanager_secret" "signal_store_users_object" {
  depends_on = [data.aws_secretsmanager_secrets.signal_store_users]

  for_each = toset(data.aws_secretsmanager_secrets.signal_store_users.names)

  name = each.value
}

data "aws_secretsmanager_secret_version" "signal_store_users" {
  depends_on = [data.aws_secretsmanager_secret.signal_store_users_object]

  for_each = { for key, object in data.aws_secretsmanager_secret.signal_store_users_object : key => object if object.tags["EKSClusterName"] == var.eks_cluster_name }

  secret_id = each.value.name
}

locals {
  sv_namespaces_pairs = flatten([
    for sv_key, sv_value in data.aws_secretsmanager_secret_version.signal_store_users : [
      for ns in toset(split(" ", (data.aws_secretsmanager_secret.signal_store_users_object[sv_key].tags["EKSClusterNamespacesSpaceSeparated"]))) : {
        eks_replica_secret_name = data.aws_secretsmanager_secret.signal_store_users_object[sv_value.secret_id].tags["EKSReplicaSecretName"],
        secret_version          = sv_value,
        namespace               = ns
      }
    ]
  ])
}

resource "time_static" "secret_string_update" {
  for_each = data.aws_secretsmanager_secret_version.signal_store_users

  triggers = {
    secret_string = each.value.secret_string
  }
}

resource "kubernetes_secret_v1" "signal_store_users" {
  depends_on = [time_static.secret_string_update]

  for_each = { for elem in local.sv_namespaces_pairs : "${elem.namespace}/${elem.eks_replica_secret_name}" => elem }

  metadata {
    namespace = each.value.namespace
    name      = each.value.eks_replica_secret_name
    annotations = {
      "infra.interop.pagopa.it/aws-secretsmanager-secret-id" : each.value.secret_version.secret_id,
      "infra.interop.pagopa.it/aws-secretsmanager-version-id" : each.value.secret_version.version_id,
      "infra.interop.pagopa.it/updated-at" : time_static.secret_string_update[each.value.secret_version.secret_id].rfc3339
    }
  }

  data = {
    for key, value in jsondecode(each.value.secret_version.secret_string) : key => value
  }
}
