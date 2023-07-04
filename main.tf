# resource "null_resource" "dependencies" {
#   triggers = var.dependency_ids
# }
#
# resource "random_password" "restic_repo_password" {
#   length  = 32
#   special = false
# }
#
# resource "kubernetes_namespace" "velero_namespace" {
#   metadata {
#     annotations = {
#       name = var.namespace
#     }
#     name = var.namespace
#   }
# }
#
# # This has to be deployed before velero as it cannot be set in the chart values
# resource "kubernetes_secret" "velero_repo_credentials" {
#   metadata {
#     name      = "velero-repo-credentials"
#     namespace = var.namespace
#   }
#   data = {
#     "repository-password" = random_password.restic_repo_password.result
#   }
#
# }
#
# resource "argocd_project" "this" {
#   metadata {
#     name      = "velero"
#     namespace = var.argocd_namespace
#     annotations = {
#       "devops-stack.io/argocd_namespace" = var.argocd_namespace
#     }
#   }
#
#   spec {
#     description  = "Backup application project"
#     source_repos = ["https://github.com/camptocamp/devops-stack-module-backup.git"]
#
#     destination {
#       name      = "in-cluster"
#       namespace = var.namespace
#     }
#
#     orphaned_resources {
#       warn = true
#     }
#
#     cluster_resource_whitelist {
#       group = "*"
#       kind  = "*"
#     }
#   }
# }
#
# data "helm_template" "this" {
#   name      = "velero"
#   namespace = var.namespace
#   chart     = "${path.module}/charts/velero"
#   values    = [sensitive(data.utils_deep_merge_yaml.values.output)]
# }
#
# resource "null_resource" "k8s_resources" {
#   triggers = data.helm_template.this.manifests
# }
#
# data "utils_deep_merge_yaml" "values" {
#   input = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
# }
#
# resource "argocd_application" "this" {
#   metadata {
#     name      = "velero"
#     namespace = var.argocd_namespace
#   }
#
#   timeouts {
#     create = "15m"
#     delete = "15m"
#   }
#
#   wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true
#
#   spec {
#     project = argocd_project.this.metadata.0.name
#
#     source {
#       repo_url = "https://github.com/camptocamp/devops-stack-module-backup.git"
#       path     = "charts/velero"
#       target_revision = var.target_revision
#       helm {
#         values = data.utils_deep_merge_yaml.values.output
#       }
#     }
#
#     destination {
#       name      = "in-cluster"
#       namespace = var.namespace
#     }
#
#     sync_policy {
#       automated = var.app_autosync
#
#       retry {
#         backoff = {
#           duration     = ""
#           max_duration = ""
#         }
#         limit = "0"
#       }
#
#       sync_options = [
#         "CreateNamespace=true"
#       ]
#     }
#   }
#
#   depends_on = [
#     resource.null_resource.dependencies,
#     kubernetes_secret.velero_repo_credentials
#   ]
# }
#
# resource "null_resource" "this" {
#   depends_on = [
#     resource.argocd_application.this,
#   ]
# }
