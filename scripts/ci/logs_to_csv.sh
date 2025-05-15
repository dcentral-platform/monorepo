#!/bin/bash
# logs_to_csv.sh - Converts JSON test summary to CSV report

# Check if input file is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <json_summary_file>"
  exit 1
fi

if [ ! -f "$1" ]; then
  echo "Error: File not found: $1"
  exit 1
fi

# Read JSON file
json_file="$1"

# Extract session information
session_id=$(jq -r '.session_id' "$json_file")
start_time=$(jq -r '.start_time' "$json_file")

# Output CSV header
echo "session_id,test_id,description,start_time,end_time,duration_seconds,status,message"

# Process each test and output as CSV
jq -r '.tests[] | [
  $ENV.session_id,
  .test_id,
  .description,
  .start_time,
  .end_time,
  .duration_seconds,
  .status,
  .message
] | @csv' --arg session_id "$session_id" "$json_file"