# FARM LIFE

Juego de granja en Godot 4 y GDScript, sin servicios externos. El flujo de trabajo y la interfaz están preparados para jugar con mando a 1280 × 800, la resolución de Steam Deck.

## Ejecutar

Abre `project.godot` con Godot 4.3 o posterior y pulsa **F5**. Usa el renderizador Compatibility. La interfaz conserva su proporción al cambiar de resolución.

## Controles

| Acción | Steam Deck / mando | Teclado / ratón |
|---|---|---|
| Mover y orientar | Stick izquierdo | WASD / flechas |
| Apuntar a una casilla | Stick derecho | Ratón |
| Acción principal contextual | **A** | **E** |
| Herramienta seleccionada | **X** | Espacio / clic izquierdo |
| Cambiar herramienta | **L1 / R1** | R / Q o 1–6 |
| Cargar azada / regadera | Mantener **R2** y soltar | Mantener Mayús y soltar |
| Mochila | **Y** | I |
| Selector de semillas | Cruceta **↑** | Z |
| Variedad anterior / siguiente de esta estación | Cruceta **← / →** | V / C |
| Viajes | Cruceta **↓** | T |
| Subir / interactuar / vender cosecha | **A** | E |
| Aparcar y bajar | **X** | Espacio |
| Pausa | **Menú / Start** o B | Esc |
| Volver en menús / cancelar movimiento | **B** | Esc |
| Confirmar en menús | **A** | Intro / Espacio |
| Zoom | Pausa → Ajustes de juego y cámara | Rueda / + / − / Ajustes |
| Dormir | **A** junto a casa o desde pausa | E junto a casa / N / pausa |

Los índices de mando corresponden a **Godot 4**: L1/R1 son los botones 9/10; Menú es el botón 6. No hace falta usar pantalla táctil ni emular el ratón.

## Un ciclo de juego más directo

1. Apunta a una casilla dentro de tu terreno y pulsa **A**. La acción principal elige lo que necesita: despejar hierba, preparar tierra, plantar la semilla elegida, regar o cosechar. La ayuda inferior muestra la acción antes de ejecutarla. Las plantas frutales se conservan al recogerlas.
2. Cada fase requiere una pulsación nueva. Puedes **mantener A mientras avanzas por una fila** para repetir el mismo trabajo; mantenerlo sobre una casilla no encadena despejar, arar, sembrar y regar. Mantener X repite la herramienta seleccionada, con un intervalo entre usos.
3. La cosecha y la fruta se acumulan en la **mochila**, con sus calidades. Puedes recoger varias plantas y distintas variedades seguidas. Las herramientas manuales no cosechan accidentalmente un cultivo.
4. Semillas, cosechas, fruta silvestre, madera, piedra y fibra van directamente a tu mochila. Las pilas se agrupan por objeto y se añaden páginas automáticamente; no necesitas cajas ni cargar mercancía en el vehículo.
5. Pulsa **A** para subir a la camioneta. Toda la mochila viaja contigo, también a pie. En el puesto de la granja o la tienda del pueblo puedes vender la cosecha directamente; conduciendo junto al mercado, **A** vende y **X** aparca y permite bajar.
6. Duerme en casa para recuperar energía, llenar la regadera, avanzar el día y guardar. Las confirmaciones comienzan con **Cancelar** seleccionado.

Puedes desactivar la acción contextual desde **Pausa → Ajustes** y trabajar con la herramienta elegida mediante X. La herramienta seleccionada aparece resaltada en la barra. La mochila permite elegir directamente las semillas de la estación; el selector muestra desactivadas las de otras estaciones y la cruceta solo recorre variedades utilizables.

## Ritmo y accesibilidad

- Textos de interfaz principales de 20–30 px, ayudas de 18 px, botones grandes y foco de alto contraste.
- Tienda de 120 cultivos dividida en **6 páginas de 5 por estación**. L1/R1 cambian página. Las compras y los cambios de ajustes mantienen el foco en la misma posición.
- Los menús se recorren con stick, cruceta, flechas o WASD. Mantener una dirección repite con un intervalo controlado; el ruido del stick no salta varias opciones. B / Esc vuelve al menú anterior y recupera el elemento y desplazamiento que tenías.
- Stick derecho o rueda: desplazar listas. L2/R2 o RePág/AvPág: saltar cinco filas o avanzar en una página de lectura. Tab recorre opciones con teclado. El foco permanece dentro del menú y omite botones desactivados.
- En la tienda, las pestañas y los botones de venta/taller quedan fijos: L1/R1 cambia página y L2/R2 cambia estación. Las compras muestran su resultado dentro del menú.
- La mochila muestra **24 huecos por página en una cuadrícula de 6 × 4**. L1/R1 cambia entre Todo, Semillas, Cosecha y Materiales; L2/R2 o RePág/AvPág cambia de página. A / Intro abre los detalles. Cultivos y habilidades tienen sus propias vistas.
- Para recolocar una pila: **X / F**, elige destino con cruceta o stick y pulsa **A / Intro**. Un destino ocupado intercambia las dos pilas; B / Esc cancela. Puedes cambiar de página mientras mueves el objeto. Con ratón, arrastra con el botón izquierdo.
- **Y / O** ordena toda la mochila alfabéticamente y una segunda pulsación deshace ese orden. El orden manual se guarda con la partida y recoger nuevos objetos aprovecha huecos libres.
- La pausa muestra las acciones frecuentes sin desplazamiento. Guardar, cargar, nueva partida y salir se agrupan en **Pausa → Partida**. Abrir menús detiene el reloj.
- Cámara ajustable íntegramente con mando. El objetivo de trabajo vuelve a la dirección de marcha cuando te mueves, sin quedarse anclado a una dirección antigua del stick derecho.
- **Día tranquilo:** 6 minutos reales entre las 06:00 y medianoche. **Día ágil:** 3 minutos. El reloj se detiene en los menús.
- Tras 2 segundos quieto y sin trabajar, recuperas 1,5 puntos de energía por segundo. El río ofrece descanso de 20 minutos de juego y 15 de energía.
- Acción contextual, repetición mantenida, ritmo del día, vibración, herramienta elegida y cámara se incluyen en el guardado. La vibración se puede desactivar.
- Al perder el foco de la aplicación o desconectarse el mando utilizado, el juego se pausa. Abrir un menú cancela la carga de herramientas; los botones mantenidos deben soltarse antes de repetir trabajo al volver.

