#EC2 Public IP Address ID
output "ec2_pip" {
  value = aws_eip.ec2_pip.public_ip
}
 # Route 53 name server 
output "dessygold_hosted_zone_ns" {
    value = aws_route53_zone.dessygold.name_servers
}