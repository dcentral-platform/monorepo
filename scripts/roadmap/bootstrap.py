
#!/usr/bin/env python3
import os, yaml, requests, sys
REPO=os.getenv("GITHUB_REPO")
TOKEN=os.getenv("GITHUB_TOKEN")
if not (REPO and TOKEN):
    sys.exit("Set GITHUB_REPO and GITHUB_TOKEN")
BASE="https://api.github.com"
HEAD={"Authorization":f"token {TOKEN}","Accept":"application/vnd.github+json"}
tasks=yaml.safe_load(open("scripts/roadmap/tasks.yaml"))
mil={}
for t in tasks:
    wk=str(t['week'])
    if wk not in mil:
        r=requests.post(f"{BASE}/repos/{REPO}/milestones",headers=HEAD,json={"title":f"Week {wk}","due_on":t['due']+"T23:59:59Z"})
        mil[wk]=r.json()["number"]
    requests.post(f"{BASE}/repos/{REPO}/issues",headers=HEAD,json={"title":t['title'],"body":t['body'],"labels":t['labels'],"milestone":mil[wk]})
print("Bootstrap complete")
