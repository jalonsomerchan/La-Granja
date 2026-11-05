# FARM LIFE

Prototipo jugable de granja en Godot 4, GDScript y renderizado 2D. Todo el contenido funciona sin red ni servicios externos.

## Ejecutar

Abre `project.godot` con Godot 4.3 o posterior y pulsa **F6** para la escena abierta o **F5** para iniciar el proyecto. El proyecto usa el renderizador Compatibility y una ventana base de 1280 × 800.

## Controles

| Acción | Teclado | Mando |
|---|---|---|
| Mover | WASD / flechas | Stick izquierdo |
| Elegir casilla objetivo | Ratón | Stick derecho |
| Usar herramienta | Espacio | A |
| Recoger / interactuar | E | X |
| Inventario | I | Y |
| Herramienta anterior / siguiente | R / Q | L1 / R1 |
| Cambiar variedad de semilla | V / C | Cruceta izquierda / derecha |
| Abrir selector de semillas | Z o botón «Elegir semilla» | Cruceta arriba o botón «Elegir semilla» |
| Cargar herramienta mejorada | Mayús | Mantener R2 |
| Confirmar dormir y guardar | N o E junto a la casa | X junto a la casa |
| Entregar cosecha a una caja | E junto a una caja | X junto a una caja |
| Recoger / soltar una caja | E junto a una caja | X junto a una caja |
| Mover una caja con el ratón | Mantener botón derecho y arrastrar | — |
| Cargar una caja completa en la camioneta | E junto a una caja, cerca de la camioneta | X junto a una caja, cerca de la camioneta |
| Subir / salir de la camioneta | E junto a la camioneta | X junto a la camioneta |
| Conducir / vender la carga en el mercadillo | WASD y E | Stick izquierdo y X |
| Ajustar zoom | Rueda del ratón o + / − | — |
| Menú de pausa | Esc | Menú / Start |
| Cerrar ventana | Esc | B |

Las interacciones **E/X** seleccionan el objeto cercano según la distancia y la casilla a la que apuntas. Un círculo resalta el objeto elegido y la ayuda indica la acción disponible. Puedes llenar la regadera en el pozo, la fuente o el muelle con **E/X**, o usando la regadera junto a ellos. La compra de terreno se activa junto a su cartel.

Las herramientas, la cosecha y el arrastre de cajas requieren estar cerca. Una casilla ya regada no vuelve a gastar agua ni energía. Las cajas incompletas se pueden recoger incluso cerca de la camioneta; una caja completa a su alcance se carga con E/X. Si llevas una caja, E/X permite soltarla o cargarla antes de interactuar con otros objetos.

El foco de los menús se puede recorrer con la cruceta, el stick o el teclado. El botón izquierdo del ratón usa la herramienta en la casilla señalada.

El menú de pausa permite continuar, iniciar una nueva partida, guardar, cargar y salir. Nueva partida y cargar piden confirmación para evitar perder progreso sin querer.

## Primer día

1. Elige **Azada** y prepara tierra dentro de la valla.
2. Selecciona **Semillas**, abre **Elegir semilla** (Z en teclado o ↑ en mando) y escoge una variedad que tengas en la mochila. Planta nabos, zanahorias o patatas durante primavera.
3. Cambia a **Regadera** y riega cada cultivo cada día para que crezca; sembrarlo no lo riega. La lluvia riega automáticamente las plantas de exterior. Los cultivos secos se ven caídos y llevan un indicador marrón; los regados están verdes y muestran gotas azules.
4. Pide dormir con **N** o interactúa con la casa usando **E/X** para ver la transición de noche a mañana, avanzar el día y guardar automáticamente. Al cosechar, lleva la fruta en las manos hasta una caja frente al mercadillo; cada caja admite cinco unidades del mismo cultivo. Cerca de las cajas aparece el botón **Guardar…**; también puedes usar **E/X** junto a ellas o el mostrador. Si ya están ocupadas, se prepara otra caja. La camioneta verde está aparcada al este de la granja: carga allí las cajas completas (hasta seis), súbete y conduce al mercadillo. Al girar, la camioneta muestra su vista frontal, trasera o lateral según la dirección. Al llegar, pulsa **E/X** para vender la carga; el importe respeta la calidad de la cosecha.
5. Tala, extrae roca y limpia maleza para reunir materiales; llena la regadera en el pozo.
6. Visita el puesto del mercadillo para comprar semillas, vender cosechas y mejorar la herramienta seleccionada.
7. La puerta del lado este lleva a la compra de la parcela del arroyo.

