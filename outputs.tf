output "instance_public_ip" {
  value = aws_instance.techeazy_app.public_ip
}

output "instance_url" {
  value = "http://${aws_instance.techeazy_app.public_ip}"
}

output "private_key_path" {
  value       = local_file.private_key.filename
  description = "Path to the private SSH key for EC2 access"
}
