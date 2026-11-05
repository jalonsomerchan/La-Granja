"""Pack ImageGen sheets into the mandatory eight-state crop atlases.

Create the manifest: python3 tools/pack_crop_lifecycle.py plan
Clean/split sources: python3 tools/pack_crop_lifecycle.py process 1 2 ...
Pack cleaned frames: python3 tools/pack_crop_lifecycle.py pack

Processing requires Pillow, NumPy and the generate2dsprite skill. Packing and
validation need only Pillow. No artwork is drawn or synthesized by this tool.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
import subprocess
import sys
import unicodedata
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets/sprites/crops/lifecycle'
CONTRACT = ROOT / 'assets/data/crop_sprite_contract.json'
STATES = ['seed_bag', 'planted', 'growing_1', 'growing_2', 'growing_3', 'harvest_ready', 'inventory', 'rotten']
LABELS = ['Semillas', 'Plantada', 'Crece 1', 'Crece 2', 'Crece 3', 'Lista', 'Mochila', 'Podrida']
WILD = [dict(id='apple', name='Manzana'), dict(id='pear', name='Pera'), dict(id='wild_berries', name='Bayas silvestres'), dict(id='raspberry', name='Frambuesa')]
ALIASES = {'Manzano':'apple', 'Peral':'pear', 'Frambuesa':'raspberry', 'Grosella':'grosella_roja'}


def slug(name: str) -> str:
    return re.sub('[^a-z0-9]+', '_', unicodedata.normalize('NFKD', name).encode('ascii', 'ignore').decode().lower()).strip('_')


def plan() -> dict:
    crops = json.loads((ROOT / 'assets/data/crops.json').read_text())
    names = json.loads(re.search(r'EXTENDED_NAMES := (\[.*?\])', (ROOT / 'scripts/crop_database.gd').read_text(), re.S)[1])
    by_name = {c['name']:c['id'] for c in crops}
    extra = [dict(id=slug(name), name=name) for name in names if name not in by_name and name not in ALIASES]
    entries = {}
    packs = [crops[i:i+8] for i in range(0, len(crops), 8)] + [WILD] + [extra[i:i+8] for i in range(0, len(extra), 8)]
    for number, group in enumerate(packs, 1):
        for row, crop in enumerate(group):
            entries[crop['id']] = dict(name=crop['name'], sheet=f'res://assets/sprites/crops/lifecycle/{crop["id"]}.png', frames=dict(zip(STATES, range(8))), source=f'pack_{number:02}.png', row=row)
    aliases = {}
    for index, name in enumerate(names):
        aliases[f'catalog_{index:03}'] = by_name.get(name, ALIASES.get(name, slug(name)))
    data = dict(version=1, cell_size=64, states=STATES, crops=entries, legacy_aliases=aliases)
    CONTRACT.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n')
    (OUT / 'sources').mkdir(parents=True, exist_ok=True)
    (OUT / 'sources/plan.json').write_text(json.dumps([dict(source=f'pack_{i:02}.png', rows=[dict(id=c['id'], name=c['name']) for c in group]) for i, group in enumerate(packs, 1)], ensure_ascii=False, indent=2) + '\n')
    print(f'{len(entries)} varieties, {len(entries)*8} sprites, {len(packs)} source sheets')
    return data


def normalize_grid(source: Path, rows: int, output: Path) -> Path:
    """Move intact source cells onto a regular grid without resizing the art.

    ImageGen gutters can drift by a few pixels. Cut only in genuinely empty
    gutters, never through a plant, and use one pixel scale for the whole sheet.
    """
    import numpy as np
    raw = Image.open(source).convert('RGB')
    pixels = np.asarray(raw).astype(np.int16)
    foreground = ~((pixels[:,:,0] > 180) & (pixels[:,:,2] > 180) & (pixels[:,:,1] < 100))
    def boundaries(profile, count):
        size = len(profile)
        step = size / count
        cuts = [0]
        for i in range(1, count):
            center = round(i*step)
            candidates = range(max(cuts[-1]+1, round(center-step*0.28)), min(size-1, round(center+step*0.28)))
            candidates = [j for j in candidates if profile[j] == 0]
            if not candidates: raise ValueError(f'{source.name}: no empty gutter near boundary {i}/{count}')
            cut = min(candidates, key=lambda j: (int(profile[max(0,j-2):j+3].sum()), abs(j-center)))
            if profile[cut] != 0: raise ValueError(f'{source.name}: no empty gutter near boundary {i}/{count}')
            cuts.append(cut)
        return cuts + [size]
    ys = boundaries(foreground.sum(axis=1), rows)
    cells, boxes = [], []
    for row in range(rows):
        top, bottom = ys[row:row+2]
        xs = boundaries(foreground[top:bottom].sum(axis=0), 8)
        for col in range(8):
            left, right = xs[col:col+2]
            mask = foreground[top:bottom, left:right]
            active_y, active_x = np.nonzero(mask)
            if not len(active_y): raise ValueError(f'{source.name}: empty cell {row},{col}')
            box = (left+int(active_x.min()), top+int(active_y.min()), left+int(active_x.max())+1, top+int(active_y.max())+1)
            if box[0] == 0 or box[1] == 0 or box[2] == raw.width or box[3] == raw.height:
                raise ValueError(f'{source.name}: sprite crosses a cell edge at {row},{col}')
            cells.append(raw.crop(box))
            boxes.append(box)
    cell_size = max(max(cell.size) for cell in cells) + 32
    normalized = Image.new('RGB', (cell_size*8, cell_size*rows), '#ff00ff')
    for i, cell in enumerate(cells):
        normalized.paste(cell, ((i%8)*cell_size+(cell_size-cell.width)//2, (i//8)*cell_size+cell_size-cell.height-16))
    output.mkdir(parents=True, exist_ok=True)
    path = output/'normalized.png'
    normalized.save(path)
    (output/'source-boxes.json').write_text(json.dumps(dict(source=source.name, boxes=boxes), indent=2)+'\n')
    return path


def process(numbers: list[int], processor: Path) -> None:
    data = json.loads(CONTRACT.read_text())
    groups = {}
    for crop in data['crops'].values(): groups.setdefault(crop['source'], []).append(crop)
    for number in numbers:
        source = f'pack_{number:02}.png'
        output = OUT / 'processing' / source[:-4]
        if not (OUT / 'sources' / source).exists(): raise ValueError(f'Missing generated source: {source}')
        normalized = normalize_grid(OUT/'sources'/source, len(groups[source]), output)
        subprocess.run([sys.executable, str(processor), 'process', '--input', str(normalized), '--target', 'asset', '--mode', 'custom', '--rows', str(len(groups[source])), '--cols', '8', '--cell-size', '64', '--fit-scale', '0.84', '--align', 'bottom', '--shared-scale', '--trim-border', '0', '--edge-clean-depth', '0', '--reject-edge-touch', '--output-dir', str(output), '--prompt-file', str(OUT/'sources'/f'{source[:-4]}.prompt.txt')], check=True)


def pack() -> None:
    data = json.loads(CONTRACT.read_text())
    qc = []
    for crop_id, crop in data['crops'].items():
        atlas = Image.new('RGBA', (512, 64))
        hashes = set()
        frame_meta = {}
        for col, state in enumerate(STATES):
            frame_path = OUT/'processing'/crop['source'][:-4]/f'custom-{crop["row"]*8+col+1}.png'
            if not frame_path.exists(): raise ValueError(f'Missing processed frame: {frame_path}')
            frame = Image.open(frame_path).convert('RGBA')
            # Remove very faint magenta ringing introduced by resampling.
            # This is chroma-key cleanup only; species colors stay untouched.
            frame.putdata([(0,0,0,0) if r >= 220 and b >= 220 and g <= 60 and abs(r-b) <= 30 else (r,g,b,a) for r,g,b,a in frame.getdata()])
            bounds = frame.getbbox()
            if not bounds or bounds[0] <= 0 or bounds[1] <= 0 or bounds[2] >= 64 or bounds[3] >= 64:
                raise ValueError(f'{crop_id}/{state}: empty frame or clipped edge: {bounds}')
            digest = hashlib.sha256(frame.tobytes()).hexdigest()
            if digest in hashes: raise ValueError(f'{crop_id}: reused image for {state}')
            hashes.add(digest)
            atlas.alpha_composite(frame, (col*64, 0))
            frame_meta[state] = dict(bounds=list(bounds), sha256=digest)
        atlas.save(ROOT/crop['sheet'].removeprefix('res://'))
        qc.append(dict(id=crop_id, source=crop['source'], frames=frame_meta))
    (OUT/'qc.json').write_text(json.dumps(qc, ensure_ascii=False, indent=2)+'\n')
    preview(data)
    print(f'Packed {len(qc)*8} distinct nonempty sprites with transparent margins')


def preview(data: dict) -> None:
    try: font = ImageFont.truetype('/System/Library/Fonts/Supplemental/Arial.ttf', 15)
    except OSError: font = ImageFont.load_default()
    items = list(data['crops'].items())
    for start in range(0, len(items), 24):
        group = items[start:start+24]
        image = Image.new('RGBA', (880, 44+len(group)*76), '#21382e')
        draw = ImageDraw.Draw(image)
        draw.text((12,14), 'Variedad', fill='#ffe1a1', font=font)
        for col, label in enumerate(LABELS): draw.text((210+col*82,14), label, fill='#ffe1a1', font=font)
        for row, (crop_id, crop) in enumerate(group):
            y = 44+row*76
            if row % 2 == 0: draw.rectangle((0,y,879,y+75), fill='#2d4638')
            draw.text((12,y+25), crop['name'], fill='#fff0d0', font=font)
            atlas = Image.open(ROOT/crop['sheet'].removeprefix('res://')).convert('RGBA')
            for col in range(8): image.alpha_composite(atlas.crop((col*64,0,(col+1)*64,64)), (210+col*82,y+6))
        image.convert('RGB').save(OUT/f'preview_{start//24+1:02}.png')
    # Compact first-page sample for reviewing the actual in-game pixel scale.
    Image.open(OUT/'preview_01.png').crop((0,0,880,44+8*76)).save(OUT/'preview_sample.png')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=['plan','process','pack'])
    parser.add_argument('numbers', nargs='*', type=int)
    parser.add_argument('--processor', type=Path, default=Path.home()/'.codex/skills/generate2dsprite/scripts/generate2dsprite.py')
    args = parser.parse_args()
    if args.action == 'plan': plan()
    elif args.action == 'process': process(args.numbers, args.processor)
    else: pack()
