output "bastion_public_ip" {
  description = "IP publique du Bastion"
  value       = aws_instance.bastion.public_ip
}

output "appserver_private_ip" {
  description = "IP privée du serveur App"
  value       = aws_instance.appserver.private_ip
}

output "vpc_id" {
  description = "ID du VPC"
  value       = aws_vpc.payflow.id
}
