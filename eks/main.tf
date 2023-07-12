data "aws_region" "current" {}

module "backup" {
  source = "../"

  cluster_name     = var.cluster_name
  base_domain      = var.base_domain
  argocd_namespace = var.argocd_namespace
  target_revision  = var.target_revision
  cluster_issuer   = var.cluster_issuer
  namespace        = var.namespace
  app_autosync     = var.app_autosync
  dependency_ids   = var.dependency_ids

  backup_schedules            = var.backup_schedules
  enable_monitoring_dashboard = var.enable_monitoring_dashboard
  alert_backup_timeout        = var.alert_backup_timeout

  helm_values = concat(local.helm_values, var.helm_values)
}
