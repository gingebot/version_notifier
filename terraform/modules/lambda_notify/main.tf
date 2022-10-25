### START - Packaging lambda function for upload ####
### See also

resource "null_resource" "install_dependencies" {
  provisioner "local-exec" {
    command = "pip install -r ${var.lambda_root}/requirements.txt -t ${var.lambda_root}/"
  }
  triggers = {
    dependencies_versions = filemd5("${var.lambda_root}/requirements.txt")
    source_versions       = filemd5("${var.lambda_root}/main.py")
  }
}

resource "random_uuid" "lambda_package" {
  keepers = {
    "filea" = filemd5("${var.lambda_root}/requirements.txt"),
    "fileb" = filemd5("${var.lambda_root}/main.py")
  }
}

### END - Packaging lambda function for upload ####

resource "aws_lambda_function" "notify" {
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = data.archive_file.lambda_source.output_base64sha256
  function_name    = "new_version_notifier"
  role             = aws_iam_role.role_for_notify_lambda.arn
  runtime          = "python3.9"
  handler          = "main.lambda_handler"

  tags = {
    project = "Terraver"
  }
}

resource "aws_lambda_event_source_mapping" "notify" {
  event_source_arn  = var.dynamo_stream_arn
  function_name     = aws_lambda_function.notify.function_name
  starting_position = "LATEST"
}

resource "aws_iam_role" "role_for_notify_lambda" {
  name               = "role_for_notify_lambda"
  assume_role_policy = templatefile("${path.module}/templates/role-assume-lambda-policy.json", {})
}

resource "aws_iam_policy" "policy_for_notify_lambda" {
  name   = "policy_for_notify_lambda"
  policy = templatefile("${path.module}/templates/lambda-dynamo-read-policy.json", { "dynamo_arn" : var.dynamo_arn })
}

resource "aws_iam_policy" "sns_publish_policy" {
  name   = "policy_for_notify_lambda_sns_publish"
  policy = templatefile("${path.module}/templates/lambda-sns-publish-policy.json", { "sns_topic_arn" : aws_sns_topic.notify.arn })
}

resource "aws_iam_role_policy_attachment" "notify_lambda" {
  role       = aws_iam_role.role_for_notify_lambda.name
  policy_arn = aws_iam_policy.policy_for_notify_lambda.arn
}

resource "aws_iam_role_policy_attachment" "notify_lambda_sns_publish" {
  role       = aws_iam_role.role_for_notify_lambda.name
  policy_arn = aws_iam_policy.sns_publish_policy.arn
}

resource "aws_sns_topic" "notify" {
  name = "package-update"
}

resource "aws_sns_topic_subscription" "notify_email" {
  for_each  = var.notify_email
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "email"
  endpoint  = each.value
}

resource "aws_sns_topic_subscription" "notify_sms" {
  for_each  = var.notify_sms
  topic_arn = aws_sns_topic.notify.arn
  protocol  = "sms"
  endpoint  = each.value
}
