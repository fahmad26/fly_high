import sys, json, hashlib, math
from pathlib import Path
sys.path.insert(0, str(Path('.local-tools/video-analysis').resolve()))
import av
from PIL import Image, ImageDraw

out = Path(__file__).parent
paths = [Path('D:/Downloads/WhatsApp Video 2026-11-11 at 23.41.36.mp4'), Path('D:/Downloads/WhatsApp Video 2026-11-11 at 23.41.337.mp4')]
metadata = []
for i, path in enumerate(paths, 1):
    c = av.open(str(path)); s = c.streams.video[0]
    duration = float(s.duration*s.time_base) if s.duration else c.duration/av.time_base
    meta = dict(file=str(path), sha256=hashlib.sha256(path.read_bytes()).hexdigest(), duration=duration, fps=float(s.average_rate), width=s.width, height=s.height, audio_streams=len(c.streams.audio))
    metadata.append(meta)
    targets = [j*duration/19 for j in range(19)]
    images=[]; n=0
    for frame in c.decode(s):
        t=float(frame.time)
        if n>=len(targets): break
        if t+0.001<targets[n]: continue
        im=frame.to_image().convert('RGB'); im.thumbnail((480,300))
        tile=Image.new('RGB',(480,325),'#161b25'); tile.paste(im,((480-im.width)//2,24))
        ImageDraw.Draw(tile).text((8,6),f'VIDEO {i}  {t:.2f}s',fill='white')
        images.append(tile); n+=1
    sheet=Image.new('RGB',(480*4,325*math.ceil(len(images)/4)),'#161b25')
    for j,im in enumerate(images):sheet.paste(im,((j%4)*480,(j//4)*325))
    sheet.save(out/f'video-{i}-overview.jpg',quality=88)
    c.close()
(out/'metadata.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
print(json.dumps(metadata,indent=2))
