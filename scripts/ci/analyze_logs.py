#!/usr/bin/env python3
"""
Log Analysis Tool for D Central Test Suite

This script analyzes test logs to provide insights, trends, and summaries.
It can process individual log files or directories containing multiple logs.
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime
import matplotlib.pyplot as plt
from collections import defaultdict, Counter


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Analyze D Central test logs")
    parser.add_argument("path", help="Path to log file or directory")
    parser.add_argument("--output", "-o", help="Output directory for reports", default="log_analysis")
    parser.add_argument("--format", "-f", choices=["text", "json", "html", "all"], 
                        default="text", help="Output format")
    parser.add_argument("--trends", "-t", action="store_true", 
                        help="Generate trend analysis across multiple runs")
    parser.add_argument("--verbose", "-v", action="store_true", 
                        help="Enable verbose output")
    return parser.parse_args()


def find_json_summary_files(path):
    """Find all JSON summary files in the given path."""
    if os.path.isdir(path):
        json_files = []
        for root, _, files in os.walk(path):
            for file in files:
                if file.startswith("test_summary_") and file.endswith(".json"):
                    json_files.append(os.path.join(root, file))
        return json_files
    elif os.path.isfile(path) and path.endswith(".json"):
        return [path]
    else:
        raise ValueError(f"Path is not a directory or JSON file: {path}")


def load_json_summary(file_path):
    """Load a JSON summary file."""
    try:
        with open(file_path, 'r') as f:
            return json.load(f)
    except json.JSONDecodeError:
        print(f"Error: Invalid JSON in {file_path}")
        return None
    except Exception as e:
        print(f"Error loading {file_path}: {e}")
        return None


def analyze_single_run(summary):
    """Analyze a single test run."""
    if not summary:
        return None
    
    # Basic metrics
    test_count = summary.get('summary', {}).get('total_tests', 0)
    pass_count = summary.get('summary', {}).get('passed', 0)
    fail_count = summary.get('summary', {}).get('failed', 0)
    warn_count = summary.get('summary', {}).get('warnings', 0)
    skip_count = summary.get('summary', {}).get('skipped', 0)
    
    # Pass rate
    pass_rate = (pass_count / test_count * 100) if test_count > 0 else 0
    
    # Test duration statistics
    durations = [test.get('duration_seconds', 0) for test in summary.get('tests', [])]
    avg_duration = sum(durations) / len(durations) if durations else 0
    max_duration = max(durations) if durations else 0
    min_duration = min(durations) if durations else 0
    
    # Failed tests
    failed_tests = [
        {
            'test_id': test.get('test_id'),
            'description': test.get('description'),
            'message': test.get('message')
        }
        for test in summary.get('tests', [])
        if test.get('status') == 'fail'
    ]
    
    # Tests by week
    tests_by_week = defaultdict(list)
    for test in summary.get('tests', []):
        test_id = test.get('test_id', '')
        week_match = re.match(r'W(\d+)-', test_id)
        if week_match:
            week = int(week_match.group(1))
            tests_by_week[week].append(test)
    
    # Week pass rates
    week_stats = {}
    for week, tests in tests_by_week.items():
        week_test_count = len(tests)
        week_pass_count = sum(1 for test in tests if test.get('status') == 'pass')
        week_fail_count = sum(1 for test in tests if test.get('status') == 'fail')
        week_warn_count = sum(1 for test in tests if test.get('status') == 'warn')
        week_pass_rate = (week_pass_count / week_test_count * 100) if week_test_count > 0 else 0
        
        week_stats[week] = {
            'test_count': week_test_count,
            'pass_count': week_pass_count,
            'fail_count': week_fail_count,
            'warn_count': week_warn_count,
            'pass_rate': week_pass_rate
        }
    
    return {
        'session_id': summary.get('session_id'),
        'start_time': summary.get('start_time'),
        'end_time': summary.get('summary', {}).get('end_time'),
        'total_duration': summary.get('summary', {}).get('total_duration_seconds'),
        'test_count': test_count,
        'pass_count': pass_count,
        'fail_count': fail_count,
        'warn_count': warn_count,
        'skip_count': skip_count,
        'pass_rate': pass_rate,
        'avg_duration': avg_duration,
        'max_duration': max_duration,
        'min_duration': min_duration,
        'failed_tests': failed_tests,
        'week_stats': week_stats
    }


def analyze_trends(analyses):
    """Analyze trends across multiple test runs."""
    if not analyses:
        return None
    
    # Sort analyses by start time
    analyses.sort(key=lambda a: datetime.strptime(a['start_time'], "%Y-%m-%d %H:%M:%S"))
    
    # Track metrics over time
    dates = [a['start_time'] for a in analyses]
    pass_rates = [a['pass_rate'] for a in analyses]
    avg_durations = [a['avg_duration'] for a in analyses]
    
    # Track week pass rates over time
    week_pass_rates = defaultdict(list)
    for analysis in analyses:
        for week, stats in analysis.get('week_stats', {}).items():
            week_pass_rates[week].append(stats.get('pass_rate', 0))
    
    # Most frequent failures
    failure_counts = Counter()
    for analysis in analyses:
        for test in analysis.get('failed_tests', []):
            failure_counts[test['test_id']] += 1
    
    top_failures = failure_counts.most_common(5)
    
    return {
        'run_count': len(analyses),
        'dates': dates,
        'pass_rates': pass_rates,
        'avg_durations': avg_durations,
        'week_pass_rates': dict(week_pass_rates),
        'top_failures': top_failures
    }


def generate_text_report(analysis, trends=None):
    """Generate a text report from the analysis."""
    if not analysis:
        return "No analysis data available."
    
    report = []
    report.append("=" * 60)
    report.append(f"D CENTRAL TEST ANALYSIS - {analysis['session_id']}")
    report.append("=" * 60)
    report.append(f"Start time: {analysis['start_time']}")
    report.append(f"End time: {analysis['end_time']}")
    report.append(f"Total duration: {analysis['total_duration']} seconds")
    report.append("-" * 60)
    report.append("TEST RESULTS SUMMARY:")
    report.append(f"Total tests: {analysis['test_count']}")
    report.append(f"Passed: {analysis['pass_count']} ({analysis['pass_rate']:.2f}%)")
    report.append(f"Failed: {analysis['fail_count']}")
    report.append(f"Warnings: {analysis['warn_count']}")
    report.append(f"Skipped: {analysis['skip_count']}")
    report.append("-" * 60)
    report.append("TEST DURATION STATISTICS:")
    report.append(f"Average duration: {analysis['avg_duration']:.2f} seconds")
    report.append(f"Maximum duration: {analysis['max_duration']} seconds")
    report.append(f"Minimum duration: {analysis['min_duration']} seconds")
    
    if analysis['failed_tests']:
        report.append("-" * 60)
        report.append("FAILED TESTS:")
        for i, test in enumerate(analysis['failed_tests'], 1):
            report.append(f"{i}. {test['test_id']} - {test['description']}")
            report.append(f"   Message: {test['message']}")
    
    report.append("-" * 60)
    report.append("WEEK STATISTICS:")
    for week, stats in sorted(analysis['week_stats'].items()):
        report.append(f"Week {week}:")
        report.append(f"  Tests: {stats['test_count']}")
        report.append(f"  Pass rate: {stats['pass_rate']:.2f}%")
        report.append(f"  Failed: {stats['fail_count']}")
        report.append(f"  Warnings: {stats['warn_count']}")
    
    if trends:
        report.append("=" * 60)
        report.append("TREND ANALYSIS")
        report.append("=" * 60)
        report.append(f"Runs analyzed: {trends['run_count']}")
        report.append("-" * 60)
        report.append("TOP 5 MOST FREQUENT FAILURES:")
        for test_id, count in trends['top_failures']:
            report.append(f"  {test_id}: {count} failures")
    
    return "\n".join(report)


def generate_html_report(analysis, trends=None, output_dir=None):
    """Generate an HTML report from the analysis."""
    if not analysis:
        return "No analysis data available."
    
    # Create output directory if it doesn't exist
    if output_dir and not os.path.exists(output_dir):
        os.makedirs(output_dir)
    
    # Generate HTML
    html = []
    html.append("<!DOCTYPE html>")
    html.append("<html lang='en'>")
    html.append("<head>")
    html.append("  <meta charset='UTF-8'>")
    html.append("  <meta name='viewport' content='width=device-width, initial-scale=1.0'>")
    html.append(f"  <title>D Central Test Analysis - {analysis['session_id']}</title>")
    html.append("  <style>")
    html.append("    body { font-family: Arial, sans-serif; line-height: 1.6; max-width: 1200px; margin: 0 auto; padding: 20px; }")
    html.append("    h1, h2, h3 { color: #3a5fcd; }")
    html.append("    .summary { display: flex; flex-wrap: wrap; gap: 20px; }")
    html.append("    .summary-box { flex: 1; min-width: 300px; background-color: #f8f9fa; padding: 15px; border-radius: 5px; }")
    html.append("    .pass { color: #28a745; }")
    html.append("    .fail { color: #dc3545; }")
    html.append("    .warn { color: #ffc107; }")
    html.append("    .skip { color: #6c757d; }")
    html.append("    table { width: 100%; border-collapse: collapse; margin: 20px 0; }")
    html.append("    th, td { padding: 12px 15px; text-align: left; border-bottom: 1px solid #e0e0e0; }")
    html.append("    th { background-color: #f8f9fa; }")
    html.append("    tr:hover { background-color: #f1f1f1; }")
    html.append("    .chart-container { margin: 30px 0; }")
    html.append("  </style>")
    html.append("</head>")
    html.append("<body>")
    
    # Header
    html.append(f"<h1>D Central Test Analysis - {analysis['session_id']}</h1>")
    html.append("<div class='summary'>")
    
    # Test Run Summary
    html.append("  <div class='summary-box'>")
    html.append("    <h2>Test Run Summary</h2>")
    html.append(f"    <p><strong>Start time:</strong> {analysis['start_time']}</p>")
    html.append(f"    <p><strong>End time:</strong> {analysis['end_time']}</p>")
    html.append(f"    <p><strong>Total duration:</strong> {analysis['total_duration']} seconds</p>")
    html.append("  </div>")
    
    # Test Results
    html.append("  <div class='summary-box'>")
    html.append("    <h2>Test Results</h2>")
    html.append(f"    <p><strong>Total tests:</strong> {analysis['test_count']}</p>")
    html.append(f"    <p><strong>Passed:</strong> <span class='pass'>{analysis['pass_count']} ({analysis['pass_rate']:.2f}%)</span></p>")
    html.append(f"    <p><strong>Failed:</strong> <span class='fail'>{analysis['fail_count']}</span></p>")
    html.append(f"    <p><strong>Warnings:</strong> <span class='warn'>{analysis['warn_count']}</span></p>")
    html.append(f"    <p><strong>Skipped:</strong> <span class='skip'>{analysis['skip_count']}</span></p>")
    html.append("  </div>")
    
    # Duration Statistics
    html.append("  <div class='summary-box'>")
    html.append("    <h2>Duration Statistics</h2>")
    html.append(f"    <p><strong>Average duration:</strong> {analysis['avg_duration']:.2f} seconds</p>")
    html.append(f"    <p><strong>Maximum duration:</strong> {analysis['max_duration']} seconds</p>")
    html.append(f"    <p><strong>Minimum duration:</strong> {analysis['min_duration']} seconds</p>")
    html.append("  </div>")
    
    html.append("</div>") # End summary
    
    # Week Statistics
    html.append("<h2>Week Statistics</h2>")
    html.append("<table>")
    html.append("  <thead>")
    html.append("    <tr>")
    html.append("      <th>Week</th>")
    html.append("      <th>Tests</th>")
    html.append("      <th>Pass Rate</th>")
    html.append("      <th>Failed</th>")
    html.append("      <th>Warnings</th>")
    html.append("    </tr>")
    html.append("  </thead>")
    html.append("  <tbody>")
    
    for week, stats in sorted(analysis['week_stats'].items()):
        html.append("    <tr>")
        html.append(f"      <td>Week {week}</td>")
        html.append(f"      <td>{stats['test_count']}</td>")
        html.append(f"      <td class='{'pass' if stats['pass_rate'] >= 90 else 'warn' if stats['pass_rate'] >= 70 else 'fail'}'>{stats['pass_rate']:.2f}%</td>")
        html.append(f"      <td>{stats['fail_count']}</td>")
        html.append(f"      <td>{stats['warn_count']}</td>")
        html.append("    </tr>")
    
    html.append("  </tbody>")
    html.append("</table>")
    
    # Failed Tests
    if analysis['failed_tests']:
        html.append("<h2>Failed Tests</h2>")
        html.append("<table>")
        html.append("  <thead>")
        html.append("    <tr>")
        html.append("      <th>Test ID</th>")
        html.append("      <th>Description</th>")
        html.append("      <th>Message</th>")
        html.append("    </tr>")
        html.append("  </thead>")
        html.append("  <tbody>")
        
        for test in analysis['failed_tests']:
            html.append("    <tr>")
            html.append(f"      <td>{test['test_id']}</td>")
            html.append(f"      <td>{test['description']}</td>")
            html.append(f"      <td>{test['message']}</td>")
            html.append("    </tr>")
        
        html.append("  </tbody>")
        html.append("</table>")
    
    # Trend Analysis
    if trends:
        html.append("<h2>Trend Analysis</h2>")
        html.append(f"<p>Based on {trends['run_count']} test runs.</p>")
        
        # Top failures
        html.append("<h3>Most Frequent Failures</h3>")
        html.append("<table>")
        html.append("  <thead>")
        html.append("    <tr>")
        html.append("      <th>Test ID</th>")
        html.append("      <th>Failure Count</th>")
        html.append("    </tr>")
        html.append("  </thead>")
        html.append("  <tbody>")
        
        for test_id, count in trends['top_failures']:
            html.append("    <tr>")
            html.append(f"      <td>{test_id}</td>")
            html.append(f"      <td>{count}</td>")
            html.append("    </tr>")
        
        html.append("  </tbody>")
        html.append("</table>")
        
        # Charts for pass rates and durations
        if output_dir:
            # Generate pass rate trend chart
            plt.figure(figsize=(10, 6))
            plt.plot(range(len(trends['dates'])), trends['pass_rates'], marker='o', linewidth=2)
            plt.title('Pass Rate Trend')
            plt.xlabel('Run')
            plt.ylabel('Pass Rate (%)')
            plt.xticks(range(len(trends['dates'])), [d.split()[0] for d in trends['dates']], rotation=45)
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.tight_layout()
            
            pass_rate_chart = os.path.join(output_dir, 'pass_rate_trend.png')
            plt.savefig(pass_rate_chart)
            plt.close()
            
            html.append("<div class='chart-container'>")
            html.append("  <h3>Pass Rate Trend</h3>")
            html.append(f"  <img src='{os.path.basename(pass_rate_chart)}' alt='Pass Rate Trend' style='max-width: 100%;'>")
            html.append("</div>")
            
            # Generate duration trend chart
            plt.figure(figsize=(10, 6))
            plt.plot(range(len(trends['dates'])), trends['avg_durations'], marker='o', linewidth=2)
            plt.title('Average Test Duration Trend')
            plt.xlabel('Run')
            plt.ylabel('Duration (seconds)')
            plt.xticks(range(len(trends['dates'])), [d.split()[0] for d in trends['dates']], rotation=45)
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.tight_layout()
            
            duration_chart = os.path.join(output_dir, 'duration_trend.png')
            plt.savefig(duration_chart)
            plt.close()
            
            html.append("<div class='chart-container'>")
            html.append("  <h3>Average Test Duration Trend</h3>")
            html.append(f"  <img src='{os.path.basename(duration_chart)}' alt='Duration Trend' style='max-width: 100%;'>")
            html.append("</div>")
            
            # Generate week pass rate trends
            plt.figure(figsize=(10, 6))
            for week, rates in trends['week_pass_rates'].items():
                if len(rates) == len(trends['dates']):  # Only if we have data for all runs
                    plt.plot(range(len(trends['dates'])), rates, marker='o', linewidth=2, label=f'Week {week}')
            
            plt.title('Week Pass Rate Trends')
            plt.xlabel('Run')
            plt.ylabel('Pass Rate (%)')
            plt.xticks(range(len(trends['dates'])), [d.split()[0] for d in trends['dates']], rotation=45)
            plt.grid(True, linestyle='--', alpha=0.7)
            plt.legend()
            plt.tight_layout()
            
            week_chart = os.path.join(output_dir, 'week_pass_rate_trends.png')
            plt.savefig(week_chart)
            plt.close()
            
            html.append("<div class='chart-container'>")
            html.append("  <h3>Week Pass Rate Trends</h3>")
            html.append(f"  <img src='{os.path.basename(week_chart)}' alt='Week Pass Rate Trends' style='max-width: 100%;'>")
            html.append("</div>")
    
    html.append("</body>")
    html.append("</html>")
    
    # Write HTML to file if output directory is specified
    if output_dir:
        html_file = os.path.join(output_dir, f"analysis_{analysis['session_id']}.html")
        with open(html_file, 'w') as f:
            f.write("\n".join(html))
        return html_file
    else:
        return "\n".join(html)


def main():
    """Main function."""
    args = parse_args()
    
    try:
        # Find JSON summary files
        json_files = find_json_summary_files(args.path)
        if not json_files:
            print(f"No JSON summary files found in {args.path}")
            return 1
        
        # Load and analyze each file
        analyses = []
        for json_file in json_files:
            if args.verbose:
                print(f"Analyzing {json_file}...")
            summary = load_json_summary(json_file)
            if summary:
                analysis = analyze_single_run(summary)
                if analysis:
                    analyses.append(analysis)
        
        if not analyses:
            print("No valid analyses generated")
            return 1
        
        # Get the most recent analysis for the primary report
        latest_analysis = max(analyses, key=lambda a: datetime.strptime(a['start_time'], "%Y-%m-%d %H:%M:%S"))
        
        # Generate trend analysis if requested and we have multiple runs
        trend_analysis = None
        if args.trends and len(analyses) > 1:
            if args.verbose:
                print("Generating trend analysis...")
            trend_analysis = analyze_trends(analyses)
        
        # Create output directory if needed
        if args.format != "text" and args.output:
            os.makedirs(args.output, exist_ok=True)
        
        # Generate reports in the requested format
        if args.format in ["text", "all"]:
            text_report = generate_text_report(latest_analysis, trend_analysis)
            if args.output:
                text_file = os.path.join(args.output, f"analysis_{latest_analysis['session_id']}.txt")
                with open(text_file, 'w') as f:
                    f.write(text_report)
                print(f"Text report saved to {text_file}")
            else:
                print(text_report)
        
        if args.format in ["json", "all"]:
            json_output = {
                "analysis": latest_analysis,
                "trends": trend_analysis
            }
            if args.output:
                json_file = os.path.join(args.output, f"analysis_{latest_analysis['session_id']}.json")
                with open(json_file, 'w') as f:
                    json.dump(json_output, f, indent=2)
                print(f"JSON report saved to {json_file}")
            else:
                print(json.dumps(json_output, indent=2))
        
        if args.format in ["html", "all"]:
            html_file = generate_html_report(latest_analysis, trend_analysis, args.output)
            print(f"HTML report saved to {html_file}")
        
        return 0
    
    except Exception as e:
        print(f"Error: {e}")
        if args.verbose:
            import traceback
            print(traceback.format_exc())
        return 1


if __name__ == "__main__":
    sys.exit(main())