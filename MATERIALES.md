# Materiales y fabricación

Todos los recursos se almacenan, apilan, recolocan y guardan en la mochila. Los materiales de las partidas anteriores conservan sus identificadores y reciben los nuevos sprites automáticamente.

| Objeto | Obtención o utilidad | Venta por unidad |
|---|---|---:|
| Madera | Árboles: 5; tocones: 2. Tablones y taller. | 3 |
| Piedra | Todas las rocas: 3. Ladrillos y taller. | 3 |
| Fibra | Maleza y arbustos: 1. Cuerda y abono. | 2 |
| Arcilla | Rocas terracota: 2 además de la piedra. | 4 |
| Carbón | Rocas oscuras: 2 además de la piedra. | 6 |
| Mineral de hierro | Rocas con vetas ocres: 2 además de la piedra. | 9 |
| Tablón | Fabricación. Vallas y herramientas desde nivel 3. | 5 |
| Cuerda | Fabricación. Vallas y herramientas desde nivel 3. | 7 |
| Ladrillo | Fabricación. Apoyos de las vallas. | 9 |
| Lingote de hierro | Fabricación. Herramientas desde nivel 3. | 25 |
| Abono | Fabricación. +0,15 a la tirada de calidad de la siguiente cosecha. | 4 |
| Valla de madera | Fabricación. Colocable y recuperable con el hacha. | 12 |

## Recetas

| Resultado de una tanda | Coste |
|---|---|
| 2 tablones | 3 maderas |
| 1 cuerda | 4 fibras |
| 2 ladrillos | 3 arcillas, 1 piedra, 1 carbón |
| 1 lingote de hierro | 3 minerales de hierro, 1 carbón |
| 3 abonos | 2 fibras, 1 arcilla |
| 2 vallas | 2 tablones, 1 cuerda, 1 ladrillo |

«Fabricar ×5» multiplica todos los ingredientes y el resultado por cinco. Una operación comprueba todos los ingredientes antes de consumirlos. Los resultados entran en la misma mochila y conservan sus posiciones al recoger más unidades.

La venta de materiales se hace junto al mercadillo, desde los detalles del objeto o desde Tienda → Vender materiales. No incluye semillas ni otros recursos por error. «Vender cosecha» mantiene los materiales intactos.

El abono se aplica una vez sobre una casilla preparada, vacía o con una planta sana. No riega ni acelera días de crecimiento. Se conserva hasta la cosecha y se consume también cuando la planta da rebrotes. Las vallas requieren suelo libre propio, no ocupan cultivos, caminos, edificios ni al jugador. El hacha las devuelve enteras a la mochila.

## Recursos artísticos

Los 12 iconos de 64 × 64 se generaron con **ImageGen integrado**, siguiendo `generate2dsprite`, con los sprites de manzana como referencia de estilo. El procesamiento local solo elimina magenta, separa celdas, recorta, normaliza y exporta transparencia. No se dibujaron sustitutos procedurales.

- Sprites finales: `assets/sprites/items/{id}.png`.
- Índice: `assets/sprites/items/atlas.json`.
- Fuente original: `assets/sprites/items/sources/materials-raw.png`.
- Prompt exacto: `assets/sprites/items/sources/prompt-used.txt`.
- Parámetros y QC: `assets/sprites/items/sources/pipeline-meta.json`.
- Intermedios: `assets/sprites/items/processing/`, excluidos de importación y exportación.
- Catálogo, recetas y botines: `scripts/item_database.gd`.

Reproducción del procesamiento (Python con Pillow, NumPy y dependencias del procesador instaladas):

```sh
python generate2dsprite.py process --input assets/sprites/items/sources/materials-raw.png --target asset --mode single --output-dir assets/sprites/items/processing --rows 3 --cols 4 --cell-size 64 --fit-scale 0.85 --align center --component-mode all --min-component-area 12 --edge-touch-margin 2 --reject-edge-touch --label-prefix item
```

Las celdas se asignan en orden de lectura: madera, piedra, fibra, arcilla; carbón, mineral de hierro, tablón, cuerda; ladrillo, lingote, abono, valla. `tools/validate_item_sprites.py` valida tamaño, transparencia, margen, ausencia de magenta y dibujos distintos.
