#!/usr/bin/env python3
import os, yaml, requests, sys, json

REPO=os.getenv("GITHUB_REPO")
TOKEN=os.getenv("GITHUB_TOKEN")
if not (REPO and TOKEN):
    sys.exit("Set GITHUB_REPO and GITHUB_TOKEN")
    
BASE="https://api.github.com"
HEAD={"Authorization":f"token {TOKEN}","Accept":"application/vnd.github+json"}

try:
    # Get existing milestones
    existing_milestones = {}
    r = requests.get(f"{BASE}/repos/{REPO}/milestones", headers=HEAD, params={"state": "open"})
    if r.status_code == 200:
        for milestone in r.json():
            existing_milestones[milestone['title']] = milestone['number']
    
    print(f"Found {len(existing_milestones)} existing milestones")
    
    # Get existing issues to avoid duplicates
    existing_issues = set()
    r = requests.get(f"{BASE}/repos/{REPO}/issues", headers=HEAD, params={"state": "all"})
    if r.status_code == 200:
        for issue in r.json():
            existing_issues.add(issue['title'])
    
    print(f"Found {len(existing_issues)} existing issues")
    
    # Load tasks
    tasks = yaml.safe_load(open("scripts/roadmap/tasks.yaml"))
    print(f"Loaded {len(tasks)} tasks")
    
    # Process tasks
    milestone_cache = {}
    tasks_created = 0
    for t in tasks:
        wk = str(t['week'])
        milestone_title = f"Week {wk}"
        
        # Skip if issue already exists
        if t['title'] in existing_issues:
            print(f"Skipping existing issue: {t['title']}")
            continue
        
        # Get or create milestone
        if milestone_title in milestone_cache:
            milestone_number = milestone_cache[milestone_title]
        elif milestone_title in existing_milestones:
            milestone_number = existing_milestones[milestone_title]
            milestone_cache[milestone_title] = milestone_number
            print(f"Using existing milestone: {milestone_title} (#{milestone_number})")
        else:
            r = requests.post(
                f"{BASE}/repos/{REPO}/milestones",
                headers=HEAD,
                json={"title": milestone_title, "due_on": t['due']+"T23:59:59Z"}
            )
            
            if r.status_code >= 400:
                print(f"Error creating milestone {milestone_title}: {r.json()}")
                continue
                
            milestone_number = r.json()["number"]
            milestone_cache[milestone_title] = milestone_number
            print(f"Created new milestone: {milestone_title} (#{milestone_number})")
        
        # Create issue
        issue_data = {
            "title": t['title'],
            "body": t['body'],
            "labels": t['labels'],
            "milestone": milestone_number
        }
        
        r = requests.post(f"{BASE}/repos/{REPO}/issues", headers=HEAD, json=issue_data)
        
        if r.status_code >= 400:
            print(f"Error creating issue {t['title']}: {r.json()}")
        else:
            print(f"Created issue: {t['title']}")
            tasks_created += 1
    
    print(f"Bootstrap complete! Created {tasks_created} new issues")
    
except Exception as e:
    print(f"Error: {e}")