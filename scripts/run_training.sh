#!/bin/bash

echo " EC2 setup started..."

# 1. Update & install system dependencies
sudo apt update -y
sudo apt install -y python3 python3-pip git

# 2. Clone your private GitHub repo via SSH
git clone git@github.com:Shoaib720/asl-mlops.git
cd asl-mlops

# 3. Setup virtual environment
pip3 install virtualenv
virtualenv .venv
source .venv/bin/activate

# 4. Install Python dependencies
pip install -r requirements.txt
pip install dvc[s3]

# 5. DVC pull and pipeline run
dvc pull
dvc repro

echo "All done. Training complete."
