// Read-only binary source verification using Node's built-in zstd decoder.
const fs = require('node:fs');
const path = require('node:path');
const zlib = require('node:zlib');
const crypto = require('node:crypto');
const [place, mirror, reportDir] = process.argv.slice(2);
const data = fs.readFileSync(place);
if (data.subarray(0, 8).toString() !== '<roblox!') throw Error('Invalid place header');
const classes = new Map(), props = new Map(), parents = new Map();
function strings(b, offset, count) {
  const result = [];
  for (let i = 0; i < count; i++) {
    const length = b.readUInt32LE(offset); offset += 4;
    result.push(b.subarray(offset, offset + length).toString('utf8')); offset += length;
  }
  return result;
}
function refs(b, offset, count) {
  let sum = 0; const result = [];
  for (let i = 0; i < count; i++) {
    const n = ((b[offset+i]*0x1000000)+(b[offset+count+i]<<16)+(b[offset+2*count+i]<<8)+b[offset+3*count+i]) >>> 0;
    sum += (n >>> 1) ^ -(n & 1); result.push(sum);
  }
  return result;
}
for (let at = 32; at < data.length;) {
  const tag = data.subarray(at, at+4).toString();
  const compressed = data.readUInt32LE(at+4), length = data.readUInt32LE(at+8); at += 16;
  const raw = data.subarray(at, at+(compressed || length)); at += raw.length;
  const b = compressed ? zlib.zstdDecompressSync(raw) : raw;
  if (b.length !== length) throw Error('Invalid chunk length');
  if (tag === 'INST') {
    const id = b.readUInt32LE(0), n = b.readUInt32LE(4), name = b.subarray(8,8+n).toString();
    const count = b.readUInt32LE(9+n);
    classes.set(id, {name, refs: refs(b,13+n,count)});
  } else if (tag === 'PROP') {
    const id = b.readUInt32LE(0), n = b.readUInt32LE(4), key = b.subarray(8,8+n).toString();
    const cls = classes.get(id);
    if (cls && b[8+n] === 1 && ['Name','Source'].includes(key)) {
      strings(b,9+n,cls.refs.length).forEach((value,i) => {
        const ref = cls.refs[i]; if (!props.has(ref)) props.set(ref,{}); props.get(ref)[key] = value;
      });
    }
  } else if (tag === 'PRNT') {
    const n = b.readUInt32LE(1), children = refs(b,5,n), pp = refs(b,5+4*n,n);
    children.forEach((ref,i)=>parents.set(ref,pp[i]));
  }
  if (tag === 'END\0') break;
}
function full(ref) {
  const names = [], seen = new Set();
  while (ref !== -1 && props.has(ref)) {
    if (seen.has(ref)) throw Error('Parent cycle'); seen.add(ref);
    names.unshift(props.get(ref).Name); ref = parents.get(ref);
  }
  return names.join('.');
}
const norm = s => s.replace(/\r\n/g,'\n').trimEnd();
const sha = s => crypto.createHash('sha256').update(s).digest('hex');
const stored = {};
for (const cls of classes.values()) for (const ref of cls.refs) {
  const p = props.get(ref); if (!p || p.Source === undefined) continue;
  const name = full(ref);
  if (!/^(ReplicatedStorage|ServerScriptService|StarterPlayer)\./.test(name)) continue;
  if (stored[name]) throw Error('Duplicate script path: '+name);
  stored[name] = {class:cls.name,source:p.Source};
}
const studio = JSON.parse(fs.readFileSync(path.join(reportDir,'studio-checksums.json'),'utf8'));
const report = {place: path.resolve(place), bytes:data.length, sha256:sha(data), normalization:'CRLF to LF, trimEnd; rolling Studio checksum is only supplemental', scripts:[], missing:[], failures:[]};
for (const [name,p] of Object.entries(stored)) {
  const file = path.join(mirror,...name.split('.'))+'.luau';
  const content = fs.existsSync(file) ? fs.readFileSync(file,'utf8') : null;
  const rawBytes = Buffer.from(p.source); let rolling = 5381;
  for (const byte of rawBytes) rolling = (rolling*33+byte)>>>0;
  const live = studio[name];
  const row = {path:name,class:p.class,mirrorEqual:content!==null && norm(content)===norm(p.source),studioChecksumMatches:!!live && live.class===p.class && live.bytes===rawBytes.length && live.checksum===rolling,sourceSha256:sha(norm(p.source))};
  report.scripts.push(row);
  if (!row.mirrorEqual || !row.studioChecksumMatches) report.failures.push(name);
}
for (const name of Object.keys(studio)) if (!stored[name]) report.missing.push(name);
fs.writeFileSync(path.join(reportDir,'binary-source-report.json'),JSON.stringify(report,null,2)+'\n');
fs.writeFileSync(path.join(reportDir,'binary-sources.json'),JSON.stringify(stored));
console.log(JSON.stringify({scripts:report.scripts.length,failures:report.failures,missing:report.missing,bytes:report.bytes,sha256:report.sha256},null,2));
if (report.failures.length || report.missing.length) process.exitCode = 1;
