variable "s3_bucket_name" {
  description = "The name of the S3 bucket to store logs."
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t2.micro"
}
