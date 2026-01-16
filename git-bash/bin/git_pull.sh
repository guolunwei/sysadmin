#!/bin/bash

set -e

PROJECT_DIR=/d/Downloads/projects

find $PROJECT_DIR -maxdepth 1 -mindepth 1 -type d | while read -r project; do
  echo -e "\nProcessing $project"
  cd "$project"
  git pull
  cd - > /dev/null
done
