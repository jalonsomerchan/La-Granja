"""Pack the generated travel props after generate2dsprite processing.

Run from the project root: python3 tools/pack_travel_sprites.py
Requires Pillow. This only crops, scales and packs existing generated art.
"""
import sys,json
from pathlib import Path
sys.path.insert(0,str(Path('tools').resolve()))
from pack_world_refresh import fit
from PIL import Image
out=Path('assets/sprites/travel')
assets=[('village_shop',(192,192)),('river_bridge',(256,128)),('fishing_dock',(176,96)),('village_fountain',(128,128))]
meta={}
for i,(name,size) in enumerate(assets,1):
    sprite=fit(Image.open(out/'processing'/f'sheet-{i}.png'),size)
    sprite.save(out/f'{name}.png')
    meta[name]={'size':size,'source_cell':i,'alpha_bounds':sprite.getbbox()}
(out/'atlas.json').write_text(json.dumps(meta,indent=2)+'\n')
(out/'processing'/'.gdignore').touch()
