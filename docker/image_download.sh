#!/bin/bash
# Pull an image and save it to a tarball
set -e

IMAGE=$1
NAME=${IMAGE##*/}
NAME=${NAME/:/_}
IMAGE_DIR=/home/admin/images

if [ -z "$IMAGE" ]; then
  echo "Usage: $0 <image>"
  exit 1
fi

docker pull $IMAGE
echo "Saving to $IMAGE_DIR/$NAME.tar.gz"
docker save $IMAGE | gzip > $IMAGE_DIR/$NAME.tar.gz
docker rmi $IMAGE
