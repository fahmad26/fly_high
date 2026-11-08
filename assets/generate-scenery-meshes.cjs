// Run with Node to rebuild the GLB used by the Studio importer.
const fs = require('node:fs');
const path = require('node:path');

const palette = {
  Ivory: [0.91, 0.83, 0.67], Porcelain: [1, 0.95, 0.81],
  Sandstone: [0.68, 0.48, 0.36], Gold: [0.94, 0.64, 0.23],
  GoldHighlight: [1, 0.79, 0.34], Teal: [0.11, 0.44, 0.52],
  Turquoise: [0.21, 0.66, 0.65], DeepBlue: [0.075, 0.19, 0.29],
  Crystal: [0.35, 0.85, 0.91], Cloud: [0.99, 0.92, 0.77],
  CloudShadow: [0.86, 0.78, 0.72], CloudWarm: [0.97, 0.86, 0.68],
  Rock: [0.25, 0.31, 0.35], Sand: [0.92, 0.79, 0.52],
  Grass: [0.26, 0.50, 0.31], Reef: [0.26, 0.65, 0.58],
  Indigo: [0.26, 0.23, 0.44], IndigoLight: [0.39, 0.36, 0.62],
  IndigoBlue: [0.29, 0.33, 0.58], Basalt: [0.29, 0.19, 0.27],
  Moss: [0.31, 0.40, 0.32], TerraCotta: [0.78, 0.48, 0.32],
  Astral: [0.26, 0.27, 0.47], Violet: [0.59, 0.40, 0.75],
};

const groups = new Map();
let asset;
const subtract = (a, b) => a.map((v, i) => v - b[i]);
const cross = (a, b) => [a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]];
const unit = v => { const length = Math.hypot(...v); return v.map(x => x/length); };
const tau = 2 * Math.PI;

function group(material) {
  const key = asset + '_' + material;
  if (!groups.has(key)) groups.set(key, { material, positions: [], normals: [] });
  return groups.get(key);
}

function face(material, a, b, c, d, normals) {
  const normal = unit(cross(subtract(b, a), subtract(c, a)));
  const geometry = group(material);
  const vertices = d ? [a, b, c, a, c, d] : [a, b, c];
  for (const [index, v] of vertices.entries()) {
    geometry.positions.push(...v);
    geometry.normals.push(...(normals ? normals[[0, 1, 2, 0, 2, 3][index]] : normal));
  }
}

// Extrude a counterclockwise outline in XZ. Keep the bevels in the mesh.
function extrude(material, outline, bottom, top) {
  const lower = outline.map(([x,z]) => [x,bottom,z]);
  const upper = outline.map(([x,z]) => [x,top,z]);
  for (let i=0; i<outline.length; i++) {
    const j=(i+1)%outline.length;
    face(material, lower[i], upper[i], upper[j], lower[j]);
    if (i>0 && j>0) {
      face(material, lower[0], lower[i], lower[j]);
      face(material, upper[0], upper[j], upper[i]);
    }
  }
}

function block(material, x, y, z, w, h, d, cut=0) {
  const l=x-w/2, r=x+w/2, f=z-d/2, b=z+d/2;
  const shape=cut ? [[l+cut,f],[r-cut,f],[r,f+cut],[r,b-cut],[r-cut,b],[l+cut,b],[l,b-cut],[l,f+cut]]
    : [[l,f],[r,f],[r,b],[l,b]];
  extrude(material, shape, y, y+h);
}

