# Diseño del mundo (documento vivo)

Estado: **mapa macro cerrado** (136 salas, 6 regiones, 34 Anclas). Unifica la propuesta `docs/reunion/disenadores/01-mapa-macro.md` con los puzles (`02`, `03`), el combate (`04`), la progresión (`05`) y el arte de entornos (`06`). Las decisiones tomadas al unificar, con su porqué, están en `docs/reunion/disenadores/DECISIONES-EDITOR-MUNDO.md`. Los puzles y mecánicas de mundo, en `docs/puzles.md`; la leyenda del mapa de texto, en `docs/vertical-slice.md`.

**Qué es referencia de qué.** Este documento tiene todo lo necesario para trabajar: lógica espacial, posiciones, qué pide y qué da cada bloque, Anclas, atajos, reglas. Las tablas completas **sala por sala** (tamaño, conexiones, enemigos, coleccionables y textos de las 136 salas) están en `01-mapa-macro.md` §4: ábrelo solo cuando vayas a construir una sala concreta. Si un dato de `01` contradice a este documento, manda este (las correcciones están listadas en `DECISIONES-EDITOR-MUNDO.md`).

Los nombres de las salas nuevas son **de trabajo**: antes de fijarlos hay que comprobar que no tengan acepciones vulgares (regla de `CLAUDE.md`).

## Lógica espacial del mundo

Dos ideas, una encima de la otra:

1. **Estructura radial de la Desmemoria.** Cuanto más cerca de la **Herida** (donde empezó la Desmemoria), menos "recordado" está el mundo: el terreno, la arquitectura y los colores se erosionan y la dificultad y la rareza crecen sin diálogos explicativos. Periferia (poblada, medieval, decadente por miseria) → interior (cada vez más irreal).
2. **Un anillo con un hueco en el centro.** Las tres regiones libres (Archivo al norte, Minas al sur, Costa al este) rodean la Herida; el Cinturón es la rampa de entrada por el oeste; el Último Umbral queda en el extremo. El minimapa dice "voy hacia dentro" sin una palabra, y **el rectángulo central sin dibujar es el destino**.

Reglas rectoras del mapa:

- **Un cruce único lo ata todo: el Pilar de Lacre (COS-04).** Sala vertical enorme donde se cruzan el camino del Cinturón a la Costa, el puente que baja del Archivo y el pozo que da al Páramo y a la Puerta Sin Muro. Los tres huecos vacíos de la puerta se ven desde el primer rellano (ver antes de poder, a escala de mundo).
- **Cada habilidad tiene su cerradura visible antes que su llave** (foso de las Terrazas, cornisa del Ancla, pozos lisos de la Era, muro del primer pantallazo, piedra de lectura del Mirador).
- **Cada región tiene un bucle de regreso corto.** No se vuelve dos veces por el mismo pasillo: o hay un atajo de sentido único, o la vuelta pasa por otra sala.
- **El mundo se pliega sobre sí mismo.** Los atajos de Excavar y la barca convierten un viaje de 1.400 baldosas (Costa → Umbral) en 4-5 minutos.
- **Una Ancla cada 6-8 salas del camino principal como máximo, y siempre a ≤ 1 sala de un jefe** (nunca dentro de su arena).
- **El Mirador es una vista, no una sala a 450 baldosas.** La Herida que se ve desde allí es fondo de arte. El Mirador es un callejón sin salida con Ancla: **no conecta físicamente con la Herida**. A la Puerta Sin Muro solo se llega por el Páramo Gris (HER-01), bajando desde el Pilar de Lacre o subiendo por el Pozo del Latido (ver "La Puerta Sin Muro" más abajo).

## Las seis regiones

Coordenadas en baldosas (16 px), con **la esquina superior izquierda de El Último Umbral en (0,0)**, x hacia el este, y hacia el sur. Tamaño = columnas × filas. La pantalla es 54×30.

| Región | Salas | Acto | Tono | Pide | Da |
|---|---|---|---|---|---|
| **El Último Umbral** (UMB) | 8 | I y IV | Miedo y duelo, sin Desmemoria | Excavar solo para el muro del oeste | Nada: enseña y es hub |
| **El Cinturón Yermo** (CIN) | 30 | I y II | La rutina como último vestigio, del cielo abierto al subsuelo | Dash, luego Doble, luego Agarre, en ese orden | Dash (Centinela), Doble (Torre), Agarre (Jacinto) |
| **El Archivo** (ARC) | 26 | II | Ordenado e intacto junto a lo en blanco | Agarre | Sello de Cera (Hesper), Llave de Tinta (Ilara) |
| **Las Minas del Origen** (MIN) | 28 | III | Exceso (calor, lámparas, fe en lo de abajo) | Agarre | Excavar y Sello de Piedra (Magda) |
| **La Costa Retenida** (COS) | 20 | III | Nítido, el más vivo; el alivio es real | Agarre (camino largo) o Excavar (corto) | Sello de Cal (Eudora) |
| **La Herida** (HER) | 16 | V | Lo reconocible se disuelve | Los tres Sellos; usa todas las habilidades | Nada: el final |
| **Secretas y atajos** (SEC) | 8 | I-V | Recompensa por mirar y volver | Excavar, Doble, Agarre, Dash | Fragmentos, reliquias, atajos |
| **Total** | **136** | | | | |

Más 4 salas de reserva (SEC-09, SEC-10, SEC-11 y HER-17, de `02`) con sus IDs reservados, **fuera del presupuesto** de 136: solo si sobra tiempo.

**Orden permitido.** Dash → Doble → Agarre es obligatorio (cada habilidad está tras la anterior). Archivo, Minas y Costa se pueden hacer en cualquier orden (6 permutaciones). Los tres Sellos, en cualquier orden. La Costa corta (Excavar) solo tras vencer a Magda. Nombrar solo tras tener los tres Sellos o tras Magda (el regreso al Umbral, acto IV). **Nombrar nunca bloquea el camino de la Herida** (la Sala de Aún exige Nombrar; el resto, no).

## El mapa global

Cada carácter = 24 baldosas; x de -96 a 1620, y de -480 a 330; el número de la izquierda es la y de cada fila.

