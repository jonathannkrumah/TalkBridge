resource "aws_s3_bucket" "talkbridge_bucket" {
  bucket = var.bucket_name
}

resource "aws_s3_bucket_acl" "talkbridge_bucket_acl" {
  bucket = aws_s3_bucket.talkbridge_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_versioning" "talkbridge_bucket_versioning" {
  bucket = aws_s3_bucket.talkbridge_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "talkbridge_bucket_lifecycle_configuration" {
  bucket = aws_s3_bucket.talkbridge_bucket.id
  rule {
    id = "lifecycle"
    status = "Enabled"
  }
}

resource "aws_s3_bucket_policy" "talkbridge_bucket_policy" {
  bucket = aws_s3_bucket.talkbridge_bucket.id
  policy = data.aws_iam_policy_document.talkbridge_bucket_policy.json
}

resource "aws_api_gateway_rest_api" "talkbridge_restapi" {
  name = "talkbridge-restapi"
  description = "REST API FOR TalkBridge (signup, profiles, friend requests)"
}

resource "aws_apaigatewayv2_api" "talkbridge_websocketapi" {
  name = "talkbridge-websocketapi"
  description = "WEBSOCKET API FOR TalkBridge (chat, voice calls)"
  protocol_type = "WEBSOCKET"
  route_selection_expression = "$request.body.action"
  tags = {
    Name = "talkbridge-websocketapi"
  }
  target = "websocket"
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_s3_bucket" "frontend" {
  bucket = var.frontend_bucket_name
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.bucket

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html" # SPA routing fallback
  }
}

resource "aws_s3_bucket_policy" "frontend_policy" {
  bucket = aws_s3_bucket.frontend.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Sid       = "PublicReadGetObject",
      Effect    = "Allow",
      Principal = "*",
      Action    = "s3:GetObject",
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# Table 1: Users & Friends
resource "aws_dynamodb_table" "users" {
  name         = var.dynamodb_table_name_users
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "userId"

  attribute {
    name = "userId"
    type = "S"
  }
}

# Table 2: Messages
resource "aws_dynamodb_table" "messages" {
  name         = var.dynamodb_table_name_messages
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "chatId"
  range_key    = "timestamp"

  attribute {
    name = "chatId"
    type = "S"
  }

  attribute {
    name = "timestamp"
    type = "N"
  }
}

# Table 3: Connections (WebSocket session mapping)
resource "aws_dynamodb_table" "connections" {
  name         = var.dynamodb_table_name_connections
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "connectionId"

  attribute {
    name = "connectionId"
    type = "S"
  }
}

# Connect route
resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.talkbridge_ws.id
  route_key = "$connect"
  target    = "integrations/${aws_apigatewayv2_integration.connect.id}"
}

# Disconnect route
resource "aws_apigatewayv2_route" "disconnect" {
  api_id    = aws_apigatewayv2_api.talkbridge_ws.id
  route_key = "$disconnect"
  target    = "integrations/${aws_apigatewayv2_integration.disconnect.id}"
}

# SendMessage route
resource "aws_apigatewayv2_route" "send_message" {
  api_id    = aws_apigatewayv2_api.talkbridge_ws.id
  route_key = "sendMessage"
  target    = "integrations/${aws_apigatewayv2_integration.send_message.id}"
}

# Integrations with Lambda functions
resource "aws_apigatewayv2_integration" "connect" {
  api_id           = aws_apigatewayv2_api.talkbridge_ws.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.connect.invoke_arn
}

resource "aws_apigatewayv2_integration" "disconnect" {
  api_id           = aws_apigatewayv2_api.talkbridge_ws.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.disconnect.invoke_arn
}

resource "aws_apigatewayv2_integration" "send_message" {
  api_id           = aws_apigatewayv2_api.talkbridge_ws.id
  integration_type = "AWS_PROXY"
  integration_uri  = aws_lambda_function.send_message.invoke_arn
}

# Deployments and stages
resource "aws_apigatewayv2_deployment" "talkbridge_ws_deploy" {
  api_id      = aws_apigatewayv2_api.talkbridge_ws.id
  description = "Initial WebSocket deployment"

  depends_on = [
    aws_apigatewayv2_route.connect,
    aws_apigatewayv2_route.disconnect,
    aws_apigatewayv2_route.send_message
  ]
}

