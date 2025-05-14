#!/usr/bin/env python3
"""
DCentral Project Verification Tool

This script performs comprehensive verification of all project components
from Weeks 1-3, testing file existence, content quality, and validating
various file formats (JSON, SVG, YAML, etc.).

It generates both console output and an HTML report.
"""

import os
import sys
import json
import re
import subprocess
import datetime
import glob
from pathlib import Path

# Configuration
PROJECT_ROOT = subprocess.getoutput("git rev-parse --show-toplevel")
REPORT_FILE = os.path.join(PROJECT_ROOT, "verification_report.html")

# Define color codes for terminal output
GREEN = "\033[0;32m"
YELLOW = "\033[1;33m"
RED = "\033[0;31m"
BLUE = "\033[0;34m"
NC = "\033[0m"  # No Color

# Test result counters
total_tests = 0
passed_tests = 0
warning_tests = 0
failed_tests = 0

# Test results for reporting
test_results = []

def print_header(text):
    """Print a formatted header."""
    print(f"\n{BLUE}▶ {text}{NC}")

def print_result(status, message, details=""):
    """Print a colored test result."""
    global total_tests, passed_tests, warning_tests, failed_tests
    total_tests += 1
    
    if status == "PASS":
        passed_tests += 1
        color = GREEN
        symbol = "✓"
    elif status == "WARN":
        warning_tests += 1
        color = YELLOW
        symbol = "⚠"
    else:  # FAIL
        failed_tests += 1
        color = RED
        symbol = "✗"
    
    print(f"{color}{symbol} {message}{NC}")
    if details:
        print(f"  └─ {details}")
    
    # Save for report
    test_results.append({
        "status": status,
        "message": message,
        "details": details
    })

def check_file_exists(filepath):
    """Check if file exists and return appropriate result."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if os.path.isfile(path):
        print_result("PASS", f"File exists: {filepath}")
        return True
    else:
        print_result("FAIL", f"File missing: {filepath}")
        return False

def check_dir_exists(dirpath):
    """Check if directory exists and return appropriate result."""
    path = os.path.join(PROJECT_ROOT, dirpath)
    if os.path.isdir(path):
        print_result("PASS", f"Directory exists: {dirpath}")
        return True
    else:
        print_result("FAIL", f"Directory missing: {dirpath}")
        return False

def check_file_content(filepath, expected_content):
    """Check if file contains expected content (case-insensitive)."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot check content - file missing: {filepath}")
        return False

    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()

        # Case-insensitive search and handle Unicode variations
        content_lower = content.lower()
        expected_lower = expected_content.lower()

        # Normalize some common Unicode variations
        content_normalized = content_lower.replace('‑', '-').replace('—', '-').replace('·', ' ').replace('\u00a0', ' ')

        if expected_lower in content_normalized:
            print_result("PASS", f"Content verified in: {filepath}", f"Found (case-insensitive): '{expected_content}'")
            return True
        else:
            print_result("FAIL", f"Content missing from: {filepath}", f"Expected (case-insensitive): '{expected_content}'")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading file {filepath}", str(e))
        return False

def check_file_size(filepath, min_size):
    """Check if file size is at least min_size bytes."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot check size - file missing: {filepath}")
        return False
    
    try:
        size = os.path.getsize(path)
        if size >= min_size:
            print_result("PASS", f"File size adequate: {filepath}", f"{size} bytes (>= {min_size})")
            return True
        else:
            print_result("WARN", f"File too small: {filepath}", f"{size} bytes (expected >= {min_size})")
            return False
    except Exception as e:
        print_result("FAIL", f"Error checking file size for {filepath}", str(e))
        return False

def check_json_valid(filepath):
    """Check if file is valid JSON."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate JSON - file missing: {filepath}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            json.load(f)
        print_result("PASS", f"Valid JSON: {filepath}")
        return True
    except json.JSONDecodeError as e:
        print_result("FAIL", f"Invalid JSON: {filepath}", str(e))
        return False
    except Exception as e:
        print_result("FAIL", f"Error reading JSON file {filepath}", str(e))
        return False

