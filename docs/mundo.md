# Diseño del mundo (documento vivo)

Estado: estructura geográfica de alto nivel aprobada. El detalle completo de cada bioma (fauna, enemigos concretos, atajos exactos) se desarrolla progresivamente, más cerca del momento de construir cada zona — no todo de golpe ahora, para no diseñar contenido que aún podemos necesitar cambiar tras el prototipo jugable.

## Lógica espacial del mundo

Estructura radial: cuanto más cerca de la **Herida** (el punto donde empezó la Desmemoria), menos "recordado" está el mundo — el terreno, la arquitectura y los colores se vuelven más erosionados y extraños. Esta es la razón física y narrativa de por qué las zonas se conectan entre sí, y de por qué la dificultad y la rareza crecen según se avanza, sin depender de diálogos explicativos.

Esto da al mundo un eje claro: periferia (poblada, medievalmente reconocible, decadente por pobreza) → interior (afectado por la Desmemoria, cada vez más irreal).

## Regiones (boceto, de periferia a Herida)

1. **El Último Umbral** — zona inicial / hub. Asentamiento fronterizo de refugiados. Arquitectura medieval pobre y remendada; decadente por miseria, no todavía por la Desmemoria. Punto de entrada del jugador.
2. **El Cinturón Yermo** — antiguas tierras de cultivo y aldeas, terrazas y torres de riego. Terreno mixto: decadencia agrícola normal junto a parches grises donde la memoria de lo cultivado ya se perdió. Verticalidad natural (terrazas, andamios) para plataformas.
3. **El Archivo** — ciudad-biblioteca de la Orden: salas de escribas, estanterías-torre, salones de sellado. Afectación parcial: pasillos enteros en blanco junto a otros intactos. Base de la facción de los Custodios.
4. **Las Minas del Origen** — túneles donde la Orden cavó buscando la Primera Memoria. Conecta subterráneamente varias zonas de superficie (atajos). Criaturas evolucionadas ajenas a la luz.
5. **La Costa Retenida** — asentamientos altos y defendibles; la zona menos afectada del mapa. Base de los Descreídos, hostiles políticamente.
6. **La Herida** — zona final. Origen de la Desmemoria, inestable, apenas reconocible. Confrontación con la causa real del fenómeno.

## Conexiones (a definir con precisión durante el diseño de nivel)

- Las Minas del Origen actúan como nexo subterráneo entre varias regiones de superficie (atajo clásico de metroidvania una vez se obtiene la habilidad de excavar/descender).
- El Último Umbral es el único hub con acceso directo garantizado desde el principio; el resto de rutas se abren por habilidades o por historia.

## Cómo está construido: salas conectadas

El mundo se hace de **salas**: cada una es un mapa de texto (`game/levels/*.map`,
ver `vertical-slice.md` para la leyenda) con su escena (`*.tscn`, script
`game/levels/room.gd`). `game/levels/world.tscn` (se llega desde el menú principal) las coloca
una junto a otra en su sitio del mundo, todas cargadas a la vez: el jugador pasa
de una a otra caminando, cayendo o saltando, sin pantallas de carga ni cortes.

- **Cámara:** se limita a la sala en la que está el jugador; al cambiar de sala
  se desliza suavemente hasta la nueva (como en Hollow Knight o Super Metroid).
- **Caída mortal:** se muere al caer por debajo de la sala actual. Por eso un
  foso puede matar (El Último Umbral) o ser la entrada a otra sala de abajo
  (Las Terrazas Secas → La Cisterna): depende de si debajo hay sala.
- **Mapa:** se descubre explorando, baldosa a baldosa: solo se dibuja lo que
  ha quedado a menos de 12 baldosas del jugador (`REVEAL_RADIUS` en `world.gd`),
  no la sala entera al entrar. La primera vez que se entra en una sala se
  anuncia su nombre. El minimapa (arriba a la izquierda) y el mapa completo
  (Esc → Mapa) muestran al jugador (dorado), las Anclas (azul) y el Eco de la
  última muerte (violeta), estos dos solo si se ha pasado cerca. Sin comprar
  mapas ni cartógrafos.

**Para ampliar el mundo** con una sala nueva:
1. Dibujar su `.map` (lo normal es 54 columnas o más, el ancho de la pantalla; una sala vertical estrecha, como La Chimenea con 34, se centra con la cámara; si es más
   baja de 31 filas, la cámara enseña lo que hay encima de ella).
2. Copiar una escena de sala (p. ej. `terrazas_secas.tscn`) cambiando `map_file`,
   `title` y `has_sky` (false bajo tierra o bajo techo).
3. Instanciarla en `world.tscn` bajo `Rooms`, en una posición múltiplo de 16
   que la deje pegada a su vecina sin solaparse, con las aberturas a la misma
   altura en las dos salas.
