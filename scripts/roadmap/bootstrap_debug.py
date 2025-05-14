#!/usr/bin/env python3
import os, yaml, requests, sys, json

REPO=os.getenv("GITHUB_REPO")
TOKEN=os.getenv("GITHUB_TOKEN")
if not (REPO and TOKEN):
    sys.exit("Set GITHUB_REPO and GITHUB_TOKEN")
    
BASE="https://api.github.com"
HEAD={"Authorization":f"token {TOKEN}","Accept":"application/vnd.github+json"}

try:
    tasks=yaml.safe_load(open("scripts/roadmap/tasks.yaml"))
    print(f"Loaded {len(tasks)} tasks")
    
    # Test milestone creation and print full response
    sample_wk = str(tasks[0]['week'])
    sample_due = tasks[0]['due']
    r = requests.post(
        f"{BASE}/repos/{REPO}/milestones",
        headers=HEAD,
        json={"title":f"Week {sample_wk}","due_on":sample_due+"T23:59:59Z"}
    )
    
    print(f"Status code: {r.status_code}")
    print(f"Response content: {json.dumps(r.json(), indent=2)}")
    
    if r.status_code >= 400:
        print("Error creating milestone")
    else:
        print("Milestone created successfully")
        
except Exception as e:
    print(f"Error: {e}")