// Each profile row holds height, X radius, Z radius, and the material above it.
function rings(x,z,profile,sides,{jitter=0,rotation=0,smooth=false,phase=0}={}) {
  const vertex=(ring,i)=>{
    const [y,rx,rz] = profile[ring];
    const a=tau*i/sides+rotation;
    const ripple=1+jitter*(Math.sin(5*a+phase+ring*.37)*.58+Math.cos(3*a-phase)*.42);
    return [x+Math.cos(a)*rx*ripple,y+jitter*Math.sin(a*4+phase+ring*.41)*6,z+Math.sin(a)*rz*ripple];
  };
  const normal=(ring,i)=>{
    const angle=tau*i/sides+rotation;
    const p=profile[Math.max(0,ring-1)], q=profile[Math.min(profile.length-1,ring+1)];
    return unit([Math.cos(angle),-(q[1]-p[1])/Math.max(1,q[0]-p[0]),Math.sin(angle)]);
  };
  for(let row=0;row<profile.length-1;row++) {
    const choose=profile[row][3];
    for(let i=0;i<sides;i++) {
      const mat=Array.isArray(choose)?choose[i%choose.length]:choose;
      face(mat,vertex(row,i),vertex(row+1,i),vertex(row+1,i+1),vertex(row,i+1),
        smooth?[normal(row,i),normal(row+1,i),normal(row+1,i+1),normal(row,i+1)]:null);
    }
  }
  for(const row of [0,profile.length-1]) {
    const [y,,,choose]=profile[row], mat=Array.isArray(choose)?choose[0]:choose;
    for(let i=0;i<sides;i++) {
      const a=vertex(row,i),b=vertex(row,i+1);
      face(mat,[x,y,z],row===0?a:b,row===0?b:a);
    }
  }
}

function arch(material,x,y,z,rx,ry,thickness,depth,segments=12) {
  const vertex=(angle,inset,back) => [x+Math.cos(angle)*(rx-inset), y+Math.sin(angle)*(ry-inset), z-back*depth];
  for(let i=0;i<segments;i++) {
    const a=Math.PI*i/segments,b=Math.PI*(i+1)/segments;
    const oa=vertex(a,0,0),ob=vertex(b,0,0),ia=vertex(a,thickness,0),ib=vertex(b,thickness,0);
    const oa2=vertex(a,0,1),ob2=vertex(b,0,1),ia2=vertex(a,thickness,1),ib2=vertex(b,thickness,1);
    face(material,oa,ob,ib,ia);
    face(material,ob2,oa2,ia2,ib2);
    face(material,oa,oa2,ob2,ob);
    face(material,ia,ib,ib2,ia2);
    if(i===0) face(material,oa,ia,ia2,oa2);
    if(i===segments-1) face(material,ob,ob2,ib2,ib);
  }
}

function window(x,y,z,width,height) {
  const radius=width/2;
  block('DeepBlue',x,y,z-.4,width,height,1.15);
  arch('DeepBlue',x,y+height,z+.18,radius,radius*1.1,radius-.03,1);
  arch('Gold',x,y+height,z+.7,radius+.7,radius*1.1+.8,.85,1.2);
  for(const side of [-1,1]) block('Gold',x+side*(radius+.25),y,z+.25,.65,height,1.35);
  block('Porcelain',x,y-.48,z+.4,width+2,.6,1.9,.2);
  block('Turquoise',x,y+.8,z+.23,.58,height+radius*.78,.8);
}

function finial(x,z,y,scale) {
  rings(x,z,[[y,1.9*scale,1.9*scale,'Gold'],[y+2*scale,1.35*scale,1.35*scale,'Gold'],
    [y+5*scale,.6*scale,.6*scale,'GoldHighlight'],[y+6.5*scale,.12,.12,'Gold']],8);
}

function tower(x,z,scale,height) {
  const r=8*scale;
  rings(x,z,[[0,r*1.22,r*1.22,'Sandstone'],[2,r*1.22,r*1.22,'Ivory'],[4,r,r,'Porcelain'],
    [height-8,r*.9,r*.9,'Ivory'],[height-6,r*1.13,r*1.13,'Gold'],[height-4,r*1.17,r*1.17,'Porcelain'],
    [height,r*1.16,r*1.16,'Gold']],8,{rotation:Math.PI/8});
  rings(x,z,[[height,r*1.18,r*1.18,'Gold'],[height+2,r*1.14,r*1.14,['Teal','Turquoise','Teal','Teal']],
    [height+6,r*.88,r*.88,['Teal','Turquoise','Teal','Teal']],[height+12,r*.47,r*.47,'Teal'],
    [height+16,r*.19,r*.19,'Gold'],[height+17,r*.1,r*.1,'Gold']],16);
  finial(x,z,height+17,scale*.67);
  for(const y of [height*.31,height*.59]) window(x,y,z+r*.91,3.5*scale,6.8*scale);
}

