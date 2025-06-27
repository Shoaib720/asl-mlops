terraform {
  backend "s3" {
    bucket         = "terraform-test12-s3"
    key            = "env/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.0.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "test vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "public"
  }
}

resource "aws_security_group" "sg_train" {
  name   = "sg_train"
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "sg_train"
  }
}

resource "aws_vpc_security_group_ingress_rule" "allow_ssh" {
  security_group_id = aws_security_group.sg_train.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  security_group_id = aws_security_group.sg_train.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.sg_train.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
  security_group_id = aws_security_group.sg_train.id
  cidr_ipv6         = "::/0"
  ip_protocol       = "-1"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "public-rt"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_instance" "train_server" {
  ami                         = "ami-0b5ab71f6a75e8bae"
  instance_type               = "m5.xlarge"
  key_name                    = "mlops"
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.sg_train.id]
  associate_public_ip_address = true

  tags = {
    Name = "Train Server"
  }

  # Copy the training script
  provisioner "file" {
    source      = "../scripts/run_training.sh"
    destination = "/home/ubuntu/run_training.sh"
  }

  # Copy GitHub SSH private key
  provisioner "file" {
    source      = "/home/neosoft/.ssh/id_rsa"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  # Run training with proper GitHub SSH config
  provisioner "remote-exec" {
    inline = [
      "mkdir -p /home/ubuntu/.ssh",
      "chmod 700 /home/ubuntu/.ssh",
      "chmod 600 /home/ubuntu/.ssh/id_rsa",
      "ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts",
      "echo 'Host github.com\n  IdentityFile ~/.ssh/id_rsa\n  StrictHostKeyChecking no' >> /home/ubuntu/.ssh/config",
      "chmod 600 /home/ubuntu/.ssh/config",
      "chmod +x /home/ubuntu/run_training.sh",
      "sudo /home/ubuntu/run_training.sh"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("/home/neosoft/.ssh/mlops.pem")
    host        = self.public_ip
    timeout     = "5m"
  }
}
