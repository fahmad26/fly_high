import json, hashlib, subprocess
from pathlib import Path
from datetime import datetime, timezone

root = Path(__file__).resolve().parents[2]
git = 'C:/Program Files/WindowsApps/OpenAI.CodexPrimaryRuntime.v26-1110-973-0_26.1110.973.0_x64__3k8sg7r9htsxt/dependencies/native/git/cmd/git.exe'
def run(*args):
    return subprocess.check_output([git, *args], cwd=root).decode('utf-8', errors='replace').strip()
files = [
    'ReplicatedStorage/FlyHigh/Modules/HUDTheme.luau',
    'ReplicatedStorage/FlyHigh/Modules/HUDAdventureArt.luau',
    'ReplicatedStorage/FlyHigh/Modules/HUDLayout.luau',
    'StarterPlayer/StarterPlayerScripts/FlightHUDController.luau',
    'StarterPlayer/StarterPlayerScripts/FlightJumpController.luau',
    'StarterPlayer/StarterPlayerScripts/WeaponClientController.luau',
    'StarterPlayer/StarterPlayerScripts/ShopClientController.luau',
]
snapshot = dict(captured_utc=datetime.now(timezone.utc).isoformat(), branch=run('branch','--show-current'), base_commit=run('rev-parse','HEAD'), scope='Local mirror analysis only; Studio/place not compared. Git status captured after motion draft was written.', git_status=run('status','--short'), sources=[])
for name in files:
    p = root/'audit/sources'/name
    data = p.read_bytes()
    snapshot['sources'].append(dict(path=p.relative_to(root).as_posix(), bytes=len(data), sha256=hashlib.sha256(data).hexdigest()))
(Path(__file__).parent/'source-snapshot.json').write_text(json.dumps(snapshot,indent=2),encoding='utf-8')
print('Recorded seven source hashes, base commit and dirty status; no Studio inspection.')