```
 -480             AAAAAAAAAAAAAAA
 -456             AAAAAAAAAAAAAAA
 -432             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 -408             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 -384             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 -360             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 -336             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 -312             AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
 -288                   CCCCCCCCCAAAAAAAAAAAAAAAAAAAAA
 -264                   CCCCCCCCCAAAAAAAAAAAAAAAAAAAAA
 -240             CCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAAAAAA
 -216             CCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAAAAAA
 -192             CCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAAAAAA
 -168             CCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAAAAAA
 -144     UUUCCCCCCCCCCCCCCCCCCCAAAAAAAAAAAAAAAAAAPPPP   KKKKKKKKKKKKKKKKKKKK
 -120     UUUCCCCCCCCCCCCCCCCCCCCCCCCkkkkkkkkkkkkkPPPkkkkkKKKKKKKKKKKKKKKKKKK
  -96     UUUCCCCCCCCCCCCCCCCCCCCCCCCkkkkkkkkkkkkkPPPkkkkkKKKKKKKKKKKKKKKKKKK
  -72   UUUUUUUUUUCCCCCCCCCCCCCCCCCCCkkkkkkkkkkkkkPPPkkkkkKKKKKKKKKKKKKKKKKKK
  -48   UUUUUUUUUUCCCCCCCCCCCCCCCCCCCC            PPPP   KKKKKKKKKKKKKKKKKKKK
  -24     UUUUUUccCCCCCCCCcccC**CCCCCC            PPPP   KKKKKKKKKKKKKKKKKKKK
    0 UUUUUUUccccccccccccccccccc  CCCC            PPPP   KKKKKKKKKKKKKKKKKKKK
   24 UUUUUUUccccccccccccccsssss  CCCC  mmmmmHHHHHPPPPHHHHKKKKKKKKKKKKKKKKKKK
   48 mmm    csssccccccccc sssss  CCCC  mmmmmHHHHHHHHHHHHHKKKKKKKKKKKKKKKKKKK
   72 mmm     sss MMMMMMMMMMMMMMMMCCCCMMmmmmmHHHHHHHHHHHHHKKKKKKKKKKKKKKKKKKK
   96 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHHKKKKKKKKKKKKKKKKKKK
  120 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHHKKKKmmmmKKKKKKKKKKK
  144 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHHKKKKmmmmKKKKKKKKKKK
  168 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHHKKKKmmmmKKKKKKKKKKK
  192 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHH    mmmm
  216 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHH    mmmm
  240 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmHHHHHHHHHHHHH    mmmm
  264 mmm     mmm MMMMMMMMMMMMMMMMMMMMMMmmmmmmmmmmmmmmmmmmmmmmmmmmm
  288 mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
  312 mmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmmm
```

**U** Umbral · **c** Cinturón bajo (construido) · **C** Cinturón alto · **\*** Mirador · **A** Archivo (en L) · **k/K** Cornisa y Costa · **P** Pilar de Lacre · **H** Páramo y Herida · **M/m** Minas y red de Excavar (galerías largas y pozos) · **s** secretas.

Cómo se lee en el minimapa: un pico oeste (Umbral), una faja ancha que sube hacia la derecha (Cinturón alto), un bloque alto (Archivo), un bloque bajo que crece en U (Minas) y, a la derecha de todo, la Costa. El hueco central (la Herida) queda como rectángulo sin dibujar hasta el acto V.

### Cajas de región

Relleno = suma de áreas de sala / área de la caja. Por debajo del 60 % sobra sitio; entre 60 y 85 % hay que plegar la región (las Minas en U, el Archivo apilando en vertical); por encima del 85 % (la Herida) se dibuja primero su manifiesto de posiciones, porque no hay holgura para errores de abertura.

| Región | Caja (x0,y0) → (x1,y1) | Tamaño | Salas | Relleno |
|---|---|---|---|---|
| Umbral | (-96,-124) → (80,40) y tira (80,-72) → (192,-20) | 176×164 + 112×52 | 8 | 63 % |
| Cinturón bajo (construido) | (80,-21) → (524,55) | 444×76 | 7 | 56 % |
| Cinturón alto | (88,-276) → (656,80) | 568×356 | 23 | 42 % |
| Archivo (en L) | (544,-430) → (1040,-130) y ala noroeste (200,-480) → (544,-290) | 496×300 + 344×190 | 26 | 69 % |
| Minas | (-96,40) → (740,330); tira (740,270) → (1360,330); pozo (740,30) → (820,270) | 836×290 + 620×60 | 28 | 71 % |
| Cornisa y Pilar | (656,-130) → (1040,30) | 384×160 | 4 | 55 % |
| Costa (pueblo; incluye el Acantilado de Cortinas) | (1040,-130) → (1600,190) | 460×320 | 16 | 60 % |
| Herida | (820,30) → (1140,290) | 320×260 | 16 | 84 % |

### Salas fijas de ensamblaje

Se colocan primero; las demás se encajan con ellas. Las ocho primeras salen de `world.tscn` (posición en píxeles ÷ 16). Aberturas en y absoluta. Donde una abertura mide menos de 6 baldosas se indica en negrita: **se ensancha a 6 con los retoques R7** (ver más abajo).

| Sala | Posición (x,y) | Tamaño | Aberturas fijadas |
|---|---|---|---|
| UMB-01 Último Umbral | (0,0) | 80×28 | E: y 0-19 (suelo en 20); N: cols 0-79 (cielo abierto); O: muro sellado y 6-19 |
| CIN-01 Terrazas Secas | (80,0) | 64×24 | O: y 0-19; E: y 16-19 (**4**, pasa a 14-19); S: cols 30-49 (foso) |
| CIN-02 Cisterna | (80,24) | 128×31 | N: cols 30-49; E: y 40-45 |
| CIN-03 Galerías Bajas | (208,20) | 112×34 | O y E: y 40-45 |
| CIN-04 Aljibe | (320,16) | 64×33 | O y E: y 40-45 (rastrillos) |
| CIN-05 Chimenea | (384,-21) | 40×69 | O: y 40-45; E: y -19 a -14 |
| CIN-06 Pasarela y Mirador | (424,-21) | 100×24 | O: y -21 a -14; cielo abierto; Mirador al este (cota y -13) |
| CIN-07 Torre de Riego | (144,-20) | 56×44 | O: y 16-19 (**4**, pasa a 14-19); cornisa del Ancla al este, y -14 (pared cerrada hoy) |
| SEC-01 Silo Sin Grano | (96,55) | 64×32 | N: bajo la Cisterna (Excavar) |
| ARC-01 Pozos Blancos | (544,-250) | 48×130 | S: sobre la Era (y -120) |
| COS-04 Pilar de Lacre | (960,-130) | 80×160 | N: Puente de Cera; O y E: y -110 a -104; S: Páramo |
| HER-01 Páramo Gris | (820,30) | 200×50 | N: bajo el Pilar (x 960-1020) |

Las 52 salas con posición exacta de `01` §4 (columna "@") se comprobaron con un script: 0 solapes y todas las conexiones declaradas son adyacencias reales con ≥ 4 baldosas de contacto. La regla para las nuevas es **≥ 6**.

### Distancias (para dimensionar el viaje)

Carrera ≈ 18,75 baldosas/s; con rodeos y combate el tiempo real sube ×2-3. Umbral → Aljibe: 400 baldosas (4-6 min). Aljibe → Era: 380 (6-9 min). Era → Pilar por la Cornisa: 400 (4-5 min). Pilar → Muro Blanco: 220 (3 min). **Costa → Umbral sin atajos: 1.440 baldosas (12-15 min); con Cauce y Metro, 4-5 min.** Sin los atajos de abajo el acto IV costaría un cuarto de hora de vuelta: es lo que los justifica.

