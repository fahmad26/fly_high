// Serve only the user's 27 selected UI PNGs to the Studio image uploader.
const http = require('node:http');
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve(__dirname, '../assets/ui/final/compressed_img');
const manifest = JSON.parse(fs.readFileSync(path.resolve(__dirname, '../assets/ui/asset-manifest.json'), 'utf8'));
const files = new Map(manifest.assets.map(a => ['/' + a.file, fs.readFileSync(path.join(root, a.file))]));
const port = Number(process.argv[2] || 53259);
http.createServer((req, res) => {
  const data = files.get(req.url);
  if (req.method !== 'GET' || !data) { res.writeHead(404); res.end(); return; }
  console.log('Serving ' + req.url);
  res.writeHead(200, {'Content-Type':'image/png','Content-Length':data.length,'Cache-Control':'no-store'});
  res.end(data);
}).listen(port, '127.0.0.1', () => console.log('Serving 27 selected PNGs on 127.0.0.1:' + port));
