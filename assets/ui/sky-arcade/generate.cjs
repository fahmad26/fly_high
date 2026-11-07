// Render each piece of UI art to an independent transparent PNG.
// Set NODE_PATH to a directory containing sharp, then run node generate.cjs.
const sharp = require('sharp');
const fs = require('node:fs/promises');
const path = require('node:path');
const dir = __dirname;

const colors = {
  aqua: ['#7bfaff', '#0870ce', '#01375e', '#1ebfff'],
  blue: ['#72c8ff', '#1555c0', '#142569', '#487aff'],
  green: ['#c5fb6e', '#248934', '#123b39', '#54e47d'],
  gold: ['#fff3a0', '#bc6d13', '#583324', '#ffc551'],
  orange: ['#ffd198', '#c34a20', '#57223a', '#ff913f'],
  red: ['#ff9db7', '#b82656', '#591d40', '#ff5979'],
  violet: ['#efb4ff', '#703cc7', '#31225f', '#b77fff'],
  navy: ['#637fb1', '#26395d', '#101b33', '#60a9de'],
};

const icons = {
  shop: '<path d="M15 28h34v23H15zM12 27l5-12h30l5 12v6H12z"/><path d="M27 51V39h11v12M23 15l-2 15m20-15 2 15"/>',
  kit: '<rect x="12" y="22" width="40" height="29" rx="6"/><path d="M24 22v-7h16v7m-8 7v15m-7-7h14"/>',
  ping: '<path d="M32 53S15 39 15 26a17 17 0 0 1 34 0c0 13-17 27-17 27Z"/><circle cx="32" cy="26" r="6"/>',
  sound: '<path d="M11 27h9l11-9v28l-11-9h-9zM40 24q11 8 0 16m6-23q17 15 0 30"/>',
  muted: '<path d="M11 27h9l11-9v28l-11-9h-9zM41 25l13 14m0-14L41 39"/>',
  jump: '<path d="M32 10l18 18h-9v14H23V28h-9z" fill="#edfcff"/><path d="M23 51h18m-14 7h10"/>',
  gas: '<path d="M36 9c1 15 15 18 15 30a19 19 0 0 1-38 0c0-10 8-17 11-21 0 8 3 10 5 11 4-7 7-13 7-20Z" fill="#fff2a0"/><path d="M32 35c-3 5-8 7-8 13a8 8 0 0 0 16 0c0-4-3-8-8-13Z" fill="#ff9154"/>',
  auto: '<path d="M21 15a19 19 0 0 1 28 9l3-9m-3 9-10-1M43 49a19 19 0 0 1-28-9l-3 9m3-9 10 1"/><path d="m34 19-11 15h8l-1 11 11-16h-8z" fill="#fff5a3"/>',
  release: '<circle cx="25" cy="32" r="13"/><circle cx="25" cy="32" r="4"/><path d="M25 19v9m-11 11 8-5m14 5-8-5m12-2h13m-5-6 6 6-6 6"/>',
  reload: '<path d="M31 15a18 18 0 0 1 19 15l4-8m-4 8-8-2M32 49a18 18 0 0 1-19-15l-4 8m4-8 8 2"/><path d="m32 22-5 8v12h10V30z" fill="#f9e2a4"/>',
  drop: '<path d="M15 44h34v9H15zM32 11v25m-9-9 9 9 9-9"/>',
  fire: '<circle cx="32" cy="32" r="16"/><circle cx="32" cy="32" r="5" fill="#fff5b2"/><path d="M32 8v10m0 28v10M8 32h10m28 0h10"/>',
  aim: '<path d="M32 7v13m0 24v13M7 32h13m24 0h13"/><circle cx="32" cy="32" r="3" fill="#fff"/>',
  attach: '<path d="m26 36-4 4a8 8 0 0 1-11-11l10-10a8 8 0 0 1 11 0m6 9 4-4a8 8 0 0 1 11 11L43 45a8 8 0 0 1-11 0M23 41l18-18"/>',
  detach: '<path d="m23 41-4 4a7 7 0 0 1-10-10l9-9m24-3 4-4a7 7 0 0 1 10 10l-9 9M23 13l3 9m-13 2 9 3m16 15 3 9m3-14 9 3"/>',
  climb: '<path d="M15 52h34M32 46V12m-10 10 10-10 10 10M15 31v13m34-13v13"/>',
  descend: '<path d="M15 12h34M32 18v34m-10-10 10 10 10-10M15 20v13m34-13v13"/>',
  repair: '<path d="m14 43 28-26 10 11-28 26z" fill="#cceebd"/><path d="m24 41 5 6m0-11 5 6m0-11 5 6m0-11 5 6M14 15l7 4m-2-9 3 7"/>',
  rope: '<path d="M30 51c-10 0-17-7-17-16s8-15 17-15 15 5 15 12-5 13-13 13-11-4-11-10 4-8 9-8 7 2 7 5-2 5-5 5m13-5c9-4 10-10 4-17l-7-5"/>',
  rescue: '<path d="M15 51h34M22 43l10-10 10 10M32 35V12m-8 8 8-8 8 8"/><path d="M13 33h5m28 0h5"/>',
  warning: '<path d="M30 13c1-2 3-2 4 0l19 33c1 2 0 4-3 4H14c-3 0-4-2-3-4Z" fill="#ffcb65"/><path d="M32 26v10" stroke="#401e32"/><circle cx="32" cy="42" r="2" fill="#401e32" stroke="none"/>',
  close: '<path d="m20 20 24 24m0-24L20 44" stroke-width="8"/>',
  weapon: '<path d="M14 26h37v11H31l-3 13H17l3-13h-6zM44 26v-5h7"/>',
  helm: '<circle cx="32" cy="32" r="18"/><circle cx="32" cy="32" r="6"/><path d="M32 9v17m0 12v17M9 32h17m12 0h17m-39-16 12 12m8 8 12 12m0-32L36 28m-8 8L16 48"/>',
};