## Llaves y cerraduras

```
        ARCHIVO:  Pozos(Agarre) → Puerta → Nave → HUB ─┬─ ala en blanco → ILARA ─Tinta→ Relatores
                                                       ├─ ala intacta, Negadores              → Extracción
                                                       └───────── ... → Blanco → Lacre → HESPER ─ Puente (CERA) ─┐
                                                                                                                 ▼
UMBRAL ─ Terrazas ─(foso: DASH)─ Torre ─(DOBLE)─ Cinturón alto ─ ERA ─(AGARRE)─ Cuesta ─ Cornisa ─► PILAR DE LACRE ─► PÁRAMO ─► PUERTA SIN MURO
  ▲        │ (caída)                                  │        JACINTO         │                    (Cera+Piedra+Cal)         │
  │        ▼                                          │                        ▼                                              ▼
  │     Cisterna ─ Galerías ─ ALJIBE (Centinela)→DASH │                 Brocal ─ Descenso ─► MINAS (U) ─ MAGDA (PIEDRA+EXCAVAR)    HERIDA → Asiento → Aún
  │                           └ Chimenea ─ Pasarela ─ MIRADOR (se ve la Herida)               │
  │                                                                                           ├─ Galería de la Marea ─ Cauce (barca) ─► COSTA (corto) ─ EUDORA (CAL)
  └── Sótano ◄ Pozo de los Cantores ◄ METRO ◄ Veta Tapiada ► Silo ► Cisterna                  └─ Pozo del Latido ─► Páramo
```

| Cerradura (dónde) | Llave | Dónde está la llave | Qué se ve antes de poder |
|---|---|---|---|
| Foso de 20 baldosas (CIN-01) | Dash | Aljibe (CIN-04), tras el Centinela | El otro borde, desde el borde |
| Cruces de la Chimenea y huecos de la Pasarela (CIN-05/06) | Dash | Ídem | La luz del Mirador desde la Chimenea |
| Cornisa del Ancla de la Torre (CIN-07) y Casa Varga (CIN-09) | Doble | Torre de Riego (CIN-07) | La cornisa, desde el primer tablón |
| Pozos Blancos, Pastor y Escalones, vuelta del Descenso (ARC-01, COS-01/02, CIN-21) | Agarre | La Era (CIN-18), Jacinto | Los pozos lisos de la Era, con arañazos en la piedra |
| Muro oeste del Umbral, suelo del Silo, Veta, Metro, Marea, Latido, suelos de la Herida | Excavar | Cámara de Apuntalamiento (MIN-15), Magda | El muro del primer pantallazo; la reja con grano sobre el Silo |
| Sala de los Relatores (ARC-17) | Tinta | Scriptorium (ARC-08), Ilara | La puerta con cerradura de pluma, en el Claustro |
| Piedras de lectura (Mirador, Patio) y escalera final | Nombrar | Hito del Umbral (acto IV) | La piedra con el hueco "pide un nombre", visible desde la primera visita |
| Puerta Sin Muro (HER-02) | Cera + Piedra + Cal | Hesper (ARC-22), Magda (MIN-15), Eudora (COS-20) | Los tres huecos vacíos, ya desde el Pilar |
| Epílogo del Relevo (Aljibe) | Insignia + final Compartir | Oda (secreto, CIN-06) | La coraza arrodillada, desde la primera vez |

El Puente de Cera (ARC-23) y el Pilar (COS-04) **no piden Sellos**: el Sello de Cera es solo lo que suelta Hesper. Los Sellos se piden únicamente en HER-02.

### La Puerta Sin Muro (HER-02), cerrada

- **Sala:** HER-02, 96×48. Se entra por el norte desde el Páramo Gris (HER-01) y se sale por el sur (hacia HER-03) a través de una **niebla de cal** (compuerta variante cal, cerrada hasta romper el tercer Sello). En el centro, un marco de piedra de 8×6 de pie sin muro. Cruzar el marco no hace nada: es el "nada cambia" del canon.
- **Acceso (único camino físico):** Pilar de Lacre (COS-04) → Páramo Gris (HER-01) → HER-02. Atajo tras Magda: Hueco del Pico → Pozo del Latido (MIN-24) → HER-01. **El Mirador no conecta**: solo enseña el marco en el paisaje.
- **Ancla antes de la puerta:** A30, en HER-01, no en la sala. Cano está allí.
- **Sin Sellos se puede llegar y volver** (con 0, 1, 2 o 3). El menú de pausa muestra los Sellos y su región para quien llegue de pronto. Diseño exacto de los tres nichos en `puzles.md`.

## Las salas, por bloques

La tabla sala por sala está en `01-mapa-macro.md` §4. Aquí, por bloque: IDs, función y qué se necesita para entrar o cruzar. "—" = nada.

### El Último Umbral (8)

| Bloque | Salas | Función | Requiere |
|---|---|---|---|
| Primera pantalla | UMB-01 (construida) | Tutorial, calma, Anclas A01-A02, foso mortal, 2 cascarones | — (muro oeste: Excavar) |
| Pueblo alto | UMB-02 Escalera del Remiendo, UMB-03 Patio de los Nombres (A03, hub social), UMB-04 Fragua, UMB-05 Rellano de la Vela | Calma, PNJ, regreso del acto IV; todo cuelga hacia arriba de la primera pantalla | — |
| Secreta | UMB-06 Detrás del Estandarte | Recompensa | — (pared que se rompe al golpear) |
| Tras el muro | UMB-07 Puerta Tapiada, UMB-08 Sótano de los Cantores (A34) | Atajo de vuelta del acto IV; lore de Aún | Excavar |

### El Cinturón Yermo (30)

| Bloque | Salas | Función | Requiere |
|---|---|---|---|
| Cinturón bajo (7, construido) | CIN-01 Terrazas, 02 Cisterna, 03 Galerías, 04 Aljibe (**jefe 1, da Dash**), 05 Chimenea, 06 Pasarela y Mirador (**jefe 10 secreto**), 07 Torre de Riego (**da Doble**) | Foso, caída, tensión previa al jefe, puzle del Dash | Dash para cruzar el foso, la Chimenea y la Pasarela; Doble para la cornisa |
| Alto, eje (7) | CIN-08 Surco Ciego, 09 Casa Varga, 10 Campo de los Ferrán, 11 Cruce del Pan, 12 Acequia, 13 Segunda Torre, 15 Bancales Altos | Puzles de Doble de dificultad creciente, calma entre ellos | Doble |
| Ronda, Cercado, Era (3) | CIN-14 Camino de Ronda, 17 Cercado Vacío (A12), 18 La Era (**jefe 2, da Agarre**) | Combate de puesto, calma, jefe | — (N de la Era: Agarre) |
| Salida al hondo (5) | CIN-19 Cuesta del Segador (bifurcación de 3 caminos), 20 Brocal, 21 Descenso del Brocal, 22 Almiar, 23 Rampa de Servicio | Respiro, caída larga que decide, atajos B4/B5 | Agarre (salir y volver) |
| Ramas altas (8) | CIN-16 Molino, 24 Granero Sin Techo, 25 Pozo de Piedra Seca (primer pozo), 26 Lavadero, 27 Balsa, 28 Ermita, 29 Mojones, 30 Linde Gris | Plataformas, calma, lore, secretas; la rama norte se cierra sobre los Pozos Blancos del Archivo | Doble (casi todas); Agarre (25, 26) |

