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
  DomeGold: [1, 195/255, 79/255], DomeRib: [1, 224/255, 145/255],
  CascadeBlue: [114/255, 192/255, 219/255], CascadeLight: [124/255, 201/255, 227/255],
  CascadeFoam: [141/255, 211/255, 233/255],
  OpalGlass: [0.47, 0.67, 0.79], WindowGlint: [0.77, 0.89, 0.97],
  CloudIvory: [250/255, 243/255, 230/255], CloudShade: [199/255, 209/255, 229/255],
  ReliefGold: [0.89, 0.68, 0.31], CarvedIvory: [0.96, 0.91, 0.80],
  CarvedShade: [0.77, 0.70, 0.58],
  ArrivalIvory: [0.93, 0.89, 0.79], ArrivalTrim: [0.83, 0.67, 0.36],
  ArrivalBase: [0.67, 0.65, 0.58], ArrivalSlate: [0.70, 0.75, 0.75],
  PortalGlow: [0.46, 0.80, 0.86], CascadeEdge: [0.51, 0.78, 0.87],
  PhotoStone: [0.88, 0.84, 0.74], PhotoSlate: [0.20, 0.34, 0.43],
  PhotoGold: [0.82, 0.65, 0.31], PhotoIvory: [0.99, 0.92, 0.76],
  PhotoAmber: [1, 0.79, 0.43],
  MasonryIvory: [0.93, 0.89, 0.81], MasonryCream: [0.95, 0.91, 0.84],
  MasonrySand: [0.91, 0.86, 0.78], ApproachMist: [0.99, 0.96, 0.90],
  ApproachShadow: [0.85, 0.89, 0.95],
  GalleryRecess: [0.15, 0.29, 0.39], GalleryGlass: [0.39, 0.64, 0.72],
  GardenLeaf: [0.29, 0.46, 0.42], GardenTip: [0.48, 0.63, 0.51],
  GardenBloom: [0.72, 0.57, 0.74], VistaShadow: [0.77, 0.77, 0.85],
  VistaIvory: [0.96, 0.90, 0.82],
  HorizonStone: [0.68, 0.66, 0.76], HorizonGold: [0.89, 0.77, 0.62],
  SkyHull: [0.40, 0.24, 0.28], SkyHullLight: [0.58, 0.36, 0.30],
  SkyBrass: [0.89, 0.68, 0.39], SkySail: [0.98, 0.94, 0.83],
  SkySailShade: [0.89, 0.82, 0.72],
  SkyPennant: [0.69, 0.32, 0.30],
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

function window(x,y,z,width,height,glass='DeepBlue',segments=8) {
  const radius=width/2;
  block(glass,x,y,z-.4,width,height,1.15);
  arch(glass,x,y+height,z+.18,radius,radius*1.1,radius-.03,1,segments);
  arch('Gold',x,y+height,z+.7,radius+.7,radius*1.1+.8,.85,1.2,segments);
  for(const side of [-1,1]) block('Gold',x+side*(radius+.25),y,z+.25,.65,height,1.35);
  block('Porcelain',x,y-.48,z+.4,width+2,.6,1.9,.2);
  block(glass==='DeepBlue'?'Turquoise':'WindowGlint',x,y+.8,z+.36,.58,height+radius*.78,.8);
}

function finial(x,z,y,scale) {
  rings(x,z,[[y,1.9*scale,1.9*scale,'Gold'],[y+2*scale,1.35*scale,1.35*scale,'Gold'],
    [y+5*scale,.6*scale,.6*scale,'GoldHighlight'],[y+6.5*scale,.12,.12,'Gold']],8);
}

function onionDome(x,z,y,r,h) {
  const outline=[[0,.72,'Gold'],[.06,.84,'DomeRib'],[.15,.98,'DomeGold'],[.27,1,'DomeGold'],
    [.40,.88,'DomeGold'],[.55,.67,'DomeGold'],[.69,.48,'DomeGold'],[.82,.29,'DomeGold'],
    [.92,.19,'DomeRib'],[1,.10,'DomeGold']];
  rings(x,z,outline.map(([level,width,mat])=>[y+level*h,width*r,width*r,mat]),32,{smooth:true});
  finial(x,z,y+h,r*.078);
}

function tower(x,z,r,height,base=0) {
  const top=base+height;
  const shaft=[[base,r*1.23,'Sandstone'],[base+2,r*1.23,'Ivory'],[base+4,r,'Porcelain'],
    [top-16,r*.88,'Ivory'],[top-14,r*.93,'Gold'],[top-12,r*.89,'Porcelain'],
    [top-7,r*.9,'Ivory'],[top-5,r*1.14,'Gold'],[top-3,r*1.17,'Porcelain'],[top,r*1.13,'Gold']];
  rings(x,z,shaft.map(([y,width,mat])=>[y,width,width,mat]),12);
  onionDome(x,z,top,r*1.24,r*2.85);
  for(const fraction of [.27,.56]) window(x,base+height*fraction,z+r*.9,r*.58,r*1.8,'OpalGlass',6);
}

function arcade(center,z,width,base,height,count) {
  block('Sandstone',center,base,z,width,2,29,3);
  block('Ivory',center,base+2,z-1,width-1,height-3,27,2.6);
  block('Porcelain',center,base+height-1,z,width,1.6,29,3);
  block('Gold',center,base+height+.6,z,width-.4,1.25,28.7,2.8);
  const span=(width-5)/count;
  for(let index=0;index<count;index++) {
    const x=center-width/2+2.5+(index+.5)*span;
    const radius=span*.37;
    const front=z+13.2;
    const spring=base+height*.63;
    block('Sandstone',x,base+2,front-.25,radius*2,spring-base-2,1);
    arch('Sandstone',x,spring,front+.32,radius,radius*1.16,radius-.05,.9,7);
    arch('Porcelain',x,spring,front+.85,radius+.74,radius*1.16+.82,1.05,1.75,8);
    block('OpalGlass',x,base+4,front+.34,radius*.72,spring-base-4,.3);
    block('Porcelain',x-span*.47,base+2,front+.38,1.4,spring-base-2,2.2,.31);
    block('Gold',x-span*.47,spring-.35,front+.36,2,.72,2.35,.29);
  }
}

function pavilion(x,z,base,r,height) {
  rings(x,z,[[base,r*1.10,r*1.10,'Sandstone'],[base+3,r*1.1,r*1.1,'Porcelain'],
    [base+5,r,r,'Ivory'],[base+height-3,r,r,'Porcelain'],[base+height-1,r*1.13,r*1.13,'Gold'],
    [base+height,r*1.15,r*1.15,'Gold']],24);
  for(const offset of [-r*.52,0,r*.52]) {
    const front=z+Math.sqrt(r*r-offset*offset);
    window(x+offset,base+6,front,r*.31,height-12,'OpalGlass');
    block('Porcelain',x+offset-r*.23,base+4,front-.6,.9,height-7,2,.25);
  }
  onionDome(x,z,base+height,r*1.13,r*1.68);
}

