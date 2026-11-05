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
| Recoger / soltar una caja manualmente | **L2** | F / arrastrar con botón derecho |
| Cargar cosecha en la camioneta | **X**, junto al vehículo | Espacio, junto al vehículo |
| Subir / interactuar / vender carga | **A** | E |
| Aparcar y bajar | **X** | Espacio |
| Pausa | **Menú / Start** o B | Esc |
| Volver en menús / soltar caja | **B** | Esc en menús / E para soltar |
| Confirmar en menús | **A** | Intro / Espacio |
| Zoom | Pausa → Ajustes de juego y cámara | Rueda / + / − / Ajustes |
| Dormir | **A** junto a casa o desde pausa | E junto a casa / N / pausa |

Los índices de mando corresponden a **Godot 4**: L1/R1 son los botones 9/10; Menú es el botón 6. No hace falta usar pantalla táctil ni emular el ratón.

## Un ciclo de juego más directo

1. Apunta a una casilla dentro de tu terreno y pulsa **A**. La acción principal elige lo que necesita: despejar hierba, preparar tierra, plantar la semilla elegida, regar o cosechar. La ayuda inferior muestra la acción antes de ejecutarla. Las plantas frutales se conservan al recogerlas.
2. Cada fase requiere una pulsación nueva. Puedes **mantener A mientras avanzas por una fila** para repetir el mismo trabajo; mantenerlo sobre una casilla no encadena despejar, arar, sembrar y regar. Mantener X repite la herramienta seleccionada, con un intervalo entre usos.
3. La cosecha y la fruta se acumulan en la **mochila**, con sus calidades. Puedes recoger varias plantas y distintas variedades seguidas. Las herramientas manuales no cosechan accidentalmente un cultivo.
4. Acércate a la camioneta y pulsa **X** para empaquetar y cargar de una vez: primero las cajas cercanas con producto y después la cosecha suelta. Caben **6 cajas**, con **1–5 unidades de una variedad por caja**. Lo que no cabe permanece en la mochila. También puedes vender la cosecha suelta en la tienda.
5. Pulsa **A** para subir. Conduce al puesto de la granja o a la tienda del pueblo y pulsa **A** para vender la carga. **X** permite aparcar y bajar aunque haya carga vendible cerca.
6. Duerme en casa para recuperar energía, llenar la regadera, avanzar el día y guardar. Las confirmaciones comienzan con **Cancelar** seleccionado.

Puedes desactivar la acción contextual desde **Pausa → Ajustes** y trabajar con la herramienta elegida mediante X. La herramienta seleccionada aparece resaltada en la barra. La mochila permite elegir directamente las semillas de la estación; el selector muestra desactivadas las de otras estaciones y la cruceta solo recorre variedades utilizables.

## Ritmo y accesibilidad

- Textos de interfaz principales de 20–30 px, ayudas de 18 px, botones grandes y foco de alto contraste.
- Tienda de 120 cultivos dividida en **6 páginas de 5 por estación**. L1/R1 cambian página. Las compras y los cambios de ajustes mantienen el foco en la misma posición.
- Los menús se recorren con stick o cruceta; el contenido se desplaza para seguir el foco. B vuelve al menú anterior. Abrir mochila, semillas, tienda o pausa detiene el reloj.
- Cámara ajustable íntegramente con mando. El objetivo de trabajo vuelve a la dirección de marcha cuando te mueves, sin quedarse anclado a una dirección antigua del stick derecho.
- **Día tranquilo:** 6 minutos reales entre las 06:00 y medianoche. **Día ágil:** 3 minutos. El reloj se detiene en los menús.
- Tras 2 segundos quieto y sin trabajar, recuperas 1,5 puntos de energía por segundo. El río ofrece descanso de 20 minutos de juego y 15 de energía.
- Acción contextual, repetición mantenida, ritmo del día, vibración, herramienta elegida y cámara se incluyen en el guardado. La vibración se puede desactivar.
- Al perder el foco de la aplicación o desconectarse el mando utilizado, el juego se pausa. Abrir un menú cancela la carga de herramientas; los botones mantenidos deben soltarse antes de repetir trabajo al volver.

