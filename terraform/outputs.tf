output "instance_ip" {
  description = "The public IP address of the web instance"
  value       = aws_instance.web.public_ip
}

output "repository_url" {
  description = "The URL of the repository"
  value       = var.ecr_repository_url
}

output "private_key" {
  description = "The private key for SSH access"
  value       = tls_private_key.ssh.private_key_pem
  sensitive   = true
}

output "ssh_key_commands" {
  description = "Commands to add the SSH key to your agent"
  value       = <<-EOT
    # Save the private key
    terraform output -raw private_key > ~/.ssh/knot-takehome.pem
    
    # Set correct permissions
    chmod 600 ~/.ssh/knot-takehome.pem
    
    # Add to SSH agent
    ssh-add ~/.ssh/knot-takehome.pem
    
    # SSH command (after key is added)
    ssh -o StrictHostKeyChecking=no -A ubuntu@${aws_instance.web.public_ip}
  EOT
}

output "ssh_key_commands_raw" {
  description = "Raw commands to add the SSH key to your agent"
  value       = <<-EOT
    terraform output -raw private_key > ~/.ssh/knot-takehome.pem
    chmod 600 ~/.ssh/knot-takehome.pem
    ssh-add ~/.ssh/knot-takehome.pem
  EOT
}