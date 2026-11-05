# Sprites del mundo

## Frutas y cultivos: ocho estados obligatorios

El contenido activo está en `crops/lifecycle/`: **145 atlas RGBA de 512 × 64**, ocho celdas de 64 × 64 por variedad, **1.160 sprites**. Abarca 120 cultivos estacionales, cuatro frutas silvestres adicionales y 21 variedades exclusivas de guardados antiguos. Los identificadores históricos que ya representan una variedad actual usan un alias hacia su juego completo de sprites.

Orden de izquierda a derecha de cada atlas:

| Celda | Estado | Uso |
|---:|---|---|
| 0 | `seed_bag` | Bolsa de semillas con pictograma; tienda, selector y mochila |
| 1 | `planted` | Semilla recién plantada |
| 2 | `growing_1` | Primer crecimiento |
| 3 | `growing_2` | Segundo crecimiento |
| 4 | `growing_3` | Tercer crecimiento, anterior a la madurez |
| 5 | `harvest_ready` | Planta madura lista para recoger |
| 6 | `inventory` | Producto recolectado, separado de la planta |
| 7 | `rotten` | Planta podrida de esa variedad |

Cada fase tiene un dibujo propio. El renderizador mantiene un lienzo y anclaje constantes; no simula el crecimiento escalando la planta madura ni reutiliza una planta marchita genérica. En cultivos rápidos, las fases intermedias también pueden cambiar durante una jornada regada, sin adelantar su disponibilidad para cosechar. Los frutales silvestres muestran la planta con fruto maduro o todavía en desarrollo según su contador de rebrote; los robles decorativos mantienen su arte anterior.

El registro obligatorio es `../data/crop_sprite_contract.json`. `scripts/crop_visuals.gd` carga los estados y `CropDatabase` rechaza variedades incompletas. `AGENTS.md` establece la condición para futuras incorporaciones. El generador del catálogo también exige los ocho estados y el archivo del atlas.

### Fuentes, prompts y reproducción

Las 19 hojas originales se generaron con la **herramienta integrada ImageGen**. Se conservan en `crops/lifecycle/sources/pack_XX.png`, junto con cada prompt completo en `pack_XX.prompt.txt` y el orden de filas en `plan.json`.

Los prompts solicitan el mismo estilo pixel art del juego, perspectiva frontal elevada, contornos definidos, fondo magenta uniforme y ocho columnas: bolsa, semilla plantada, tres dibujos de crecimiento, planta madura, producto y planta podrida. Las filas identifican explícitamente cada variedad. Las plantas pequeñas conservan su tamaño relativo; las fases de campo comparten el punto de apoyo y ninguna parte debe cruzar el margen de su celda.

Procesamiento determinista mediante la habilidad `generate2dsprite`: retirada del magenta, separación de celdas, escala común, alineación inferior y exportación transparente. `tools/pack_crop_lifecycle.py` encuentra los huecos reales entre sprites, sin recortar hojas, y empaqueta cada variedad. Después limpia posibles restos del color de clave introducidos por el remuestreo. Los intermedios y el QC de origen quedan en `processing/`; el QC final, en `qc.json`.

```sh
python3 tools/pack_crop_lifecycle.py plan
# Con Pillow, NumPy y la habilidad generate2dsprite instalada:
python3 tools/pack_crop_lifecycle.py process 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
python3 tools/pack_crop_lifecycle.py pack
python3 tools/validate_crop_sprites.py
godot --headless --path . --script res://tests/crop_sprites_test.gd
```

La validación comprueba cobertura de catálogo y guardados, ocho índices distintos, ocho imágenes distintas por variedad, tamaño, canal alfa, márgenes, anclaje y ausencia de magenta visible. Fuentes, prompts y procesamiento se excluyen de la importación con `.gdignore`. Las exportaciones incluyen el contrato JSON y excluyen los catálogos de revisión.

Previsualizaciones: `crops/lifecycle/preview_01.png` a `preview_07.png`, y muestra compacta en `preview_sample.png`. Capturas reales a 1280 × 800: `review/gameplay.png`, `review/inventory.png` y `review/seeds.png`.

Los atlas de `crops/seasonal/`, las parejas antiguas de `fruiting/` y sus herramientas de empaquetado se conservan como archivo de las versiones anteriores; el juego consume el contrato de ocho estados.

## Árboles

- `trees/oak.png`: árbol frondoso sin fruta, 80 × 96 px.
- `trees/apple.png`: manzano con frutos, 80 × 96 px.
- El pie de ambos sprites coincide con la casilla de colisión del tronco.

## Elementos de suelo

`props/ground_props_atlas.png` es un atlas de 3 × 3 con celdas de 64 × 64 px. Orden row-major y nombres en `props/atlas.json`: agrupación de piedras, roca grande, pareja de piedras, arbusto de bayas, arbusto florido, helecho, hierba alta, margaritas y cardo.

## Cultivos

El sistema activo se describe en «Frutas y cultivos: ocho estados obligatorios». Los atlas anteriores de `crops/seasonal/` y `crops/crop_atlas.png` son referencias históricas y ya no deciden las fases de crecimiento, mochila ni pudrición.

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
