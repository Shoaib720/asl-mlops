#!/bin/bash

echo " EC2 setup started..."

# 1. Update & install system dependencies
sudo apt update -y
sudo apt install -y python3 python3-pip git

# 2. Prepare SSH for GitHub access
mkdir -p /home/ubuntu/.ssh
chmod 700 /home/ubuntu/.ssh
chmod 600 /home/ubuntu/.ssh/id_rsa
ssh-keyscan github.com >> /home/ubuntu/.ssh/known_hosts

#  Use SSH key while cloning GitHub repo
export GIT_SSH_COMMAND='ssh -i /home/ubuntu/.ssh/id_rsa -o StrictHostKeyChecking=no'

# 3. Clone your private GitHub repo via SSH
git clone git@github.com:Shoaib720/asl-mlops.git
cd asl-mlops
git checkout feature/bts-13-terraform

# 4. Setup Python virtual environment
pip3 install virtualenv
virtualenv .venv
source .venv/bin/activate

# 5. Install Python dependencies
pip install -r requirements.txt
pip install dvc[s3]

# 6. DVC pull and pipeline run
dvc pull
dvc repro

echo "All done. Training complete."
