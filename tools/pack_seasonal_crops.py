"""Process ImageGen sources, then pack three 6x5 atlases per season.

python3 tools/pack_seasonal_crops.py SEASON SOURCE.png [--process]
Processing needs generate2dsprite and NumPy; packing only needs Pillow.
"""
import json, os, shutil, subprocess, sys
from pathlib import Path
from PIL import Image
root=Path(__file__).resolve().parents[1]
out=root/'assets/sprites/crops/seasonal'
slug,source=sys.argv[1:3]
processing=out/'processing'/slug
processing.mkdir(parents=True,exist_ok=True)
(out/'processing'/'.gdignore').touch()
if Path(source).resolve() != (out/f'{slug}_source.png').resolve():
 shutil.copyfile(source,out/f'{slug}_source.png')
if '--process' in sys.argv:
 # Generated grids can drift: locate blank bands before cutting individual cells.
 import numpy as np
 raw=Image.open(out/f'{slug}_source.png').convert('RGB')
 pixels=np.asarray(raw).astype(int)
 foreground=~((pixels[:,:,0]>140)&(pixels[:,:,2]>120)&(pixels[:,:,1]<130))
 def spans(active):
  result=[]; start=None
  for pos,value in enumerate(list(active)+[False]):
   if value and start is None: start=pos
   if not value and start is not None:
    result.append((start,pos))
    start=None
  return result
 rows=spans(foreground.sum(axis=1)>5)
 if len(rows)!=10: raise ValueError(f'{slug}: expected 10 rows, got {len(rows)}')
 normalized=Image.new('RGB',(1152,1280),'#ff00ff')
 for row,(top,bottom) in enumerate(rows):
  columns=spans(foreground[top:bottom].sum(axis=0)>2)
  if len(columns)!=9: raise ValueError(f'{slug} row {row}: expected 9 cells, got {len(columns)}: {columns}')
  for col,(left,right) in enumerate(columns):
   cell=raw.crop((left,top,right,bottom))
   cell.thumbnail((108,108),Image.Resampling.NEAREST)
   normalized.paste(cell,(col*128+(128-cell.width)//2,row*128+(128-cell.height)//2))
 normalized.save(processing/'normalized.png')
 processor=Path.home()/'.codex/skills/generate2dsprite/scripts/generate2dsprite.py'
 subprocess.run([sys.executable,str(processor),'process','--input',str(processing/'normalized.png'),'--target','asset','--mode','custom','--rows','10','--cols','9','--cell-size','64','--fit-scale','0.84','--align','bottom','--component-mode','all','--output-dir',str(processing),'--prompt-file',str(out/f'{slug}.prompt.txt')],check=True)
crops=[c for c in json.loads((root/'assets/data/crops.json').read_text()) if c['sprite_season']==slug]
qc=[]
for offset,kind in enumerate(['produce','plants','seeds']):
 atlas=Image.new('RGBA',(384,320))
 for i,crop in enumerate(crops):
  frame=Image.open(processing/f'custom-{i*3+offset+1}.png').convert('RGBA')
  bounds=frame.getbbox()
  if not bounds: raise ValueError(f'Empty {crop["id"]} {kind}')
  if bounds[0]==0 or bounds[1]==0 or bounds[2]==64 or bounds[3]==64: raise ValueError(f'Edge touch: {crop["id"]} {kind}')
  atlas.alpha_composite(frame,((i%6)*64,(i//6)*64))
  qc.append(dict(id=crop['id'],kind=kind,bounds=bounds))
 atlas.save(out/f'{slug}_{kind}.png')
(out/f'{slug}.qc.json').write_text(json.dumps(qc,indent=2)+'\n')
print(f'{slug}: 90 transparent sprites, nonempty, no edge touching')