4. Añadir a `tests/smoke_test.gd` una prueba de que se llega a ella y de que se
   puede volver (que no deje al jugador atrapado).

Hoy son ocho salas, todas cargadas a la vez; solo la actual y sus vecinas
procesan (ver `world.gd`). Si el mundo crece mucho, habrá que cargarlas y
descargarlas, pero hoy no hace falta.

## El mundo construido hoy

```
                        ┌────────────┐
┌─────────────────┬─────┤ La Torre de│                                       ┌─ La Pasarela ─ El Mirador
│ El Último Umbral│Terra│   Riego    │                          La Chimenea ─┘  (3 huecos, solo con dash)
│ (inicio, Anclas)│zas  └────────────┘                               ▲
└─────────────────┴──┬──┘                                            │ recuerdo del dash
                     │ La Cisterna ─► Las Galerías Bajas ─► El Aljibe (jefe)
                     │ (128, Ancla)   (112, Ancla, pinchos)   (arena cerrada)
```

El recorrido sigue el ritmo de un primer tramo de Hollow Knight (un pueblo, una
caída a una zona subterránea, un banco justo antes del primer jefe y el poder que
da, probado enseguida en un pasaje exigente). Las salas del tramo son **largas**
(la Cisterna 128 baldosas, las Galerías 112) y los enemigos van separados unas
14 o 18 baldosas, para que cada encuentro sea suyo y no un montón.

1. **El Último Umbral** — la zona de inicio (ver `vertical-slice.md`). Su borde
   derecho continúa hacia el Cinturón Yermo.
2. **Las Terrazas Secas** — primera sala del Cinturón Yermo. Un foso de 20
   baldosas no se puede saltar sin dash; caer en él no mata, lleva a La Cisterna.
3. **La Cisterna** (128×31) — depósito subterráneo seco. Se aterriza en una zona
   tranquila bajo el foso; una escalera de tablones devuelve a él (no se puede
   quedar atrapado). Hacia el este, un lancero, un cascarón, un arrojador sobre un
   tablón y un acechador, y al final, junto a la puerta, un **Ancla**.
4. **Las Galerías Bajas** (112×34) — el tramo largo antes del jefe, en un salón
   alto: un cascarón, un foso de pinchos, otro cascarón, una galería alta con un
   arrojador, un acechador, un lancero, un coloso, una hilera de pinchos que salen y
   se retraen y, justo antes de la puerta, un **Ancla** y una inscripción que anuncia
   al Custodio.
5. **El Aljibe** (64×33) — la **arena** del **Centinela Hueco** (ver `jefes.md`).
   Es una sala aparte, con su propia puerta de entrada y de salida: al cruzar la línea
   de la sala, **caen dos rastrillos de hierro** (uno por puerta) y no se puede huir
   hasta vencerlo. Al vencerlo se abren y aparece el recuerdo del **dash**.
6. **La Chimenea** (40×69) — el puzle del dash: un eje abierto, sin techos, con
   escalones anchos y **tres cruces de 16 baldosas que solo se salvan con dash**
   (saltar y dash en el aire; solo cabe uno por salto). Cada fallo cuesta caer a un
   escalón inferior o a los pinchos (1 de daño y de vuelta al último suelo firme), no
   volver al Ancla. Tiene un **Ancla** al acabar el primer cruce y otra a mitad.
7. **La Pasarela de los Mensajeros** (100×24) — al aire libre, a lo alto del mundo:
   tres huecos de 17 baldosas sobre un abismo de pinchos, todos con dash, hasta **El
   Mirador**, con un **Ancla** y una inscripción. Allí se acaba el camino por ahora:
   es el sitio natural para ampliar el mundo hacia el este.
8. **La Torre de Riego** — al otro lado del foso de las Terrazas. Escalera de
   tablones hasta el recuerdo del **doble salto**; con él se alcanza la cornisa
   del Ancla. Su pared derecha queda cerrada.

Es el primer bucle metroidvania del mundo real, ahora más largo: ves un foso que
no puedes cruzar, caes, abres el camino bajo tierra con un jefe, vuelves con el
dash y cruzas ese mismo foso; y el puzle del dash pone a prueba lo aprendido.

Cómo se comprueba que el puzle se puede resolver (y solo con dash): las
maniobras de referencia están en `tests/puzzle_plans.json` y la prueba de humo
las repite en el motor (ver `jefes.md` y `docs/arquitectura.md#verificación`).

## Pendiente de definir en próximas sesiones de diseño

- Plantilla completa por región (clima, cultura, recursos, fauna, enemigos, rutas exactas, atajos, evolución narrativa) — se rellena región por región, más cerca de cuando se construya cada una.
- Mapa visual/esquemático de las conexiones.
- Qué habilidad concreta abre el acceso a cada región.