resource "aws_apigatewayv2_stage" "talkbridge_ws_stage" {
  api_id      = aws_apigatewayv2_api.talkbridge_ws.id
  name        = "prod"
  deployment_id = aws_apigatewayv2_deployment.talkbridge_ws_deploy.id
  auto_deploy = true
}

resource "aws_lambda_function" "connect" {
  function_name = "talkbridge-connect"
  handler = "connect.handler"
  runtime = "python3.12"
  role = aws_iam_role.lambda_role.arn
  package_type = "Zip"
  filename = "connect.zip"
  source_code_hash = filebase64sha256("connect.zip")
  tags = {
    Name = "talkbridge-connect"
  }
  lifecycle {
    create_before_destroy = true
  }
}


# REST API Integration for Signup
resource "aws_api_gateway_integration" "signup_integration" {
  rest_api_id = aws_api_gateway_rest_api.talkbridge_rest.id
  resource_id = aws_api_gateway_rest_api.talkbridge_rest.root_resource_id
  http_method = aws_api_gateway_method.signup.http_method
  integration_http_method = "POST"
  type = "AWS_PROXY"
  uri  = aws_lambda_function.signup.invoke_arn
}

resource "aws_cognito_user_pool" "talkbridge_users" {
  name = "talkbridge-user-pool"

  # password policy
  password_policy {
    minimum_length    = 8
    require_lowercase = true
    require_uppercase = true
    require_numbers   = true
    require_symbols   = false
  }

  auto_verified_attributes = ["email"]
}

resource "aws_cognito_user_pool_client" "talkbridge_client" {
  name         = "talkbridge-client"
  user_pool_id = aws_cognito_user_pool.talkbridge_users.id
  generate_secret = false   # mobile/web apps usually don’t use a secret

  explicit_auth_flows = [
    "ALLOW_USER_PASSWORD_AUTH",
    "ALLOW_REFRESH_TOKEN_AUTH",
    "ALLOW_USER_SRP_AUTH"
  ]
}

resource "aws_cognito_user_pool_domain" "talkbridge_domain" {
  domain       = "talkbridge-app-auth"
  user_pool_id = aws_cognito_user_pool.talkbridge_users.id
}

resource "aws_cognito_identity_pool" "talkbridge_identity_pool" {
  identity_pool_name               = "TalkBridgeIdentityPool"
  allow_unauthenticated_identities = false

  cognito_identity_providers {
    client_id               = aws_cognito_user_pool_client.talkbridge_client.id
    provider_name           = aws_cognito_user_pool.talkbridge_users.endpoint
  }
}

#REST API Authorizer
resource "aws_api_gateway_authorizer" "cognito_auth" {
  name                   = "talkbridge-cognito-authorizer"
  rest_api_id            = aws_api_gateway_rest_api.talkbridge_rest.id
  type                   = "COGNITO_USER_POOLS"
  provider_arns          = [aws_cognito_user_pool.talkbridge_users.arn]
  identity_source        = "method.request.header.Authorization"
}


resource "aws_api_gateway_method" "get_friends" {
  rest_api_id   = aws_api_gateway_rest_api.talkbridge_rest.id
  resource_id   = aws_api_gateway_resource.friends.id
  http_method   = "GET"
  authorization = "COGNITO_USER_POOLS"
  authorizer_id = aws_api_gateway_authorizer.cognito_auth.id
}

#Cognito Authorizer for WebSocket
resource "aws_apigatewayv2_authorizer" "cognito_ws_auth" {
  api_id          = aws_apigatewayv2_api.talkbridge_ws.id
  name            = "talkbridge-ws-cognito"
  authorizer_type = "JWT"

  identity_sources = ["$request.header.Authorization"]

  jwt_configuration {
    audience = [aws_cognito_user_pool_client.talkbridge_client.id]
    issuer   = "https://${aws_cognito_user_pool.talkbridge_users.endpoint}"
  }
}

resource "aws_apigatewayv2_route" "connect" {
  api_id    = aws_apigatewayv2_api.talkbridge_ws.id
  route_key = "$connect"

  authorization_type = "JWT"
  authorizer_id      = aws_apigatewayv2_authorizer.cognito_ws_auth.id

  target = "integrations/${aws_apigatewayv2_integration.connect.id}"
}