asset='Palace';
block('Sandstone',0,0,-37,75,3,60,6);
block('Ivory',0,3,-37,71,34,56,6);
block('Porcelain',0,37,-37,73,2.8,58,5);
block('Gold',0,39.8,-37,72,1,57,5);
block('Ivory',0,40.8,-37,66,2.1,50,4);
for(const x of [-31,-22,22,31]) {
  block('Porcelain',x,3,-8.5,4.5,34,4,1);
  block('Gold',x,34.4,-8.1,5.8,2.1,4.7,.55);
  block('Ivory',x,3.4,-8.2,6,2.3,4.5,.6);
}
for(const x of [-25,25]) {
  window(x,15,-8.4,5.7,9.5);
  window(x,27,-8.4,4.5,4);
}
block('Porcelain',0,0.1,-3,29,1.2,8,2);
block('Ivory',0,1.3,-4.5,26,1.3,7,2);
block('DeepBlue',0,2.6,-6.7,21,16,1.4,1);
arch('DeepBlue',0,18.6,-5.96,10.3,11.1,10.26,1);
arch('Gold',0,18.6,-4.85,11.3,12.1,1.45,1.9);
arch('Porcelain',0,18.6,-5.6,14.5,15.6,3.25,2.7);
arch('Sandstone',0,18.6,-5.25,15.2,16.25,.72,2.35);
for(const x of [-12.75,12.75]) {
  block('Porcelain',x,2.6,-6,3.2,16,4,1);
  block('Gold',x,16.6,-5.6,4,1.8,4.2,.6);
}
for(const x of [-7.8,-5.2,-2.6,0,2.6,5.2,7.8]) block('Teal',x,2.6,-5.94,.36,13.7,0.26);
for(const x of [-2.4,2.4]) block('Gold',x,8.7,-5.6,.62,3,.58,.18);
block('Gold',0,26.4,-4.4,2.1,2.1,1.1,.65);
for(const x of [-42,42]) tower(x,-39,1,53);
for(const x of [-65,65]) tower(x,-13,.7,33);
for(const x of [-23,23]) tower(x,-59,.63,39);

rings(0,-37,[[42.6,24,24,'Sandstone'],[44.7,23.4,23.4,'Porcelain'],[50,22.4,22.4,'Gold'],
  [51.8,23.3,23.3,'Porcelain'],[53,23.4,23.4,'Gold']],16);
const domePanels=['Teal','Teal','Turquoise','Teal','Gold','Teal','Turquoise','Teal'];
rings(0,-37,[[53,23.6,23.6,'Gold'],[55,24,24,domePanels],[60,23.5,23.5,domePanels],
  [66,20.8,20.8,domePanels],[72,16,16,domePanels],[78,9.8,9.8,domePanels],[82,4.7,4.7,'GoldHighlight'],
  [84.6,2.8,2.8,'Gold']],32,{smooth:true});
finial(0,-37,84.4,1.5);

for(let z=2;z<=46;z+=5) for(let x=-12;x<=12;x+=4) {
  const border=Math.abs(x)===12;
  const color=border?'Gold':((x/4+z)%2===0?'Ivory':'Porcelain');
  block(color,x,.012,z,3.88,.105,4.88,.25);
}
for(const x of [-17.5,17.5]) for(const z of [54,80]) {
  rings(x,z,[[.55,3.4,3.4,'DeepBlue'],[1.15,3.4,3.4,'Gold'],[1.65,2.7,2.7,'DeepBlue']],8);
  rings(x,z,[[1.65,1.8,1.8,'Teal'],[3,2.1,2.1,['Crystal','Turquoise','Crystal']],
    [8.5,1.55,1.55,['Crystal','Turquoise','Crystal']],[11.2,.12,.12,'Crystal']],7,{rotation:.3});
}