## Contenido implementado

- Distribución sin superposiciones: la vegetación reserva su contorno visible y un margen de separación, respetando edificios, vallas, caminos, arroyo, cultivos y cajas. Los árboles se dibujan a 64 × 80 y los objetos de suelo a 48 × 48; las cajas de 30 × 25 caben en su casilla. Al cargar se recolocan los objetos incompatibles conservando su fruta, plazos y daño; la ampliación también aplica estas reglas.

- Mapa de 54 × 40 casillas con césped con variaciones, camino, arroyo, parcela inicial, valla, casa, tienda, pozo, árboles, maleza y rocas.
- Personaje original con una hoja de 16 poses generada para caminar en cuatro direcciones. Su archivo fuente está en `assets/generated/farmer_walk.png`; la hoja ajustada a 32 × 48 está en `assets/generated/farmer_walk_32x48.png`.
- Efectos originales de tierra, agua, cosecha, madera y piedra en `assets/audio/`.
- Árboles, rocas, arbustos, maleza, flores y 120 variedades de plantas en atlas transparentes de `assets/sprites/`; el renderizador usa esos sprites para los objetos del mundo y los cultivos maduros.
- Manzanos, perales y arbustos de bayas, arándanos y frambuesas con sprites nuevos con fruta y sin fruta. Pulsa **E/X** cerca de la planta; apunta a su casilla para elegirla si hay varios objetos juntos para recoger 2–3 frutas sin destruirla; se llevan a cajas y se venden en la camioneta como las cosechas. Cada planta elige un plazo aleatorio tras recogerla: manzano 3–5 días, peral 4–7, bayas y frambuesas 2–4, arándanos 3–5. La fruta madura permanece hasta recogerla; los plazos y la fruta disponible se guardan incluso al cambiar de estación. Los robles son decorativos y no producen fruta; el hacha y la guadaña siguen permitiendo retirar árboles y arbustos.
- Cuatro sprites de terreno para hierba alta, suelo despejado, tierra arada y tierra sembrada; al usar la guadaña se despeja la casilla y la azada puede ararla después.
- El exterior de la granja aparece cubierto de hierba alta y vegetación, con más árboles, maleza, arbustos y rocas que hay que retirar. El sendero queda limpio y no admite herramientas.
- Zoom inicial aumentado, ajustable con la rueda o +/− y guardado con la partida. Quedarse quieto recupera energía poco a poco; dormir inicia el nuevo día y guarda la partida.
- Transición animada de sueño y amanecer; cajas físicas para agrupar y llevar al mercadillo cosechas de cinco unidades del mismo cultivo. La fruta cosechada se muestra en las manos y queda guardada entre partidas.
- Camioneta pixel art con vistas frontal, trasera y laterales, caja visible en la parte trasera, carga para seis cajas completas, conducción rápida hasta el mercadillo y venta de la carga al llegar. Una carretera asfaltada con marcas discontinuas cruza únicamente la parte inferior del mapa, de izquierda a derecha. Sus extremos conectan automáticamente el río, la granja y el pueblo. Su posición, orientación, carga y estado de conducción se guardan con la partida.
- Animaciones de cuatro fotogramas para hacha, azada, regadera, guadaña, pico y sembrado; cada acción se reproduce cuando se usa esa herramienta.
- Herramientas, energía, agua, clima, día/noche, cuatro estaciones, riego por lluvia y deterioro comprensible tras tres días secos.
- 120 cultivos comprables y funcionales: 30 por estación, con sprites propios de producto, planta y bolsa de semillas. La tienda permite elegir estación y muestra precio por bolsa de 5, venta por unidad, primera cosecha, rendimiento y rebrote. Listado completo: [CULTIVOS.md](CULTIVOS.md).
- Las mejoras de nivel 2 o superior permiten cargar la azada y la regadera para trabajar una zona de 3 × 3 con vista previa.
- Cosecha repetida, calidad Normal/Buena/Excelente/Excepcional con bonificación comercial, habilidades, herramientas mejorables e inventario apilable.
- Ampliación del terreno del arroyo, guardado versionado en `user://farm_life_save.json` y respaldo temporal durante la escritura.
- Teclado, ratón, mando y navegación de interfaz sin pantalla táctil.
- Presets de exportación para Windows Desktop y Linux x86-64 en `export_presets.cfg`.

