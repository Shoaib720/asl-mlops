#!/bin/bash
set -ex

chmod 600 ~/.ssh/id_rsa
ssh-keyscan github.com >> ~/.ssh/known_hosts

sudo apt update && sudo apt install -y git python3-pip

git clone --branch refactor/terraform-scripts git@github.com:Shoaib720/asl-mlops.git
cd asl-mlops

python3 -m venv .venv
source .venv/bin/activate

pip install -r requirements.txt
dvc pull

export MLFLOW_TRACKING_URI="${MLFLOW_TRACKING_URI}"
export EPOCHS="${EPOCHS}"
export ACCURACY_THRESHOLD="${ACCURACY_THRESHOLD}"

dvc repro
dvc push
