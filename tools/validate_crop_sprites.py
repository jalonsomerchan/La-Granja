"""Validate the mandatory eight distinct sprite states for every game variety.

Usage: python3 tools/validate_crop_sprites.py [--contract PATH]
Requires Pillow. Exits nonzero for missing/duplicated/clipped/opaque frames,
missing catalog/legacy mappings, or residual magenta in visible sprite pixels.
"""
from __future__ import annotations
import argparse
import hashlib
import json
import re
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
STATES = ['seed_bag','planted','growing_1','growing_2','growing_3','harvest_ready','inventory','rotten']


def validate(contract: dict, root: Path = ROOT) -> list[str]:
    errors = []
    entries = contract.get('crops', {})
    if contract.get('version') != 1 or contract.get('cell_size') != 64 or contract.get('states') != STATES:
        errors.append('Invalid sprite contract version, cell size or ordered states')
    catalog = json.loads((root/'assets/data/crops.json').read_text())
    db_source = (root/'scripts/crop_database.gd').read_text()
    wild_block = re.search(r'WILD_FRUITS: Array\[Dictionary\] = (\[.*?\])', db_source, re.S)[1]
    required = {c['id'] for c in catalog} | set(re.findall(r'"id":"([^"]+)"', wild_block))
    for crop_id in required:
        if crop_id not in entries: errors.append(f'{crop_id}: missing complete sprite set')
    names = json.loads(re.search(r'EXTENDED_NAMES := (\[.*?\])', db_source, re.S)[1])
    for i in range(len(names)):
        alias = f'catalog_{i:03}'
        target = contract.get('legacy_aliases', {}).get(alias)
        if target not in entries: errors.append(f'{alias}: missing visual mapping for legacy save')
    for crop_id, entry in entries.items():
        frames = entry.get('frames', {})
        if set(frames) != set(STATES) or set(frames.values()) != set(range(8)):
            errors.append(f'{crop_id}: needs exactly eight different frame indices')
            continue
        path_string = entry.get('sheet', '')
        if not path_string.startswith('res://assets/sprites/crops/lifecycle/'):
            errors.append(f'{crop_id}: atlas must live in the workspace lifecycle folder')
            continue
        path = root/path_string.removeprefix('res://')
        if not path.is_file():
            errors.append(f'{crop_id}: missing atlas {path_string}')
            continue
        with Image.open(path) as source:
            if source.mode != 'RGBA' or source.size != (512,64):
                errors.append(f'{crop_id}: expected RGBA atlas 512x64')
                continue
            atlas = source.copy()
        hashes = set()
        anchors = []
        for state in STATES:
            index = frames[state]
            frame = atlas.crop((index*64,0,(index+1)*64,64))
            bounds = frame.getbbox()
            if not bounds or bounds[0] <= 0 or bounds[1] <= 0 or bounds[2] >= 64 or bounds[3] >= 64:
                errors.append(f'{crop_id}/{state}: empty or clipped sprite ({bounds})')
                continue
            if state not in ['inventory','seed_bag']: anchors.append(bounds[3])
            digest = hashlib.sha256(frame.tobytes()).hexdigest()
            if digest in hashes: errors.append(f'{crop_id}/{state}: duplicated state artwork')
            hashes.add(digest)
            visible = [p for p in frame.getdata() if p[3] > 10]
            if any(r >= 220 and b >= 220 and g <= 60 and abs(r-b) <= 30 for r,g,b,a in visible):
                errors.append(f'{crop_id}/{state}: visible magenta key remains')
            if sum(p[3] == 0 for p in frame.getdata()) < 4096*0.2:
                errors.append(f'{crop_id}/{state}: missing transparent background')
        if anchors and max(anchors)-min(anchors) > 1:
            errors.append(f'{crop_id}: growing plants do not share the same ground anchor')
        source_path = root/'assets/sprites/crops/lifecycle/sources'/entry.get('source', '')
        if not source_path.is_file() or not source_path.with_suffix('.prompt.txt').is_file():
            errors.append(f'{crop_id}: preserve ImageGen source and prompt')
    return errors


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--contract', type=Path, default=ROOT/'assets/data/crop_sprite_contract.json')
    args = parser.parse_args()
    errors = validate(json.loads(args.contract.read_text()))
    if errors:
        for error in errors: print('ERROR:', error)
        raise SystemExit(1)
    contract = json.loads(args.contract.read_text())
    print(f'Crop sprites: {len(contract["crops"])} complete varieties, {len(contract["crops"])*8} distinct states; all checks passed')
