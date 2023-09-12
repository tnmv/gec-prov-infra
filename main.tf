terraform {
    required_providers {
        aws = {
          source = "hashicorp/aws"
          version = "~>3.0"
        }
    }
}
provider "aws" {
    access_key = var.key_access
    secret_key = var.key_secret
    region = var.region1
}
resource "tls_private_key" "key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "key_pair" {
  key_name   = "ssh_key"  
  public_key = tls_private_key.key_pair.public_key_openssh
}

resource "local_file" "ssh_key" {
  filename = "${aws_key_pair.key_pair.key_name}.pem"
  content  = tls_private_key.key_pair.private_key_pem
}

resource "aws_security_group" "aws-vm-sg" {
  name        = "vm-sg"
  description = "Allow incoming connections"
  vpc_id      = var.id_vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "ALL"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }
    egress {
    from_port   = 0
    to_port     = 0
    protocol    = "ALL"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow incoming SSH connections"
  }
}

resource "aws_instance" "cp01" {
  ami                    = var.id_image
  instance_type          = var.instance_type
  subnet_id              = var.id_subnet
  vpc_security_group_ids = [aws_security_group.aws-vm-sg.id]
  source_dest_check      = false
  key_name               = aws_key_pair.key_pair.key_name
  
  tags = {
    Owner = "GEC Microservices"
    Name  = "cp01"
  }
}


resource "aws_instance" "cp02" {
  ami                    = var.id_image
  instance_type          = var.instance_type
  subnet_id              = var.id_subnet
  vpc_security_group_ids = [aws_security_group.aws-vm-sg.id]
  source_dest_check      = false
  key_name               = aws_key_pair.key_pair.key_name

  tags = {
    owner = "GEC Microservices"
    Name  = "cp02"
  }
}
resource "aws_instance" "cp03" {
  ami                    = var.id_image
  instance_type          = var.instance_type
  subnet_id              = var.id_subnet
  vpc_security_group_ids = [aws_security_group.aws-vm-sg.id]
  source_dest_check      = false
  key_name               = aws_key_pair.key_pair.key_name

  tags = {
    owner = "GEC Microservices"
    Name  = "cp03"
  }
}

resource "aws_instance" "bastion" {
  ami                    = var.id_image
  instance_type          = var.instance_type
  subnet_id              = var.id_subnet
  vpc_security_group_ids = [aws_security_group.aws-vm-sg.id]
  source_dest_check      = false
  key_name               = aws_key_pair.key_pair.key_name

  tags = {
    owner = "GEC Microservices"
    Name  = "bastion"
  }
}

resource "aws_efs_file_system"  "data-k8s"{
  creation_token = "data-k8s"
  encrypted = true
  tags = {
    Owner = "GEC Microservices"
    Name  = "data_K8s"
  }
}

resource "aws_vpc" "vpc_master" {
  cidr_block		= "192.168.0.0/16"
  enable_dns_support	= true
  enable_dns_hostnames	= true
  tags = {
    Name = "VPC-GEC-K8S"
    Owner = "GEC Microservices"
  }
}

#resource "aws_instance" "ec2-virtual-machine" {
# ami                         = ami-12345
# instance_type               = t2.micro
# key_name                    = aws_key_pair.master-key.key_name
# associate_public_ip_address = true
# vpc_security_group_ids      = [aws_security_group.jenkins-sg.id]
# subnet_id                   = aws_subnet.subnet.id
# provisioner "local-exec" {
#   command = "aws ec2 wait instance-status-ok --region us-east-1 --instance-ids ${self.id}"
#  }
#}