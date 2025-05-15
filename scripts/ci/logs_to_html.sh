#!/bin/bash
# logs_to_html.sh - Converts JSON test summary to HTML report

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

# Extract basic info
session_id=$(jq -r '.session_id' "$json_file")
start_time=$(jq -r '.start_time' "$json_file")
end_time=$(jq -r '.summary.end_time' "$json_file")
total_duration=$(jq -r '.summary.total_duration_seconds' "$json_file")
total_tests=$(jq -r '.summary.total_tests' "$json_file")
passed=$(jq -r '.summary.passed' "$json_file")
failed=$(jq -r '.summary.failed' "$json_file")
warnings=$(jq -r '.summary.warnings' "$json_file")
skipped=$(jq -r '.summary.skipped' "$json_file")

# Calculate pass percentage
if [ "$total_tests" -gt 0 ]; then
  pass_percent=$((passed * 100 / total_tests))
else
  pass_percent=0
fi

# Generate HTML header
cat << EOF
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>D Central Test Report - ${session_id}</title>
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
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
    }
    .summary-item {
      flex: 1;
      min-width: 200px;
      margin: 10px;
    }
    .progress-bar {
      height: 20px;
      background-color: #e0e0e0;
      border-radius: 10px;
      margin-top: 5px;
      overflow: hidden;
    }
    .progress-fill {
      height: 100%;
      background-color: #4CAF50;
      border-radius: 10px;
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
    .status {
      font-weight: bold;
    }
    .pass {
      color: #4CAF50;
    }
    .fail {
      color: #f44336;
    }
    .warn {
      color: #ff9800;
    }
    .skip {
      color: #9e9e9e;
    }
    .modal {
      display: none;
      position: fixed;
      z-index: 1;
      left: 0;
      top: 0;
      width: 100%;
      height: 100%;
      overflow: auto;
      background-color: rgba(0,0,0,0.4);
    }
    .modal-content {
      background-color: #fefefe;
      margin: 5% auto;
      padding: 20px;
      border: 1px solid #888;
      width: 80%;
      max-height: 80%;
      overflow: auto;
    }
    .close {
      color: #aaa;
      float: right;
      font-size: 28px;
      font-weight: bold;
    }
    .close:hover,
    .close:focus {
      color: black;
      text-decoration: none;
      cursor: pointer;
    }
    pre {
      background-color: #f8f8f8;
      padding: 10px;
      border-radius: 5px;
      overflow-x: auto;
    }
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
  <p>Session ID: <strong>${session_id}</strong></p>
  
  <div class="summary-box">
    <div class="summary-item">
      <h3>Test Summary</h3>
      <p>Start time: ${start_time}</p>
      <p>End time: ${end_time}</p>
      <p>Total duration: ${total_duration} seconds</p>
    </div>
    
    <div class="summary-item">
      <h3>Test Results</h3>
      <p>Total tests: ${total_tests}</p>
      <p>Passed: <span class="status pass">${passed}</span></p>
      <p>Failed: <span class="status fail">${failed}</span></p>
      <p>Warnings: <span class="status warn">${warnings}</span></p>
      <p>Skipped: <span class="status skip">${skipped}</span></p>
    </div>
    
    <div class="summary-item">
      <h3>Pass Rate: ${pass_percent}%</h3>
      <div class="progress-bar">
        <div class="progress-fill" style="width: ${pass_percent}%"></div>
      </div>
    </div>
  </div>
  
  <h2>Test Details</h2>
  <table>
    <thead>
      <tr>
        <th>Test ID</th>
        <th>Description</th>
        <th>Duration</th>
        <th>Status</th>
        <th>Details</th>
      </tr>
    </thead>
    <tbody>
EOF

# Generate test rows
jq -c '.tests[]' "$json_file" | while read -r test; do
  test_id=$(echo "$test" | jq -r '.test_id')
  description=$(echo "$test" | jq -r '.description')
  duration=$(echo "$test" | jq -r '.duration_seconds')
  status=$(echo "$test" | jq -r '.status')
  message=$(echo "$test" | jq -r '.message')
  
  # Determine the week (assuming test IDs start with W1-, W2-, etc.)
  week=$(echo "$test_id" | grep -o "W[0-9]" | tr -d 'W')
  
  # Set status class
  status_class=""
  case "$status" in
    "pass") status_class="pass" ;;
    "fail") status_class="fail" ;;
    "warn") status_class="warn" ;;
    "skip") status_class="skip" ;;
  esac
  
  cat << EOF
      <tr>
        <td><span class="badge week${week}">${test_id}</span></td>
        <td>${description}</td>
        <td>${duration}s</td>
        <td class="status ${status_class}">${status}</td>
        <td>${message}</td>
      </tr>
EOF
done

# Generate HTML footer
cat << EOF
    </tbody>
  </table>
  
  <script>
    // JavaScript for modal dialogs if needed
    function showDetails(testId) {
      const modal = document.getElementById('modal-' + testId);
      if (modal) modal.style.display = "block";
    }
    
    function closeModal(testId) {
      const modal = document.getElementById('modal-' + testId);
      if (modal) modal.style.display = "none";
    }
    
    // Close modal when clicking outside
    window.onclick = function(event) {
      if (event.target.classList.contains('modal')) {
        event.target.style.display = "none";
      }
    }
  </script>
</body>
</html>
EOF