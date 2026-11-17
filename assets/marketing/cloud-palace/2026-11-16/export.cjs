// Mechanical PNG export only. Artwork was created with built-in image_gen.
// Usage: node export.cjs <absolute path to the installed sharp package>
const fs = require('node:fs');
const path = require('node:path');
const crypto = require('node:crypto');
const sharp = require(process.argv[2]);

const outputs = __dirname;
const originals = {
  icon: 'C:/Users/fahma/.codex/generated_images/01a1823f-9734-7ac0-84ab-5dd5aeb30c8a/exec-ee3bf6b7-60d9-42d4-9b8b-17d9732131a8.png',
  thumbnail: 'C:/Users/fahma/.codex/generated_images/01a1823f-9734-7ac0-84ab-5dd5aeb30c8a/exec-532d83b5-10c5-4df0-8813-82bd49365de3.png',
};
const digest = (data) => crypto.createHash('sha256').update(data).digest('hex');

function saveNew(name, data) {
  const target = path.join(outputs, name);
  if (fs.existsSync(target)) {
    if (digest(fs.readFileSync(target)) !== digest(data)) {
      throw new Error(`Refusing to overwrite a different file: ${name}`);
    }
    return;
  }
  fs.writeFileSync(target, data, { flag: 'wx' });
}

async function main() {
  for (const [kind, source] of Object.entries(originals)) {
    saveNew(`${kind}-master-v1.png`, fs.readFileSync(source));
  }
  const specs = [
    ['icon', 'icon-1024-v1.png', 1024, 1024],
    ['icon', 'icon-512-v1.png', 512, 512],
    ['thumbnail', 'thumbnail-1920x1080-v1.png', 1920, 1080],
    ['icon', 'qa-icon-150.png', 150, 150],
    ['thumbnail', 'qa-thumbnail-384x216.png', 384, 216],
  ];
  for (const [kind, name, width, height] of specs) {
    const buffer = await sharp(originals[kind])
      .resize(width, height, { fit: 'cover', position: 'centre', kernel: 'lanczos3' })
      .toColourspace('srgb')
      .png({ compressionLevel: 9 })
      .toBuffer();
    saveNew(name, buffer);
  }
  const files = [];
  for (const name of ['icon-master-v1.png', 'thumbnail-master-v1.png', ...specs.map(s => s[1])]) {
    const data = fs.readFileSync(path.join(outputs, name));
    const metadata = await sharp(data).metadata();
    files.push({ name, width: metadata.width, height: metadata.height, bytes: data.length, sha256: digest(data) });
  }
  const manifest = {
    game: 'Fly High: Cloud Palace',
    created: '2026-11-16',
    method: 'Built-in image_gen: two independent image generations; Sharp used only for export sizing and colourspace conversion.',
    type: 'Illustrated marketing key art; not an in-game screenshot.',
    published: false,
    files,
  };
  saveNew('manifest.json', Buffer.from(JSON.stringify(manifest, null, 2) + '\n'));
  console.log(JSON.stringify(files.map(({ name, width, height, bytes }) => ({ name, width, height, bytes })), null, 2));
}

main().catch(error => { console.error(error.message); process.exitCode = 1; });
