import yaml
from fastapi import FastAPI, HTTPException, Request
import subprocess

app = FastAPI()

# Простой health-check, чтобы curl был доволен
@app.get("/health")
async def health_check():
    return {"status": "ok"}

PLAYBOOKS = {
    "12": "playbooks/playbook-12-api-down.yml",
    "1": "playbooks/playbook-01-postgres.yml"
}

@app.post("/playbook/{id}")
async def run_playbook(id: str):
    playbook_path = PLAYBOOKS.get(id)
    if not playbook_path:
        raise HTTPException(404, "Playbook not found")
    
    with open(playbook_path) as f:
        pb = yaml.safe_load(f)
    
    results = []
    for i, step_data in enumerate(pb['steps']):
        step_id = i + 1
        command = step_data.get('command')
        recovery = step_data.get('recovery')
        
        result = subprocess.run(command, shell=True, capture_output=True, text=True, timeout=30)
        step_result = {"step": step_id, "status": result.returncode == 0, "output": result.stdout}
        
        if result.returncode != 0 and recovery:
            recovery_result = subprocess.run(recovery, shell=True, capture_output=True, text=True, timeout=30)
            step_result["recovery_output"] = recovery_result.stdout
        
        results.append(step_result)
            
    return {"playbook": id, "steps": results}

@app.post("/execute")
async def execute(req: dict):
    command = req.get("command")
    p = subprocess.run(command, shell=True, capture_output=True, text=True)
    return {"stdout": p.stdout, "stderr": p.stderr, "rc": p.returncode}
