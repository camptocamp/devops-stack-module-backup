locals {
  helm_values = [{
    velero = {
      deployNodeAgent  = true
      nodeAgent = {
          tolerations = {} # TODO
        }
      snapshotsEnabled = true

      configuration = {
        namespace = "${var.namespace}"
      }
      schedules = var.backup_schedules
      metrics = {
        serviceMonitor = {
          enabled = true
        }
        prometheusRule = {
          enabled = true
          spec = [
            {
              alert = "VeleroBackupPartialFailures"
              annotations = {
                message = "Velero backup {{ $labels.schedule }} has {{ $value | humanizePercentage }} partially failed backups."
              }
              expr = "velero_backup_partial_failure_total{schedule!=\"\"} / velero_backup_attempt_total{schedule!=\"\"} > 0.25"
              for  = "15m"
              labels = {
                severity = "warning"
              }
            },
            {
              alert = "VeleroBackupFailures"
              annotations = {
                message = "Velero backup {{ $labels.schedule }} has {{ $value | humanizePercentage }} failed backups."
              }
              expr = "velero_backup_partial_failure_total{schedule!=\"\"} / velero_backup_attempt_total{schedule!=\"\"} > 0.25"
              for  = "15m"
              labels = {
                severity = "warning"
              }
            },
            {
              alert = "VeleroBackupTooOld"
              annotations = {
                message = "No Velero backup {{ $labels.schedule }} has been made since {{ $value | humanizeTimestamp }}."
              }
              expr = "(time() - velero_backup_last_successful_timestamp{schedule!=\"\"}) > ${var.alert_backup_timeout}"
              labels = {
                severity = "warning"
              }
            }
          ]
        }
      }
    }
    grafana_dashboard = {
      enabled = var.enable_monitoring_dashboard
    }
  }]
}
