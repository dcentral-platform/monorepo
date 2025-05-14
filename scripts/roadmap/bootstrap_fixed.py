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
    r = requests.get(f"{BASE}/repos/{REPO}/milestones", headers=HEAD)
    if r.status_code == 200:
        for milestone in r.json():
            existing_milestones[milestone['title']] = milestone['number']
    
    print(f"Found {len(existing_milestones)} existing milestones")
    
    # Load tasks
    tasks = yaml.safe_load(open("scripts/roadmap/tasks.yaml"))
    print(f"Loaded {len(tasks)} tasks")
    
    # Process tasks
    mil = {}
    for t in tasks:
        wk = str(t['week'])
        milestone_title = f"Week {wk}"
        
        # Check if milestone exists
        if milestone_title in existing_milestones:
            print(f"Using existing milestone: {milestone_title}")
            mil[wk] = existing_milestones[milestone_title]
        else:
            print(f"Creating new milestone: {milestone_title}")
            r = requests.post(
                f"{BASE}/repos/{REPO}/milestones",
                headers=HEAD,
                json={"title": milestone_title, "due_on": t['due']+"T23:59:59Z"}
            )
            
            if r.status_code >= 400:
                print(f"Error creating milestone {milestone_title}: {r.json()}")
                continue
                
            mil[wk] = r.json()["number"]
        
        # Create issue
        issue_data = {
            "title": t['title'],
            "body": t['body'],
            "labels": t['labels'],
            "milestone": mil[wk]
        }
        
        r = requests.post(f"{BASE}/repos/{REPO}/issues", headers=HEAD, json=issue_data)
        
        if r.status_code >= 400:
            print(f"Error creating issue {t['title']}: {r.json()}")
        else:
            print(f"Created issue: {t['title']}")
    
    print("Bootstrap complete")
    
except Exception as e:
    print(f"Error: {e}")