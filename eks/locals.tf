locals {
  helm_values = [{
    velero = {
      configuration = {
        backupStorageLocation = [{
          name     = "aws-default"
          default  = true
          provider = "velero.io/aws"
          bucket   = var.default_backup_storage.bucket_id
          config = {
            region = var.default_backup_storage.region
          }
        }]
        volumeSnapshotLocation = [{
          name      = "aws-default"
          namespace = "velero"
          provider  = "velero.io/aws"
          config = {
            region = data.aws_region.current.name
          }
        }]
      }
      defaultVolumeSnapshotLocations = "aws-default"
      serviceAccount = {
        server = {
          annotations = {
            "eks.amazonaws.com/role-arn" = var.default_backup_storage.iam_role_arn
          }
        }
      }
      initContainers = [{
        name  = "velero-plugin-for-aws"
        image = "velero/velero-plugin-for-aws"
        volumeMounts = [{
          name      = "plugins"
          mountPath = "/target"
        }]
      }]
    }
  }]
}
