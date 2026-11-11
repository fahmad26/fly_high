from pathlib import Path
import json, hashlib, re, datetime
root=Path.cwd()
base=root/'docs/roblox-development'
manifest=json.loads((base/'skills-manifest.json').read_text(encoding='utf-8-sig'))
errors=[]
names=[]
for item in manifest:
    p=root/item['local']
    data=p.read_bytes()
    if hashlib.sha256(data).hexdigest().upper()!=item['sha256'].upper(): errors.append('sha256: '+item['local'])
    blob=hashlib.sha1(b'blob '+str(len(data)).encode()+b'\0'+data).hexdigest()
    if blob!=item['gitBlob']: errors.append('git blob: '+item['local'])
    if item['gitMode']!='100644': errors.append('mode: '+item['local'])
    if p.name=='SKILL.md':
        text=data.decode('utf-8')
        m=re.match(r'^---\r?\nname: ([a-z0-9-]+)\r?\ndescription: .+?\r?\n---',text,re.S)
        if not m: errors.append('frontmatter: '+item['local'])
        else: names.append(m.group(1))
if len(names)!=len(set(names)): errors.append('Duplicate skill names')
installed=json.loads((base/'installation-results.json').read_text(encoding='utf-8-sig'))
for item in installed:
    p=Path(item['destination'])
    archive=base/'skills/ash'/item['name']/'SKILL.md'
    norm=lambda b:b.decode('utf-8').replace('\r\n','\n').rstrip('\n')
    if norm(p.read_bytes())!=norm(archive.read_bytes()): errors.append('installation: '+item['name'])
    if not p.with_name('LICENSE').exists(): errors.append('license: '+item['name'])
docs=[root/'AGENTS.md',root/'HANDOVER.md',root/'PROGRESS.md',root/'docs/WORKFLOW.md']+list(base.glob('*.md'))
links=0
for doc in docs:
    text=doc.read_text(encoding='utf-8-sig')
    for match in re.finditer(r'\]\(([^)]+)\)',text):
        target=match.group(1).split('#')[0].strip('<>')
        if not target or re.match(r'^[a-zA-Z][a-zA-Z0-9+.-]*:',target): continue
        links+=1
        if not (doc.parent/target).exists(): errors.append('link: '+str(doc.relative_to(root))+' -> '+target)
report={'checkedUTC':datetime.datetime.now(datetime.timezone.utc).isoformat(),'archiveFiles':len(manifest),'archiveSkills':len(names),'regularGitBlobsVerified':len(manifest),'sha256Verified':len(manifest),'newInstallationsVerified':len(installed),'localInventoryCount':len(json.loads((base/'local-skill-inventory.json').read_text(encoding='utf-8-sig'))),'localLinksChecked':links,'errors':errors,'success':not errors,'scope':'Archive byte integrity, frontmatter, installed content/licensing, local links. Not a guarantee of all semantic instructions or future versions.'}
(base/'verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report))
raise SystemExit(bool(errors))

