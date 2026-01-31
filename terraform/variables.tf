
variable "aws_region" {
  description = "AWS region to use"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "current project name can bse used for tagging"
  type = string
  default = "portfolio-website"
}

variable "github_username" {
  type = string
  default = "hkcodebase"
}

variable "repo_name" {
  type = string
  default = "hkcodebase.github.io"
}