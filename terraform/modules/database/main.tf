resource "aws_dynamodb_table" "package_version" {
  name           = var.dynamo_table
  billing_mode   = "PROVISIONED"
  read_capacity  = 20
  write_capacity = 20
  hash_key       = "Package"

  attribute {
    name = "Package"
    type = "S"
  }

  stream_enabled   = true
  stream_view_type = "NEW_IMAGE"

  tags = {
    project = "Terraver"
  }
}