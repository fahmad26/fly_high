exec((__import__('pathlib').Path(__file__).parent/'extract.py').read_text().split('metadata = []')[0])
windows=[(1,5.5,19,.5,(0,250,576,790)),(2,0,7,.35,(0,300,576,880)),(2,85,94.5,.5,(0,280,576,900))]
for i,start,end,step,crop in windows:
    c=av.open(str(paths[i-1])); s=c.streams.video[0]
    targets=[start+j*step for j in range(int((end-start)/step)+1)]
    images=[]; n=0
    for f in c.decode(s):
        if n>=len(targets):break
        t=float(f.time)
        if t+.001<targets[n]:continue
        im=f.to_image().convert('RGB').crop(crop);im.thumbnail((360,390))
        tile=Image.new('RGB',(360,415),'#161b25');tile.paste(im,((360-im.width)//2,24))
        ImageDraw.Draw(tile).text((8,6),f'VIDEO {i} {t:.2f}s',fill='white')
        images.append(tile);n+=1
    sheet=Image.new('RGB',(1440,415*math.ceil(len(images)/4)),'#161b25')
    for j,im in enumerate(images):sheet.paste(im,((j%4)*360,(j//4)*415))
    sheet.save(out/f'video-{i}-{start:g}-{end:g}.jpg',quality=93)
    c.close()
