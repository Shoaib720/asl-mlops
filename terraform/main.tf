# Create AWS Key Pair using generated public key
resource "aws_key_pair" "gpu_key" {
  key_name   = "gpu-key"
  # public_key = file("~/.ssh/mlops-kp.pub")
  public_key = file("${path.module}/mlops-kp.pub")
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
  instance_type               = "g4dn.xlarge"
  key_name                    = aws_key_pair.gpu_key.key_name
  security_groups        = [aws_security_group.allow_ssh.name]
  iam_instance_profile   = aws_iam_instance_profile.dvc_instance_profile.name
  instance_market_options {
    market_type = "spot"
    spot_options {
      instance_interruption_behavior = "terminate"
      max_price                      = "0.17" # adjust based on region
    }
  }

  tags = {
    Name = "train-server-gpu-spot"
  }

  provisioner "file" {
    source      = "${path.module}/train_server_github_rsa"
    destination = "/home/ubuntu/.ssh/id_rsa"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.ssh/id_rsa",
      "echo 'Host github.com\n\tStrictHostKeyChecking no\n' >> /home/ubuntu/.ssh/config",

      "sudo apt update && sudo apt install -y git python3-pip",

      "git clone --branch refactor/terraform+scripts git@github.com:Shoaib720/asl-mlops.git",
      "cd asl-mlops",

      "python3 -m venv .venv",
      "source .venv/bin/activate",

      "pip install -r requirements.txt",

      "dvc pull",

      # "export MLFLOW_TRACKING_URI=http://your-mlflow-server:5000"
      "export MLFLOW_TRACKING_URI='${var.mlflow_tracking_uri}'",
      "export EPOCHS='${var.epochs}'"

      "dvc repro"
    ]
  }

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = file("${path.module}/mlops-kp")  # your AWS EC2 key for SSH
    host        = self.public_ip
  }
}

# resource "aws_instance" "mseries_spot" {
#   ami                         = "ami-05017f1c00f77723b"
#   instance_type               = "m5.xlarge" 
#   key_name                    = aws_key_pair.gpu_key.key_name
#   iam_instance_profile   = aws_iam_instance_profile.dvc_instance_profile.name
#   security_groups        = [aws_security_group.allow_ssh.name]
#   instance_market_options {
#     market_type = "spot"
#     spot_options {
#       instance_interruption_behavior = "terminate"
#       max_price                      = "0.07" # adjust based on region
#     }
#   }
#   provisioner "file" {
#     source      = "${path.module}/train_server_github_rsa"
#     destination = "/home/ubuntu/.ssh/id_rsa"
#   }

#   provisioner "remote-exec" {
#     inline = [
#       "chmod 600 /home/ubuntu/.ssh/id_rsa",
#       "echo 'Host github.com\n\tStrictHostKeyChecking no\n' >> /home/ubuntu/.ssh/config",

#       "sudo apt update && sudo apt install -y git python3-pip",

#       "git clone git@github.com:Shoaib720/asl-mlops.git",
#       "cd asl-mlops",

#       "python3 -m venv .venv",
#       "source .venv/bin/activate",

#       "pip install -r requirements.txt",

#       "dvc pull",

#       # "export MLFLOW_TRACKING_URI=http://your-mlflow-server:5000"
#       "export MLFLOW_TRACKING_URI='${var.mlflow_tracking_uri}'",
#       "export EPOCHS='${var.epochs}'"

#       "python scripts/train.py"
#     ]
#   }

#   connection {
#     type        = "ssh"
#     user        = "ubuntu"
#     private_key = file("${path.module}/mlops-kp")  # your AWS EC2 key for SSH
#     host        = self.public_ip
#   }
# }