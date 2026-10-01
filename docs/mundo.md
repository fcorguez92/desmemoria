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
`game/levels/room.gd`). `game/levels/world.tscn` (la escena principal) las coloca
una junto a otra en su sitio del mundo, todas cargadas a la vez: el jugador pasa
de una a otra caminando, cayendo o saltando, sin pantallas de carga ni cortes.

- **Cámara:** se limita a la sala en la que está el jugador; al cambiar de sala
  se desliza suavemente hasta la nueva (como en Hollow Knight o Super Metroid).
- **Caída mortal:** se muere al caer por debajo de la sala actual. Por eso un
  foso puede matar (El Último Umbral) o ser la entrada a otra sala de abajo
  (Las Terrazas Secas → La Cisterna): depende de si debajo hay sala.
- **Mapa:** cada sala se descubre al entrar en ella por primera vez, y entonces
  se anuncia su nombre. El minimapa (arriba a la izquierda) y el mapa completo
  (Esc → Mapa) solo dibujan salas descubiertas, con el jugador (dorado), las
  Anclas (azul) y el Eco de la última muerte (violeta). Sin comprar mapas ni
  cartógrafos: se descubre explorando.

**Para ampliar el mundo** con una sala nueva:
1. Dibujar su `.map` (mínimo 54 columnas, el ancho de la pantalla; si es más
   baja de 31 filas, la cámara enseña lo que hay encima de ella).
2. Copiar una escena de sala (p. ej. `terrazas_secas.tscn`) cambiando `map_file`,
   `title` y `has_sky` (false bajo tierra o bajo techo).
3. Instanciarla en `world.tscn` bajo `Rooms`, en una posición múltiplo de 16
   que la deje pegada a su vecina sin solaparse, con las aberturas a la misma
   altura en las dos salas.
4. Añadir a `tests/smoke_test.gd` una prueba de que se llega a ella y de que se
   puede volver (que no deje al jugador atrapado).

Cuando el mundo sea grande, tener todas las salas cargadas a la vez dejará de
ser barato; entonces se cargarán solo la sala actual y sus vecinas. Hoy son
cuatro salas pequeñas y no hace falta.

## El mundo construido hoy

```
                                           ┌──────────────┐
                                           │ La Torre de  │
                                           │    Riego     │
┌──────────────────┬──────────────────────┤ (doble salto,│
│ El Último Umbral │  Las Terrazas Secas  │  cornisa con │
│ (inicio, Anclas) │  ════ foso ════      │  Ancla)      │
└──────────────────┼───────┤      ├───────┴──────────────┘
                   │     La Cisterna      │
                   │    (Ancla, dash)     │
                   └──────────────────────┘
```

1. **El Último Umbral** — la zona de inicio (ver `vertical-slice.md`). Su borde
   derecho, antes abierto al vacío, continúa ahora hacia el Cinturón Yermo.
2. **Las Terrazas Secas** — primera sala del Cinturón Yermo: bancales de cultivo
   abandonados y la torre rota de una acequia. Un foso de 20 baldosas no se
   puede saltar sin dash; caer en él no mata, lleva a La Cisterna.
3. **La Cisterna** — depósito subterráneo de agua, ya seco. Ancla junto a la
   entrada, dos Cascarones y, al fondo, el recuerdo del **dash**. Una escalera de
   tablones devuelve al borde oeste del foso: no se puede quedar atrapado.
4. **La Torre de Riego** — interior de una torre de riego, al otro lado del
   foso. Escalera de tablones hasta el recuerdo del **doble salto**; con él se
   alcanza una cornisa alta con un Ancla. Su pared derecha queda cerrada: es el
   sitio natural para la siguiente ampliación del Cinturón Yermo.

Es el primer bucle metroidvania del mundo real: ves un foso que no puedes
cruzar, caes, encuentras el dash abajo, vuelves y lo cruzas.

## Pendiente de definir en próximas sesiones de diseño

- Plantilla completa por región (clima, cultura, recursos, fauna, enemigos, rutas exactas, atajos, evolución narrativa) — se rellena región por región, más cerca de cuando se construya cada una.
- Mapa visual/esquemático de las conexiones.
- Qué habilidad concreta abre el acceso a cada región.