asset='Palace';
block('Sandstone',0,0,-37,73,3,60,6);
block('Ivory',0,3,-37,69,29,56,6);
block('Porcelain',0,32,-37,73,2.4,58,5);
block('Gold',0,34.4,-37,72,1.35,57,5);
block('Ivory',0,35.75,-39,65,3.4,50,4);
for(const x of [-31,-22,22,31]) {
  block('Porcelain',x,3,-8.5,3.4,27,4,.65);
  block('Gold',x,28.7,-8.1,4.8,1.9,4.7,.55);
  block('Ivory',x,3.4,-8.2,6,2.3,4.5,.6);
}
for(const x of [-25,25]) {
  window(x,8,-8.4,6.5,16,'OpalGlass');
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
tower(-52,-51,5.4,84);
tower(49,-54,5.1,72);
tower(-74,1,4.7,49);
tower(70,-7,4.6,50);
tower(81,-43,3.8,39);

arcade(-48,-10,44,0,24,5);
arcade(48,-9,45,0,24,5);
arcade(-41,-39,29,24.8,13,3);
arcade(48,-39,30,24.8,13,3);
pavilion(-30,-28,39.15,14.8,22.5);
pavilion(30,-33,39.15,13.8,20.5);
pavilion(55,-11,25.85,9.4,12.8);

block('Ivory',0,39.15,-48,43,7.5,42,5);
block('Gold',0,46.65,-48,42,1.3,41,4);
pavilion(0,-48,47.95,17.3,52);
for(const x of [-12,-6,6,12]) {
  const front=-48+Math.sqrt(17.3**2-x*x);
  block('Porcelain',x,52,front+.1,1.12,42.2,2.2,.36);
}
const crownY=136;
rings(0,-48,[[crownY,.8,.8,'WindowGlint'],[crownY+3,1.5,1.5,'WindowGlint'],
  [crownY+8,.16,.16,'WindowGlint']],8);

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

asset='PalaceOrnament';
// Shallow relief runs along the friezes and catches the low morning light.
function lozenge(x,y,z,radius,height,material) {
  const left=[x-radius,y,z], top=[x,y+height,z], right=[x+radius,y,z], bottom=[x,y-height,z];
  const crest=[x,y,z+.48];
  face(material,left,bottom,crest);
  face(material,bottom,right,crest);
  face(material,right,top,crest);
  face(material,top,left,crest);
}

function frieze(center,span,y,z) {
  block('CarvedShade',center,y-.12,z-.10,span,.95,.34,.10);
  block('CarvedIvory',center,y-.5,z+.07,span,.23,.3,.08);
  block('ReliefGold',center,y+.86,z+.05,span,.24,.34,.08);
  for(let x=center-span/2+1.2;x<center+span/2-.8;x+=2.5) {
    lozenge(x,y+.36,z+.13,.42,.29,'ReliefGold');
    lozenge(x+1.17,y+.36,z+.13,.30,.23,'CarvedIvory');
  }
}

frieze(-48,38,22.1,4.43);
frieze(51,32,22.1,5.43);
frieze(-18,31,33.25,-8.47);
frieze(7.9,13.8,33.25,-8.47);
frieze(-41,24,35.65,-24.55);
frieze(48,24,35.65,-24.55);

for(const [center,span,z] of [[-48,36,3.5],[52,30,4.5]]) {
  block('ReliefGold',center,26.9,z,span,.35,1.05,.3);
  block('CarvedIvory',center,25.8,z,span,.35,.94,.25);
  for(let x=center-span/2+1;x<center+span/2;x+=2.35) {
    rings(x,z,[[25.3,.57,.57,'CarvedIvory'],[25.84,.46,.46,'CarvedIvory'],
      [26.35,.22,.22,'ReliefGold'],[26.85,.39,.39,'CarvedIvory'],[27.15,.42,.42,'CarvedIvory']],8);
  }
}

for(const x of [-12.75,12.75]) {
  for(const offset of [-.88,-.44,0,.44,.88]) {
    block('CarvedShade',x+offset,4.1,-3.94,.12,10.5,.28,.03);
  }
  lozenge(x,15.56,-3.67,1.09,.81,'ReliefGold');
  for(const side of [-1,1]) lozenge(x+side*.98,15.35,-3.65,.40,.28,'CarvedIvory');
}

for(let i=1;i<12;i++) {
  const angle=Math.PI*i/12;
  const x=Math.cos(angle)*13.8;
  const y=18.6+Math.sin(angle)*14.8;
  if(y<32.1) lozenge(x,y,-5.02,.29,.46,'CarvedIvory');
}
lozenge(0,31.65,-5.15,.78,.7,'ReliefGold');

asset='PalaceArrival';
function roundDeck(x,z,width,depth,radius) {
  const corners=[[-1,-1],[1,-1],[1,1],[-1,1]];
  return corners.flatMap(([sx,sz],i)=>{
    const cx=x+sx*(width/2-radius),cz=z+sz*(depth/2-radius);
    return Array.from({length:5},(_,j)=>{
      const angle=Math.PI+(i+j/4)*Math.PI/2;
      return [cx+Math.cos(angle)*radius,cz+Math.sin(angle)*radius];
    });
  });
}

extrude('ArrivalBase',roundDeck(0,70,36.7,38,3.1),-2.1,-1.24);
extrude('ArrivalIvory',roundDeck(0,70,38.5,39,3.45),-1.24,-.47);
extrude('ArrivalTrim',roundDeck(0,70,39.15,39.55,3.6),-.47,-.29);
extrude('ArrivalSlate',roundDeck(0,70,40,40,4.0),-.29,.509);

const dockRimOuter=roundDeck(0,70,38.5,38.5,3.64);
const dockRimInner=roundDeck(0,70,37.76,37.76,3.27);
for(let i=0;i<dockRimOuter.length;i++) {
  const j=(i+1)%dockRimOuter.length;
  const point=([x,z])=>[x,.528,z];
  face('ArrivalTrim',point(dockRimOuter[i]),point(dockRimInner[i]),
    point(dockRimInner[j]),point(dockRimOuter[j]));
}

// The portal rests in a masonry recess with the blue light inside the opening.
block('ArrivalBase',45,.02,12.25,17.9,.24,12.2,1.1);
block('ArrivalIvory',45,.26,13.4,17.4,.31,10.1,.95);
for(const side of [-1,1]) {
  const x=45+side*7.6;
  block('ArrivalIvory',x,.56,13.72,2.9,1.26,6.95,.5);
  block('ArrivalIvory',x,1.82,13.62,2.32,4.9,6.78,.32);
  block('ArrivalTrim',x,6.3,13.64,2.48,.43,6.88,.34);
  block('ArrivalBase',x,1.35,8.9,2.82,4.6,5.4,.46);
  block('ArrivalIvory',x,5.95,8.9,2.76,.51,5.6,.4);
}
arch('ArrivalIvory',45,6.72,17.2,9,8.02,2.26,6.96,20);
arch('ArrivalTrim',45,6.72,17.36,7.38,6.45,.48,.48,20);
arch('ArrivalBase',45,6.72,16.42,6.85,6.04,.32,1.23,20);
arch('PortalGlow',45,6.72,16.27,6.55,5.92,.23,.28,20);
lozenge(45,13.82,17.35,.72,.95,'ArrivalTrim');

// Ivory inserts leave the original gilded cornices visible around the gallery roofs.
for(const [x,z,w] of [[-48,-10,44],[48,-9,45]]) {
  block('ArrivalIvory',x,25.854,z,w-3.1,.26,26.1,2.4);
  for(const side of [-1,1]) {
    const px=x+side*(w/2-3.4);
    for(const pz of [z-9,z+9]) {
      rings(px,pz,[[26.12,1.3,1.3,'ArrivalBase'],[26.6,1.25,1.25,'ArrivalIvory'],
        [28.07,.84,.84,'ArrivalIvory'],[28.51,1.12,1.12,'ArrivalTrim'],
        [28.76,1.10,1.10,'ArrivalTrim']],12);
    }
  }
}

asset='PalacePhoto';
const photoX=-45,photoZ=15;
rings(photoX,photoZ,[[-.04,11.89,11.89,'PhotoStone'],[.17,11.89,11.89,'PhotoStone'],
  [.25,11.59,11.59,'PhotoGold'],[.33,11.59,11.59,'PhotoStone'],[.45,11.36,11.36,'PhotoStone'],
  [.59,11.33,11.33,'PhotoStone'],[.66,11.16,11.16,'PhotoStone']],48);
rings(photoX,photoZ,[[.651,9.67,9.67,'PhotoGold'],[.677,9.67,9.67,'PhotoGold']],48);
rings(photoX,photoZ,[[.669,9.40,9.40,'PhotoSlate'],[.691,9.40,9.40,'PhotoSlate']],48);

// The eight points use raised faces and a gold center rather than floor decals.
for(let i=0;i<8;i++) {
  const angle=i*Math.PI/4;
  const point=(r,a,y)=>[photoX+Math.cos(a)*r,y,photoZ+Math.sin(a)*r];
  const tip=point(i%2===0?8.43:5.92,angle,.713);
  const a=point(1.62,angle-.33,.711);
  const b=point(1.62,angle+.33,.711);
  const crest=point(2.7,angle,.752);
  face('PhotoGold',a,crest,tip);
  face('PhotoIvory',crest,b,tip);
  const tickAngle=angle+Math.PI/8;
  face('PhotoGold',point(8.34,tickAngle+.038,.706),point(8.94,tickAngle,.706),
    point(8.34,tickAngle-.038,.706));
}
rings(photoX,photoZ,[[.694,1.8,1.8,'PhotoGold'],[.746,1.78,1.78,'PhotoStone'],
  [.782,1.26,1.26,'PhotoGold'],[.802,.65,.65,'PhotoIvory']],24);

for(const x of [photoX-10.1,photoX+10.1]) {
  const z=7.8;
  rings(x,z,[[.02,1.43,1.43,'PhotoStone'],[.32,1.43,1.43,'PhotoGold'],
    [.43,1.27,1.27,'PhotoStone'],[.58,1.08,1.08,'PhotoStone'],[1.52,.73,.73,'PhotoStone'],
    [1.69,1.06,1.06,'PhotoGold'],[1.84,1.06,1.06,'PhotoGold']],8,{rotation:Math.PI/8});
  rings(x,z,[[1.84,.82,.82,'PhotoAmber'],[2.57,.91,.91,'PhotoAmber'],
    [2.95,.70,.70,'PhotoAmber']],8,{rotation:Math.PI/8});
  for(let i=0;i<8;i++) {
    const angle=i*Math.PI/4+Math.PI/8;
    rings(x+Math.cos(angle)*.84,z+Math.sin(angle)*.84,
      [[1.83,.081,.081,'PhotoGold'],[2.94,.083,.083,'PhotoGold']],5);
  }
  rings(x,z,[[2.93,.99,.99,'PhotoGold'],[3.06,1.03,1.03,'PhotoGold'],
    [3.15,.88,.88,'PhotoStone'],[3.47,.44,.44,'PhotoStone'],[3.52,.26,.26,'PhotoGold'],
    [3.68,.22,.22,'PhotoGold'],[3.78,.09,.09,'PhotoGold']],8,{rotation:Math.PI/8});
}

asset='PalaceMasonry';
// Thin stone faces sit behind the arches and leave the existing wall visible in the joints.
function masonry(x,z,dx,dz,width,bottom,top,seed) {
  const shades=['MasonryIvory','MasonryCream','MasonrySand'];
  const point=(u,y)=>[x+dx*u,y,z+dz*u];
  const course=2.55, joint=.085;
  for(let row=0;bottom+row*course<top;row++) {
    const low=bottom+row*course+joint/2;
    const high=Math.min(top,bottom+(row+1)*course)-joint/2;
    if(high<=low) continue;
    for(let start=-(row%2)*2.7,col=0;start<width;col++) {
      const pattern=(row*7+col*3+seed)%11;
      const end=start+4.1+pattern*.35;
      const left=Math.max(0,start)+joint/2,right=Math.min(width,end)-joint/2;
      if(right>left) {
        const shade=shades[(pattern+row+col)%shades.length];
        face(shade,point(left,low),point(right,low),point(right,high),point(left,high));
      }
      start=end;
    }
  }
}
masonry(-28.5,-8.927,1,0,57,3,32,2);
masonry(34.573,-15,0,-1,44,3,32,4);
masonry(-34.573,-59,0,1,44,3,32,8);
masonry(-66.88,2.573,1,0,37.76,2,23,3);
masonry(28.62,3.573,1,0,38.76,2,23,7);
masonry(-69.573,-21.9,0,1,21.8,2,23,5);
masonry(70.073,.9,0,-1,21.8,2,23,9);

asset='PalaceGallery';
// Set the panes behind a projecting frame so the reveal reads from the terrace.
for(const [center,z,width] of [[-48,-10,44],[48,-9,45]]) {
  const span=(width-5)/5;
  const front=z+13.2;
  const spring=24*.63;
  for(let i=0;i<5;i++) {
    const x=center-width/2+2.5+(i+.5)*span;
    const r=span*.37-.36;
    const rise=span*.37*1.16-.30;
    const paneZ=front+.64;
    const frameZ=front+1.18;
    block('GalleryRecess',x,3.6,paneZ-.08,r*2,spring-3.6,.20);
    arch('GalleryRecess',x,spring,paneZ+.02,r,rise,r-.03,.16,12);
    arch('CarvedIvory',x,spring,frameZ,r+.08,rise+.08,.29,.63,12);
    for(const side of [-1,1]) {
      block('CarvedIvory',x+side*(r-.08),3.6,front+.87,.31,spring-3.6,.67);
      block('GalleryGlass',x+side*r*.32,4.35,paneZ+.12,r*.54,spring-4.45,.16,.07);
    }
    arch('GalleryGlass',x,spring,paneZ+.13,r*.67,rise*.72,r*.67-.04,.13,10);
    block('ReliefGold',x,4.25,paneZ+.27,.18,spring-4.25+rise*.64,.18);
    block('ReliefGold',x,spring-.21,paneZ+.28,r*1.25,.24,.23);
    block('CarvedIvory',x,3.1,front+1.13,r*2+.72,.55,1.36,.16);
    block('ReliefGold',x,3.65,front+1.15,r*2+.53,.13,1.15,.12);
  }
}

asset='PalaceGarden';
// Keep bases on the marble terrace, clear of the canal, cloud paths and photo podium.
for(const [x,z,scale,low] of [[-30,9,1,false],[-28,44,.78,true],[-34,42,.74,false],
  [19,33,.65,true],[56.8,10,.88,false],[22,47,.72,true]]) {
  const s=scale;
  if(low) {
    block('CarvedIvory',x,.08,z,7*s,1.2*s,4.7*s,.55*s);
    block('ReliefGold',x,1.14*s,z,7.15*s,.22*s,4.85*s,.57*s);
    block('GardenLeaf',x,1.33*s,z,6.32*s,.12*s,4.02*s,.49*s);
    for(const [dx,dz,y,r] of [[-2,0,1.5,1.2],[0,.34,2,1.28],[1.9,-.28,1.6,1.15]]) {
      rings(x+dx*s,z+dz*s,[[1.37*s,r*.65*s,r*.7*s,'GardenLeaf'],[(y+1.1)*s,r*s,r*s,'GardenLeaf'],
        [(y+2)*s,r*.65*s,r*.65*s,'GardenTip'],[(y+2.8)*s,.13*s,.14*s,'GardenTip']],9,{jitter:.10,smooth:true,phase:x});
      rings(x+dx*s,z+(dz+.75)*s,[[(y+.6)*s,.20*s,.24*s,'GardenLeaf'],
        [(y+1.45)*s,.57*s,.53*s,'GardenBloom'],[(y+1.82)*s,.31*s,.28*s,'GardenBloom']],7);
    }
    continue;
  }
  rings(x,z,[[.10,2.35*s,2.35*s,'CarvedIvory'],[.48,2.54*s,2.54*s,'CarvedIvory'],
    [1.7*s,2.17*s,2.17*s,'ReliefGold'],[1.91*s,2.52*s,2.52*s,'CarvedIvory'],
    [2.08*s,2.47*s,2.47*s,'GardenLeaf']],12);
  rings(x,z,[[1.95*s,.44*s,.42*s,'ReliefGold'],[4.85*s,.35*s,.34*s,'ReliefGold']],7);
  for(const [dx,dz,y,r] of [[-.83,.42,4.9,1.75],[.83,.53,5.38,1.74],[.12,-.86,5.74,1.92],[-.25,.08,6.62,1.42]]) {
    rings(x+dx*s,z+dz*s,[[(y-r*.67)*s,r*.45*s,r*.42*s,'GardenLeaf'],
      [(y-.34)*s,r*.88*s,r*.83*s,'GardenLeaf'],[y*s,r*s,r*.97*s,'GardenLeaf'],
      [(y+r*.65)*s,r*.72*s,r*.75*s,'GardenTip'],[(y+r*.91)*s,r*.16*s,r*.16*s,'GardenTip']],10,
      {jitter:.07,smooth:true,phase:x*.2+dz});
  }
  for(let i=0;i<4;i++) {
    const a=i*tau/4+x;
    const fx=x+Math.cos(a)*1.55*s, fz=z+Math.sin(a)*1.55*s;
    rings(fx,fz,[[1.95*s,.14*s,.14*s,'GardenLeaf'],[2.44*s,.46*s,.48*s,'GardenBloom'],
      [2.82*s,.19*s,.21*s,'GardenBloom']],6);
  }
}
for(const [x,z,tall] of [[-27.5,50,true],[-16,35,false],[16,35,false],[27.5,50,true]]) {
  const lantern=[[.1,1,1,'CarvedIvory'],[.48,1.02,1.02,'ReliefGold'],[.62,.64,.64,'CarvedIvory'],
    [2.55,.55,.55,'ReliefGold'],[2.78,.88,.88,'ReliefGold'],[3,.78,.78,'PhotoAmber'],
    [3.73,.78,.78,'ReliefGold'],[4.04,.96,.96,'ReliefGold'],[4.24,.32,.32,'ReliefGold']];
  rings(x,z,lantern.map(([y,rx,rz,mat])=>[tall?y:y*.67,rx*(tall?1:1.19),rz*(tall?1:1.19),mat]),
    tall?8:6,{rotation:Math.PI/8});
}

asset='PalaceCloud';
rings(0,1,[[-45,16,25,'CloudShadow'],[-39,52,46,'CloudShadow'],[-30,77,67,'CloudWarm'],
  [-20,96,90,'Cloud'],[-10,101,99,'Cloud'],[-3,93,94,'CloudWarm'],[-.85,79,81,'Cloud']],48,
  {smooth:true,jitter:.16,phase:1.4});
for(const [x,z,s,phase] of [[-74,13,.75,3],[57,63,.71,5],[63,-58,.64,1],[-56,-66,.74,2]]) {
  rings(x,z,[[-22,11*s,10*s,'CloudShadow'],[-15,37*s,29*s,'CloudWarm'],[-7,48*s,41*s,'Cloud'],
    [-2,36*s,31*s,'Cloud'],[-.8,14*s,10*s,'Cloud']],24,{smooth:true,jitter:.19,phase});
}

asset='PalaceFoundation';
// Each row follows the middle of the stream with its own width.
function waterSheet(rows,lanes=15,softEdges=true) {
  const shades=['CascadeBlue','CascadeLight','CascadeBlue','CascadeFoam','CascadeLight','CascadeBlue','CascadeLight'];
  const vertex=(index,lane)=>{
    const [x,y,z,width]=rows[index];
    const t=lane/lanes;
    const corrugation=Math.sin(t*Math.PI*8+y*.05)*Math.min(.62,width*.028);
    return [x+(t-.5)*width,y,z+corrugation];
  };
  for(let row=0;row<rows.length-1;row++) for(let lane=0;lane<lanes;lane++) {
    const a=vertex(row,lane),b=vertex(row+1,lane),c=vertex(row+1,lane+1),d=vertex(row,lane+1);
    const edge=softEdges&&(lane===0||lane===lanes-1);
    const shade=edge?'CascadeEdge':shades[(lane*5+Math.floor(lane/4))%shades.length];
    face(shade,a,b,c,d);
    face(shade,d,c,b,a);
  }
}

function fallingStreams(rows, profiles, taper) {
  for(const [center,span] of profiles) {
    const strip=rows.map(([x,y,z,width],i)=>{
      const flow=Math.min(1,Math.max(0,(i-2)/3));
      const end=Math.max(0,(i-rows.length+3)/2);
      return [x+center*width,y,z+Math.sin(i*.72+center*8)*flow*.28,
        span*width*(1-flow*.24-end*taper)];
    });
    waterSheet(strip,5);
  }
}

// A stone spillway projects past the arcade so the water falls free of the facade.
block('Porcelain',24,35.45,-4.4,18.4,2.95,19.3,1.1);
block('Gold',24,36.1,-4.45,18.65,.38,19.7,.85);
for(const side of [-1,1]) {
  block('Porcelain',24+side*7.75,38.4,-4.6,1.65,1.65,18.1,.34);
  block('Gold',24+side*7.75,40.05,-4.6,1.70,.31,18.2,.32);
  block('Porcelain',24+side*6.6,33.7,-5,2.2,1.85,12,1.2);
  block('Porcelain',24+side*6.6,32.45,-7.4,1.86,1.28,7.8,.78);
}
fallingStreams([[24,38.5,-10,13.6],[24,38.49,3.7,13.8],[24,38.38,5.46,13.7],
  [24.06,37.35,6.44,13.25],[24.18,32.5,7.2,12.4],[24.34,25,7.68,11.8],
  [24.52,14,8.24,11.55],[24.34,4.1,8.94,12.8],[24.44,.25,9.82,14.4]],
  [[-.34,.32],[-.02,.32],[.32,.36]],0);

// A shallow receiving pool narrows into a channel that feeds the two lower falls.
const canal=[[24.44,.24,7.8,15.2],[24.7,.23,13.6,16.4],[26.9,.22,19.8,12.2],
  [31.7,.21,30.5,9.4],[40,.20,46,9.3],[47.8,.19,61,10.8],[51.2,.16,75,16.2],
  [52.4,.12,84,24],[53,.04,89,27]];
waterSheet(canal,13,false);
for(const side of [-1,1]) {
  for(let i=0;i<canal.length-2;i++) {
    const [x0,,z0,w0]=canal[i];
    const [x1,,z1,w1]=canal[i+1];
    const a=x0+side*(w0*.5+.3),b=x1+side*(w1*.5+.3);
    const outline=[[a-.57,z0],[a+.57,z0],[b+.57,z1],[b-.57,z1]];
    extrude('Porcelain',outline,-.10,i<2?.70:.43);
  }
}
block('Porcelain',24.44,-.08,7.35,16.8,.81,1.12,.29);

for(const [x,z,top,width,depth,lean] of [
  [-57,87,2.2,23,114,-3],[-36,90,1.7,15,120,-1],
  [46,88,.03,13,134,2],[61,87,.03,17,130,3],[77,77,.05,7.8,91,4],
]) {
  block('Porcelain',x,top-3.1,z-3.15,width+3.3,3,7.8,1);
  const rows=[[x,top+.08,z-4,width*.91],[x,top,z,width],[x,top-2,z+2.2,width*.99],
    [x+lean*.2,top-9,z+4.3,width*.94],[x+lean*.37,top-23,z+5.8,width*.94],
    [x+lean*.67,top-52,z+8.5,width*.90],[x+lean,top-depth*.78,z+10.8,width*.79],
    [x+lean*1.1,top-depth,z+13,width*.7]];
  const streams=width>16?[[-.34,.32],[-.02,.32],[.32,.36]]:[[-.23,.54],[.27,.46]];
  fallingStreams(rows,streams,.42);
}

// Fuse overlapping cloud volumes so there are no straight seams around the terrace.
function cloudField(lobes,{
  lower=[-120,-56,-118],upper=[123,26,125],step=7.4,shadeBelow=-20,
  shade='CloudShade',highlight='CloudIvory',
}={}) {
  function density(x,y,z) {
    let distance=1e6;
    for(const [cx,cy,cz,rx,ry,rz] of lobes) {
      const sample=(Math.hypot((x-cx)/rx,(y-cy)/ry,(z-cz)/rz)-1)*ry;
      const blend=Math.max(4.4-Math.abs(distance-sample),0)/4.4;
      distance=Math.min(distance,sample)-blend*blend*1.1;
    }
    return distance+Math.sin(x*.12+y*.17)*Math.sin(z*.113-y*.14)*.73;
  }
  const size=lower.map((start,i)=>Math.ceil((upper[i]-start)/step)+1);
  const samples=new Float32Array(size[0]*size[1]*size[2]);
  const index=(x,y,z)=>(z*size[1]+y)*size[0]+x;
  const point=(x,y,z)=>[lower[0]+x*step,lower[1]+y*step,lower[2]+z*step];
  for(let z=0;z<size[2];z++) for(let y=0;y<size[1];y++) for(let x=0;x<size[0];x++) {
    samples[index(x,y,z)]=density(...point(x,y,z));
  }
  const tetrahedra=[[0,1,3,7],[0,3,2,7],[0,2,6,7],[0,6,4,7],[0,4,5,7],[0,5,1,7]];
  const offsets=[[0,0,0],[1,0,0],[0,1,0],[1,1,0],[0,0,1],[1,0,1],[0,1,1],[1,1,1]];
  const normal=([x,y,z])=>unit([density(x+.3,y,z)-density(x-.3,y,z),
    density(x,y+.3,z)-density(x,y-.3,z),density(x,y,z+.3)-density(x,y,z-.3)]);
  const triangle=(a,b,c)=>{
    const n=normal(a);
    const crossProduct=cross(subtract(b,a),subtract(c,a));
    if(Math.hypot(...crossProduct)<1e-6) return;
    const oriented=crossProduct.reduce((sum,value,i)=>sum+value*n[i],0);
    if(oriented<0) [b,c]=[c,b];
    const mat=(a[1]+b[1]+c[1])/3<shadeBelow?shade:highlight;
    face(mat,a,b,c,null,[n,normal(b),normal(c)]);
  };
  for(let z=0;z<size[2]-1;z++) for(let y=0;y<size[1]-1;y++) for(let x=0;x<size[0]-1;x++) {
    const values=offsets.map(([dx,dy,dz])=>samples[index(x+dx,y+dy,z+dz)]);
    if(values.every(value=>value>=0)||values.every(value=>value<0)) continue;
    const corners=offsets.map(([dx,dy,dz])=>point(x+dx,y+dy,z+dz));
    const cut=(a,b)=>{
      const blend=values[a]/(values[a]-values[b]);
      return corners[a].map((value,i)=>value+(corners[b][i]-value)*blend);
    };
    for(const tetrahedron of tetrahedra) {
      const inside=tetrahedron.filter(corner=>values[corner]<0);
      const outside=tetrahedron.filter(corner=>values[corner]>=0);
      if(inside.length===1) triangle(...outside.map(corner=>cut(inside[0],corner)));
      if(outside.length===1) triangle(...inside.map(corner=>cut(corner,outside[0])));
      if(inside.length===2) {
        const [a,b,c,d]=inside.flatMap(from=>outside.map(to=>cut(from,to)));
        triangle(a,b,c);
        triangle(b,d,c);
      }
    }
  }
}

cloudField([
  [-3,-31,-2,95,21,86],[-60,-25,18,44,17,49],[55,-25,26,45,16,47],
  [-78,-13,-43,29,16,31],[-49,-15,-64,27,17,32],[-18,-13,-73,28,17,26],
  [22,-14,-72,28,19,27],[57,-13,-66,31,18,28],[85,-14,-45,27,17,32],
  [-89,-9,-22,22,14,25],[-79,0,-2,19,12,20],[-88,-7,17,25,13,23],
  [-94,-12,37,22,13,21],[-78,-7,47,23,15,21],[-72,3,35,16,12,17],
  [-74,0,63,22,13,20],[-60,-2,72,22,13,22],[-50,3,78,19,12,17],
  [-38,-3,84,16,11,15],[-37,-6,61,16,11,15],[-58,-10,55,18,10,15],
  [86,-8,-4,24,14,24],[78,1,10,16,12,19],[87,-9,30,23,16,22],
  [83,-2,48,18,13,18],[70,3,57,19,13,17],[60,-5,64,22,14,21],
  [60,1,79,18,11,17],[74,-6,77,19,10,19],[46,-5,82,16,11,18],
  [39,-8,69,15,10,18],[71,-9,94,16,9,14],
]);

asset='PalaceApproach';
// Stagger the banks along +Z, the real docking approach. Their inner edges leave the center clear.
const approachStyle={step:6.25,shadeBelow:1,shade:'ApproachShadow',highlight:'ApproachMist'};
cloudField([
  [-72,-9,63,43,21,25],[-58,5,64,27,16,17],[-48,10,70,17,11,13],
  [-82,2,80,30,20,21],[-55,2,91,22,12,16],[-76,-6,110,34,15,20],
  [-65,-8,132,24,11,19],[-95,-13,133,28,15,28],[-89,-10,160,26,13,21],
],{...approachStyle,lower:[-128,-36,32],upper:[-25,31,189]});
cloudField([
  [76,-10,56,43,21,25],[58,3,58,25,16,18],[50,8,64,20,11,13],
  [89,0,78,29,18,23],[59,0,88,24,14,18],[77,-4,109,33,16,20],
  [64,-8,133,23,11,19],[96,-13,146,28,15,27],[90,-10,164,24,13,19],
],{...approachStyle,lower:[25,-36,26],upper:[129,31,190]});

asset='PalaceVista';
// A low cloud sea and separate pavilion islands frame the palace from the dock.
function vistaCloud(lobes,shadeBelow,step=12) {
  const bounds=(sign)=>[0,1,2].map(axis=>{
    const extremes=lobes.map(lobe=>lobe[axis]+sign*lobe[axis+3]);
    return (sign<0?Math.min(...extremes):Math.max(...extremes))+sign*step;
  });
  cloudField(lobes,{lower:bounds(-1),upper:bounds(1),step,shadeBelow,
    shade:'VistaShadow',highlight:'VistaIvory'});
}
vistaCloud([[-277,-35,-303,86,24,60],[-187,-24,-342,94,28,59],[-95,-33,-378,111,25,60],
  [27,-38,-390,104,27,59],[138,-27,-371,100,28,59],[245,-24,-326,95,25,55],[328,-31,-258,83,23,61]],-37,15);
vistaCloud([[-353,51,-451,106,13,30],[-271,57,-467,86,10,24],[-219,53,-474,51,8,23]],46,10);
vistaCloud([[338,52,-441,99,14,30],[255,49,-484,85,10,24],[197,45,-497,47,7,19]],44,10);
for(const [x,y,z,s] of [[-172,4,-88,1],[174,3,-145,.84],[-275,24,-215,.66],[296,-3,-85,.77]]) {
  vistaCloud([[x,y-13*s,z,43*s,16*s,30*s],[x-26*s,y-9*s,z+9*s,23*s,13*s,22*s],
    [x+25*s,y-10*s,z-6*s,25*s,11*s,21*s],[x+8*s,y-12*s,z+22*s,20*s,10*s,15*s]],y-14*s,8);
  rings(x,z,[[y-20*s,8*s,6*s,'VistaShadow'],[y-7*s,21*s,14*s,'CarvedIvory'],
    [y+2*s,21*s,14*s,'CarvedIvory'],[y+4*s,17*s,11*s,'ReliefGold']],14,{jitter:.09});
  for(let i=0;i<6;i++) {
    const a=i*tau/6;
    const sx=x+Math.cos(a)*10.2*s, sz=z+Math.sin(a)*7.3*s;
    rings(sx,sz,[[y+4*s,1.45*s,1.45*s,'CarvedIvory'],[y+6*s,1.06*s,1.06*s,'CarvedIvory'],
      [y+18*s,1.06*s,1.06*s,'CarvedIvory'],[y+20*s,1.52*s,1.52*s,'ReliefGold']],8);
  }
  rings(x,z,[[y+19*s,12*s,9*s,'CarvedIvory'],[y+21*s,13*s,10*s,'ReliefGold'],
    [y+23*s,11*s,9*s,'CarvedIvory']],18);
  onionDome(x,z,y+23*s,9*s,13*s);
}

asset='HorizonArch';
// Open spans keep the far landmark readable as a silhouette through the haze.
vistaCloud([[-93,-16,6,65,24,36],[-30,-22,5,78,25,40],[43,-20,-6,75,26,40],
  [110,-17,9,55,21,32],[-142,-28,-14,36,15,26]],-27,11);
for(const x of [-105,-35,35,105]) {
  block('HorizonStone',x,-20,0,23,24,36,4);
  block('HorizonGold',x,4,0,23.8,2.2,37,3.8);
  block('HorizonStone',x,6,0,17.5,22,26,3.2);
  block('HorizonGold',x,27.5,0,22,3.6,31,3.5);
}
for(const x of [-70,0,70]) {
  arch('HorizonStone',x,28,12,36,34,7.7,25,16);
  arch('HorizonGold',x,28,12.4,36.5,34.5,2.3,1.2,16);
  block('HorizonStone',x,61,-.5,71,4.3,24,1.2);
  block('HorizonGold',x,65.3,-.5,71,1.6,25,.9);
}
for(const x of [-105,105]) {
  rings(x,0,[[30,10,11,'HorizonStone'],[56,9,10,'HorizonStone'],[62,11,12,'HorizonGold'],
    [67,11,12,'HorizonGold'],[79,6,6,'HorizonGold'],[89,.5,.5,'HorizonGold']],12,{smooth:true});
}

asset='HorizonSpire';
vistaCloud([[-83,-26,14,62,22,37],[-34,-17,-5,59,25,41],[19,-21,11,65,27,43],
  [79,-31,-10,61,21,39],[106,-28,17,42,16,31]],-27,10);
for(const [x,z,r,height] of [[-69,8,13,76],[-24,-18,20,105],[29,6,16,86],[67,-17,12,65]]) {
  rings(x,z,[[-38,r*.45,r*.45,'HorizonStone'],[-9,r*1.22,r*1.16,'HorizonStone'],
    [8,r*1.15,r*1.1,'HorizonGold'],[10,r*.8,r*.79,'HorizonStone'],
    [height*.63,r*.7,r*.65,'HorizonStone'],[height*.65,r*.87,r*.83,'HorizonGold'],
    [height*.72,r*.86,r*.83,'HorizonGold'],[height*.83,r*.48,r*.47,'HorizonGold'],
    [height,.4,.4,'HorizonGold']],14,{smooth:true});
}

asset='HorizonCloud';
vistaCloud([[-178,-6,19,91,16,43],[-95,-3,0,109,22,51],[-14,4,-12,125,26,57],
  [72,-1,-10,120,18,49],[162,-7,9,93,17,42],[225,-11,21,58,13,36]],-9,13);

asset='HorizonPavilion';
vistaCloud([[-85,-13,18,62,22,38],[-30,-23,-6,76,24,46],[35,-16,8,70,24,42],
  [88,-31,-24,57,24,33],[121,-25,19,43,17,31]],-25,9);
for(const [x,y,z,s] of [[-49,-4,5,.68],[9,9,-12,1],[59,-1,11,.67]]) {
  rings(x,z,[[y-12,34*s,22*s,'HorizonStone'],[y,34*s,22*s,'HorizonGold'],
    [y+3,28*s,19*s,'HorizonStone'],[y+8,26*s,18*s,'HorizonGold']],12);
  for(let i=0;i<8;i++) {
    const a=i*tau/8;
    const px=x+Math.cos(a)*19*s, pz=z+Math.sin(a)*13*s;
    rings(px,pz,[[y+8,2.4*s,2.4*s,'HorizonStone'],[y+32*s,1.9*s,1.9*s,'HorizonStone'],
      [y+34*s,2.7*s,2.7*s,'HorizonGold']],6);
  }
  rings(x,z,[[y+34*s,25*s,18*s,'HorizonGold'],[y+38*s,24*s,17*s,'HorizonGold'],
    [y+52*s,14*s,10*s,'HorizonStone'],[y+55*s,12*s,9*s,'HorizonGold'],
    [y+69*s,5.4*s,4.2*s,'HorizonGold'],[y+81*s,.5,.5,'HorizonGold']],14,{smooth:true});
}

// Hull stations taper the keel toward the stern and the raised prow.
function cloudSailer(name,length,beamWidth,depth,sails,pennant) {
  asset=name;
  const hullStations=[[-46,2,5,3],[-37,8,2,-7],[-19,12,1,-12],[0,13,1,-13],
    [21,11,2,-10],[39,6,5,-3],[49,.8,8,6]].map(([x,width,deck,keel])=>[x*length,width*beamWidth,deck,keel*depth]);
  function hullStation(t) {
    const last=hullStations.length-1;
    const index=Math.min(last-1,Math.max(0,Math.floor(t)));
    const fraction=Math.max(0,Math.min(1,t-index));
    const a=hullStations[Math.max(0,index-1)], b=hullStations[index];
    const c=hullStations[index+1], d=hullStations[Math.min(last,index+2)];
    return b.map((v,k)=>.5*(2*v+(c[k]-a[k])*fraction+
      (2*a[k]-5*v+4*c[k]-d[k])*fraction**2+(3*v-a[k]-3*c[k]+d[k])*fraction**3));
  }
  function hullPoint(t,angle) {
    const [x,width,deck,keel]=hullStation(t);
    return [x,deck+(keel-deck)*Math.sin(angle),width*Math.cos(angle)];
  }
  function hullNormal(t,angle) {
    const lengthwise=subtract(hullPoint(t+.012,angle),hullPoint(t-.012,angle));
    const across=subtract(hullPoint(t,angle+.012),hullPoint(t,angle-.012));
    return unit(cross(across,lengthwise));
  }
  for(let i=0;i<(hullStations.length-1)*4;i++) {
    const a=i/4,b=(i+1)/4;
    for(let j=0;j<16;j++) {
      const angle=j*Math.PI/16,next=(j+1)*Math.PI/16;
      const stripe=j===1||j===14;
      const material=stripe?'SkyBrass':(j<4||j>11?'SkyHullLight':'SkyHull');
      face(material,hullPoint(a,angle),hullPoint(a,next),hullPoint(b,next),hullPoint(b,angle),
        [hullNormal(a,angle),hullNormal(a,next),hullNormal(b,next),hullNormal(b,angle)]);
    }
    face('SkyHullLight',hullPoint(a,0),hullPoint(b,0),hullPoint(b,Math.PI),hullPoint(a,Math.PI));
    for(const rim of [0,Math.PI]) {
      const start=hullPoint(a,rim), end=hullPoint(b,rim);
      const rail=[start,end,[end[0],end[1]+1.45,end[2]],[start[0],start[1]+1.45,start[2]]];
      face('SkyBrass',...rail);
      face('SkyBrass',...rail.reverse());
    }
  }
  for(const [t,stern] of [[0,true],[hullStations.length-1,false]]) {
    const outline=Array.from({length:17},(_,j)=>hullPoint(t,j*Math.PI/16));
    const [x,,deck,keel]=hullStation(t);
    const center=[x,(deck+keel)*.5,0];
    for(let j=0;j<outline.length;j++) {
      const a=outline[j], b=outline[(j+1)%outline.length];
      face('SkyHull',center,stern?a:b,stern?b:a);
    }
  }

  // The cloth tapers to the head and shares smooth normals across its sewn panels.
  function skySail(mast,foot,top,width,side) {
    const vertex=(u,v)=>{
      const span=width*(1-.84*v+.06*Math.sin(Math.PI*v));
      return [mast+(u-.88)*span+v*1.8,foot+v*(top-foot)+u*2.4-Math.sin(Math.PI*u)*(1-v)*2,
        side*(.45+Math.sin(Math.PI*u)*Math.sin(Math.PI*(v*.88+.08))*width*.23)];
    };
    const normal=(u,v)=>unit(cross(subtract(vertex(u+.005,v),vertex(u-.005,v)),
      subtract(vertex(u,v+.005),vertex(u,v-.005))));
    for(let i=0;i<20;i++) for(let j=0;j<10;j++) {
      const u=i/20,v=j/10, nextU=(i+1)/20,nextV=(j+1)/10;
      const corners=[[u,v],[nextU,v],[nextU,nextV],[u,nextV]];
      const quad=corners.map(pair=>vertex(...pair));
      const normals=corners.map(pair=>normal(...pair));
      const material=i===0||i===19||i===7||i===13?'SkySailShade':'SkySail';
      face(material,...quad,normals);
      face(material,...quad.reverse(),normals.reverse().map(n=>n.map(value=>-value)));
    }
  }
  function skyLine(material,start,end,radius) {
    const direction=unit(subtract(end,start));
    const perpendicular=unit(cross(direction,Math.abs(direction[1])>.92?[1,0,0]:[0,1,0]));
    const binormal=cross(direction,perpendicular);
    const point=(center,i)=>center.map((value,k)=>value+radius*(perpendicular[k]*Math.cos(i*tau/6)+binormal[k]*Math.sin(i*tau/6)));
    for(let i=0;i<6;i++) face(material,point(start,i),point(start,i+1),point(end,i+1),point(end,i));
  }
  for(const [x,foot,top,width,side] of sails) {
    rings(x,0,[[2,1.35,1.35,'SkyHull'],[top+4,.62,.62,'SkyBrass'],[top+7,.28,.28,'SkyBrass']],8);
    skySail(x,foot,top,width,side);
    skyLine('SkyBrass',[x-width*.88,foot,.5*side],[x+width*.12,foot+2.4,.5*side],.45);
    const [railX,railWidth,railY]=hullStation(x<0?2.2:3.8);
    skyLine('SkyBrass',[x,top+2,0],[railX,railY,railWidth*.91],.30);
    skyLine('SkyBrass',[x,top+2,0],[railX,railY,-railWidth*.91],.30);
  }
  const [mast,,mastTop]=sails.at(-1);
  skyLine('SkyBrass',[mast,mastTop+2,0],[48*length,8,0],.34);
  for(let i=0;i<8;i++) {
    const point=(j,edge)=>[mast-j*1.85,mastTop+7-.21*j+Math.sin(j*.65)*1.2-edge*(5.9-j*.48),Math.sin(j*.63)*1.6];
    const quad=[point(i,0),point(i+1,0),point(i+1,1),point(i,1)];
    face(pennant,...quad);
    face(pennant,...quad.reverse());
  }
  block('SkyHull',-33*length,2,0,14*length,6,12*beamWidth,2);
  block('SkyBrass',-33*length,8,0,15*length,1.2,13*beamWidth,2);
}
cloudSailer('CloudSailer',1,1,1,[[-12,15,46,34,1],[20,13,57,40,-1]],'SkyPennant');
cloudSailer('CloudKetch',1.04,.78,.76,[[-19,14,39,28,1],[15,12,61,30,-1]],'SkyBrass');
cloudSailer('CloudCutter',.78,1.06,1.23,[[12,11,65,54,1]],'SkyBrass');

asset='UpperSkyCloud';
vistaCloud([[-210,-4,22,65,8,29],[-155,0,10,78,17,34],[-105,8,-1,88,24,39],
  [-52,1,-11,73,18,43],[-7,8,-21,68,21,35],[35,4,-32,63,13,29],
  [86,4,-53,55,9,27],[159,13,-65,66,11,26],[205,17,-70,51,7,20]],1,8);

asset='ZenithCloud';
// A ragged crescent with gaps separates the layers when seen from below.
vistaCloud([[-145,6,56,60,23,43],[-107,10,30,67,30,51],[-63,-3,6,61,26,47],
  [-12,4,-12,66,26,51],[37,12,-41,64,34,46],[86,0,-50,61,25,43],
  [132,-7,-42,54,17,36],[161,-9,-21,45,12,30],[-66,-6,62,47,13,31],
  [-108,-16,27,44,18,34],[-33,-20,-11,41,17,31],[47,-16,-31,49,20,33],
  [103,-13,-31,34,17,27],[-18,-10,48,42,12,31],[143,7,47,43,11,22],[195,6,36,29,8,16]],-13,6.6);

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
  Storm:[750,0,0], Sunset:[1050,0,0], Cosmic:[1290,0,0], PalaceFoundation:[1510,0,0],
  PalaceOrnament:[1780,0,0], PalaceArrival:[2010,0,0], PalacePhoto:[2260,0,0],
  PalaceMasonry:[2520,0,0], PalaceApproach:[2760,0,0],
  PalaceGallery:[3040,0,0], PalaceGarden:[3280,0,0], PalaceVista:[3850,0,0],
  HorizonArch:[4540,0,0], HorizonSpire:[4950,0,0], HorizonCloud:[5510,0,0],
  CloudSailer:[5950,0,0], UpperSkyCloud:[6320,0,0],
  ZenithCloud:[6950,0,0],
  HorizonPavilion:[7380,0,0], CloudKetch:[7630,0,0], CloudCutter:[7780,0,0],
};
const palaceOnly=process.argv.includes('--palace-only');
const palacePolish=process.argv.includes('--palace-polish');
const palaceWater=process.argv.includes('--palace-water');
const palaceArrival=process.argv.includes('--palace-arrival');
const palacePhoto=process.argv.includes('--palace-photo');
const palaceView=process.argv.includes('--palace-view');
const palaceSummit=process.argv.includes('--palace-summit');
const palaceHorizon=process.argv.includes('--palace-horizon');
const palaceSky=process.argv.includes('--palace-sky');
const palaceScenery=process.argv.includes('--palace-scenery');
const summitOffsets={PalaceGallery:[0,0,0],PalaceGarden:[240,0,0],PalaceVista:[770,0,0],PalaceFoundation:[1350,0,0]};
const horizonOffsets={HorizonArch:[0,0,0],HorizonSpire:[410,0,0],HorizonCloud:[970,0,0]};
const skyOffsets={CloudSailer:[0,0,0],UpperSkyCloud:[440,0,0],ZenithCloud:[1070,0,0]};
const sceneryOffsets={CloudSailer:[0,0,0],CloudKetch:[140,0,0],CloudCutter:[285,0,0],
  ZenithCloud:[560,0,0],HorizonPavilion:[990,0,0],PalaceGarden:[1300,0,0]};
