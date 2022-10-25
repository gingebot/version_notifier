variable "dynamo_table" {
  type        = string
  description = "Name of the Dynamo DB table"
  default     = "package_version"
}

variable "notify_email" {
  type        = set(string)
  description = "Set of email addresses to be notified when a new release occurs"
  default = []
}

variable "notify_sms" {
  type        = set(string)
  description = "Set a mobile numbers to be notified by test when a new release occurs"
  default = []
}

variable "release_offset" {
  type        = number
  description = "release offset in case someone wants to monitor n-x releases"
  default = 0
}