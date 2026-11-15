// Procedural RGBA mask: dense center, transparent edge; no external image inputs.
const fs = require('fs');
const sharp = require('C:/Program Files/WindowsApps/OpenAI.Codex_26.1111.2228.0_x64__2p2nqsd0c76g0/app/resources/cua_node/bin/node_modules/sharp');
const size = 256;
const pixels = Buffer.alloc(size * size * 4);
for (let y=0; y<size; y++) for (let x=0; x<size; x++) {
  const nx=(x+0.5-size/2)/(size/2), ny=(y+0.5-size/2)/(size/2);
  const r=Math.hypot(nx,ny);
  const edge=Math.max(0,Math.min(1,(1-r)/0.38));
  const smooth=edge*edge*(3-2*edge);
  const grain=0.93+0.07*Math.sin(x*0.11+Math.sin(y*0.055)*2)*Math.cos(y*0.097);
  const offset=(y*size+x)*4;
  pixels[offset]=pixels[offset+1]=pixels[offset+2]=255;
  pixels[offset+3]=Math.round(255*smooth*grain);
}
const output='assets/models/obstacles/generated/weather_opacity_mask.png';
sharp(pixels,{raw:{width:size,height:size,channels:4}}).png().toFile(output).then(()=>{
  console.log(JSON.stringify({output,size,centerAlpha:pixels[((128*size)+128)*4+3],cornerAlpha:pixels[3]}));
});
