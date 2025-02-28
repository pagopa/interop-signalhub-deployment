data "local_file" "cronjobs_list" {
  filename = "${path.module}/assets/cronjobs-list.json"
}


locals {
  cronjobs_names = jsondecode(data.local_file.cronjobs_list.content)
}

module "k8s_cronjob_monitoring" {
  for_each = toset(local.cronjobs_names)

# VERIFY THE TAG VALUE
  source = "git::https://github.com/pagopa/interop-infra-commons//terraform/modules/k8s-workload-monitoring?ref=v1.6.0"

# Assign workload kind value
  kind = "CronJob"

  env               = var.env
  eks_cluster_name  = var.eks_cluster_name
  k8s_namespace     = var.env

  k8s_workload_name = each.key

  create_performance_alarm      = true
  create_app_logs_errors_alarm  = true

  avg_cpu_alarm_threshold           = 70
  avg_memory_alarm_threshold        = 70
  performance_alarms_period_seconds = 300 # 5 minutes

  create_dashboard = false


  cloudwatch_app_logs_errors_metric_name      = try(data.external.cloudwatch_log_metric_filters.result.metricName, null)
  cloudwatch_app_logs_errors_metric_namespace = try(data.external.cloudwatch_log_metric_filters.result.metricNamespace, null)

  sns_topics_arns     = [data.aws_sns_topic.platform_alarms.arn]

  tags = var.tags
}