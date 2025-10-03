variable "region" {
  description = "The region to deploy the infrastructure"
  type        = string
}

variable "environment" {
  description = "The environment to deploy the infrastructure"
  type        = string
  default     = "dev"
}

variable "bucket_name" {
  description = "The name of the bucket"
  type        = string
}

variable "dynamodb_table_name" {
  description = "The name of the DynamoDB table"
  type        = string
}

variable "frontend_bucket_name" {
  description = "The name of the frontend bucket"
  type        = string
}

variable "dynamodb_table_name_users" {
  description = "The name of the DynamoDB table for users"
  type        = string
}

variable "dynamodb_table_name_messages" {
  description = "The name of the DynamoDB table for messages"
  type        = string
}

variable "dynamodb_table_name_connections" {
  description = "The name of the DynamoDB table for connections"
  type        = string
}