const surfaces = {
  shop_toggle: ['tile','gold'], kit_use: ['tile','green'], kit_clutch: ['tile','red'],
  ping_toggle: ['tile','aqua'], audio_on: ['tile','violet'], audio_off: ['tile','navy'],
  shoot: ['round','red'], jump: ['round','aqua'], gas: ['tile','orange'],
  auto_off: ['wide','blue'], auto_on: ['wide','green'], release: ['tile','navy'],
  reload: ['tile','blue'], drop: ['tile','navy'], attach: ['wide','aqua'],
  detach: ['wide','navy'], climb: ['wide','aqua'], descend: ['wide','blue'],
  patch: ['wide','green'], repair_rope: ['wide','green'], pull: ['wide','orange'],
  buy_kit: ['wide','green'], buy_rifle: ['wide','gold'], spot: ['wide','violet'], close: ['round','red'],
  ping1: ['wide','orange'], ping2: ['wide','violet'], ping3: ['wide','gold'],
  ping4: ['wide','green'], ping5: ['wide','red'],
  altitude: ['readout','aqua'], status: ['readout','green'], status_critical: ['readout','red'],
  ammo: ['readout','gold'], tether: ['wide','gold'], countdown: ['wide','orange'],
  alert: ['card','red'], storm: ['card','violet'], shop_panel: ['modal','aqua'],
  ping_panel: ['card','blue'], spot_panel: ['wide','violet'], kit_card: ['card','green'],
  rifle_card: ['card','gold'], world_sign: ['card','aqua'], pod_sign: ['card','blue'],
  palace_sign: ['card','gold'], storm_sign: ['wide','violet'], crew_name: ['wide','blue'],
  marker: ['wide','violet'], hint: ['wide','navy'], badge_green: ['round','green'],
  badge_red: ['round','red'], speed: ['wide','aqua'], counter: ['wide','navy'],
  track: ['line','navy'], progress: ['line','green'], rope_fill: ['line','gold'],
  hull_good: ['line','green'], hull_broken: ['line','red'],
};

const sizes = {
  tile: [240,224], round: [256,256], wide: [384,112], readout: [512,128],
  card: [448,192], modal: [448,528], line: [256,36],
};

function svg(w,h,content) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}">${content}</svg>`;
}

