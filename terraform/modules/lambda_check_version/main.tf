### START - Packaging lambda function for upload ####

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

resource "aws_lambda_function" "check_version" {
  filename         = data.archive_file.lambda_source.output_path
  source_code_hash = data.archive_file.lambda_source.output_base64sha256
  function_name    = "check_package_${var.package_check_name}"
  role             = aws_iam_role.role_for_version_check_lambda.arn
  runtime          = "python3.9"
  handler          = "main.lambda_handler"

  tags = {
    project = "Terraver"
  }
  environment {
    variables = {
      RELEASE_OFFSET = var.release_offset
      DYNAMO_TABLE   = var.dynamo_table
    }
  }
}

resource "aws_cloudwatch_event_rule" "check_version" {
  name        = "check_version"
  description = "Daily Terraform Check"

  schedule_expression = "cron(0 8 * * ? *)"
  #schedule_expression = "rate(2 minutes)" /* Testing only */
}

resource "aws_cloudwatch_event_target" "check_version" {
  rule = aws_cloudwatch_event_rule.check_version.name
  arn  = aws_lambda_function.check_version.arn
}


resource "aws_iam_role" "role_for_version_check_lambda" {
  name               = "role_for_version_check_lambda"
  assume_role_policy = templatefile("${path.module}/templates/role-assume-lambda-policy.json", {})
}

resource "aws_iam_policy" "policy_for_version_check_lambda" {
  name   = "policy_for_version_check_lambda"
  policy = templatefile("${path.module}/templates/lambda-dynamo-write-policy.json", { "dynamo_arn" : var.dynamo_arn })
}

resource "aws_iam_role_policy_attachment" "check_lambda" {
  role       = aws_iam_role.role_for_version_check_lambda.name
  policy_arn = aws_iam_policy.policy_for_version_check_lambda.arn
}

resource "aws_lambda_permission" "allow_clodwatch_to_check_version" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.check_version.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.check_version.arn
}
