
resource "null_resource" "dependencies" {
  triggers = var.dependency_ids
}

resource "random_password" "restic_repo_password" {
  length  = 32
  special = false
}

resource "kubernetes_namespace" "k8up_namespace" {
  metadata {
    annotations = {
      name = var.namespace
    }
    name = var.namespace
  }
}

# This has to be deployed before k8up as it cannot be set in the chart values
resource "kubernetes_secret" "k8up_repo_credentials" {
  metadata {
    name      = "k8up-repo-credentials"
    namespace = "k8up"
  }
  data = {
    "repository-password" = random_password.restic_repo_password.result
  }

}

resource "argocd_project" "this" {
  metadata {
    name      = "k8up"
    namespace = var.argocd_namespace
    annotations = {
      "devops-stack.io/argocd_namespace" = var.argocd_namespace
    }
  }

  spec {
    description  = "Backup application project - k8up version"
    source_repos = ["https://github.com/camptocamp/devops-stack-module-backup.git"]

    destination {
      name      = "in-cluster"
      namespace = "k8up"
    }

    orphaned_resources {
      warn = true
    }

    cluster_resource_whitelist {
      group = "*"
      kind  = "*"
    }
  }
}

data "helm_template" "this" {
  name      = "k8up"
  namespace = "k8up"
  chart     = "${path.module}/charts/k8up"
  values    = [sensitive(data.utils_deep_merge_yaml.values.output)]
}

resource "null_resource" "k8s_resources" {
  triggers = data.helm_template.this.manifests
}

data "utils_deep_merge_yaml" "values" {
  input = [for i in concat(local.helm_values, var.helm_values) : yamlencode(i)]
}

resource "argocd_application" "this" {
  metadata {
    name      = "k8up"
    namespace = var.argocd_namespace
  }

  timeouts {
    create = "15m"
    delete = "15m"
  }

  wait = var.app_autosync == { "allow_empty" = tobool(null), "prune" = tobool(null), "self_heal" = tobool(null) } ? false : true

  spec {
    project = argocd_project.this.metadata.0.name

    source {
      repo_url = "https://github.com/camptocamp/devops-stack-module-backup.git"
      path     = "charts/k8up"
      target_revision = var.target_revision
      helm {
        values = data.utils_deep_merge_yaml.values.output
      }
    }

    destination {
      name      = "in-cluster"
      namespace = "k8up"
    }

    sync_policy {
      automated = var.app_autosync

      retry {
        backoff = {
          duration     = ""
          max_duration = ""
        }
        limit = "0"
      }

      sync_options = [
        "CreateNamespace=true"
      ]
    }
  }

  depends_on = [
    resource.null_resource.dependencies,
    kubernetes_secret.k8up_repo_credentials
  ]
}

resource "null_resource" "this" {
  depends_on = [
    resource.argocd_application.this,
  ]
}