## Cultivos, herramientas y economía

Hay **120 variedades, 30 por estación**, con semillas, plantas y productos propios. Cada bolsa trae 5 semillas. La tienda muestra el precio de compra, venta por unidad, primera cosecha, rendimiento y rebrote. Catálogo completo en [CULTIVOS.md](CULTIVOS.md).

Los cultivos necesitan agua cada día. Sembrar no cuenta como riego; regar dos veces la misma casilla no gasta agua ni energía. La lluvia contribuye al crecimiento. Tres días secos o un cambio de estación marchitan la planta. La acción principal retira la planta seca y conserva el suelo preparado.

La azada y la regadera de nivel 2 permiten mantener R2 / Mayús y soltar para trabajar **3 × 3**, con vista previa. El taller permite elegir qué herramienta mejorar, sin depender de la herramienta que llevaras seleccionada. Cada mejora cuesta 80 monedas, 3 de madera y 2 de piedra.

Hacha, pico y guadaña proporcionan madera, piedra y fibra. Las calidades Normal, Buena, Excelente y Excepcional conservan su valor tanto en la venta directa como al cargar y vender la camioneta. El producto de una caja física se reserva para evitar venderlo también como cosecha suelta.

Las cajas siguen siendo objetos movibles: A permite guardar producto o cargarlas junto a la camioneta; **L2 / F** permite recogerlas para recolocarlas independientemente de la cosecha que lleves. Apunta a suelo libre para soltarlas.

## El valle

La granja ocupa 54 × 40 casillas. Incluye casa, mercadillo, pozo, parcela inicial, arroyo y ampliación por 450 monedas. Los árboles y objetos respetan edificios, cultivos, caminos, vallas y cajas. Las posiciones incompatibles de guardados antiguos se reparan al cargar.

La carretera recorre la parte inferior del mapa. Sal por la **izquierda para ir al río** o por la **derecha para ir al pueblo**. El paso entre zonas es automático al avanzar hasta el extremo, a pie o en camioneta. El menú Viajar también permite elegir destino.

- **Andando:** 30 minutos de juego y 5 de energía. La camioneta queda aparcada donde la dejaste.
- **En camioneta:** 10 minutos de juego; debes estar dentro o cerca del vehículo. La carga viaja contigo.
- **Río:** puente transitable, muelle para llenar la regadera y banco para descansar.
- **Pueblo:** tienda de semillas, taller, recepción de carga y fuente.

No se puede viajar con una caja física en las manos. La cosecha de la mochila sí puede viajar y permite subir a la camioneta.

Manzanos, perales y arbustos de bayas, arándanos y frambuesas dan fruta sin destruirse. Cada planta conserva su propio plazo de rebrote: manzano 3–5 días, peral 4–7, bayas y frambuesas 2–4, arándanos 3–5. La fruta madura permanece hasta recogerla. Los robles no dan fruta.

## Guardados

El archivo versionado es `user://farm_life_save.json`, con escritura temporal y respaldo. Conserva cultivos, objetos, calidades, zonas, camioneta, carga, cámara y ajustes. Las cosechas que los guardados anteriores tenían en las manos se incorporan a la mochila al cargar, sin duplicarlas. Dormir guarda al amanecer; también puedes guardar desde pausa. Nueva partida, cargar y volver al inicio piden confirmación.

## Recursos y exportación

- Personaje y animaciones: `assets/generated/` y `assets/sprites/animations/`.
- Entorno, plantas, vehículos y objetos: `assets/sprites/`.
- Cultivos estacionales y catálogo visual: `assets/sprites/crops/seasonal/catalog_preview.png`.
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
```

Las pruebas de Steam Deck cubren asignación real de botones de Godot 4, trabajo contextual, repetición, apuntado, carga 3×3, pausa, desconexión, migración de guardados, capacidad del vehículo, conservación del valor de las cosechas y navegación de menús.
