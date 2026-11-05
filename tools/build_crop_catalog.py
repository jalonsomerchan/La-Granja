"""Build the explicit seasonal catalog and its Spanish review list."""
import json, re, unicodedata
from pathlib import Path
root = Path(__file__).resolve().parents[1]
seasons = json.loads((root/'assets/data/season_names.json').read_text())
# Growth / seed bag (5 seeds) / sale per item / regrowth. Existing prices retained.
original = {
 'Nabo dulce':('turnip',3,18,42,0),'Zanahoria':('carrot',4,14,35,0),
 'Patata':('potato',5,20,58,0),'Lechuga':('lettuce',4,16,40,0),
 'Fresa':('strawberry',6,32,30,3),'Tomate':('tomato',6,28,34,2),
 'Maíz dulce':('corn',6,22,45,2),'Pimiento':('pepper',6,26,38,2),
 'Melón':('melon',8,42,128,0),'Trigo':('wheat',4,12,28,0),
 'Arándano':('blueberry',7,35,24,3),'Calabaza':('pumpkin',9,38,110,0),
 'Berenjena':('eggplant',6,25,56,1),'Espinaca':('spinach',4,17,44,0),
 'Ajo':('garlic',5,19,52,0),
}
herbs = 'Albahaca Perejil Cilantro Cebollino Menta Manzanilla Lavanda Borraja Orégano Mejorana Eneldo Salvia Romero Tomillo Perifollo'.split()
grains = 'Trigo Lino Mostaza Arroz Mijo Sésamo Girasol Soja Cacahuete Garbanzo Lenteja Cebada Avena Centeno Alforfón Quinoa'.split()
fruits = ['Fresa','Arándano','Melón','Sandía','Frambuesa de verano','Mora','Physalis','Grosella roja']
repeaters = ['Tomate cherry','Pimiento rojo','Pimiento amarillo','Calabacín','Pepino','Judía verde','Albahaca morada','Mora','Frambuesa de verano','Physalis','Grosella roja','Chile','Okra','Tomatillo']
# Explicit first-harvest schedules for each seasonal row, in the same order as the artwork.
schedules = [
 [3,4,5,4,6,3,5,6,7,8,4,5,4,3,3,4,4,4,4,4,5,7,6,7,7,6,6,6,4,5],
 [6,6,6,8,4,7,5,6,6,5,5,9,5,7,8,8,6,7,8,4,5,4,4,7,7,6,6,6,6,6],
 [9,6,4,5,7,5,6,7,6,4,4,5,8,5,6,4,5,5,8,8,7,6,6,5,6,5,6,5,6,5],
 [3,4,4,5,6,7,7,6,7,7,8,6,4,6,4,3,5,6,7,8,8,4,5,4,5,5,3,3,4,4],
]
catalog=[]
for si,(slug,names) in enumerate(seasons):
 for i,name in enumerate(names.split(', ')):
  cid = re.sub('[^a-z0-9]+','_',unicodedata.normalize('NFKD',name).encode('ascii','ignore').decode().lower()).strip('_')
  days=schedules[si][i]; repeat=3 if name in repeaters or name.split()[0] in herbs else 0
  seed=10+days*3+(8 if repeat else 0); sell=12+days*7 if not repeat else 18+days*3
  if name in original: cid,days,seed,sell,repeat=original[name]
  category='Aromática' if name.split()[0] in herbs else ('Cereal y legumbre' if name in grains else ('Fruta' if name in fruits else 'Hortaliza'))
  catalog.append(dict(id=cid,name=name,category=category,season=['Primavera','Verano','Otoño','Invierno'][si],seasons=[['Primavera','Verano','Otoño','Invierno'][si]],seed=seed,seed_pack=5,sell=sell,days=days,repeat=repeat,regrow_days=repeat,water_per_day=1,stages=5,yield_amount=2,harvest_mode='repeat' if repeat else 'single',soil='tilled',experience=days+4,rarity='común',sprite_season=slug,sprite_index=i,product_sprite=f'res://assets/sprites/crops/seasonal/{slug}_produce.png',plant_sprite=f'res://assets/sprites/crops/seasonal/{slug}_plants.png',seed_sprite=f'res://assets/sprites/crops/seasonal/{slug}_seeds.png'))
for c in catalog: c['yield']=c.pop('yield_amount')
(root/'assets/data/crops.json').write_text(json.dumps(catalog,ensure_ascii=False,indent=2)+'\n')
lines=['# Cultivos por estación','', '120 cultivos jugables. Los precios se expresan en monedas del juego; la semilla se vende en bolsas de 5. Rendimiento: 2 productos por cosecha. Los días cuentan jornadas regadas (la lluvia también riega). Tras 3 días secos la planta se marchita; al cambiar de estación se marchitan las variedades de la anterior. Calendario de juego de 28 días por estación, no una guía agrícola real.','']
for slug,names in seasons:
 group=[c for c in catalog if c['sprite_season']==slug]
 lines+=['## '+group[0]['season'],'','| Producto | Bolsa ×5 | Venta/unidad | Primera cosecha | Rebrote |','|---|---:|---:|---:|---:|']
 lines += [f"| {c['name']} | {c['seed']} | {c['sell']} | {c['days']} días | {str(c['repeat'])+' días' if c['repeat'] else 'Única'} |" for c in group]
 lines += ['']
(root/'CULTIVOS.md').write_text('\n'.join(lines)+'\n')
print(f'{len(catalog)} crops written')
