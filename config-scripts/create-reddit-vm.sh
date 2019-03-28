#!/bin/bash
set -e

# generating random id
id=$(date +'%Y%m%d%H%M%S')$RANDOM
gcloud compute instances create reddit-app-$id --image-family=reddit-full --machine-type=f1-micro --tags=puma-server
