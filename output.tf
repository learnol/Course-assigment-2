output "VPC" {
  value = aws_vpc.vpc_demo1.arn
}

output "Internet-gateway" {
  value = aws_internet_gateway.gw1.arn
}

output "Public-Subnet" {
  value = aws_subnet.public_1a.arn
}

output "Route-table-public" {
  value = aws_route_table.dc1-public-route1.arn
}

output "Private-Subnet" {
  value = aws_subnet.private_1a.arn
}


output "Nat-Gateway-IP" {
  value = aws_nat_gateway.nat_gw1.public_ip
}

output "Bastion-HOST-IP" {
  value = aws_instance.BASTION1.public_ip
}

output "Jenkins-IP" {
  value = aws_instance.jenkins1.private_ip
}

output "App-IP" {
  value = aws_instance.app1.private_ip
}

output "name_server"{
  value=aws_route53_zone.easy_aws.name_servers
}

output "elb_example" {
  description = "The DNS name of the ELB"
  value       = aws_lb.elb_example.dns_name
}
