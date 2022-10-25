variable "dynamo_table" {
  type        = string
  description = "Name of the Dynamo DB table"
  default     = "package_version"
}