const materials=Object.entries(palette).map(([name,rgb])=>{
  const dome=name==='DomeGold'||name==='DomeRib';
  return {name,pbrMetallicRoughness:{baseColorFactor:[...rgb,1],
    metallicFactor: dome ? .72 : 0, roughnessFactor: dome ? .33 : .83}};
});
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
  const assetName=name.split('_')[0];
  const reference=assetName.startsWith('Reference');
  const cloud=name==='PalaceFoundation_CloudIvory'||name==='PalaceFoundation_CloudShade';
  if(palaceOnly && !['Palace','PalaceFoundation','PalaceOrnament','PalaceArrival','PalacePhoto','PalaceMasonry','PalaceApproach'].includes(assetName) && !reference) continue;
  if(palacePolish && assetName!=='PalaceOrnament' && !cloud && !reference) continue;
  if(palaceWater && (assetName!=='PalaceFoundation'||cloud) && !reference) continue;
  if(palaceArrival && assetName!=='PalaceArrival' && (assetName!=='PalaceFoundation'||cloud) && !reference) continue;
  if(palacePhoto && assetName!=='PalacePhoto' && !reference) continue;
  if(palaceView && !['PalaceMasonry','PalaceApproach'].includes(assetName) && !reference) continue;
  if(palaceSummit && !(assetName in summitOffsets && (assetName!=='PalaceFoundation'||mesh.material.startsWith('Cascade'))) && !reference) continue;
  if(palaceHorizon && !(assetName in horizonOffsets) && !reference) continue;
  if(palaceSky && !(assetName in skyOffsets) && !reference) continue;
  if(palaceScenery && !(assetName in sceneryOffsets) && !reference) continue;
  if(mesh.normals.some(v=>!Number.isFinite(v))) throw Error('Degenerate face in '+name);
  const min=[Infinity,Infinity,Infinity],max=[-Infinity,-Infinity,-Infinity];
  mesh.positions.forEach((value,i)=>{
    min[i%3]=Math.min(min[i%3],value);max[i%3]=Math.max(max[i%3],value);
  });
  const position=accessor(mesh.positions,min,max);
  const normal=accessor(mesh.normals);
  const index=gltf.meshes.length;
  gltf.meshes.push({name,primitives:[{attributes:{POSITION:position,NORMAL:normal},material:materialIndex[mesh.material]}]});
  let translation=offsets[assetName]||[0,0,0];
  if(palaceOnly) {
    if(assetName==='PalaceFoundation') translation=[250,0,0];
    if(assetName==='PalaceOrnament') translation=[500,0,0];
    if(assetName==='PalaceArrival') translation=[750,0,0];
    if(assetName==='PalacePhoto') translation=[1000,0,0];
    if(assetName==='PalaceMasonry') translation=[1250,0,0];
    if(assetName==='PalaceApproach') translation=[1500,0,0];
  } else if(palacePolish) {
    if(assetName==='PalaceFoundation') translation=[250,0,0];
    if(assetName==='PalaceOrnament') translation=[0,0,0];
  } else if(palaceWater && assetName==='PalaceFoundation') {
    translation=[250,0,0];
  } else if(palaceArrival) {
    if(assetName==='PalaceFoundation') translation=[250,0,0];
    if(assetName==='PalaceArrival') translation=[0,0,0];
  } else if(palacePhoto && assetName==='PalacePhoto') {
    translation=[0,0,0];
  } else if(palaceView) {
    if(assetName==='PalaceMasonry') translation=[0,0,0];
    if(assetName==='PalaceApproach') translation=[300,0,0];
  } else if(palaceSummit && !reference) {
    translation=summitOffsets[assetName];
  } else if(palaceHorizon && !reference) {
    translation=horizonOffsets[assetName];
  } else if(palaceSky && !reference) {
    translation=skyOffsets[assetName];
  } else if(palaceScenery && !reference) {
    translation=sceneryOffsets[assetName];
  }
  gltf.nodes.push({name,mesh:index,translation});
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
const out=process.argv.slice(2).find(arg=>!arg.startsWith('--'))||
  path.join(__dirname,palaceScenery?'FlyHighPalaceScenery.glb':palaceSky?'FlyHighPalaceSky.glb':palaceHorizon?'FlyHighPalaceHorizon.glb':palaceSummit?'FlyHighPalaceSummit.glb':palaceView?'FlyHighPalaceView.glb':palacePhoto?'FlyHighPalacePhoto.glb':palaceArrival?'FlyHighPalaceArrival.glb':palaceWater?'FlyHighPalaceWater.glb':
    palacePolish?'FlyHighPalacePolish.glb':palaceOnly?'FlyHighPalace.glb':'FlyHighScenery.glb');
fs.writeFileSync(out,Buffer.concat([header,json,jsonPadding,binary,...chunks]));
console.log(`Wrote ${gltf.meshes.length} mesh groups to ${out}`);