### El Archivo (26)

| Bloque | Salas | Función | Requiere |
|---|---|---|---|
| Pozos y entrada (3) | ARC-01 Pozos Blancos, 02 Puerta (A14), 03 Vestíbulo | Primer pozo de Agarre por contraste; primer encuentro | Agarre |
| Eje (2) | ARC-04 Nave Raspada, 05 Estantería Nueve (A15, **hub**) | Paredes que pierden relieve; reparto de tres alas | — |
| Ala en Blanco hasta Ilara (3) | ARC-06 Pasillo Tres, 07 Sala de los Lacres (A16), 08 Scriptorium Callado (**jefe 3 Ilara, da Tinta**) | Pasillo en blanco con suelo que late; pre-jefe | — |
| Ala Intacta (6) | ARC-09 Biblioteca Intacta, 10 Altos del Catálogo, 11 Aula Pequeña, 12 Retrato Ausente (secreta), 24 Galería de los Atriles, 25 Refectorio | Torres lisas de Doble, bucle B6, calma, Nombres | — (Doble ayuda; sin Agarre trivial: paredes `%`) |
| Ala de los Negadores (3) | ARC-13 Ala de los Negadores, 14 Pasaje de las Llaves (atajo B7), 16 Cripta de los Registros Quemados | Combate alto, atajo de un solo sentido, ramal | — |
| Escalera y Relatores hasta Hesper y Puente (9) | ARC-15 Escalera Taponada, 17 Sala de los Relatores (escena), 18 Extracción, 19 **Archivo en Blanco** (sin mapa), 20 Corredor de Lacre, 21 Antesala del Prior (A18), 22 Salón de Sellado (**jefe 4 Hesper, da Cera**), 23 Puente de Cera, 26 Claustro de la Tinta (A17) | Tensión máxima, escena, jefe, respiro y gran descenso al Pilar | Tinta (ARC-17) |

### Las Minas del Origen (28)

| Bloque | Salas | Función | Requiere |
|---|---|---|---|
| Bajada y primer tramo (5) | MIN-01 Andén (A19), 02 Vagoneta Quieta, 03 Nicho de las Ofrendas, 04 Pasillo de las Rayas, 05 Fila de Espera (A20) | Entrada en calma, primera vagoneta, combate lineal | — |
| La U de descenso (8) | MIN-06 Cuerda de Mil Nudos (pozo de Agarre), 07 Apeos, 08 Cámara de las Voces (A21), 09 Estratos, 10 Cuarto del Capataz, 11 Taller de Dola (A22), 12 Vetas Vivas, 13 Descenso de los Zapadores | Se va al oeste por arriba, se baja y se vuelve al este por debajo | Agarre (06, 13), Doble (09) |
| Magda (3) | MIN-14 Antesala (A23), 15 Cámara de Apuntalamiento (**jefe 6 Magda, da Excavar y Piedra**), 16 Hueco del Pico | Pre-jefe, jefe, primer suelo roto | Excavar (16) |
| Ramal de Casimar y lámparas (4) | MIN-21 Trono Hundido (**jefe 5 opcional**), 22 Antecámara, 23 Cripta de las Lámparas, 25 Mina Inundada | Opcional | — (23 y 25: ver `puzles.md` para las versiones base) |
| Red de Excavar (7) | MIN-17 Veta Tapiada, 18 Pozo de los Cantores, 19 Galería de la Marea, 20 Cauce Hundido (barca), 24 Pozo del Latido, 27 y 28 Galería Larga (el Metro) | Atajos largos, pocas peleas: rutas de viaje, no de combate | Excavar |
| Colonia (1) | MIN-26 Colonia de los Hondos (A24) | Calma, neutral | — |

### La Costa Retenida (20)

| Bloque | Salas | Función | Requiere |
|---|---|---|---|
| Cornisa y Pilar (4) | COS-01 Paso del Pastor, 02 Escalones del Tajo, 03 Cornisa de Sal, 04 **Pilar de Lacre** (A25, nudo) | Camino largo de ceniza a sal; nudo de tres regiones | Agarre (01-04); Doble y Dash (03) |
| Acantilado y aldea (7) | COS-05 Acantilado de Cortinas, 06 Sendero de los Pañuelos, 07 Muro Blanco (A26), 08 Altar de Sal, 09 Casa Atada, 10 Banco Doble (A27), 11 Tendederos | Pueblo, Quiteria, Vael, el sueño | Doble y Dash (11) |
| Playa y salinas (3) | COS-12 Playa de Nombres, 13 Salina, 14 Casa de las Redes | Respiro, combate abierto, lore | — |
| Puerto y gruta (3) | COS-15 Barca Varada, 16 Cala de Mirena (A29), 17 Gruta de la Marea | Embarcadero; salida al Cauce | — |
| Faro (2) | COS-18 Escalera de las Velas (A28), 19 Faro de las Velas (**jefe 7 opcional**) | Opcional | Doble |
| Rellano de Cal (1) | COS-20 Rellano de Cal (**jefe 8 Eudora, da Cal**) | Jefe | — |

### La Herida (16)

| Bloque | Salas | Función | Requiere |
|---|---|---|---|
| Páramo y puerta (2) | HER-01 Páramo Gris (A30), 02 Puerta Sin Muro | Aproximación en calma; la cerradura de los tres Sellos | Cera + Piedra + Cal (02) |
| Descenso (4) | HER-03 Escalera de Hojas, 04 Círculo Colgado (A31), 05 Pared Raspada, 06 Hueco del Cuerpo | Caída en caracol, Nombres, lore | — |
| Fragmentos reconstruidos (5) | HER-07 Cisterna Doblada, 08 Chimenea Vuelta, 09 Terrazas de Ceniza (A32), 10 Scriptorium Sin Tinta, 11 Galerías Dobladas | Salas conocidas mal recordadas, cada una con un giro mecánico | Excavar (07), Dash+Doble+Agarre (08), Dash (09) |
| Eco Quieto y Mesa de Dos (2) | HER-12, 13 | Calma, ciclo de la puerta que no existe | **—** (no Nombrar) |
| Antesala y Asiento (2) | HER-14 (A33, la última), 15 (**jefe 9 Maelis**) | Pre-jefe, jefe | — |
| Sala de Aún (1) | HER-16 | Las tres salidas: Asiento, Margen, Escalera | Nombrar + 20 Nombres solo para la Escalera |

### Secretas y atajos (8)

