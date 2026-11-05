"""Normalize generated fruit pairs, then run the generate2dsprite processor.
Only chroma cleanup, cropping, alignment and atlas packing; no artwork is drawn.
Usage: PYTHONPATH=/private/tmp/farm-sprite-deps python3 tools/pack_fruit_sprites.py SOURCE
"""
import importlib.util
import json
from pathlib import Path
import shutil
import subprocess
import sys
from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
PROCESSOR = Path.home()/'.codex/skills/generate2dsprite/scripts/generate2dsprite.py'
NAMES = ['apple', 'pear', 'berry', 'blueberry', 'raspberry']

def pack(source):
    dest = ROOT/'assets/sprites/fruiting'
    dest.mkdir(exist_ok=True)
    (dest/'processing').mkdir(exist_ok=True)
    (dest/'processing/.gdignore').touch()
    shutil.copy2(source, dest/'raw-sheet.png')
    spec = importlib.util.spec_from_file_location('sprite_processor', PROCESSOR)
    processor = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(processor)
    raw = Image.open(source).convert('RGBA')
    clean = processor.remove_bg_magenta(raw.copy(), 100, 150)
    # Generated rows have unequal spacing: locate the five separated plant bands.
    occupied = [clean.crop((0, y, clean.width, y+1)).getbbox() is not None for y in range(clean.height)]
    bands = []
    for y, filled in enumerate(occupied):
        if filled and (y == 0 or not occupied[y-1]): start = y
        if filled and (y == clean.height-1 or not occupied[y+1]): bands.append((start, y+1))
    assert len(bands) == 5, bands
    metadata = {}
    preview = Image.new('RGBA', (160, 480))
    for row, (name, (top, bottom)) in enumerate(zip(NAMES, bands)):
        # Equal square cells with generous padding, preserving each pair's scale.
        pair = Image.new('RGBA', (1024, 512), (255, 0, 255, 255))
        for col in range(2):
            frame = raw.crop((col*raw.width//2, top, (col+1)*raw.width//2, bottom))
            pair.paste(frame, (col*512, (512-frame.height)//2))
        work = dest/'processing'/name
        work.mkdir(parents=True, exist_ok=True)
        pair.save(work/'normalized.png')
        size = 96 if row < 2 else 64
        subprocess.run([sys.executable, str(PROCESSOR), 'process', '--input', str(work/'normalized.png'), '--target', 'asset', '--mode', 'single', '--rows', '1', '--cols', '2', '--cell-size', str(size), '--fit-scale', '0.86' if row < 2 else '0.92', '--align', 'bottom', '--shared-scale', '--reject-edge-touch', '--output-dir', str(work)], check=True, stdout=subprocess.DEVNULL)
        qc = json.loads((work/'pipeline-meta.json').read_text())
        assert not qc['edge_touch_frames']
        files = []
        for col, state in enumerate(['empty', 'ripe']):
            frame = Image.open(work/f'single-{col+1}.png')
            if row < 2: frame = frame.crop((8, 0, 88, 96))
            bbox = frame.getbbox()
            assert bbox and bbox[0] > 0 and bbox[2] < frame.width
            file = f'{name}_{state}.png'
            frame.save(dest/file)
            files.append(file)
            preview.alpha_composite(frame, (col*80+(80-frame.width)//2, row*96+96-frame.height))
        metadata[name] = {'files': files, 'cell': [80,96] if row < 2 else [64,64], 'source_band': [top,bottom], 'edge_touch': False}
    preview.save(dest/'preview.png')
    (dest/'atlas.json').write_text(json.dumps(metadata, indent=2)+'\n')
    # Keep the historical apple sprite entry point in sync.
    shutil.copy2(dest/'apple_ripe.png', ROOT/'assets/sprites/trees/apple.png')
    shutil.copy2(dest/'apple_empty.png', ROOT/'assets/sprites/trees/oak.png')
    shutil.copy2(dest/'berry_ripe.png', ROOT/'assets/sprites/props/berry_bush.png')

if __name__ == '__main__': pack(Path(sys.argv[1]))
