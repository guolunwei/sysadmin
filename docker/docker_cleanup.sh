#!/bin/bash
# This script is used to clean up docker build cache.

KEEP="168h"

echo "[INFO] Begin to clean up docker build cache..."
docker buildx prune -f --filter "until=$KEEP"

echo "[INFO] Clean up complete. Current disk usage:"
docker buildx du
