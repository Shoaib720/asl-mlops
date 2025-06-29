# Create AWS Key Pair using generated public key
resource "aws_key_pair" "gpu_key" {
  key_name   = "gpu-key"
  public_key = file("~/.ssh/id_rsa.pub")
  # public_key = file("${path.module}/mlops-kp.pub")
}

resource "aws_security_group" "allow_ssh" {
  name        = "allow_ssh"
  description = "Allow SSH access"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # WARNING: Open to all
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Spot GPU EC2 instance
resource "aws_instance" "gpu_spot" {
  ami                         = "ami-05017f1c00f77723b"
  instance_type               = "g4dn.2xlarge"
  key_name                    = aws_key_pair.gpu_key.key_name
  security_groups        = [aws_security_group.allow_ssh.name]
  iam_instance_profile   = aws_iam_instance_profile.dvc_instance_profile.name
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      max_price                      = "0.26" # adjust based on region
    }
  }

  tags = {
    Name = "train-server-gpu-spot"
  }

  provisioner "file" {
    # source      = "${path.module}/train_server_github_rsa"
    source      = "~/.ssh/train_server_github_rsa"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("~/.ssh/id_rsa")
    host        = self.public_ip
  }
}