SEC-01 Silo Sin Grano (Excavar; atajo Minas ↔ Cisterna) · SEC-02 Palomar (Doble + Agarre) · SEC-03 Casa del Peón (Doble; nodo del atajo al Umbral) · SEC-04 Cuarto de la Cama Hecha (dentro de COS-07) · SEC-05 Depósito de lo Rechazado (dentro de ARC-16) · SEC-06 Establos de los Mensajeros (Dash; el Doble también lo cruza) · SEC-07 Grieta de Rosendo (Excavar + Agarre) · SEC-08 Torreón de las Campanas Mudas (Doble + Agarre).

## Anclas

34 en total: 8 existentes y 26 nuevas. "Bonita" = lleva un PNJ y una línea propia en el Hito.

| Ancla | Sala | Ancla | Sala | Ancla | Sala |
|---|---|---|---|---|---|
| A01-A02 | UMB-01 (Hito y plataforma alta) | A13 | CIN-19 Cuesta | A25 | COS-04 Pilar (nudo) |
| A03 | UMB-03 Patio (bonita) | A14 | ARC-02 Puerta | A26 | COS-07 Muro Blanco (bonita) |
| A04 | CIN-02 Cisterna | A15 | ARC-05 Estantería Nueve (bonita) | A27 | COS-10 Banco Doble (pre-jefe 8) |
| A05 | CIN-03 Galerías (pre-jefe 1) | A16 | ARC-07 Lacres (pre-jefe 3) | A28 | COS-18 Escalera de las Velas (pre-jefe 7) |
| A06-A07 | CIN-05 Chimenea | A17 | ARC-26 Claustro | A29 | COS-16 Cala de Mirena (bonita) |
| A08 | CIN-06 Mirador | A18 | ARC-21 Antesala (pre-jefe 4) | A30 | HER-01 Páramo (ante la puerta) |
| A09 | CIN-07 Torre (cornisa) | A19 | MIN-01 Andén | A31 | HER-04 Círculo Colgado |
| A10 | CIN-11 Cruce del Pan (bonita) | A20 | MIN-05 Fila de Espera (bonita) | A32 | HER-09 Terrazas de Ceniza |
| A11 | CIN-14 Camino de Ronda (bonita) | A21 | MIN-08 Cámara de las Voces | A33 | HER-14 Antesala (pre-jefe 9) |
| A12 | CIN-17 Cercado (pre-jefe 2) | A22 | MIN-11 Taller de Dola (bonita) | A34 | UMB-08 Sótano (atajo de vuelta) |
| | | A23 / A24 | MIN-14 (pre-jefe 6) / MIN-26 Colonia | | |

Mayor distancia entre Anclas consecutivas del camino principal: 5 salas (A17 → A18 y A32 → A33); media, 3. Si jugando sobran, se recortan A13, A24 y A29 sin romper la regla. **Distancia Ancla → jefe:** 1 sala en todos los jefes (2 en Casimar, 0 en Oda, que se invoca desde el Ancla del Mirador). Los rastrillos de arena se abren al ganar, no al morir.

## Atajos y bucles

Reglas: todo atajo **se ve antes de abrirse** (la puerta con el lado que importa a la vista); ninguno se salta un jefe ni una llave; los de sentido único avisan con una reja con el pestillo del lado correcto; ninguno deja al jugador sin retorno.

| # | Atajo | Se abre | Lo que evita |
|---|---|---|---|
| S1 | Escalera de tablones Cisterna → Terrazas (construido) | Siempre | Quedar atrapado en el aterrizaje |
| S2 | Casa del Peón → Granero → Fragua [caída, 1→] | Doble; cae al Umbral | Volver a pie desde el Cinturón alto |
| S3 | Cruce del Pan → Chimenea alta [1→ **solo desde CIN-11**] | Desde el Cinturón alto | Repetir el primer tramo de la Chimenea |
| S4 | Rampa de Servicio ↔ Pasarela | Caída desde la Rampa; cuerda que se baja desde abajo | Rodear por la Chimenea hasta el Mirador |
| S5 | Almiar → Rampa → Cercado [1→] | Tras Jacinto | Atravesar la arena hacia el Ancla previa |
| S6 | Pasaje de las Llaves [1→] Antesala → hub | Desde la Antesala | Cruzar otra vez el Archivo en Blanco |
| S7 | Escalera Taponada [1→] Scriptorium → Claustro | Tras Ilara | Deshacer el ala en blanco |
| S8 | Mojones ↔ Pozos Blancos | Palanca desde el Archivo | Subir los pozos cada vez |
| S9 | Veta Tapiada: Silo ↔ Cisterna | Excavar | Volver de las Minas al Cinturón |
| S10 | Pozo de los Cantores ↔ Sótano (A34) | Excavar | Volver al Umbral del acto IV |
| S11 | El Metro (Galería Larga) | Excavar | Recorrer la U de las Minas |
| S12 | Pozo del Latido: Hueco del Pico → Páramo | Excavar | Rodear por el Pilar |
| S13 | Cauce: Costa ↔ Minas (barca) | Palanca en cada orilla; con Mirena aparece su línea | 1.200 baldosas |
| S14 | Puente de Cera con palanca: Pilar → Antesala | Desde el Pilar tras Hesper | Recorrer los 9 de Relatores en sentido contrario |

| Bucle | Recorrido | Qué consigue |
|---|---|---|
| B1 El foso (construido) | Terrazas → caída → Cisterna → Galerías → Aljibe → (Dash) → Terrazas, mismo foso | El modelo: ves, no puedes, caes, vuelves y puedes |
| B2 La Torre | Torre → Surco → (Doble) Casa Varga → Acequia → caída al Campo → Cruce del Pan | Círculo corto con ganancia de altura |
| B3 La Chimenea abierta | Cruce del Pan (CIN-11) → Chimenea alta, puerta de un sentido | Une el Cinturón alto con la Pasarela |
| B4 La Era y el Almiar | Cercado → Era → Almiar → Rampa → Cercado | Tras Jacinto se vuelve al Ancla sin la arena |
| B5 La Rampa | Cercado → Rampa → (caída) Pasarela; vuelta por la cuerda | Segunda entrada a la Pasarela; ruta de Oda en el epílogo |
| B6 Los Atriles | Hub → Biblioteca → Atriles → Altos → Biblioteca | Plataformas con atajo al hub |
| B7 El Pasaje de las Llaves | Antesala del Prior → Pasaje [1→] → Negadores → hub | Vuelta del último Ancla del Archivo en 3 salas |
| B8 La U de las Minas | Andén → oeste → Cuerda → este → Magda | Se pisa por debajo lo que se pisó por arriba |
| B9 El Metro | Cantores ↔ Veta ↔ Galería Larga ↔ Apuntalamiento | Red de Excavar: une Umbral, Cisterna y Magda |
| B10 Triángulo del Pilar | Pilar → Puente → Archivo → Pozos → Era → Cuesta → Cornisa → Pilar | Lazo que une tres regiones por arriba |
| B11 Costa por abajo | Magda → Marea → Cauce → Gruta → Costa; vuelta por la Cornisa | Los dos accesos a la Costa se cruzan en el pueblo |
| B12 El regreso al Umbral | Costa → Cala → Cauce → Metro → Cantores → Sótano → Puerta Tapiada → Umbral | Acto IV en ~4 min sin pisar el Cinturón |

