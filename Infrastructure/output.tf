
# Frontend

output "frontend_bucket_name" {
  description = "S3 bucket name for hosting the TalkBridge frontend"
  value       = aws_s3_bucket.frontend.bucket
}

output "frontend_website_url" {
  description = "S3 static website hosting URL for the TalkBridge frontend"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}


# API Gateway (REST)

output "rest_api_id" {
  description = "API Gateway REST API ID"
  value       = aws_apigatewayv2_api.talkbridge_rest.id
}

output "rest_api_endpoint" {
  description = "Base endpoint URL for REST API"
  value       = aws_apigatewayv2_stage.rest.invoke_url
}


# API Gateway (WebSocket)

output "websocket_api_id" {
  description = "API Gateway WebSocket API ID"
  value       = aws_apigatewayv2_api.talkbridge_ws.id
}

output "websocket_api_endpoint" {
  description = "Base endpoint URL for WebSocket API"
  value       = aws_apigatewayv2_stage.websocket.invoke_url
}


# Cognito

output "cognito_user_pool_id" {
  description = "Cognito User Pool ID"
  value       = aws_cognito_user_pool.talkbridge_users.id
}

output "cognito_user_pool_client_id" {
  description = "Cognito App Client ID"
  value       = aws_cognito_user_pool_client.talkbridge_client.id
}

output "cognito_user_pool_domain" {
  description = "Cognito Hosted UI domain"
  value       = aws_cognito_user_pool_domain.talkbridge_domain.domain
}


# DynamoDB

output "dynamodb_connections_table" {
  description = "DynamoDB table name for storing active WebSocket connections"
  value       = aws_dynamodb_table.connections.name
}
