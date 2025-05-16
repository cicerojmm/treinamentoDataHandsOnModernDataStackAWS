variable "function_name" {
  description = "Name of the Lambda function"
  type        = string
}

variable "description" {
  description = "Description of the Lambda function"
  type        = string
  default     = "Python Lambda function with custom libraries"
}

variable "timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 60
}

variable "memory_size" {
  description = "Lambda function memory size in MB"
  type        = number
  default     = 128
}

variable "ephemeral_storage_size" {
  description = "Lambda function ephemeral storage size in MB"
  type        = number
  default     = 512
}

variable "environment_variables" {
  description = "Environment variables for the Lambda function"
  type        = map(string)
  default     = {}
}

variable "additional_policy_arns" {
  description = "List of additional IAM policy ARNs to attach to the Lambda role"
  type        = list(string)
  default     = []
}

variable "log_retention_days" {
  description = "Number of days to retain Lambda logs"
  type        = number
  default     = 14
}

variable "image_uri" {
  description = "URI of the Docker image to use for the Lambda function"
  type        = string
}

variable "create_function_url" {
  description = "Whether to create a function URL for the Lambda"
  type        = bool
  default     = false
}

variable "function_url_auth_type" {
  description = "The type of authentication for the function URL (AWS_IAM or NONE)"
  type        = string
  default     = "AWS_IAM"
  validation {
    condition     = contains(["AWS_IAM", "NONE"], var.function_url_auth_type)
    error_message = "The function_url_auth_type must be either AWS_IAM or NONE."
  }
}