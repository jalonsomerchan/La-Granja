"""Pack cleaned generated sheets into the game's fixed-size runtime atlases.

Player inputs are raw-sheet-clean.png from generate2dsprite's processor.
Terrain input is the opaque generated 4x4 tileset. No art is drawn here.
"""
import argparse
import json
from pathlib import Path
from PIL import Image, ImageOps


def pack_player(source, output, rows):
    image = Image.open(source).convert('RGBA')
    # Remove residual chroma-key fringes left by antialiasing in the source.
    pixels = image.load()
    for y in range(image.height):
        for x in range(image.width):
            r,g,b,a = pixels[x,y]
            if r > 60 and b > 60 and r > g*1.3 and b > g*1.3:
                pixels[x,y] = (0,0,0,0)
    frames = []
    for row in range(rows):
        for col in range(4):
            left, right = col*image.width//4, (col+1)*image.width//4
            def boundary(index):
                if index == 0: return 0
                if index == rows: return image.height
                ideal = index*image.height//rows
                if rows != 6: return ideal
                # The generated action source has uneven row spacing. Find the
                # empty separator in each column so no boots or tool tips are cut.
                radius = image.height//rows//5
                alpha = image.getchannel('A')
                candidates = []
                for y in range(ideal-radius, ideal+radius+1):
                    occupied = sum(a >= 160 for a in alpha.crop((left,y,right,y+1)).getdata())
                    candidates.append((occupied, abs(y-ideal), y))
                return min(candidates)[2]
            frame = image.crop((left, boundary(row), right, boundary(row+1)))
            # Binary alpha and nearest sampling keep pixels crisp at game resolution.
            frame.putalpha(frame.getchannel('A').point(lambda a: 255 if a >= 160 else 0))
            bbox = frame.getbbox()
            if not bbox:
                raise ValueError(f'Empty frame {row}, {col}')
            frames.append(frame.crop(bbox))
    scale = min(30/max(f.width for f in frames), 40/max(f.height for f in frames))
    sheet = Image.new('RGBA', (128, rows*48))
    packed = []
    for i, frame in enumerate(frames):
        frame = frame.resize((max(1, round(frame.width*scale)), max(1, round(frame.height*scale))), Image.Resampling.NEAREST)
        cell = Image.new('RGBA', (32,48))
        cell.alpha_composite(frame, ((32-frame.width)//2, 44-frame.height))
        sheet.alpha_composite(cell, ((i%4)*32, (i//4)*48))
        packed.append(cell)
    sheet.save(output)
    if rows == 6:
        left = Image.new('RGBA', sheet.size)
        for i,cell in enumerate(packed):
            left.alpha_composite(ImageOps.mirror(cell), ((i%4)*32, (i//4)*48))
        left.save(output.parent/'player_tool_actions_left.png')
        for row,name in enumerate(['axe','hoe','water','scythe','pickaxe','plant']):
            sheet.crop((0,row*48,128,(row+1)*48)).save(output.parent/f'{name}.png')
    else:
        for row,name in enumerate(['down','left','right','up']):
            cells = packed[row*4:(row+1)*4]
            cells[0].save(output.parent/f'walk_{name}.gif', save_all=True, append_images=cells[1:], duration=165, loop=0, disposal=2)
    return {'cell':[32,48], 'rows':rows, 'columns':4, 'scale':scale, 'bounds':[list(f.getbbox()) for f in packed]}


def pack_terrain(source, output):
    image = Image.open(source).convert('RGB')
    sheet = Image.new('RGB',(128,128))
    for row in range(4):
        for col in range(4):
            tile = image.crop((col*image.width//4,row*image.height//4,(col+1)*image.width//4,(row+1)*image.height//4))
            tile = tile.resize((32,32),Image.Resampling.BOX)
            sheet.paste(tile,(col*32,row*32))
    sheet.save(output)
    # Keep the original public four-state atlas and standalone tiles in sync.
    legacy = Image.new('RGB',(64,64))
    for i,(name,col,row) in enumerate([('grass_high',0,1),('grass_cleared',0,2),('tilled',0,3),('sown',2,3)]):
        tile = sheet.crop((col*32,row*32,col*32+32,row*32+32))
        tile.save(output.parent/f'{name}.png')
        legacy.paste(tile,((i%2)*32,(i//2)*32))
    legacy.save(output.parent/'terrain_atlas.png')
    return {'cell':[32,32], 'rows':['short_grass','tall_grass','cleared_soil','tilled_2_and_sown_2'], 'columns':4}


if __name__ == '__main__':
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('kind',choices=['walk','actions','terrain'])
    parser.add_argument('input',type=Path)
    parser.add_argument('output',type=Path)
    args=parser.parse_args()
    args.output.parent.mkdir(parents=True,exist_ok=True)
    meta=pack_terrain(args.input,args.output) if args.kind=='terrain' else pack_player(args.input,args.output,4 if args.kind=='walk' else 6)
    args.output.with_suffix('.qc.json').write_text(json.dumps(meta,indent=2)+'\n')
    print(args.output)
