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
resource "local_file" "ip_cp01" {
      content  = aws_instance.cp01.private_ip
      filename = "cp01"
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
 resource "local_file" "ip_cp02" {
      content  = aws_instance.cp02.private_ip
      filename = "cp02"
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
resource "local_file" "ip_cp03" {
      content  = aws_instance.cp03.private_ip
      filename = "cp03"
}


resource "aws_instance" "bastion" {
  ami                    = var.id_image
  instance_type          = var.instance_type
  subnet_id              = var.id_subnet
  vpc_security_group_ids = [aws_security_group.aws-vm-sg.id]
  source_dest_check      = false
  key_name               = aws_key_pair.key_pair.key_name
 
  provisioner "file" {
    source      = "./ssh_key.pem"
    destination = "/home/ubuntu/ssh_key.pem"
    
    connection {
      host = self.public_ip
      type = "ssh"
      user = "ubuntu"
      private_key = file("ssh_key.pem")
    } 
  }

  provisioner "file" {
    source      = "cp01"
    destination = "/home/ubuntu/cp01"
    
    connection {
      host = self.public_ip
      type = "ssh"
      user = "ubuntu"
      private_key = file("ssh_key.pem")
    }
  }
  provisioner "file" {
    source      = "cp02"
    destination = "/home/ubuntu/cp02"
    
    connection {
      host = self.public_ip
      type = "ssh"
      user = "ubuntu"
      private_key = file("ssh_key.pem")
    }
  }
  provisioner "file" {
    source      = "cp03"
    destination = "/home/ubuntu/cp03"

    connection {
      host = self.public_ip
      type = "ssh"
      user = "ubuntu"
      private_key = file("ssh_key.pem")
    }
  }
  provisioner "remote-exec" {
    inline = [
      "sudo apt update -y",
      "sudo apt install ansible python3-pip -y ",
      "pip install kubernetes",
      "ansible-galaxy collection install ansible.posix",
      "ansible-galaxy collection install community.general",
      "ansible-galaxy collection install cloud.common",
      "ansible-galaxy collection install community.kubernetes",
      "git clone https://github.com/tnmv/gec-config-infra.git",
      "cd gec-config-infra",
      "cp /home/ubuntu/ssh_key.pem .",
      "chmod 700 ssh_key.pem", 
      "chmod +x inventory.sh",
      "./inventory.sh",
      "ansible-playbook install.yaml"
    ]

    connection {
      host = self.public_ip
      type = "ssh"
      user = "ubuntu"
      private_key = file("ssh_key.pem")
    }
  }

  tags = {
    owner = "GEC Microservices"
    Name  = "bastion"
  }
  depends_on = [local_file.ssh_key, aws_instance.cp01, aws_instance.cp02, aws_instance.cp03]
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

variable "region1" {
    type = string
    default = "us-east-1"
}
variable "id_image" {
    type = string
    default = "ami-0261755bbcb8c4a84"
}
variable "id_vpc" {
    type = string
    default = "vpc-0dee5d356fa292024"
}
variable "id_subnet" {
    type = string
    default ="subnet-0a799f29f38d852a5"
}
variable "key_access" {
    type = string
}
variable "key_secret" {
    type = string
}
variable "instance_type" {
    type = string
    default = "t2.medium"
}