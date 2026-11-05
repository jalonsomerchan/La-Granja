"""Deterministically clean and pack generated farm props, house and road tiles.

Usage: python3 tools/pack_world_refresh.py props|house|surfaces SOURCE.png
Requires Pillow. No art is drawn by this script.
"""
import argparse
import json
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
ASSETS = ROOT/'assets/sprites'
PROPS = [('fence_horizontal',(64,32)),('fence_vertical',(32,64)),
         ('produce_crate',(48,40)),('barrel',(40,48)),('grain_sacks',(48,40)),
         ('wooden_sign',(40,48)),('well',(64,64)),('market_stand',(96,96)),('bench',(64,40))]


def clean(image):
    image = image.convert('RGBA')
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r,g,b,a = pixels[x,y]
            if r>60 and b>60 and r>g*1.3 and b>g*1.3:
                pixels[x,y] = (0,0,0,0)
            elif a<160:
                pixels[x,y] = (0,0,0,0)
            else:
                pixels[x,y] = (r,g,b,255)
    return image


def fit(image, size):
    bbox=image.getbbox()
    if not bbox: raise ValueError('Empty sprite')
    image=image.crop(bbox)
    scale=min((size[0]-2)/image.width,(size[1]-2)/image.height)
    image=image.resize((max(1,round(image.width*scale)),max(1,round(image.height*scale))),Image.Resampling.NEAREST)
    cell=Image.new('RGBA',size)
    cell.alpha_composite(image,((size[0]-image.width)//2,size[1]-image.height-1))
    return cell


def pack(kind, source):
    image=Image.open(source)
    if kind=='surfaces':
        sheet=Image.new('RGB',(128,128))
        for row,name in enumerate(['concrete','asphalt','cobblestone','gravel']):
            for col in range(4):
                tile=image.crop((col*image.width//4,row*image.height//4,(col+1)*image.width//4,(row+1)*image.height//4)).convert('RGB')
                tile=tile.resize((32,32),Image.Resampling.BOX)
                sheet.paste(tile,(col*32,row*32))
                if col==0: tile.save(ASSETS/'terrain'/f'{name}.png')
        sheet.save(ASSETS/'terrain'/'surface_variants.png')
        (ASSETS/'terrain'/'surfaces.json').write_text(json.dumps({'cell':[32,32],'columns':4,'rows':['concrete','asphalt','cobblestone','gravel']},indent=2)+'\n')
        return
    image=clean(image)
    if kind=='house':
        target=ASSETS/'buildings'
        target.mkdir(exist_ok=True)
        fit(image,(144,144)).save(target/'farmhouse.png')
        return
    atlas=Image.new('RGBA',(288,288))
    meta={}
    for i,(name,size) in enumerate(PROPS):
        row,col=divmod(i,3)
        left,right=col*image.width//3,(col+1)*image.width//3
        # The well crank protrudes slightly beyond its nominal source cell.
        if row==2 and col==0: right=round(image.width*0.356)
        if row==2 and col==1: left=round(image.width*0.356)
        frame=image.crop((left,row*image.height//3,right,(row+1)*image.height//3))
        frame=fit(frame,size)
        assert frame.getbbox()
        frame.save(ASSETS/'props'/f'{name}.png')
        atlas.alpha_composite(frame,(col*96+(96-size[0])//2,row*96+96-size[1]))
        meta[name]={'row':row,'column':col,'size':list(size)}
    atlas.save(ASSETS/'props'/'farm_objects_atlas.png')
    (ASSETS/'props'/'farm_objects.json').write_text(json.dumps(meta,indent=2)+'\n')


if __name__=='__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('kind',choices=['props','house','surfaces'])
    parser.add_argument('source',type=Path)
    args=parser.parse_args()
    pack(args.kind,args.source)