**Viaje rápido.** Ninguno libre antes del acto IV: las Anclas y los 14 atajos físicos bastan (cada Ancla debe tener un retorno con ≤ 90 s de camino). Al obtener Nombrar (acto IV) se enciende "Decir los nombres": desde cualquier Ancla visitada, ir al Hito del Umbral y de allí a otra Ancla visitada (no hacia las Anclas "sin nombre" de la Herida). Es de `05-progresion-y-economia.md` §5.2; su construcción es posterior al mundo.

## Ver sin poder: zonas "mira pero no toques"

| Qué se ve | Desde dónde | Cuándo se puede coger |
|---|---|---|
| El muro de ladrillo del oeste | Primer pantallazo del juego | Excavar (h 7:30-9:45) |
| El otro borde del foso | Borde del foso, Terrazas | Dash |
| La cornisa del Ancla | Primer tablón de la Torre | Doble |
| La Herida (paisaje) y la piedra de lectura | Mirador | Nombrar (acto IV) |
| Tejado de la Casa Varga | Surco Ciego | Doble |
| Vigas y nidos del Palomar | Bancales | Doble + Agarre |
| Cuatro pozos lisos y la salida al Archivo | La Era | Agarre, justo tras el jefe |
| La Puerta Sin Muro y sus tres huecos | Cornisa de Sal y Pilar | Cera + Piedra + Cal |
| El Faro de las Velas | Cornisa de Sal | Opcional |
| Reja con grano sobre el Silo | Suelo de la Cisterna | Excavar |
| El Trono Hundido y sus aplausos | Cámara de las Voces (ventana) | Ramal opcional |
| El sello de cera gigante | Claustro de la Tinta | Hesper |
| La Escalera de los Nombres, apagada | Entrada de la Sala de Aún | 20 Nombres y Nombrar |
| La barca y el Cauce Hundido | Cala de Mirena | Siempre (palancas) |

## Ritmo espacial

Onda de cada región: calma → ascenso → cima → jefe → respiro → giro.

| Región | Entrada (calma) | Ascenso | Cima | Jefe | Respiro | Giro |
|---|---|---|---|---|---|---|
| Umbral | Primera pantalla | Foso, 2 cascarones | Escalera al 2.º Ancla | — | Pueblo alto | Muro del oeste |
| Cinturón bajo | Terrazas | Cisterna → Galerías | Galerías (alta densidad) | Centinela | Chimenea (sin enemigos) | Mirador |
| Cinturón alto | Surco Ciego | Campo, Acequia | Torres + Bancales | Jacinto | Cuesta | Los 3 caminos |
| Archivo | Puerta | Vestíbulo, Nave | Ilara; luego Blanco y Corredor | Ilara y Hesper | Claustro, Puente | Relatores |
| Minas | Andén | Rayas, Fila | Apeos, Vetas Vivas | Magda | Hueco del Pico | Excavar abre el Metro |
| Costa | Cornisa | Pañuelos | Salina | Eudora | Playa de Nombres | El sueño |
| Herida | Páramo | Escalera y Círculo | Fragmentos reconstruidos | Maelis | Sala de Aún | La elección |

Mezcla por región (calma/PNJ · plataformas/puzle · combate · jefe · otras): Umbral 5·0·0·0·3; Cinturón 9·11·6·2·2; Archivo 8·5·7·2·4; Minas 8·6·4·2·8; Costa 8·6·2·2·2; Herida 6·3·3·1·3; Secretas 0·0·0·0·8; total 44·31·22·9·30. El Cinturón es el más plataformero (lo que enseña), el Archivo el más tenso, la Costa casi sin combate a propósito. Si sobra en las Minas, se recorta en la red de Excavar, no en la U.

Reglas:

1. **No más de 3 salas de tensión seguidas** sin una calma (Galerías, Corredor de Lacre y Vetas Vivas son las más largas).
2. **Ninguna sala de calma sin un detalle de mundo** (objeto, inscripción, PNJ, vista): una calma vacía es un pasillo.
3. **Los jefes van tras una sala larga y un Ancla, y precedidos por una vista**: la arena nunca es lo primero que se ve de su región.
4. **Dos plataformas largas seguidas se separan por una sala de combate** (Acequia, Torre y Bancales son la excepción: tres puzles de Doble de dificultad creciente).
5. **El primer pantallazo de cada región enseña su verbo** (viento en la Cornisa, tinta en la Puerta, lámparas en el Andén, cal en el Muro, tela al aire en el Pilar).

## Guía sin texto

Luz cálida en toda Ancla y destino principal (el camino opcional va en sombra) · la marca de los Mensajeros (pie alado de hierro) señala el camino largo Terrazas → Mirador → Cornisa → Pilar · los edificios de la Orden tienen la puerta orientada al centro del mapa · color de región (ocre quemado Cinturón, azul de tinta Archivo, brasa Minas, blanco y azul sal Costa, gris Herida) · sonido (el Latido crece al acercarse a la Herida) · PNJ (Cano está donde falta algo, Mirena apunta a la barca, Sabela a la última Página) · el hueco central sin dibujar del minimapa.

## Desorden, bloqueos y salvaguardas

**Qué se puede saltar.** Hacia atrás se permite (el que vuelve con más habilidades toma atajos: eso es el metroidvania); hacia delante se impide (cada sala de puerta se simula con el inventario anterior y debe dar "meta no alcanzable"). Rupturas permitidas y prohibidas, en `puzles.md`. Un salto de destreza con margen < 6 fotogramas se tolera (no se anuncia); ninguno puede abrir una sala de la que no se pueda volver con lo que ya se tiene.

**Anti-softlock** (el mundo nunca debe atrapar):

1. Toda caída sin retorno aterriza en una sala con Ancla a ≤ 2 salas, o con salida disponible con las habilidades obligatorias para estar ahí (Descenso del Brocal: el Agarre ya se tiene, porque Jacinto está antes).
2. Cada habilidad está en una sala cuya entrada **no** exige esa habilidad.
3. Todo sentido único [1→] tiene camino de vuelta con las habilidades de ese momento. **El sentido único de CIN-05 ↔ CIN-11 abre solo desde CIN-11** (donde ya se tiene el Doble): si abriera desde la Chimenea, se entraría al Cinturón alto sin Doble.
4. Las Anclas están fuera de la arena; los rastrillos no atrapan al morir.
5. Lo roto con Excavar queda abierto para siempre; el túnel de debajo de una pieza `$` tiene salida que no exige Excavar para volver.
6. La barca cruza el Cauce **sin Mirena** (palanca en cada orilla); Mirena solo añade su presencia. No hay "a nado" (el motor no tiene agua que se nade).
7. La puerta de la Herida pide los tres Sellos; el Pilar es transitable de ida y vuelta. Entrar en la Sala de Aún sin Nombres solo pierde el final Compartir, no el camino.
8. El motor ya reaparece en el inicio si el Ancla guardada no existe.
9. Ninguna sala se cierra: 28 de los 30 Nombres se alcanzan sin opcionales (Compartir pide 20).
10. Único punto sin retorno: pisar el Asiento, el Margen o el primer escalón de la escalera final.

