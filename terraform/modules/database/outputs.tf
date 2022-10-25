output "dynamodb_table_arn" {
  value = aws_dynamodb_table.package_version.arn
}

output "dynamodb_table_stream_arn" {
  value = aws_dynamodb_table.package_version.stream_arn
}