# Condiciones del contenido del juego

## Frutas y cultivos: contrato visual obligatorio

Toda fruta o cultivo nuevo, incluidas las frutas silvestres, debe tener ocho sprites originales y distintos antes de incorporarse al catálogo:

1. `seed_bag`: bolsa de semillas con pictograma de la variedad.
2. `planted`: recién plantada.
3. `growing_1`: crecimiento 1.
4. `growing_2`: crecimiento 2.
5. `growing_3`: crecimiento 3.
6. `harvest_ready`: planta lista para recoger.
7. `inventory`: producto recolectado, para la mochila.
8. `rotten`: planta podrida, todavía en el suelo.

No sustituir fases por escalados, tintes o copias de una misma imagen. No usar una planta podrida genérica para varias especies. Conservar la identidad de la variedad, la escala de dibujo y el punto de apoyo durante el crecimiento. El producto de mochila debe aparecer separado de la planta; la bolsa debe mostrar su pictograma.

Usar un atlas RGBA de ocho celdas de 64 × 64, una fila por variedad, con margen transparente y sin fondo magenta residual. Registrar su ruta y los ocho estados en `assets/data/crop_sprite_contract.json`. Los cultivos se declaran en `assets/data/crops.json`; las frutas silvestres, en `CropDatabase.WILD_FRUITS`. No añadir una variedad sin su entrada completa en el contrato. Los identificadores antiguos de guardados pueden remitir a una variedad completa existente; no son variedades nuevas.

Las imágenes fuente deben generarse con ImageGen; conservar fuentes y prompts en `assets/sprites/crops/lifecycle/sources/`. El procesamiento local solo limpia transparencia, recorta, alinea y empaqueta. No dibujar los recursos artísticos con código como sustituto de su generación.

Antes de entregar cambios de catálogo o sprites:

- Ejecutar `python3 tools/validate_crop_sprites.py` (Pillow).
- Ejecutar `godot --headless --path . --script res://tests/crop_sprites_test.gd`.
- Comprobar la integración con `seasonal_crops_test.gd`, `rules_test.gd`, `interaction_test.gd`, `travel_test.gd` y `deck_test.gd`.
- Revisar el catálogo visual y una captura del juego a 1280 × 800.

Las ocho fases de campo, tienda y mochila deben consumir estos sprites. Cualquier ampliación debe respetar los controles con mando y la legibilidad de Steam Deck.

## Materiales y objetos fabricados

Los materiales y objetos nuevos se registran en `scripts/item_database.gd`, con nombre, descripción, valor de venta e icono original RGBA de 64 × 64. No usar letras ni sprites de cultivos como sustituto del icono de un material. Conservar fuentes de ImageGen, prompt y QC en `assets/sprites/items/sources/`; las operaciones locales solo limpian y empaquetan las imágenes. Actualizar `assets/sprites/items/atlas.json` y `MATERIALES.md`.

Todo botín y resultado de fabricación debe entrar en la misma mochila mediante `_add_item` o una transacción que sincronice sus huecos. Las recetas deben validar todos los ingredientes antes de consumirlos. La venta de cosechas no vende materiales ni semillas. Los objetos colocables y los efectos persistentes deben sobrevivir al guardado y no consumir unidades en usos inválidos. Verificar `tests/materials_test.gd`, `tests/backpack_test.gd` y `tools/validate_item_sprites.py`, además de la navegación con mando y una captura a 1280 × 800.