## Reglas para construir salas

Salen de lo aprendido jugando (`decisiones.md`, 2026-10-20 y 2026-10-22):

- **Aberturas entre salas: ≥ 6 baldosas** de alto (mínimo absoluto 4 en lo ya construido, que se ensancha: retoques R7), a la misma y absoluta en las dos salas y con el mismo nivel de suelo.
- **Techos: ≥ 6 baldosas libres** sobre cualquier plataforma (lo vigila la prueba de humo), salvo muros laterales (cols 0-1 y últimas).
- **Enemigos a ≥ 10 baldosas de cualquier puerta**, separados 14-18 baldosas entre sí, y solo actúan dentro de su sala.
- **Salas anchas**: ≥ 54 de ancho (la pantalla); las verticales estrechas se centran con la cámara. Los saltos largos (≥ 26) muestran el destino antes de despegar: salas anchas (≥ 96), no altas.
- **Huecos plataformeros**: márgenes de `puzles.md` (≥ 12 fotogramas en el camino principal); aterrizajes de ≥ 6 baldosas.
- **Cada sala nueva** declara región, requisitos y Ancla más cercana (manifiesto). Máximo 3 enemigos nuevos por región en las primeras versiones (la lista final de enemigos nuevos la fija el editor de combate).
- **Salas de calma**: nada que mate, un detalle de mundo.

## Retoques a las salas ya construidas

Detalle exacto (mapa, filas, columnas, cuándo aplicarlos) en `docs/reunion/disenadores/DECISIONES-EDITOR-MUNDO.md`. Resumen:

| # | Sala | Cambio | Cuándo |
|---|---|---|---|
| R1 | UMB-01 | Muro oeste excavable: pieza `$` 2×6 en cols 0-1, filas 14-19 | Con la mecánica de grieta honda y UMB-07 |
| R2 | UMB-01 | Prolongar la escalera de tablones hacia UMB-02 (tres tablones, filas 8, 5 y 2) | Al construir UMB-02 |
| R3 | CIN-07 | Abrir la pared derecha de la cornisa (cols 54-55, filas 1-6) | Al construir CIN-08 |
| R4 | CIN-05 | Reja de un sentido en la pared izquierda alta (cols 0-1, filas 11-16) y salida este baja (cols 38-39, filas 61-66) | Con la compuerta (M3) y CIN-11 / SEC-06 |
| R5 | CIN-06 | Sin cambio de baldosas; el hueco de caída va en el suelo de CIN-23, sobre la plataforma larga (x 504-516) | Al construir CIN-23 |
| R6 | CIN-02 | Reja con grano: pieza `$` 3×9 en cols 54-56, filas 22-30 | Con SEC-01 |
| R7 | CIN-01 / CIN-07 | Ensanchar la abertura de 4 a 6: Terrazas col 63 filas 14-15 y Torre cols 0-1 filas 34-35 | Cuando se quiera (sin dependencias) |

## Cómo está construido: salas conectadas

El mundo se hace de **salas**: cada una es un mapa de texto (`game/levels/*.map`, ver `vertical-slice.md` para la leyenda) con su escena (`*.tscn`, script `game/levels/room.gd`). `game/levels/world.tscn` (se llega desde el menú principal) las coloca una junto a otra en su sitio del mundo, todas cargadas a la vez: el jugador pasa de una a otra caminando, cayendo o saltando, sin pantallas de carga ni cortes.

- **Cámara:** se limita a la sala en la que está el jugador; al cambiar de sala se desliza suavemente hasta la nueva (como en Hollow Knight o Super Metroid).
- **Caída mortal:** se muere al caer por debajo de la sala actual. Por eso un foso puede matar (El Último Umbral) o ser la entrada a otra sala de abajo (Las Terrazas Secas → La Cisterna): depende de si debajo hay sala.
- **Mapa:** se descubre explorando, baldosa a baldosa: solo se dibuja lo que ha quedado a menos de 12 baldosas del jugador (`REVEAL_RADIUS` en `world.gd`), no la sala entera al entrar. La primera vez que se entra en una sala se anuncia su nombre. El minimapa (arriba a la izquierda) y el mapa completo (Esc → Mapa) muestran al jugador (dorado), las Anclas (azul) y el Eco de la última muerte (violeta), estos dos solo si se ha pasado cerca. Sin comprar mapas ni cartógrafos. **Una sala puede declarar `reveal_map = false`** (El Archivo en Blanco, ARC-19): el mapa no dibuja nada ahí y se confía en la luz (cambio mínimo en `world.gd`; pendiente de construir).
- **Enemigos:** solo actúan dentro de su sala y cuando el jugador lleva unas 4 baldosas dentro (`ROOM_ENTRY_MARGIN` en `enemy.gd`, `PatrolChaseAI.territory`).
- **Qué se guarda:** la partida (`user://`, `SaveSlot`) guarda al jugador, las salas visitadas, los jefes vencidos y lo explorado del mapa. Los puzles y secretos guardarán sus **marcas** (`flags`) y los coleccionables sus listas, como claves nuevas **opcionales** de ese mismo diccionario (ver `puzles.md`); el `FORMAT_VERSION` de `SaveSlot` no se toca, porque cambiarlo descarta las partidas existentes.
- **Carga:** hoy son ocho salas, todas cargadas; solo la actual y sus vecinas procesan (`_activate_nearby_rooms`). Con ~40 salas habrá que cargar por región (el manifiesto ya define las regiones) y descargar las que están a más de 2 salas; hoy no hace falta.
- **Verificación del mundo:** `tools/verifica_mundo.js` (Node, sin dependencias, como `sim_saltos.js`; **por construir**) leerá los `.map`, `world.tscn` y `tests/world_manifest.json` y comprobará solapes, aberturas alineadas y ≥ 6, aberturas huérfanas, caracteres válidos y accesibilidad por habilidades; cada fallo imprime región, sala, borde y fila y sale con código ≠ 0. Lo que depende del motor (colisiones, reproducción de maniobras) sigue en `tests/smoke_test.gd`. Fases y comprobaciones, en `puzles.md`.

## El mundo construido hoy

Ocho salas (posiciones en baldosas, de `world.tscn`):

