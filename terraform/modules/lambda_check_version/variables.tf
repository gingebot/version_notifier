variable "lambda_root" {
  type        = string
  description = "The relative path to the lambda source"
}

variable "package_check_name" {
  type        = string
  description = "the name of the package being checked"
}

variable "dynamo_arn" {
  type        = string
  description = "Arn of the dynamodb to write to"
}

variable "dynamo_table" {
  type        = string
  description = "Name of the Dynamo DB table"
}

variable "release_offset" {
  type        = number
  description = "release offset in case someone wants to monitor n-x releases"
}