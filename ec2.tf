
# Create VPC For the EC2 Instance
resource "aws_vpc" "my_vpc" {
  cidr_block = "172.16.0.0/16"

  tags = {
    environment = "dev"
  }
}

# access the internet: https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.my_vpc.id
}

# allow internet bound rules 
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    environment = "dev"
  }
}

# make this the main route table for subnet to use it 
resource "aws_main_route_table_association" "a" {
  vpc_id         = aws_vpc.my_vpc.id
  route_table_id = aws_route_table.my_route_table.id
}

resource "aws_subnet" "my_subnet" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "172.16.10.0/24"
  availability_zone = "us-east-1a"

  tags = {
    environment = "dev"
  }
}

resource "aws_security_group" "allow_tls" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTP from VPC"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "MYSQL/Aurora from VPC"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "NFS from VPC"
    from_port   = 2049
    to_port     = 2049
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
    name        = "allow_tls"
    environment = "dev"
  }
}

resource "aws_network_interface" "my_network_interface" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["172.16.10.100"]
  security_groups = [aws_security_group.allow_tls.id]

  tags = {
    environment = "dev"
  }
}

resource "aws_instance" "my_ec2" {
  ami           = "ami-0c94855ba95c71c99"
  instance_type = "t2.micro"
  key_name      = aws_key_pair.ec2_key.key_name

  network_interface {
    network_interface_id = aws_network_interface.my_network_interface.id
    device_index         = 0
  }

  credit_specification {
    cpu_credits = "unlimited"
  }
}

resource "aws_eip" "ec2_pip" {
  vpc = true

  network_interface         = aws_network_interface.my_network_interface.id
  associate_with_private_ip = aws_instance.my_ec2.private_ip
  depends_on                = [aws_internet_gateway.gw]
}



# "~/.ssh/id_rsa/id_pub.pub"
#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws
#https://docs.aws.amazon.com/vpc/latest/userguide/vpc-dns.html
#ssh-keygen -m PEM
resource "aws_key_pair" "ec2_key" {
  key_name   = "ec2-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDuxJ/zNqwkxMk4pjDFU4Hp6z+eaIIgZXTxGdD4NclBa5WQdggxTS5/3o3H+IOpkvKSAEXnAfwsd7S4dlMSN5DbAbEMG9g5zyjNrH27IcHv2TRXtbNkGro2/paE0xaPTcoGpfcTE5Tv0vBM5vGiaXSXXgizR3UJwBu0Kt6qm7tEjvvefyWNgC7jqh3NZ2xt7lpqJUWw46x0yU94FnorkqXIN2jb5Q9hwGAGT9+/vU01VPdT7bzpNtJ+2pNaHvmVdX1FmJYbghUtC8wkm/rtnpaZgGzvcibm/797gLUZfdNuWpWvKBEOByo12MXX4hlj4i30QnhtQnt9zGS3pUu32YiawcKVOAeCFnsXfSUlJCLpQ3nelX7J8F7ok08Z3gTHGFtTKKJDPx/T7dTpKY/JPI25hmm2ME6mJMZ5QvneWvicijnAlFNmTxKkj0QiKvspFjtaljpcpov/x00OrRHhnNh8XaqD9P+yV5wprjNpBPoYnjCDgnLWx9lG1lGUs/fHW70= dessy@DESSYGOLD-PC"
}


#--------------
# hosted zones 
#--------------

resource "aws_route53_zone" "dessygold" {
  name = "dessygold.com"
  tags = {
      env = "development"
  }
}

resource "aws_route53_record" "dessygold_a_eip" {
  zone_id = aws_route53_zone.dessygold.zone_id
  name    = "dessygold.com"
  type    = "A"
  ttl     = "30"
  records = [aws_eip.ec2_pip.public_ip]
}


#tls 
#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/SSL-on-amazon-linux-2.html

#lamp server 

#https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html
#https://docs.aws.amazon.com/vpc/latest/userguide/VPC_SecurityGroups.html
#https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-key-pairs.html#how-to-generate-your-own-key-and-import-it-to-aws

#ssh -i ~/.ssh/ec2-key-pair ec2-user@3.82.182.17

