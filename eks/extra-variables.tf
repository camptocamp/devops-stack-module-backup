variable "default_backup_storage" {
  description = "AWS S3 bucket configuration values for the bucket where the backups will be stored."
  type = object({
    bucket_id    = string
    region       = string
    iam_role_arn = string
  })
}
