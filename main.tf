provider "aws" {
  region = "us-east-2"
}

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "generated_key" {
  key_name   = "techeazy-terraform-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/techeazy-terraform-key.pem"
  file_permission = "0600"
}

resource "aws_security_group" "allow_http" {
  name_prefix = "allow-http-"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# IAM Role 1a: Read-only access on S3
resource "aws_iam_role" "s3_readonly_role" {
  name = "s3-readonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_readonly_policy" {
  name        = "s3-readonly-policy"
  description = "Provides read-only access to S3"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action   = ["s3:Get*", "s3:List*"],
      Effect   = "Allow",
      Resource = "*"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_readonly_policy" {
  role       = aws_iam_role.s3_readonly_role.name
  policy_arn = aws_iam_policy.s3_readonly_policy.arn
}

# IAM Role 1b: Write-only S3 access (restricted to the specific bucket)
resource "aws_iam_role" "s3_writeonly_role" {
  name = "s3-writeonly-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action    = "sts:AssumeRole",
      Effect    = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "s3_writeonly_policy" {
  name        = "s3-writeonly-policy"
  description = "Provides write-only access to a specific S3 bucket"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:PutObject", "s3:CreateBucket"],
        Resource = [
          "arn:aws:s3:::${var.s3_bucket_name}",
          "arn:aws:s3:::${var.s3_bucket_name}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_writeonly_policy" {
  role       = aws_iam_role.s3_writeonly_role.name
  policy_arn = aws_iam_policy.s3_writeonly_policy.arn
}

resource "aws_iam_instance_profile" "writeonly_instance_profile" {
  name = "writeonly-instance-profile"
  role = aws_iam_role.s3_writeonly_role.name
}

# S3 Bucket
resource "aws_s3_bucket" "private_logs" {
  bucket = var.s3_bucket_name

  tags = {
    Name = "PrivateLogsBucket"
  }

  force_destroy = true
}


resource "aws_s3_bucket_versioning" "private_logs_versioning" {
  bucket = aws_s3_bucket.private_logs.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "private_logs_lifecycle" {
  bucket = aws_s3_bucket.private_logs.id

  rule {
    id     = "expire-old-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    expiration {
      days = 7
    }
  }
}

resource "aws_instance" "techeazy_app" {
  ami                         = "ami-0fb653ca2d3203ac1" # Ubuntu 22.04 LTS in us-east-2
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")
  vpc_security_group_ids      = [aws_security_group.allow_http.id]
  iam_instance_profile        = aws_iam_instance_profile.writeonly_instance_profile.name

  tags = {
    Name = "techeazy-ubuntu-instance"
  }
}

# validation
locals {
  bucket_name_valid = length(var.s3_bucket_name) > 0
}

resource "null_resource" "validate_bucket_name" {
  count = local.bucket_name_valid ? 0 : 1
  provisioner "local-exec" {
    command = "echo Bucket name must be provided! && exit 1"
  }
}
