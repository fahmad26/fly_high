// Render source vectors; no raster recolouring or screenshot-based artwork.
// Usage: node tools/build_daily_dock_icon.cjs [absolute path to sharp module]
const fs = require('node:fs');
const path = require('node:path');
const sharp = require(process.argv[2] || 'sharp');
const root = path.resolve(__dirname, '..');
const source = path.join(root, 'assets/ui/sky-adventure/source/daily-dock');
const frame = fs.readFileSync(path.join(source, 'frame.svg'), 'utf8');
const calendar = fs.readFileSync(path.join(source, 'calendar.svg'), 'utf8');
const combined = frame.replace('</svg>', `<g transform="translate(43.697 41.7395) scale(5.8)">${calendar}</g></svg>`);
sharp(Buffer.from(combined))
  .png()
  .toFile(path.join(root, 'assets/ui/sky-adventure/generated/daily-shop/icon_daily_dock.png'))
  .then(info => console.log(JSON.stringify(info)))
  .catch(error => { console.error(error); process.exitCode = 1; });