| Sala | ID | Posición | Tamaño |
|---|---|---|---|
| El Último Umbral | UMB-01 | (0,0) | 80×28 |
| Las Terrazas Secas | CIN-01 | (80,0) | 64×24 |
| La Cisterna | CIN-02 | (80,24) | 128×31 |
| Las Galerías Bajas | CIN-03 | (208,20) | 112×34 |
| El Aljibe | CIN-04 | (320,16) | 64×33 |
| La Chimenea | CIN-05 | (384,-21) | 40×69 |
| La Pasarela de los Mensajeros y El Mirador | CIN-06 | (424,-21) | 100×24 |
| La Torre de Riego | CIN-07 | (144,-20) | 56×44 |

```
                        ┌────────────┐
┌─────────────────┬─────┤ La Torre de│                                       ┌─ La Pasarela ─ El Mirador
│ El Último Umbral│Terra│   Riego    │                          La Chimenea ─┘  (3 huecos, solo con dash)
│ (inicio, Anclas)│zas  └────────────┘                               ▲
└─────────────────┴──┬──┘                                            │ recuerdo del dash
                     │ La Cisterna ─► Las Galerías Bajas ─► El Aljibe (jefe)
                     │ (128, Ancla)   (112, Ancla, pinchos)   (arena cerrada)
```

El recorrido sigue el ritmo de un primer tramo de Hollow Knight (un pueblo, una caída a una zona subterránea, un banco justo antes del primer jefe y el poder que da, probado enseguida en un pasaje exigente). Las salas del tramo son **largas** (la Cisterna 128 baldosas, las Galerías 112) y los enemigos van separados unas 14 o 18 baldosas, para que cada encuentro sea suyo y no un montón.

1. **El Último Umbral** — la zona de inicio (ver `vertical-slice.md`). Su borde derecho continúa hacia el Cinturón Yermo; el techo es cielo abierto (UMB-02 irá encima).
2. **Las Terrazas Secas** — primera sala del Cinturón Yermo. Un foso de 20 baldosas no se puede saltar sin dash; caer en él no mata, lleva a La Cisterna.
3. **La Cisterna** (128×31) — depósito subterráneo seco. Se aterriza en una zona tranquila bajo el foso; una escalera de tablones (5 peldaños) devuelve a él. Hacia el este, un lancero, un cascarón, un arrojador sobre un tablón y un acechador, y al final, junto a la puerta, un **Ancla**.
4. **Las Galerías Bajas** (112×34) — el tramo largo antes del jefe, en un salón alto: cascarones, un foso de pinchos, una galería alta con un arrojador, un acechador, un lancero, un coloso, pinchos que salen y se retraen y, justo antes de la puerta, un **Ancla** y una inscripción que anuncia al Custodio.
5. **El Aljibe** (64×33) — la **arena** del **Centinela Hueco** (ver `jefes.md`): al cruzar la línea de la sala caen dos rastrillos y no se puede huir hasta vencerlo. Al vencerlo aparece el recuerdo del **dash**.
6. **La Chimenea** (40×69) — el puzle del dash: un eje abierto, sin techos, con escalones anchos y **tres cruces de 16 baldosas que solo se salvan con dash**. Cada fallo cuesta caer a un escalón inferior o a los pinchos. Tiene un **Ancla** al acabar el primer cruce y otra a mitad.
7. **La Pasarela de los Mensajeros** (100×24) — al aire libre: tres huecos de 17 baldosas sobre un abismo de pinchos, todos con dash, hasta **El Mirador**, con un **Ancla** y una inscripción. Es un callejón sin salida (ver la lógica espacial): el camino al este sale por la Cuesta del Segador (CIN-19), no por aquí.
8. **La Torre de Riego** — al otro lado del foso de las Terrazas. Escalera de tablones hasta el recuerdo del **doble salto**; con él se alcanza la cornisa del Ancla. Su pared derecha queda cerrada hasta el retoque R3.

Es el primer bucle metroidvania del mundo real: ves un foso que no puedes cruzar, caes, abres el camino bajo tierra con un jefe, vuelves con el dash y cruzas ese mismo foso; y el puzle del dash pone a prueba lo aprendido. Las maniobras de referencia del puzle están en `tests/puzzle_plans.json` y la prueba de humo las repite en el motor (ver `jefes.md` y `docs/arquitectura.md#verificación`).

## Para ampliar el mundo

Con una sala nueva:

1. Mirar su ficha en `01-mapa-macro.md` §4 (tamaño, conexiones, función) y, si lleva puzle, en `puzles.md`.
2. Dibujar su `.map` (lo normal es 54 columnas o más; una sala vertical estrecha, como La Chimenea con 40, se centra con la cámara; si es más baja de 31 filas, la cámara enseña lo que hay encima de ella). **Solo caracteres de la leyenda de `vertical-slice.md`**: un carácter desconocido se convierte en marcador sin avisar.
3. Copiar una escena de sala (p. ej. `terrazas_secas.tscn`) cambiando `map_file`, `title` y `has_sky` (false bajo tierra o bajo techo).
4. Instanciarla en `world.tscn` bajo `Rooms`, en la posición exacta del manifiesto (múltiplo de 16 px) y con las aberturas a la misma altura (≥ 6 baldosas) en las dos salas.
5. Si lleva plataformas exigentes, comprobarlas con `tools/sim_saltos.js` (márgenes de `puzles.md`) y añadir su maniobra a `tests/puzzle_plans.json`.
6. Añadir a `tests/smoke_test.gd` una prueba de que se llega a ella y de que se puede volver (que no deje al jugador atrapado), y añadir su nombre a la lista de `_test_no_platform_has_a_cramped_ceiling`.
7. Cuando exista, ejecutar `node tools/verifica_mundo.js` y la prueba de humo (`godot --headless --path . --script res://tests/smoke_test.gd`, código 0), y **jugarla**.

## Orden de construcción recomendado

Por acto, con lo que cada tramo necesita de `puzles.md` (fases W0-W9):

1. **Preparación sin contenido (W0-W1):** piezas de `TextTileMap`, pared lisa `%`, ampliación de `sim_saltos.js`, estado de mundo, coleccionables `!`, verificador mínimo. Retoque R7.
2. **Cinturón alto (CIN-08 a CIN-19) con R2/R3/R4:** es la única región que se puede encajar con lo construido y solo pide Doble. Necesita W2-W3.
3. **Era → Agarre → Archivo y Costa larga** (orden libre): `%` y compuertas de puente/tinta.
4. **Minas** hasta Magda; **Excavar** (W5) y los retoques R1 y R6 junto a UMB-07/08 y SEC-01.
5. **Costa, Sellos (W6) y Herida;** Nombrar y el diario de Nombres (W7) para el acto IV.

Un mundo pequeño y terminado es mejor que uno grande a medias: tras el Cinturón alto y la Era, el juego ya tiene cuatro habilidades, dos jefes y un final de tramo en el Pilar. Lo que queda más allá es decisión del usuario.

## Pendiente de decidir por el usuario

Ver la lista final de `DECISIONES-EDITOR-MUNDO.md` (si el Agarre recarga el dash y el doble salto, cuántos enemigos nuevos por región, reparto de reliquias). Nada de lo anterior depende de ellas.
