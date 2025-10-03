# Signup Lambda
resource "aws_lambda_function" "signup" {
  function_name = "talkbridge-signup"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambdas/signup.zip"
}

# Login Lambda
resource "aws_lambda_function" "login" {
  function_name = "talkbridge-login"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambdas/login.zip"
}

# WebSocket Lambdas
resource "aws_lambda_function" "connect_handler" {
  function_name = "talkbridge-connect"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "connect.lambda_handler"
  runtime       = "python3.10"

  s3_bucket = "talkbridge-lambda-artifacts"
  s3_key    = "connect.zip"

  environment {
    variables = {
      CONNECTIONS_TABLE = aws_dynamodb_table.connections.name
    }
  }
}

resource "aws_lambda_function" "disconnect" {
  function_name = "talkbridge-disconnect"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambdas/disconnect.zip"
}

resource "aws_lambda_function" "send_message" {
  function_name = "talkbridge-send-message"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  filename      = "${path.module}/lambdas/send_message.zip"
}
