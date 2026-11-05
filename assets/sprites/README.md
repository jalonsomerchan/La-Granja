# Sprites del mundo

## Frutales y arbustos recolectables

`fruiting/` contiene cinco parejas `*_empty.png` / `*_ripe.png`: manzano y peral (80 × 96), bayas, arándanos y frambuesas (64 × 64). El juego cambia de sprite según `fruit_count`. Los robles usan la nueva copa sin fruta; siguen siendo árboles decorativos. La hoja fuente ImageGen está en `fruiting/raw-sheet.png`, el catálogo en `fruiting/atlas.json` y la comparación en `fruiting/preview.png` (izquierda vacía, derecha madura). Los archivos de procesamiento y QC quedan en `fruiting/processing/`, excluidos de la importación con `.gdignore`.

Prompt: conservar el estilo pixel art de los árboles y arbustos anteriores; cinco filas con dos estados de la misma planta, izquierda sin fruta y derecha con manzanas rojas, peras amarillas, bayas rojas, arándanos azules o frambuesas. Mantener copa, tronco, escala y anclaje; fondo magenta uniforme, sin terreno, texto ni elementos externos. `tools/pack_fruit_sprites.py` normaliza las bandas de la imagen y usa el procesador de `generate2dsprite` para quitar magenta, recortar, escalar y alinear cada pareja con escala común, comprobando que no toque los bordes. Para reproducirlo se necesitan Pillow, NumPy y la habilidad local `generate2dsprite`.

Atlas originales para los elementos que aparecen en la primera granja. Las imágenes fuente generadas se conservan en `generated/`; los recortes transparentes que usa el juego están en `trees/`, `props/` y `crops/`.

## Árboles

- `trees/oak.png`: árbol frondoso sin fruta, 80 × 96 px.
- `trees/apple.png`: manzano con frutos, 80 × 96 px.
- El pie de ambos sprites coincide con la casilla de colisión del tronco.

## Elementos de suelo

`props/ground_props_atlas.png` es un atlas de 3 × 3 con celdas de 64 × 64 px. Orden row-major y nombres en `props/atlas.json`: agrupación de piedras, roca grande, pareja de piedras, arbusto de bayas, arbusto florido, helecho, hierba alta, margaritas y cardo.

## Cultivos

`crops/seasonal/` contiene 12 atlas transparentes de 384 × 320: producto (`*_produce.png`), planta (`*_plants.png`) y bolsa de semillas (`*_seeds.png`) para cada una de las cuatro estaciones. Cada atlas tiene 6 columnas y 5 filas de celdas de 64 × 64. El campo `sprite_index` en `assets/data/crops.json` indica la celda de cada variedad; hay 30 por estación y 360 sprites en total.

Las plantas usan el sprite de su variedad a distintas escalas durante el crecimiento y tamaño completo al madurar. La etapa de semilla recién plantada conserva el brote pequeño. La humedad, marchitez y calidad mantienen los indicadores del juego. Los productos aparecen en la mochila y las manos; las bolsas, en tienda y selector de semillas.

Las cuatro fuentes ImageGen (`*_source.png`), prompts y QC se conservan junto a los atlas. El procesador `generate2dsprite` quita el magenta, recorta, escala y alinea; `tools/pack_seasonal_crops.py` empaqueta los tres atlas y rechaza celdas vacías o que toquen bordes. `processing/.gdignore` evita importar intermedios. El atlas anterior `crops/crop_atlas.png` se conserva como referencia.

## Estados del terreno

`terrain/terrain_atlas.png` reúne cuatro celdas de 32 × 32 px: hierba alta, suelo despejado, tierra arada y tierra arada con semilla. `atlas.json` asocia cada estado a su nombre y celda.

## Acciones del jugador

`animations/player_tool_actions.png` contiene seis filas de cuatro fotogramas en celdas de 32 × 48 px: hacha, azada, regadera, guadaña, pico y sembrado. Hay tiras individuales por acción y una copia invertida para las acciones hacia la izquierda. `atlas.json` documenta el orden y los 12 FPS.

## Vehículos

