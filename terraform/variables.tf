
variable "aws_region" {
  description = "AWS region to use"
  type        = string
  default     = ""
}

variable "project_name" {
  description = "current project name can bse used for tagging"
  type = string
  default = ""
}

variable "github_username" {
  type = string
  default = ""
}

variable "repo_name" {
  type = string
  default = ""
}