- Mejora visual del entorno: casa con tejado de tejas, chimenea y jardineras; vallas, cajas, barriles, sacos, cartel, pozo, puesto y banco con sprites pixel art. Suelos adicionales de cemento, asfalto, adoquines y grava, con cuatro variantes por material.

## Validaciones

Hay pruebas de reglas en `tests/rules_test.gd`. Ejecútalas desde la raíz del proyecto con:

```sh
godot --headless --path . --script res://tests/rules_test.gd
```

La escena principal se puede iniciar sin exportaciones ni dependencias externas. La compatibilidad de Steam Deck y Windows/Linux debe probarse con las exportaciones y dispositivos reales; no se ha validado en hardware Steam Deck.

## Inicio, descanso y viajes

Al abrir el juego aparece una pantalla inicial con **Continuar partida**, **Nueva partida** y **Salir**. Continuar se desactiva si no hay un guardado válido y muestra el día, la estación y la zona del guardado. Nueva partida pide confirmación antes de sustituir un guardado existente. Desde pausa puedes volver al inicio con confirmación.

Dormir (N, interacción con la casa o pausa) muestra una confirmación: **Cancelar** conserva el día; **Confirmar** inicia la transición de sueño y guarda al amanecer. Para dormir hay que estar en la granja y fuera de la camioneta.

La carretera está exclusivamente en la parte inferior y cruza todo el mapa de izquierda a derecha. Desde la granja, sigue hasta el extremo **izquierdo para ir al río** o hasta el **derecho para ir al pueblo**. El cambio de zona es automático al avanzar hacia el extremo, sin pulsar E/X ni abrir ningún menú, tanto a pie como en camioneta. Desde el río, sal por la derecha para volver a la granja; desde el pueblo, sal por la izquierda. Apareces en el extremo correspondiente de la carretera de destino y puedes seguir avanzando.

El botón **Viajar…** y el menú de pausa también permiten elegir **La granja**, **El río** y **El pueblo**. Ambos modos de viaje conservan los costes existentes:

- **Andando:** 30 minutos y 5 de energía. La camioneta permanece donde la aparcaste; si estabas conduciendo, queda aparcada allí.
- **En coche:** 10 minutos. Debes estar cerca de la camioneta o dentro de ella y tener las manos libres. Su carga se conserva durante el viaje.
- En el **río** hay un puente transitable, un muelle para llenar la regadera con E/X y un banco para descansar 20 minutos y recuperar 15 de energía.
- En el **pueblo** puedes comprar semillas y mejorar herramientas en la tienda, vender la carga acercando la camioneta a la tienda y llenar la regadera en la fuente.

Las zonas son mapas separados y explorables con WASD/stick. La zona actual y la ubicación del coche se incluyen en el guardado; los guardados anteriores se abren en la granja. No se puede viajar cargando una caja en las manos.

Los nuevos sprites originales están en `assets/sprites/travel/` (tienda, puente, muelle y fuente). El original generado está en `assets/sprites/generated/travel_props_source.png`; el procesado con transparencia y su informe QC están en `assets/sprites/travel/processing/`. `tools/pack_travel_sprites.py` empaqueta los recortes a sus tamaños de juego.

Prueba adicional de inicio, confirmación, viajes automáticos por carretera a pie y en coche, colisiones y persistencia:

```sh
godot --headless --path . --script res://tests/travel_test.gd
```

Pruebas de interacciones (pozo, fuente, río, selección de objetos, alcance, cajas, herramientas y salida del vehículo):

```sh
godot --headless --path . --script res://tests/interaction_test.gd
```

## Catálogo estacional

Listado completo de los 120 productos, precios y tiempos en [CULTIVOS.md](CULTIVOS.md). Los 360 sprites se pueden revisar en `assets/sprites/crops/seasonal/catalog_preview.png`. Prueba de las 120 variedades:

```sh
godot --headless --path . --script res://tests/seasonal_crops_test.gd
```
