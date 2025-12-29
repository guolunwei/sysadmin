#!/bin/bash
# This scirpt is used to extract pipeline content from config.xml <script></script> tag.

JOBS_DIR="/home/admin/jenkins/jobs"

for config in "$JOBS_DIR"/*/config.xml; do
  job_dir=$(dirname "$config")
  job_name=$(basename "$job_dir")

  script_content=$(xmllint --xpath "string(//definition/script)" "$config" 2> /dev/null)
  if [[ -n "$script_content" ]]; then
    echo "Exporting script for job: $job_name"
    echo "$script_content" > "${job_name}.groovy"
  else
    echo "No pipeline script found for $job_name"
  fi
done
