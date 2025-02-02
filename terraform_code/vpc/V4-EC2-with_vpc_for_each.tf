terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.4.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "demo-server" {
  ami = "ami-053b0d53c279acc90"
  instance_type = "t2.micro"
  key_name = "Portfolio_Key"
  //security_groups = [ "demo-sg" ]
  vpc_security_group_ids = [aws_security_group.demo-sg.id]
  subnet_id = aws_subnet.ryan-public-subnet-01.id
    for_each = toset(["jenkins-master", "build-slave", "ansible"])
   tags = {
     Name = "${each.key}"
   }
}

resource "aws_security_group" "demo-sg" {
  name        = "demo-sg"
  description = "SSH Access"
  vpc_id = aws_vpc.ryan-vpc.id

  ingress {
    description      = "SSH Access"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Jenkins port"
    from_port        = 8080
    to_port          = 8080
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "ssh-port"
  }
}

resource "aws_vpc" "ryan-vpc" {
    cidr_block = "10.1.0.0/16"
    tags = {
        Name = "ryan-vpc"
    }
}

resource "aws_subnet" "ryan-public-subnet-01" {
    vpc_id = aws_vpc.ryan-vpc.id
    cidr_block = "10.1.1.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1a"
    tags = {
        Name = "ryan-public_subnet_01"
    }
}

resource "aws_subnet" "ryan-public-subnet-02" {
    vpc_id = aws_vpc.ryan-vpc.id
    cidr_block = "10.1.2.0/24"
    map_public_ip_on_launch = "true"
    availability_zone = "us-east-1b"
    tags = {
        Name = "ryan-public_subnet_02"
    }
}

resource "aws_internet_gateway" "ryan-igw" {
    vpc_id = aws_vpc.ryan-vpc.id
    tags = {
        Name = "ryan-igw"
    }
}

resource "aws_route_table" "ryan-public-rt" {
    vpc_id = aws_vpc.ryan-vpc.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.ryan-igw.id
    }
}

resource "aws_route_table_association" "ryan-rta-public-subnet-1" {
    subnet_id = aws_subnet.ryan-public-subnet-01.id
    route_table_id = aws_route_table.ryan-public-rt.id
}

resource "aws_route_table_association" "ryan-rta-public-subnet-2" {
    subnet_id = aws_subnet.ryan-public-subnet-02.id
    route_table_id = aws_route_table.ryan-public-rt.id
}

  module "sgs" {
    source = "../sg_eks"
    vpc_id     =     aws_vpc.ryan-vpc.id
 }

  module "eks" {
       source = "../eks"
       vpc_id     =     aws_vpc.ryan-vpc.id
       subnet_ids = [aws_subnet.ryan-public-subnet-01.id,aws_subnet.ryan-public-subnet-02.id]
       sg_ids = module.sgs.security_group_public
 }