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

resource "aws_instance" "techeazy_app" {
  ami                         = "ami-0fb653ca2d3203ac1" # Ubuntu 22.04 LTS in us-east-2
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.generated_key.key_name
  associate_public_ip_address = true
  user_data                   = file("${path.module}/user_data.sh")
  vpc_security_group_ids      = [aws_security_group.allow_http.id]

  tags = {
    Name = "techeazy-ubuntu-instance"
  }
}