asset='PalaceCloud';
rings(0,1,[[-45,16,25,'CloudShadow'],[-39,52,46,'CloudShadow'],[-30,77,67,'CloudWarm'],
  [-20,96,90,'Cloud'],[-10,101,99,'Cloud'],[-3,93,94,'CloudWarm'],[-.85,79,81,'Cloud']],48,
  {smooth:true,jitter:.16,phase:1.4});
for(const [x,z,s,phase] of [[-74,13,.75,3],[57,63,.71,5],[63,-58,.64,1],[-56,-66,.74,2]]) {
  rings(x,z,[[-22,11*s,10*s,'CloudShadow'],[-15,37*s,29*s,'CloudWarm'],[-7,48*s,41*s,'Cloud'],
    [-2,36*s,31*s,'Cloud'],[-.8,14*s,10*s,'Cloud']],24,{smooth:true,jitter:.19,phase});
}

asset='Dawn';
rings(0,0,[[-5,52,29,'Reef'],[-.1,53,30,'Sand'],[4,48,24,'Sand'],
  [7,35,20,'Grass'],[12,21,12,'Grass'],[16,5,6,'Grass']],26,{jitter:.31,phase:2});
rings(-29,15,[[-4,31,11,'Reef'],[.7,29,10,'Sand'],[4.5,18,7,'Sand']],18,{jitter:.32,rotation:.7});
rings(25,-10,[[1,15,14,'Rock'],[10,14,12,'Rock'],[19,7,8,'Grass'],
  [25,2,3,'Grass']],12,{jitter:.39,phase:4});

asset='Storm';
for(const [x,z,y,s,phase] of [[0,0,0,1,3],[-36,12,12,.78,2],[34,-18,26,.73,4],[10,18,53,.86,6]]) {
  rings(x,z,[[y-56*s,14*s,22*s,'Indigo'],[y-41*s,41*s,39*s,'Indigo'],[y-12*s,62*s,46*s,'IndigoBlue'],
    [y+25*s,57*s,48*s,'IndigoLight'],[y+44*s,40*s,35*s,'IndigoBlue'],[y+62*s,6*s,8*s,'IndigoLight']],
    25,{jitter:.25,smooth:true,phase});
}

asset='Sunset';
rings(0,0,[[-63,4,5,'Basalt'],[-45,22,26,'Basalt'],[-22,45,35,'Basalt'],
  [1,65,44,'TerraCotta'],[9,61,41,'Moss'],[13,45,28,'Moss']],17,{jitter:.34,phase:2});
block('Sandstone',0,12,0,64,3,32,6);
block('TerraCotta',0,15,-5,55,3,27,4);
for(const z of [-10,4]) {
  for(const x of [-20,20]) {
    block('Ivory',x,18,z,9,3,9,1.8);
    rings(x,z,[[21,3.3,3.3,'Sandstone'],[35,3.05,3.05,'Ivory'],[40,3.5,3.5,'TerraCotta'],
      [42,4.1,4.1,'Ivory']],9);
  }
  arch('TerraCotta',0,42,z+4.2,24,21,6.3,8.2);
  arch('Ivory',0,42,z+4.6,23.5,20.8,1.55,1.1);
}
block('Gold',0,61,5,5,4,3,.8);
for(const [x,z,y] of [[28,13,-4],[-39,-14,-7],[8,28,-13]]) {
  rings(x,z,[[y-36,2,4,'Basalt'],[y-21,9,8,'Basalt'],[y,14,12,'TerraCotta'],
    [y+8,10,9,'Moss']],11,{jitter:.4,rotation:x*.05});
}