def check_svg_valid(filepath):
    """Check if file is a valid SVG with opening and closing tags."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate SVG - file missing: {filepath}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if re.search(r'<svg.*?</svg>', content, re.DOTALL):
            print_result("PASS", f"Valid SVG: {filepath}")
            return True
        else:
            print_result("FAIL", f"Invalid SVG: {filepath}", "Missing <svg> or </svg> tags")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading SVG file {filepath}", str(e))
        return False

def check_go_file(filepath):
    """Check if Go file has valid syntax."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate Go file - file missing: {filepath}")
        return False
    
    try:
        # Only check syntax, don't actually build
        result = subprocess.run(
            ["go", "vet", path],
            capture_output=True,
            text=True,
            cwd=os.path.dirname(path)
        )
        
        if result.returncode == 0:
            print_result("PASS", f"Valid Go file: {filepath}")
            return True
        else:
            print_result("FAIL", f"Invalid Go file: {filepath}", result.stderr.strip())
            return False
    except Exception as e:
        print_result("WARN", f"Could not validate Go file {filepath}", str(e))
        return False

def check_dockerfile(filepath):
    """Check if Dockerfile has essential instructions."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate Dockerfile - file missing: {filepath}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check for essential Dockerfile instructions
        has_from = bool(re.search(r'^FROM\s+', content, re.MULTILINE))
        has_workdir = bool(re.search(r'^WORKDIR\s+', content, re.MULTILINE))
        has_cmd = bool(re.search(r'^CMD\s+|^ENTRYPOINT\s+', content, re.MULTILINE))
        
        if has_from and has_workdir and has_cmd:
            print_result("PASS", f"Valid Dockerfile: {filepath}")
            return True
        else:
            missing = []
            if not has_from: missing.append("FROM")
            if not has_workdir: missing.append("WORKDIR")
            if not has_cmd: missing.append("CMD/ENTRYPOINT")
            
            print_result("WARN", f"Dockerfile may be incomplete: {filepath}", 
                         f"Missing instructions: {', '.join(missing)}")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading Dockerfile {filepath}", str(e))
        return False

def check_github_workflow(filepath):
    """Check if GitHub workflow YAML has essential sections."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate workflow - file missing: {filepath}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        has_name = bool(re.search(r'^name:', content, re.MULTILINE))
        has_on = bool(re.search(r'^on:', content, re.MULTILINE))
        has_jobs = bool(re.search(r'^jobs:', content, re.MULTILINE))
        has_runs_on = "runs-on:" in content
        
        if has_name and has_on and has_jobs and has_runs_on:
            print_result("PASS", f"Valid GitHub workflow: {filepath}")
            return True
        else:
            missing = []
            if not has_name: missing.append("name")
            if not has_on: missing.append("on")
            if not has_jobs: missing.append("jobs")
            if not has_runs_on: missing.append("runs-on")
            
            print_result("WARN", f"GitHub workflow may be incomplete: {filepath}", 
                         f"Missing sections: {', '.join(missing)}")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading workflow file {filepath}", str(e))
        return False

def check_yaml_file(filepath):
    """Basic check for YAML file validity."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate YAML - file missing: {filepath}")
        return False
    
    try:
        # We'll do a very basic check here - proper YAML validation would require a YAML parser
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        if ":" in content and not content.strip().startswith("<"):
            print_result("PASS", f"YAML file appears valid: {filepath}")
            return True
        else:
            print_result("WARN", f"YAML file may be invalid: {filepath}")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading YAML file {filepath}", str(e))
        return False

def check_markdown_structure(filepath):
    """Check if Markdown file has proper headings structure."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot check Markdown - file missing: {filepath}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check for headings
        has_h1 = bool(re.search(r'^# ', content, re.MULTILINE))
        has_subheadings = bool(re.search(r'^## ', content, re.MULTILINE))
        
        if has_h1 and has_subheadings:
            print_result("PASS", f"Markdown structure valid: {filepath}")
            return True
        elif has_h1:
            print_result("WARN", f"Markdown missing subheadings: {filepath}")
            return False
        else:
            print_result("WARN", f"Markdown missing main heading: {filepath}")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading Markdown file {filepath}", str(e))
        return False

