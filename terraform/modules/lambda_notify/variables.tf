variable "lambda_root" {
  type        = string
  description = "The relative path to the lambda source"
}

variable "dynamo_arn" {
  type        = string
  description = "Arn of the dynamodb to read stream from"
}

variable "dynamo_stream_arn" {
  type = string
}

variable "notify_email" {
  type        = set(string)
  description = "Set of email addresses to be notified when a new release occurs"
}

variable "notify_sms" {
  type        = set(string)
  description = "Set a mobile numbers to be notified by test when a new release occurs"
}