#!/bin/bash
# simple_report.sh - Generate a basic HTML report without dependencies

if [ $# -ne 1 ]; then
  echo "Usage: $0 <json_summary_file>"
  exit 1
fi

json_file="$1"

cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>D Central Test Report</title>
  <style>
    body {
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
      line-height: 1.6;
      color: #333;
      max-width: 1200px;
      margin: 0 auto;
      padding: 20px;
    }
    h1, h2, h3 {
      color: #0066cc;
    }
    .summary-box {
      background-color: #f5f5f5;
      border-radius: 5px;
      padding: 15px;
      margin-bottom: 20px;
    }
    table {
      width: 100%;
      border-collapse: collapse;
      margin: 20px 0;
    }
    th, td {
      padding: 12px 15px;
      text-align: left;
      border-bottom: 1px solid #ddd;
    }
    thead {
      background-color: #f8f8f8;
    }
    tr:hover {
      background-color: #f5f5f5;
    }
    .pass { color: #4CAF50; }
    .fail { color: #f44336; }
    .warn { color: #ff9800; }
    .skip { color: #9e9e9e; }
    .badge {
      display: inline-block;
      padding: 3px 8px;
      border-radius: 12px;
      font-size: 12px;
      font-weight: bold;
      color: white;
    }
    .week1 { background-color: #3498db; }
    .week2 { background-color: #9b59b6; }
    .week3 { background-color: #2ecc71; }
  </style>
</head>
<body>
  <h1>D Central Test Report</h1>
  
  <div class="summary-box">
    <h2>Test Results</h2>
    <p>This report shows the results of running the D Central test suite.</p>
    <p>The tests verify that all components of the project comply with the defined standards and requirements.</p>
  </div>
  
  <h2>Test Details</h2>
  <table>
    <thead>
      <tr>
        <th>Test ID</th>
        <th>Description</th>
        <th>Status</th>
        <th>Details</th>
      </tr>
    </thead>
    <tbody>
EOF

# Extract tests from the JSON file using grep and sed
# This is a simplistic approach and not as robust as using jq
grep -A 7 '"test_id":' "$json_file" | while read -r line; do
  if [[ "$line" == *"test_id"* ]]; then
    test_id=$(echo "$line" | sed 's/.*"test_id": "\([^"]*\)".*/\1/')
    week=$(echo "$test_id" | grep -o "W[0-9]" | tr -d 'W')
    echo "      <tr>"
    echo "        <td><span class=\"badge week$week\">$test_id</span></td>"
  elif [[ "$line" == *"description"* ]]; then
    description=$(echo "$line" | sed 's/.*"description": "\([^"]*\)".*/\1/')
    echo "        <td>$description</td>"
  elif [[ "$line" == *"status"* ]]; then
    status=$(echo "$line" | sed 's/.*"status": "\([^"]*\)".*/\1/')
    echo "        <td class=\"$status\">$status</td>"
  elif [[ "$line" == *"message"* ]]; then
    message=$(echo "$line" | sed 's/.*"message": "\([^"]*\)".*/\1/')
    echo "        <td>$message</td>"
    echo "      </tr>"
  fi
done

# Extract summary information
passed=$(grep -o '"passed": [0-9]*' "$json_file" | grep -o '[0-9]*')
failed=$(grep -o '"failed": [0-9]*' "$json_file" | grep -o '[0-9]*')
warnings=$(grep -o '"warnings": [0-9]*' "$json_file" | grep -o '[0-9]*')
skipped=$(grep -o '"skipped": [0-9]*' "$json_file" | grep -o '[0-9]*')
total=$(grep -o '"total_tests": [0-9]*' "$json_file" | grep -o '[0-9]*')

cat << EOF
    </tbody>
  </table>
  
  <div class="summary-box">
    <h2>Summary</h2>
    <p>Total Tests: <strong>$total</strong></p>
    <p>Passed: <strong class="pass">$passed</strong></p>
    <p>Failed: <strong class="fail">$failed</strong></p>
    <p>Warnings: <strong class="warn">$warnings</strong></p>
    <p>Skipped: <strong class="skip">$skipped</strong></p>
  </div>
  
  <footer>
    <p>Generated on $(date)</p>
  </footer>
</body>
</html>
EOF