def check_js_file(filepath):
    """Basic check for JavaScript file validity."""
    path = os.path.join(PROJECT_ROOT, filepath)
    if not os.path.isfile(path):
        print_result("FAIL", f"Cannot validate JS - file missing: {filepath}")
        return False
    
    try:
        with open(path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        # Check if file has common JS patterns
        has_imports = bool(re.search(r'import|require|export', content))
        has_functions = bool(re.search(r'function|=>|\{|\}', content))
        
        if has_imports and has_functions:
            print_result("PASS", f"JS file appears valid: {filepath}")
            return True
        else:
            print_result("WARN", f"JS file may be incomplete: {filepath}")
            return False
    except Exception as e:
        print_result("FAIL", f"Error reading JS file {filepath}", str(e))
        return False

def generate_html_report():
    """Generate an HTML report of test results."""
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    pass_percentage = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
    
    # Group tests by category/section
    sections = {}
    current_section = "General"
    
    for result in test_results:
        message = result["message"]
        
        # Use the message to determine the section
        if "Week 1" in message:
            current_section = "Week 1"
        elif "Week 2" in message:
            current_section = "Week 2"
        elif "Week 3" in message:
            current_section = "Week 3"
        elif "File exists:" in message or "Directory exists:" in message:
            if "/legal/" in message:
                current_section = "Legal Documents"
            elif "/.github/" in message:
                current_section = "GitHub Workflows"
            elif "/design/" in message:
                current_section = "Design System"
            elif "/code/edge-gateway" in message:
                current_section = "Edge Gateway"
            elif "/code/helm" in message:
                current_section = "Kubernetes"
            elif "/code/tests" in message:
                current_section = "Testing"
                
        if current_section not in sections:
            sections[current_section] = []
            
        sections[current_section].append(result)
    
    # HTML template
    html = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>DCentral Project Verification Report</title>
    <style>
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1100px;
            margin: 0 auto;
            padding: 20px;
        }}
        h1, h2, h3 {{
            color: #0284C7;
        }}
        .summary {{
            background-color: #f8fafc;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 30px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.1);
        }}
        .progress-bar {{
            height: 20px;
            background-color: #e2e8f0;
            border-radius: 10px;
            margin: 10px 0 20px 0;
            overflow: hidden;
        }}
        .progress {{
            height: 100%;
            background: linear-gradient(to right, #0284C7, #6366F1);
            width: {pass_percentage}%;
            border-radius: 10px;
        }}
        .stats {{
            display: flex;
            justify-content: space-between;
            flex-wrap: wrap;
            gap: 10px;
            margin-bottom: 20px;
        }}
        .stat-box {{
            flex: 1;
            min-width: 200px;
            background: white;
            padding: 15px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
            text-align: center;
        }}
        .pass {{ color: #10B981; }}
        .warn {{ color: #F59E0B; }}
        .fail {{ color: #EF4444; }}
        .stat-number {{
            font-size: 2em;
            font-weight: bold;
            margin: 5px 0;
        }}
        .section {{
            margin-bottom: 30px;
            background: white;
            border-radius: 8px;
            padding: 20px;
            box-shadow: 0 2px 5px rgba(0,0,0,0.05);
        }}
        table {{
            width: 100%;
            border-collapse: collapse;
        }}
        th, td {{
            padding: 12px;
            text-align: left;
            border-bottom: 1px solid #e2e8f0;
        }}
        th {{
            background-color: #f1f5f9;
            font-weight: 600;
        }}
        tr:hover {{
            background-color: #f8fafc;
        }}
        .status-icon {{
            font-size: 1.2em;
        }}
        .details {{
            color: #6b7280;
            font-size: 0.9em;
        }}
        @media (max-width: 768px) {{
            .stat-box {{
                min-width: 100%;
            }}
        }}
    </style>
</head>
<body>
    <h1>DCentral Project Verification Report</h1>
    <p>Report generated on {now}</p>
    
    <div class="summary">
        <h2>Summary</h2>
        <div class="progress-bar">
            <div class="progress"></div>
        </div>
        <p><strong>{pass_percentage:.1f}%</strong> of tests passed successfully</p>
        
        <div class="stats">
            <div class="stat-box">
                <div>Total Tests</div>
                <div class="stat-number">{total_tests}</div>
            </div>
            <div class="stat-box">
                <div>Passed</div>
                <div class="stat-number pass">{passed_tests}</div>
            </div>
            <div class="stat-box">
                <div>Warnings</div>
                <div class="stat-number warn">{warning_tests}</div>
            </div>
            <div class="stat-box">
                <div>Failed</div>
                <div class="stat-number fail">{failed_tests}</div>
            </div>
        </div>
    </div>
"""

    # Add each section to the report
    for section_name, section_results in sections.items():
        passed_in_section = sum(1 for r in section_results if r["status"] == "PASS")
        total_in_section = len(section_results)
        section_percentage = (passed_in_section / total_in_section) * 100 if total_in_section > 0 else 0
        
        html += f"""
    <div class="section">
        <h2>{section_name}</h2>
        <p>{passed_in_section} of {total_in_section} tests passed ({section_percentage:.1f}%)</p>
        
        <table>
            <thead>
                <tr>
                    <th style="width: 60px">Status</th>
                    <th>Description</th>
                    <th>Details</th>
                </tr>
            </thead>
            <tbody>
"""
        
        for result in section_results:
            status_class = {
                "PASS": "pass",
                "WARN": "warn",
                "FAIL": "fail"
            }.get(result["status"], "")
            
            status_icon = {
                "PASS": "✓",
                "WARN": "⚠",
                "FAIL": "✗"
            }.get(result["status"], "")
            
            html += f"""
                <tr>
                    <td class="{status_class} status-icon">{status_icon}</td>
                    <td>{result["message"]}</td>
                    <td class="details">{result["details"]}</td>
                </tr>
"""
        
        html += """
            </tbody>
        </table>
    </div>
"""
    
    # Close HTML tags
    html += """
    <p><em>Note: This report was generated automatically by the DCentral Project Verification Tool.</em></p>
</body>
</html>
"""
    
    # Write to file
    with open(REPORT_FILE, 'w', encoding='utf-8') as f:
        f.write(html)
    
    print(f"\nHTML report generated: {REPORT_FILE}")
    return REPORT_FILE

def run_tests():
    """Run all verification tests for the DCentral project."""
    os.chdir(PROJECT_ROOT)
    
    print(f"{BLUE}=================================={NC}")
    print(f"{BLUE}= DCentral Project Verification ={NC}")
    print(f"{BLUE}=        Weeks 1-3 Check        ={NC}")
    print(f"{BLUE}=================================={NC}")
    
    # ===== WEEK 1 TESTS =====
    print_header("Checking Week 1: Repository Setup and Legal Documents")
    
    # Basic repository checks
    check_dir_exists(".git")
    check_file_exists("README.md")
    check_file_size("README.md", 100)
    check_markdown_structure("README.md")
    
    # Legal documents
    check_file_exists("legal/mutual-nda_v1.0.md")
    check_file_content("legal/mutual-nda_v1.0.md", "Ontario law")
    check_file_content("legal/mutual-nda_v1.0.md", "2-year term")
    check_file_size("legal/mutual-nda_v1.0.md", 500)
    check_markdown_structure("legal/mutual-nda_v1.0.md")

    check_file_exists("legal/revenue-share-warrant_v1.md")
    check_file_content("legal/revenue-share-warrant_v1.md", "Revenue-Share %") # Using the table header format
    check_file_content("legal/revenue-share-warrant_v1.md", "Revenue") # Checking for general revenue-related content
    check_file_size("legal/revenue-share-warrant_v1.md", 500)
    check_markdown_structure("legal/revenue-share-warrant_v1.md")
    
    # GitHub remote check
    try:
        remotes = subprocess.getoutput("git remote -v")
        if "github" in remotes.lower():
            print_result("PASS", "GitHub remote exists")
        else:
            print_result("FAIL", "GitHub remote not found")
    except Exception as e:
        print_result("FAIL", "Error checking git remotes", str(e))
    
    # LICENSE files
    check_file_exists("LICENSE.md")
    check_file_exists("LICENSE.txt")
    check_file_content("LICENSE.md", "GPL")
    check_file_content("LICENSE.md", "CC BY")
    check_file_size("LICENSE.md", 200)
    check_markdown_structure("LICENSE.md")
    
    # Privacy Notice
    check_file_exists("legal/privacy-notice_v1.0.md")
    check_file_content("legal/privacy-notice_v1.0.md", "GDPR")
    check_file_content("legal/privacy-notice_v1.0.md", "PIPEDA")
    check_file_size("legal/privacy-notice_v1.0.md", 1000)
    check_markdown_structure("legal/privacy-notice_v1.0.md")
    
    # GitHub Actions
    check_file_exists(".github/workflows/build.yml")
    check_github_workflow(".github/workflows/build.yml")
    check_file_exists(".github/workflows/security.yml")
    check_github_workflow(".github/workflows/security.yml")
    
    # Folder Structure
    for directory in [
        "code", "design", "docs", "legal", "scripts", 
        "scripts/roadmap", "community", "compliance", 
        "data-room", "finance", "governance", "marketing",
        "mobile", "pop-assets", "supply-chain", "support"
    ]:
        check_dir_exists(directory)
    
    check_file_exists("scripts/roadmap/tasks.yaml")
    check_yaml_file("scripts/roadmap/tasks.yaml")
    check_file_size("scripts/roadmap/tasks.yaml", 1000)
    
    # ===== WEEK 2 TESTS =====
    print_header("Checking Week 2: Design System Implementation")
    
    # Logo files
    check_dir_exists("design/logo/renders")
    logo_renders = glob.glob(os.path.join(PROJECT_ROOT, "design/logo/renders", "*.png"))
    if logo_renders:
        print_result("PASS", f"Found {len(logo_renders)} logo render files", 
                    f"Files: {', '.join(os.path.basename(f) for f in logo_renders)}")
    else:
        print_result("FAIL", "No logo render files found in design/logo/renders")
    
    check_dir_exists("design/logo/static")
    check_svg_valid("design/logo/static/dcentral-logo-primary.svg")
    check_file_exists("design/logo/static/dcentral-logo-simple.svg")
    check_svg_valid("design/logo/static/dcentral-logo-simple.svg")
    
    # Design tokens
    check_file_exists("design/palette-tokens/design-tokens.json")
    check_json_valid("design/palette-tokens/design-tokens.json")
    check_file_content("design/palette-tokens/design-tokens.json", "colors")
    check_file_content("design/palette-tokens/design-tokens.json", "primary")
    check_file_content("design/palette-tokens/design-tokens.json", "secondary")
    
    # Tailwind config
    check_file_exists("design/tailwind.config.js")
    check_file_content("design/tailwind.config.js", "module.exports")
    check_file_content("design/tailwind.config.js", "theme")
    check_file_content("design/tailwind.config.js", "colors")
    
    # Global CSS
    check_file_exists("design/global.css")
    check_file_content("design/global.css", "@tailwind")
    
    # Storybook
    check_dir_exists("design/storybook")
    check_file_exists("design/storybook/package.json")
    check_json_valid("design/storybook/package.json")
    check_file_content("design/storybook/package.json", "storybook")
    
    check_dir_exists("design/storybook/components")
    check_file_exists("design/storybook/components/Button.jsx")
    check_file_content("design/storybook/components/Button.jsx", "export const Button")
    check_file_exists("design/storybook/components/Button.stories.jsx")
    check_file_content("design/storybook/components/Button.stories.jsx", "import { Button }")
    
    # WCAG check and Brand Guide
    check_file_exists("design/figma-exports/WCAG_results.md")
    check_file_content("design/figma-exports/WCAG_results.md", "Contrast Ratio")
    check_markdown_structure("design/figma-exports/WCAG_results.md")
    
    check_file_exists("design/figma-exports/brand-guide.md")
    check_file_size("design/figma-exports/brand-guide.md", 500)
    check_markdown_structure("design/figma-exports/brand-guide.md")
    
    # ===== WEEK 3 TESTS =====
    print_header("Checking Week 3: Edge Gateway MVP")
    
    # Edge Gateway Go module
    check_dir_exists("code/edge-gateway")
    check_file_exists("code/edge-gateway/main.go")
    check_file_exists("code/edge-gateway/go.mod")
    check_file_content("code/edge-gateway/go.mod", "github.com/dcentral-platform/monorepo/edge-gateway")
    check_go_file("code/edge-gateway/main.go")
    
    # Dockerfile
    check_file_exists("code/edge-gateway/Dockerfile")
    check_dockerfile("code/edge-gateway/Dockerfile")
    check_file_content("code/edge-gateway/Dockerfile", "FROM")
    check_file_content("code/edge-gateway/Dockerfile", "bullseye")
    
    # MQTT client
    check_file_exists("code/edge-gateway/mqtt_client.go")
    check_file_content("code/edge-gateway/mqtt_client.go", "MQTTClient")
    check_file_content("code/edge-gateway/mqtt_client.go", "Connect")
    check_file_size("code/edge-gateway/mqtt_client.go", 1000)
    check_go_file("code/edge-gateway/mqtt_client.go")
    
    # Unit tests
    check_file_exists("code/edge-gateway/main_test.go")
    check_go_file("code/edge-gateway/main_test.go")
    check_file_exists("code/edge-gateway/mqtt_client_test.go")
    check_file_content("code/edge-gateway/mqtt_client_test.go", "Test")
    check_file_size("code/edge-gateway/mqtt_client_test.go", 500)
    check_go_file("code/edge-gateway/mqtt_client_test.go")
    
    # Helm chart
    check_dir_exists("code/helm/edge-gateway-chart")
    check_file_exists("code/helm/edge-gateway-chart/Chart.yaml")
    check_yaml_file("code/helm/edge-gateway-chart/Chart.yaml")
    check_file_exists("code/helm/edge-gateway-chart/values.yaml")
    check_yaml_file("code/helm/edge-gateway-chart/values.yaml")
    
    check_dir_exists("code/helm/edge-gateway-chart/templates")
    check_file_exists("code/helm/edge-gateway-chart/templates/deployment.yaml")
    check_yaml_file("code/helm/edge-gateway-chart/templates/deployment.yaml")
    check_file_content("code/helm/edge-gateway-chart/templates/deployment.yaml", "kind: Deployment")
    
    # K6 Performance test
    check_dir_exists("code/tests/perf")
    check_file_exists("code/tests/perf/edge-gateway-k6.js")
    check_file_content("code/tests/perf/edge-gateway-k6.js", "import")
    check_file_size("code/tests/perf/edge-gateway-k6.js", 500)
    check_js_file("code/tests/perf/edge-gateway-k6.js")
    
    # SBOM diff checker
    check_file_exists("scripts/ci/sbom_diff_checker.sh")
    check_file_content("scripts/ci/sbom_diff_checker.sh", "SBOM")
    check_file_size("scripts/ci/sbom_diff_checker.sh", 1000)
    
    # Check completion reports
    check_file_exists("Week1_Completion.md")
    check_markdown_structure("Week1_Completion.md")
    check_file_exists("Week2_Completion.md")
    check_markdown_structure("Week2_Completion.md")
    check_file_exists("Week3_Completion.md")
    check_markdown_structure("Week3_Completion.md")
    
    # Print summary
    print_header("Verification Summary")
    print(f"Total checks: {total_tests}")
    print(f"{GREEN}Passed: {passed_tests}{NC}")
    print(f"{YELLOW}Warnings: {warning_tests}{NC}")
    print(f"{RED}Failed: {failed_tests}{NC}")
    
    pass_percentage = (passed_tests / total_tests) * 100 if total_tests > 0 else 0
    print(f"Completion rate: {pass_percentage:.1f}%")
    
    # Generate report
    report_path = generate_html_report()
    print(f"HTML report generated: {report_path}")
    
    if failed_tests == 0 and warning_tests == 0:
        print(f"\n{GREEN}✅ All verification checks passed successfully!{NC}")
        return 0
    elif failed_tests == 0 and warning_tests > 0:
        print(f"\n{YELLOW}⚠️ Verification completed with warnings. Please review.{NC}")
        return 0
    else:
        print(f"\n{RED}❌ Verification failed. Please fix the issues listed above.{NC}")
        return 1

if __name__ == "__main__":
    try:
        exit_code = run_tests()
        sys.exit(exit_code)
    except KeyboardInterrupt:
        print("\nVerification interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n{RED}Error during verification: {str(e)}{NC}")
        sys.exit(1)