## Cultivos, herramientas y economía

Hay **120 variedades, 30 por estación**, con semillas, plantas y productos propios. Cada bolsa trae 5 semillas. La tienda muestra el precio de compra, venta por unidad, primera cosecha, rendimiento y rebrote. Catálogo completo en [CULTIVOS.md](CULTIVOS.md).

La tierra **seca es marrón clara y agrietada**; la **regada es marrón muy oscura, con reflejos húmedos**. El color sigue el riego real de ese día, incluida la lluvia, tanto en la parcela inicial como en la ampliación.

Los cultivos necesitan agua cada día. Sembrar no cuenta como riego; regar dos veces la misma casilla no gasta agua ni energía. La lluvia contribuye al crecimiento. Tres días secos o un cambio de estación marchitan la planta. La acción principal retira la planta seca y conserva el suelo preparado.

La azada y la regadera de nivel 2 permiten mantener R2 / Mayús y soltar para trabajar **3 × 3**, con vista previa. El taller permite elegir qué herramienta mejorar, sin depender de la herramienta que llevaras seleccionada. Cada mejora cuesta 80 monedas, 3 de madera y 2 de piedra; desde nivel 3 añade 2 tablones, 1 cuerda y 1 lingote de hierro.

Hacha, pico y guadaña proporcionan madera, piedra y fibra directamente a la mochila. Las calidades Normal, Buena, Excelente y Excepcional conservan su valor al mover, guardar y vender las pilas. La venta de cosechas conserva las semillas y los materiales. En los detalles puedes vender una pila completa si estás junto al mercado.

## Materiales, venta y fabricación

Madera, piedra, fibra, arcilla, carbón y mineral de hierro tienen sprites propios y se recogen directamente en la mochila. Al picar, las rocas grises dan piedra; las terracota añaden arcilla, las oscuras carbón y las de vetas ocres mineral de hierro. Las rocas de partidas anteriores también sirven.

En **Mochila → Fabricar** puedes hacer tablones, cuerda, ladrillos, lingotes de hierro, abono y vallas. La pantalla muestra existencias y coste por receta; **Fabricar ×1 / ×5** hace una o cinco tandas. L1/R1 cambia de página. También se accede desde el taller.

Los materiales y objetos fabricados se venden en sus detalles, por una unidad, cinco o la pila completa, estando junto a un mercado. **Tienda → Vender materiales** abre su categoría. **Vender cosecha** sigue conservando todos los materiales.

Equipa abono o vallas desde sus detalles. **A / E** los usa en la casilla de delante; **X** o cambiar de herramienta deja de usarlos. El abono mejora la probabilidad de calidad de la siguiente cosecha y permanece al regar y al avanzar los días; necesitas seguir regando. Las vallas se colocan en terreno propio libre, bloquean el paso y se recuperan enteras con el hacha. Se guardan con la partida. Desde nivel 3, las mejoras del taller consumen también 2 tablones, 1 cuerda y 1 lingote.

Recetas, precios y procedencia de los sprites en [MATERIALES.md](MATERIALES.md).

## Sprites de todas las frutas y cultivos

Cada variedad tiene **ocho sprites propios**: bolsa de semillas, recién plantada, crecimiento 1, crecimiento 2, crecimiento 3, lista para recoger, producto de mochila y planta podrida. Hay **1.160 sprites en 145 atlas**: los 120 cultivos, las frutas silvestres y las variedades adicionales de guardados antiguos.

El campo utiliza dibujos diferentes para crecer y pudrirse, con un punto de apoyo fijo. Tienda y selector muestran la bolsa, y la mochila muestra el producto recolectado. Las fases intermedias pueden cambiar durante un día regado; la cosecha respeta sus días de crecimiento.