asset='Cosmic';
for(const [x,z,y,s] of [[0,0,0,1],[-36,14,19,.42],[37,-22,26,.38],[24,17,-27,.28]]) {
  rings(x,z,[[y-33*s,.4,.4,'Astral'],[y-15*s,9*s,13*s,'Astral'],[y+1*s,16*s,15*s,['Astral','Violet','Astral']],
    [y+22*s,11*s,10*s,['Violet','Astral','Crystal']],[y+39*s,.2,.2,'Violet']],9,{rotation:x*.08});
}

// A known origin and axis triplet make the import independent of Studio unit presets.
for(const [label,coordinates] of Object.entries({ Origin:[0,0,0], X:[20,0,0], Y:[0,20,0], Z:[0,0,20] })) {
  asset='Reference'+label;
  const [x,y,z]=coordinates;
  block('Ivory',x,y-1,z,2,2,2);
}

const offsets={
  Palace:[0,0,0], PalaceCloud:[250,0,0], Dawn:[500,0,0],
  Storm:[750,0,0], Sunset:[1050,0,0], Cosmic:[1290,0,0],
};
const materials=Object.entries(palette).map(([name,rgb])=>({
  name,pbrMetallicRoughness:{baseColorFactor:[...rgb,1],metallicFactor:0,roughnessFactor:.83},
}));
const materialIndex=Object.fromEntries(Object.keys(palette).map((name,index)=>[name,index]));
const gltf={asset:{version:'2.0',generator:'Fly High scenery geometry'},scene:0,
  scenes:[{nodes:[]}],nodes:[],meshes:[],materials,accessors:[],bufferViews:[],buffers:[]};
const chunks=[];
let byteLength=0;
function accessor(values,min,max) {
  const buffer=Buffer.alloc(values.length*4);
  values.forEach((value,i)=>buffer.writeFloatLE(value,i*4));
  const view=gltf.bufferViews.length;
  gltf.bufferViews.push({buffer:0,byteOffset:byteLength,byteLength:buffer.length,target:34962});
  byteLength+=buffer.length;
  chunks.push(buffer);
  const index=gltf.accessors.length;
  gltf.accessors.push({bufferView:view,componentType:5126,count:values.length/3,type:'VEC3',min,max});
  return index;
}
for(const [name,mesh] of groups) {
  if(mesh.normals.some(v=>!Number.isFinite(v))) throw Error('Degenerate face in '+name);
  const min=[Infinity,Infinity,Infinity],max=[-Infinity,-Infinity,-Infinity];
  mesh.positions.forEach((value,i)=>{
    min[i%3]=Math.min(min[i%3],value);max[i%3]=Math.max(max[i%3],value);
  });
  const position=accessor(mesh.positions,min,max);
  const normal=accessor(mesh.normals);
  const index=gltf.meshes.length;
  gltf.meshes.push({name,primitives:[{attributes:{POSITION:position,NORMAL:normal},material:materialIndex[mesh.material]}]});
  gltf.nodes.push({name,mesh:index,translation:offsets[name.split('_')[0]]||[0,0,0]});
  gltf.scenes[0].nodes.push(index);
}
gltf.buffers.push({byteLength});
const json=Buffer.from(JSON.stringify(gltf));
const jsonPadding=Buffer.alloc((4-json.length%4)%4,0x20);
const header=Buffer.alloc(20);
header.write('glTF');header.writeUInt32LE(2,4);
header.writeUInt32LE(20+json.length+jsonPadding.length+8+byteLength,8);
header.writeUInt32LE(json.length+jsonPadding.length,12);header.write('JSON',16);
const binary=Buffer.alloc(8);binary.writeUInt32LE(byteLength);binary.write('BIN\0',4);
const out=process.argv[2]||path.join(__dirname,'FlyHighScenery.glb');
fs.writeFileSync(out,Buffer.concat([header,json,jsonPadding,binary,...chunks]));
console.log(`Wrote ${groups.size} mesh groups to ${out}`);