function surface(name, shape, palette) {
  const [w,h] = sizes[shape];
  const [light,mid,dark,edge] = colors[palette];
  const line = shape === 'line';
  const utility = ['hint','speed','counter','track'].includes(name);
  const panel = utility || ['readout','card','modal'].includes(shape) || name === 'tether' || name.endsWith('_sign') || name === 'crew_name';
  const r = shape === 'round' ? w / 2 : line ? 13 : shape === 'tile' ? 30 : 18;
  const x = shape === 'round' ? 7 : 4;
  const bw = w-x*2;
  const bh = h-(line ? 6 : 14);
  const offset = line ? 2 : 6;
  const motif = name.split('').reduce((sum,c) => sum+c.charCodeAt(0),0)%4;
  const rect = (xx,yy,ww,hh,rad,fill,more='') =>
    `<rect x="${xx}" y="${yy}" width="${ww}" height="${hh}" rx="${rad}" fill="${fill}" ${more}/>`;
  const dash = panel && !utility ? `<path d="M${r+12} 12h${32+motif*8} M${w-r-39-motif*8} ${bh-3}h${31+motif*8}" stroke="${edge}" stroke-width="3" stroke-linecap="round" opacity=".9"/>` : '';
  return svg(w,h,`
    <defs>
      <linearGradient id="edge" x2="0" y2="1"><stop stop-color="${light}"/><stop offset=".45" stop-color="${edge}"/><stop offset="1" stop-color="${dark}"/></linearGradient>
      <linearGradient id="face" x2="0" y2="1"><stop stop-color="${panel ? '#263d5d':light}"/><stop offset=".28" stop-color="${panel ? '#182a45':edge}"/><stop offset=".71" stop-color="${panel ? '#111e34':mid}"/><stop offset="1" stop-color="${dark}"/></linearGradient>
      <linearGradient id="gloss" x2="0" y2="1"><stop stop-color="#fff" stop-opacity=".34"/><stop offset="1" stop-color="#fff" stop-opacity="0"/></linearGradient>
      <pattern id="grain" width="13" height="13" patternUnits="userSpaceOnUse" patternTransform="rotate(-29)"><path d="M0 0h2v13H0z" fill="#d8efff" opacity=".12"/></pattern>
      <clipPath id="clip">${rect(x+5,7,bw-10,bh-10,r-5,'white')}</clipPath>
    </defs>
    ${rect(x,2+offset,bw,bh,r,'#050b18','opacity=".8"')}
    ${rect(x,2,bw,bh,r,'url(#edge)','stroke="#071321" stroke-width="4"')}
    ${rect(x+5,7,bw-10,bh-10,r-5,'url(#face)')}
    <g clip-path="url(#clip)">
      <path d="M${Math.round(w*(.57+motif*.04))} 0H${w}V${h}H${Math.round(w*(.38+motif*.04))}Z" fill="url(#grain)" opacity="${panel ? '.42':'.8'}"/>
      <path d="M0 0H${w}V${Math.round(h*.17)}Q${w*.52} ${h*.34} 0 ${h*.27}Z" fill="url(#gloss)" opacity="${panel ? '.5':'1'}"/>
    </g>
    ${rect(x+6,8,bw-12,bh-12,r-6,'none','stroke="#e1f6ff" stroke-width="1.5" stroke-opacity=".29"')}
    ${dash}
  `);
}

async function render() {
  const out = path.join(dir,'png');
  await fs.mkdir(out,{recursive:true});
  for (const [name, data] of Object.entries(surfaces)) {
    await sharp(Buffer.from(surface(name,...data))).png().toFile(path.join(out,name+'.png'));
  }
  for (const [name, draw] of Object.entries(icons)) {
    const g = `<g stroke-linecap="round" stroke-linejoin="round" fill="none">`;
    const shape = svg(192,192,`<g transform="scale(3)">${g}<g stroke="#07182e" stroke-width="8" opacity=".95" transform="translate(0 1.5)">${draw.replaceAll(/fill="[^"]+"/g,'fill="none"').replaceAll(/stroke="[^"]+"/g,'stroke="#07182e"').replaceAll(/stroke-width="[^"]+"/g,'stroke-width="9"')}</g><g stroke="#f4fbff" stroke-width="4.7">${draw}</g></g></g>`);
    await sharp(Buffer.from(shape)).png().toFile(path.join(out,'icon_'+name+'.png'));
  }
}
render().catch(error => { console.error(error); process.exitCode = 1; });
