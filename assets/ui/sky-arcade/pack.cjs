// Build Roblox transport textures from the independently authored PNGs.
const sharp = require('sharp');
const fs = require('node:fs/promises');
const path = require('node:path');
const dir = __dirname;
const side = 1024;
const gap = 6;
const family = process.argv.includes('--meters') ? 'meters' : process.argv.includes('--lettering') ? 'lettering' : 'arcade';

async function pack() {
  const out = path.join(dir, 'textures');
  await fs.mkdir(out, { recursive: true });
  const sprites = [];
  for (const filename of (await fs.readdir(path.join(dir, 'png'))).sort()) {
    if (!filename.endsWith('.png')) continue;
    const key = path.basename(filename, '.png');
    const sourceFamily = key.startsWith('meter_') ? 'meters' : key.startsWith('letter_') ? 'lettering' : 'arcade';
    if (sourceFamily !== family) continue;
    let image = sharp(path.join(dir, 'png', filename));
    if (key.startsWith('art_')) image = image.resize(288, 240, { fit: 'inside' });
    if (key.startsWith('icon_')) image = image.resize(128, 128);
    const { data, info } = await image.png().toBuffer({ resolveWithObject: true });
    sprites.push({ key, data, w: info.width, h: info.height });
  }
  sprites.sort((a, b) => b.h - a.h || b.w - a.w || a.key.localeCompare(b.key));
  const pages = [];
  const rects = {};
  for (const sprite of sprites) {
    const { key, data, w, h } = sprite;
    const cellW = w + 2 * gap;
    const cellH = h + 2 * gap;
    let page = pages.find(p => p.rows.some(r => r.height >= cellH && side - r.x >= cellW));
    let row = page?.rows.find(r => r.height >= cellH && side - r.x >= cellW);
    if (!row) {
      page = pages.find(p => side - p.y >= cellH);
      if (!page) {
        page = { file: `fly_high_${family}_${pages.length + 1}.png`, y: 0, rows: [], images: [] };
        pages.push(page);
      }
      row = { x: 0, y: page.y, height: cellH };
      page.rows.push(row);
      page.y += cellH;
    }
    const x = row.x + gap;
    const y = row.y + gap;
    row.x += cellW;
    page.images.push({ input: data, left: x, top: y });
    rects[key] = { page: page.file, x, y, w, h };
  }
  for (const page of pages) {
    await sharp({ create: { width: side, height: side, channels: 4, background: '#00000000' } })
      .composite(page.images).png().toFile(path.join(out, page.file));
  }
  const catalog = { textureSize: side, pages: pages.map(p => p.file), sprites: rects };
  const name = family === 'arcade' ? 'catalog.json' : family + '-catalog.json';
  await fs.writeFile(path.join(dir, name), JSON.stringify(catalog, null, 2) + '\n');
  console.log(`${sprites.length} PNGs packed into ${pages.length} textures`);
}
pack().catch(error => { console.error(error); process.exitCode = 1; });