`vehicles/farm_truck_down.png`, `farm_truck_up.png`, `farm_truck_left.png` y `farm_truck_right.png` son las vistas frontal, trasera y laterales de la misma camioneta. El juego alterna la orientación mientras conduce y dibuja las cajas cargadas sobre la caja abierta. `farm_truck_views_source.png` conserva la hoja 2 × 2 generada con fondo magenta; `farm_truck_source.png` conserva la primera versión individual.

## Revisión visual del jugador y del terreno

Generación mediante la herramienta integrada ImageGen. Fuentes: `../generated/farmer_walk_refresh_source.png`, `generated/player_actions_refresh_source.png` y `generated/terrain_refresh_source.png`. Los originales anteriores se conservan como referencia.

Prompts utilizados: mantener la identidad del granjero (gorra verde petróleo, pelo castaño, camisa naranja, peto marrón y botas), mejorar la lectura de cara, manos y ropa, y producir una caminata de 4 × 4 y seis acciones de 4 fotogramas con escala uniforme y fondo magenta. Para el suelo, producir 16 baldosas contiguas con paleta natural: cuatro de pradera, cuatro de hierba alta, cuatro de tierra despejada, dos de surcos y dos de surcos sembrados, sin bordes decorativos ni texto.

`terrain/terrain_variants.png` es el atlas activo de 128 × 128 px, con celdas de 32 × 32. Sus filas son pradera, hierba alta, tierra despejada y cultivo (dos variantes aradas y dos sembradas). El renderizador elige variantes con un hash estable de coordenadas; el césped cambia de tono con las estaciones y la tierra regada se oscurece. Los caminos usan la tierra despejada. El atlas anterior de cuatro estados mantiene sus dimensiones de 64 × 64 px.

La caminata y las acciones conservan celdas transparentes de 32 × 48 px. Los pies se alinean en la fila 44 y la copia izquierda conserva el orden de los fotogramas. `tools/pack_sprite_refresh.py` empaqueta las hojas tras la limpieza de magenta mediante el procesador de generate2dsprite; genera metadatos `.qc.json` y previsualizaciones GIF de las cuatro direcciones.

## Objetos, casa y superficies construidas

Ampliación creada con la herramienta integrada ImageGen. Las fuentes están en `generated/farm_objects_source.png`, `generated/farmhouse_source.png` y `generated/surface_tiles_source.png`.

- `props/farm_objects_atlas.png`: hoja de 3 × 3, celdas de presentación de 96 × 96. `farm_objects.json` indica el tamaño de cada sprite individual: valla horizontal y vertical, caja de cosecha abierta, barril, sacos, cartel, pozo, puesto y banco. La caja PNG se utiliza también al transportarla y cargarla en la camioneta.
- `buildings/farmhouse.png`: casa de 144 × 144 con tejado de terracota, chimenea, madera, piedra, contraventanas y jardineras. Sustituye la casa dibujada con primitivas.
- `terrain/surface_variants.png`: atlas adicional de 128 × 128, celdas de 32 × 32 y cuatro variantes por material. Filas: cemento, asfalto, adoquines y grava. `surfaces.json` documenta el orden. El camino peatonal combina cemento y grava, con adoquines en su tramo sur; el ramal de la camioneta usa asfalto y marcas discontinuas de calzada.

Prompts: crear objetos aislados en una cuadrícula exacta de 3 × 3 sobre magenta, con perspectiva frontal ligeramente elevada, contornos oscuros y paleta cálida; mantener vacía la caja y sin texto el cartel. Crear por separado una casa acogedora, de frente, con puerta central accesible, tejado de tejas, chimenea, madera cálida, base de piedra, contraventanas verde petróleo, ventanas y jardineras, sin terreno alrededor. Crear un atlas opaco de 4 × 4 con cuatro variantes de cemento gris cálido con grietas finas, asfalto oscuro sin marcas, adoquines beige y grava clara; materiales contiguos, sin márgenes ni bordes decorativos y con contraste moderado para el fondo de juego.

Reempaquetado reproducible con `python3 tools/pack_world_refresh.py props|house|surfaces RUTA_FUENTE.png` (Pillow). La limpieza de magenta, el recorte, la alineación y el escalado son deterministas. Se conserva el atlas de terreno agrícola anterior.
