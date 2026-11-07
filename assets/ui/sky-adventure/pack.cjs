// Export independently generated PNGs to transparent 1024px Roblox texture pages.
// The source PNGs and prompts are preserved unchanged.
const fs = require('node:fs/promises');
const path = require('node:path');
const sharp = require('sharp');
const size = 1024;
const gap = 4;
const clear = { r: 0, g: 0, b: 0, alpha: 0 };
const dir = __dirname;
const superseded = new Set(['reload_normal', 'hull_panel']);
const fixedCanvas = /^(jump_|kit_(normal|empty|clutch)$)/;

function maxSize(key) {
  if (/^(hull_pip_|master_crest|goal_marker)/.test(key)) return 128;
  if (/^(altitude_panel|shop_panel|result_)/.test(key)) return 768;
  if (/^(auto_|tether_|warning_|context_|hull_panel|ammo_panel|rope_panel|nameplate|buy_|progress_|shop_.*_card|ping_panel)/.test(key)) return 512;
  return 256;
}

async function makeSprite(file) {
  const key = path.basename(file, '.png');
  const source = path.join(dir, 'generated', file);
  const { data, info: { width, height, channels } } =
    await sharp(source).raw().toBuffer({ resolveWithObject: true });
  if (channels !== 4) throw new Error(`${file}: no alpha channel`);
  // Find the illustration bounds, ignoring low-alpha matte noise in the margin.
  let left = width, right = -1, top = height, bottom = -1;
  for (let y = 0; y < height; ++y) {
    for (let x = 0; x < width; ++x) {
      if (data[(y * width + x) * channels + 3] < 96) continue;
      left = Math.min(left, x); right = Math.max(right, x);
      top = Math.min(top, y); bottom = Math.max(bottom, y);
    }
  }
  if (right < left || bottom < top) throw new Error(`${file}: invisible image`);
  if (fixedCanvas.test(key)) {
    // These state variants are generated from the original; keep their registration.
    left = 0; top = 0; right = width - 1; bottom = height - 1;
  } else {
    const margin = Math.max(2, Math.round(Math.min(right - left, bottom - top) * 0.022));
    left = Math.max(0, left - margin); right = Math.min(width - 1, right + margin);
    top = Math.max(0, top - margin); bottom = Math.min(height - 1, bottom + margin);
  }
  const output = await sharp(source)
    .extract({ left, top, width: right - left + 1, height: bottom - top + 1 })
    .resize(maxSize(key), maxSize(key), { fit: 'inside' })
    .png().toBuffer({ resolveWithObject: true });
  return { key, w: output.info.width, h: output.info.height, input: output.data, source: [width, height] };
}

async function main() {
  const files = (await fs.readdir(path.join(dir, 'generated'))).sort()
    .filter(file => file.endsWith('.png') && !superseded.has(path.basename(file, '.png')));
  const sprites = [];
  for (const file of files) sprites.push(await makeSprite(file));
  sprites.sort((a, b) => b.h - a.h || b.w - a.w || a.key.localeCompare(b.key));
  const pages = [];
  const catalog = { textureSize: size, pages: [], sprites: {} };
  for (const sprite of sprites) {
    const w = sprite.w + 2 * gap;
    const h = sprite.h + 2 * gap;
    let page = pages.find(p => p.rows.some(r => r.height >= h && r.x + w <= size));
    let row = page?.rows.find(r => r.height >= h && r.x + w <= size);
    if (!row) {
      page = pages.find(p => p.y + h <= size);
      if (!page) {
        page = { file: `fly_high_adventure_${pages.length + 1}.png`, y: 0, rows: [], images: [] };
        pages.push(page);
      }
      row = { x: 0, y: page.y, height: h };
      page.rows.push(row);
      page.y += h;
    }
    const x = row.x + gap;
    const y = row.y + gap;
    row.x += w;
    page.images.push({ input: sprite.input, left: x, top: y });
    catalog.sprites[sprite.key] = { page: page.file, x, y, w: sprite.w, h: sprite.h, source: sprite.source };
  }
  const out = path.join(dir, 'textures');
  await fs.mkdir(out, { recursive: true });
  for (const page of pages) {
    await sharp({ create: { width: size, height: size, channels: 4, background: clear } })
      .composite(page.images).png().toFile(path.join(out, page.file));
    catalog.pages.push(page.file);
  }
  await fs.writeFile(path.join(dir, 'catalog.json'), JSON.stringify(catalog, null, 2) + '\n');
  console.log(`${sprites.length} PNGs packed into ${pages.length} textures`);
}

main().catch(error => { console.error(error); process.exitCode = 1; });