Esta condición también se exige a las variedades nuevas mediante `AGENTS.md`, `assets/data/crop_sprite_contract.json`, la carga del catálogo y `tools/validate_crop_sprites.py`. No se admite una variedad nueva sin los ocho estados. Fuentes y prompts de ImageGen, atlas, QC y previsualizaciones se conservan en `assets/sprites/crops/lifecycle/`. Detalles de reproducción en [assets/sprites/README.md](assets/sprites/README.md).

## El valle

La granja ocupa 54 × 40 casillas. Incluye casa, mercadillo, pozo, parcela inicial, arroyo y ampliación por 450 monedas. Los árboles y objetos respetan edificios, cultivos, caminos y vallas. Las posiciones incompatibles de guardados antiguos se reparan al cargar.

La carretera recorre la parte inferior del mapa. Sal por la **izquierda para ir al río** o por la **derecha para ir al pueblo**. El paso entre zonas es automático al avanzar hasta el extremo, a pie o en camioneta. El menú Viajar también permite elegir destino.

- **Andando:** 30 minutos de juego y 5 de energía. La camioneta queda aparcada donde la dejaste.
- **En camioneta:** 10 minutos de juego; debes estar dentro o cerca del vehículo. Toda la mochila viaja contigo.
- **Río:** puente transitable, muelle para llenar la regadera y banco para descansar.
- **Pueblo:** tienda de semillas, taller, mercado de cosechas y fuente.

Puedes viajar con toda la mochila, sin límites de cajas ni pasos de carga.

Manzanos, perales y arbustos de bayas, arándanos y frambuesas dan fruta sin destruirse. Cada planta conserva su propio plazo de rebrote: manzano 3–5 días, peral 4–7, bayas y frambuesas 2–4, arándanos 3–5. La fruta madura permanece hasta recogerla. Los robles no dan fruta.

## Guardados

El archivo versionado es `user://farm_life_save.json`, con escritura temporal y respaldo. Conserva cultivos, objetos, calidades, el orden de los huecos de la mochila, zonas, camioneta, cámara y ajustes. Los guardados anteriores recuperan en la mochila el producto de las manos, cajas y camioneta sin duplicar las cantidades ya contabilizadas. La antigua carga mantiene su valor de venta exacto. La migración se realiza una sola vez. Dormir guarda al amanecer; también puedes guardar desde pausa. Nueva partida, cargar y volver al inicio piden confirmación.

## Recursos y exportación

- Personaje y animaciones: `assets/generated/` y `assets/sprites/animations/`.
- Entorno, plantas, vehículos y objetos: `assets/sprites/`.
- Frutas y cultivos: `assets/sprites/crops/lifecycle/`; catálogo visual en `preview_01.png` a `preview_07.png`.
- Audio local: `assets/audio/`. Herramientas de empaquetado: `tools/`.
- Exportaciones Linux x86-64 y Windows Desktop: `export_presets.cfg`.

La interfaz se ha revisado renderizando el juego a 1280 × 800 y los controles se prueban con eventos de mando simulados. **Queda pendiente validar la exportación en una Steam Deck física**, incluido suspensión/reanudación y vibración del dispositivo.

## Pruebas

Desde la raíz del proyecto, con Godot disponible como `godot`:

```sh
godot --headless --path . --script res://tests/rules_test.gd
godot --headless --path . --script res://tests/interaction_test.gd
godot --headless --path . --script res://tests/travel_test.gd
godot --headless --path . --script res://tests/seasonal_crops_test.gd
godot --headless --path . --script res://tests/deck_test.gd
godot --headless --path . --script res://tests/menu_navigation_test.gd
godot --headless --path . --script res://tests/backpack_test.gd
godot --headless --path . --script res://tests/materials_test.gd
godot --headless --path . --script res://tests/crop_sprites_test.gd
python3 tools/validate_crop_sprites.py
python3 tools/validate_item_sprites.py
```

Las pruebas de Steam Deck cubren asignación real de botones de Godot 4, trabajo contextual, repetición, apuntado, carga 3×3, pausa, desconexión, migración de guardados, transporte de la mochila, conservación del valor de las cosechas y navegación de menús.

Las pruebas de navegación recorren más de 200 objetos por páginas, retorno desde detalles, categorías, teclado, mandos externos, repetición mantenida, desplazamiento, compras, confirmaciones y pérdida de foco. Las pruebas de mochila cubren movimiento e intercambio entre páginas, arrastre, cancelación, ordenación y deshacer, persistencia y migración de cantidades/calidades/valor. Capturas de revisión a 1280 × 800 en `docs/backpack-review/` y `docs/menu-review/`. Para repetir la comprobación gráfica del arrastre: `godot --path . --script res://tests/backpack_test.gd -- --screenshots`.

Las pruebas de materiales verifican los botines, las seis recetas, cantidades insuficientes, venta parcial y completa, uso de abono, colisión y recuperación de vallas, mejoras avanzadas y guardados. Capturas a 1280 × 800 en `docs/materials-review/`. Para repetirlas con renderizado: `godot --path . --script res://tests/materials_test.gd -- --screenshots`.
