"""Validate the generated material icons without changing image content."""
import hashlib
import json
from pathlib import Path
from PIL import Image

root = Path(__file__).resolve().parents[1]
folder = root / 'assets/sprites/items'
atlas = json.loads((folder / 'atlas.json').read_text())
seen = set()
for item, resource in atlas['items'].items():
    path = root / resource.removeprefix('res://')
    image = Image.open(path).convert('RGBA')
    assert image.size == (64, 64), (item, image.size)
    box = image.getchannel('A').getbbox()
    assert box and min(box[:2]) >= 2 and max(box[2:]) <= 62, (item, box)
    pixels = [image.getpixel((x, y)) for y in range(64) for x in range(64)]
    assert any(a == 0 for r, g, b, a in pixels), item
    assert not any(a > 48 and r > 180 and b > 180 and g < 90 for r, g, b, a in pixels), (item, 'magenta')
    digest = hashlib.sha256(image.tobytes()).hexdigest()
    assert digest not in seen, (item, 'duplicate sprite')
    seen.add(digest)
print(f'Item sprites: {len(seen)} distinct transparent 64x64 icons passed')
