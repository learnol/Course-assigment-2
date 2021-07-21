provider "aws" {
  region = "us-east-1"
}

resource "tls_private_key" "task1_p_key" {
  algorithm = "RSA"
}

resource "aws_key_pair" "linuxdevops" {
  key_name   = "linuxdevops"
  public_key = tls_private_key.task1_p_key.public_key_openssh
}

resource "local_file" "private_key" {
  depends_on = [
    tls_private_key.task1_p_key,
  ]
  content  = tls_private_key.task1_p_key.private_key_pem
  filename = "linuxdevops.pem"
}

####### S3 AWS Resource #######
resource  "aws_s3_bucket" "s3_bkend_store" {
  bucket = "s3bkendstore123654"
  acl    = "private"
  
  versioning {
    enabled = true
  }
}
####### VPC #######

resource "aws_vpc" "vpc_demo" {
  cidr_block                       = var.cidr
  instance_tenancy                 = var.instance_tenancy
  enable_dns_hostnames             = var.enable_dns_hostnames
  enable_dns_support               = var.enable_dns_support
  enable_classiclink               = var.enable_classiclink

  tags = {
      Name = var.tags
    }

}
####### public subnet #######
resource "aws_subnet" "public_1" {
  vpc_id     = aws_vpc.vpc_demo.id
  map_public_ip_on_launch = true
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public_1-demo"
  }
}
resource "aws_subnet" "public_2" {
  vpc_id     = aws_vpc.vpc_demo.id
  map_public_ip_on_launch = true
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "public_2-demo"
  }
}

####### private subnet #######
resource "aws_subnet" "private_1" {
  vpc_id     = aws_vpc.vpc_demo.id
  map_public_ip_on_launch = false
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "private_1-demo"
  }
}
resource "aws_subnet" "private_2" {
  vpc_id     = aws_vpc.vpc_demo.id
  map_public_ip_on_launch = false
  cidr_block = "10.0.5.0/24"
  availability_zone = "us-east-1b"
  tags = {
    Name = "private_2-demo"
  }
}
####### internet getway #######
resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc_demo.id}"

  tags = {
    Name = "internet-gateway-demo"
  }
}

####### natgetway #######
resource "aws_eip" "nat" {
  vpc      = true
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${aws_subnet.public_1.id}"
  #depends_on    = ["aws_internet_gateway.gw"]
    tags = {
      Name = "Nat Gateway"
  }
}

####### Routing #######
resource "aws_route_table" "dc1-public-route" {
  vpc_id =  "${aws_vpc.vpc_demo.id}"
  route {
      cidr_block = "0.0.0.0/0"
      gateway_id = "${aws_internet_gateway.gw.id}"
  }

   tags = {
       Name = "dc1-public-route"
   }
}


resource "aws_default_route_table" "dc1-default-route" {
  default_route_table_id = "${aws_vpc.vpc_demo.default_route_table_id}"
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_nat_gateway.nat_gw.id}"
  }
  tags = {
      Name = "dc1-default-route"
  }
}

####### subnet association #######
resource "aws_route_table_association" "public_1a" {
  subnet_id = "${aws_subnet.public_1.id}"
  route_table_id = "${aws_route_table.dc1-public-route.id}"
}

resource "aws_route_table_association" "public_2a" {
  subnet_id = "${aws_subnet.public_2.id}"
  route_table_id = "${aws_route_table.dc1-public-route.id}"
}

resource "aws_route_table_association" "private_1a" {
  subnet_id = "${aws_subnet.private_1.id}"
  route_table_id = "${aws_vpc.vpc_demo.default_route_table_id}"
}

resource "aws_route_table_association" "private_2b" {
  subnet_id = "${aws_subnet.private_2.id}"
  route_table_id = "${aws_vpc.vpc_demo.default_route_table_id}"
}

resource "aws_security_group" "bositon_host_sg" {
  depends_on = [aws_subnet.public_1]
  name       = "bositon_host_sg"
  vpc_id     = aws_vpc.vpc_demo.id

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

  tags = {
    Name = "bositon_host_sg"
  }
}


resource "aws_security_group" "allow_web_sg" {
  name   = "allow_web_sg"
  vpc_id = aws_vpc.vpc_demo.id

  ingress {

    from_port   = 3306
    to_port     = 3306
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

resource "aws_security_group" "allow_http" {
  name   = "allow_http"
  vpc_id = aws_vpc.vpc_demo.id
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
  ingress {
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "allow_http"
  }
}

resource "aws_security_group" "only_ssh_sql_bositon" {
  depends_on  = [aws_subnet.public_1]
  name        = "only_ssh_sql_bositon"
  description = "allow ssh bositon inbound traffic"
  vpc_id      = aws_vpc.vpc_demo.id
  ingress {
    description     = "Only ssh_sql_bositon in public subnet"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bositon_host_sg.id]

  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "only_ssh_sql_bositon"
  }
}

resource "aws_instance" "BASTION" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.public_1.id
  vpc_security_group_ids = [aws_security_group.bositon_host_sg.id]
  key_name               = "linuxdevops"

  tags = {
    Name = "bastionhost"
  }
}

resource "aws_instance" "jenkins" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_1.id
  vpc_security_group_ids = [aws_security_group.allow_web_sg.id, aws_security_group.only_ssh_sql_bositon.id]
  key_name               = "linuxdevops"

  tags = {
    Name = "jenkins"
  }

  user_data = <<EOF
		#! /bin/bash
                sudo yum update -y
		sudo yum install -y httpd.x86_64
		sudo service httpd start
		sudo service httpd enable
		echo "<h1>Deployed via Terraform</h1>" | sudo tee /var/www/html/index.html
    yum install java-1.8.0-openjdk-devel -y
    curl --silent --location http://pkg.jenkins-ci.org/redhat-stable/jenkins.repo | sudo tee /etc/yum.repos.d/jenkins.repo
    sudo rpm --import https://jenkins-ci.org/redhat/jenkins-ci.org.key
    yum install -y jenkins
    systemctl start jenkins
    systemctl status jenkins
    systemctl enable jenkins

    sudo apt install apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

    apt-cache policy docker-ce

    sudo apt update

    sudo apt install docker-ce

    sudo systemctl status docker
	   EOF
}

resource "aws_instance" "app" {
  ami                    = var.ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private_2.id
  vpc_security_group_ids = [aws_security_group.allow_http.id]
  key_name               = "linuxdevops"


  tags = {
    Name = "app"
  }

  user_data = <<EOF
		#! /bin/bash
                sudo yum update -y
		sudo yum install -y httpd.x86_64
		sudo service httpd start
		sudo service httpd enable
	
    sudo apt install apt-transport-https ca-certificates curl software-properties-common

    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

    sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

    apt-cache policy docker-ce

    sudo apt update

    sudo apt install docker-ce

    sudo systemctl status docker
	   EOF
}
