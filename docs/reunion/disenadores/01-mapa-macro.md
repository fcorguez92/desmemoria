# 01 · Mapa macro del mundo

Rol: arquitecto del mapa (diseño de niveles, escala macro). Estado: propuesta de la sala de diseño, sin aprobar. Respeta el canon cerrado (`historia.md`, `guion-maestro.md`, `personajes.md`, `textos-del-juego.md`) y lo ya construido (8 salas, posiciones de `world.tscn`). Los nombres de sala nuevos son **de trabajo**: antes de fijarlos hay que comprobar que no tengan acepciones vulgares (regla de `CLAUDE.md`).

Cifras: **136 salas, 6 regiones, 5 habilidades, 10 jefes, 12 PNJ, 30 Nombres, 34 Anclas, 13 h de camino principal.** Coordenadas en baldosas (16 px), con **la esquina superior izquierda de El Último Umbral en (0,0)**, x hacia el este, y hacia el sur.

---

## 0. Ideas rectoras

1. **Una forma legible: un anillo con un hueco en el centro.** Las tres regiones libres (Archivo, Minas, Costa) rodean la Herida por el norte, el sur y el este; el Cinturón es la rampa de entrada por el oeste. El minimapa dice "voy hacia dentro" sin una palabra.
2. **Un cruce único que lo ata todo: el Pilar de Lacre (COS-04).** Una sala vertical enorme donde se cruzan el camino del Cinturón a la Costa, el puente que baja del Archivo y el pozo que da a la Puerta Sin Muro. La puerta de la Herida se ve mucho antes de poder abrirla: es el "ver antes de poder" a escala de mundo.
3. **Cada habilidad tiene su cerradura visible antes que su llave** (foso de las Terrazas, cornisa del Ancla, pozos blancos, el muro del primer pantallazo, la piedra de lectura del Mirador).
4. **Cada región tiene un bucle de regreso corto.** No se vuelve dos veces por el mismo pasillo: o hay un atajo de sentido único, o la vuelta pasa por otra sala.
5. **El mundo se pliega sobre sí mismo.** Los atajos de Excavar y la barca de Mirena convierten un viaje de 1.400 baldosas (Costa → Umbral) en unos 4-5 minutos.
6. **Todo se comprueba con datos.** Propongo un manifiesto del mundo (`tests/world_manifest.json`) y una verificación automática (§8) para que ninguna ampliación rompa puertas, alturas ni accesos.

---

## 1. Convenciones

| Símbolo | Significado |
|---|---|
| N / S / E / O | Lado de la sala por el que se conecta. `(↓)` caída; `(↑)` ascenso; `[1→]` sentido único (se abre solo desde un lado). |
| Requiere | Habilidad o llave **mínima** para entrar o cruzar: Dash, Doble (doble salto), Agarre (salto de pared), Excavar, Nombrar, Cera/Piedra/Cal (Sellos), Tinta (Llave de Tinta). "—" = nada. |
| Axx | Ancla del plan de §5. |
| FV / FF | Fragmento de vida / de frasco (4 FV = +1 vida máxima, 12 en el mundo; 3 FF = +1 frasco). Coincide con `05-progresion-y-economia.md`. |
| Nombre: X | Uno de los 30 Nombres, en la fuente que fija el canon. |
| Enemigos | Existentes: cascarón, lancero, arrojador, coloso, acechador. Nuevos propuestos, máximo 3 por región, marcados (n). |
| Densidad | Baja = 1-2 enemigos; media = 3-4; alta = 5 o más. Siempre a ≥ 10 baldosas de cualquier puerta. |
| Tamaño | Columnas × filas de baldosas. La pantalla es 54×30. Salas horizontales de ≥ 54 de ancho; las verticales estrechas se centran con la cámara. |

---

## 2. El grafo del mundo

### 2.1 Regiones, bloques y número de salas

| Región | Salas | Bloques (nº de salas) | Acto | Habilidad |
|---|---|---|---|---|
| **El Último Umbral** (UMB) | 8 | Primera pantalla (1) · Pueblo alto: Escalera, Patio, Fragua, Rellano (4) · Secreta: Estandarte (1) · Tras el muro: Puerta Tapiada y Sótano (2) | I y IV | Solo Excavar, para el muro del oeste |
| **El Cinturón Yermo** (CIN) | 30 | Cinturón bajo construido (7) · Cinturón alto, eje: Surco, Varga, Campo, Cruce, Acequia, torre y Bancales (7) · Camino de Ronda, Cercado y Era (3) · Salida al hondo: Almiar, Cuesta, Brocal, Descenso, Rampa (5) · Ramas altas: Molino, Granero, Pozo, Lavadero, Balsa, Ermita, Mojones, Linde (8) | I y II | Da Dash, Doble y Agarre; exige los tres en orden |
| **El Archivo** (ARC) | 26 | Pozos y entrada (3) · Eje: Nave y Estantería Nueve (2) · Ala en Blanco hasta Ilara (3) · Ala Intacta (6) · Ala de los Negadores (3) · Escalera y sector de los Relatores hasta Hesper y el Puente (9) | II | Exige Agarre; da Cera |
| **Las Minas del Origen** (MIN) | 28 | Bajada y primer tramo (5) · La U de descenso (8) · Magda (3) · Ramal de Casimar y lámparas (4) · Red de Excavar: Metro, Veta, Cantores, Marea, Cauce, Latido (7) · Colonia (1) | III | Exige Agarre; da Excavar y Piedra |
| **La Costa Retenida** (COS) | 20 | Cornisa y Pilar (4) · Acantilado y aldea (7) · Faro (2) · Rellano de Cal (1) · Puerto y gruta (3) · Playa y salinas (3) | III | Exige Agarre (camino largo) o Excavar (corto); da Cal |
| **La Herida** (HER) | 16 | Páramo y puerta (2) · Descenso: Escalera, Círculo, Pared, Hueco (4) · Fragmentos reconstruidos (5) · Eco Quieto y Mesa de Dos (2) · Antesala y Asiento (2) · Sala de Aún (1) | V | Exige los tres Sellos; usa todas |
| **Secretas y atajos** (SEC) | 8 | Repartidas por todas las regiones | I-V | Excavar, Doble, Agarre, Dash |
| **Total** | **136** | | | |

Una precisión sobre el canon: `guion-maestro.md` §6 cuenta el Mirador aparte; aquí es parte de la sala de la Pasarela (así lo trata `world.tscn`). El Cinturón tiene **7 construidas + 23 nuevas = 30**.

### 2.2 Esquema del grafo (llaves y cerraduras)

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

Llaves y cerraduras (todo lo que bloquea el camino principal o una recompensa):

| Cerradura (dónde) | Llave | Dónde está la llave | Qué se ve antes de poder |
|---|---|---|---|
| Foso de 20 baldosas (CIN-01) | Dash | Aljibe (CIN-04), tras el Centinela | El otro borde, desde el borde |
| Cruces de la Chimenea y huecos de la Pasarela (CIN-05/06) | Dash | Ídem | La luz del Mirador desde la Chimenea |
| Cornisa del Ancla de la Torre (CIN-07) y Casa Varga (CIN-09) | Doble | Torre de Riego (CIN-07) | La cornisa, desde el primer tablón |
| Pozos Blancos, Pastor y Escalones, vuelta del Descenso (ARC-01, COS-01/02, CIN-21) | Agarre | La Era (CIN-18), Jacinto | Los pozos lisos de la Era, con arañazos en la piedra |
| Muro oeste del Umbral, suelo del Silo, Veta, Metro, Marea, Latido, suelos de la Herida | Excavar | Cámara de Apuntalamiento (MIN-15), Magda | El muro del primer pantallazo; la reja con grano sobre el Silo |
| Sala de los Relatores (ARC-17) | Tinta | Scriptorium (ARC-08), Ilara | La puerta con cerradura de pluma, en el Claustro |
| Piedras de lectura (Mirador, Herida), escalera final | Nombrar | Hito del Umbral (acto IV) | La piedra con el hueco "pide un nombre", visible desde la primera visita |
| Puerta Sin Muro (HER-02) | Cera + Piedra + Cal | Hesper (ARC-22), Magda (MIN-15), Eudora (COS-20) | Los tres huecos vacíos, ya desde el Pilar |
| Epílogo del Relevo (Aljibe) | Insignia + final Compartir | Oda (secreto, CIN-06) | La coraza arrodillada, desde la primera vez |

### 2.3 Los bucles

| Bucle | Recorrido | Qué consigue |
|---|---|---|
| **B1 El foso** (construido) | Terrazas → caída → Cisterna → Galerías → Aljibe → (Dash) → Terrazas, mismo foso | El modelo: ves, no puedes, caes, vuelves y puedes |
| **B2 La Torre** | Torre → Surco → (Doble) Casa Varga → Acequia → caída al Campo de los Ferrán → Cruce del Pan | Círculo corto con ganancia de altura y caída final |
| **B3 La Chimenea abierta** | Cruce del Pan (CIN-11) ↔ Chimenea (CIN-05) alta, puerta [1→] | Une el Cinturón alto con la Pasarela sin repetir el puzle |
| **B4 La Era y el Almiar** | Cercado → Era → Almiar → Rampa → Cercado | Tras vencer a Jacinto se vuelve al Ancla del Cercado sin recorrer la arena |
| **B5 La Rampa** | Cercado → Rampa → (caída) Pasarela; vuelta por una cuerda que se baja desde abajo | Segunda entrada a la Pasarela; es la ruta de Oda en el epílogo |
| **B6 Los Atriles** | Hub → Biblioteca → Atriles → Altos → Biblioteca | Bucle de plataformas con atajo al hub |
| **B7 El Pasaje de las Llaves** | Antesala del Prior → Pasaje [1→] → Negadores → hub | Vuelta del último Ancla del Archivo al hub en 3 salas |
| **B8 La U de las Minas** | Andén → oeste → Cuerda → este → Magda | Se pisa por debajo lo que se pisó por arriba |
| **B9 El Metro** | Pozo de los Cantores ↔ Veta ↔ Galería Larga ↔ Cámara de Apuntalamiento | Red de Excavar: une Umbral, Cisterna y Magda |
| **B10 El triángulo del Pilar** | Pilar → Puente → Archivo → Pozos → Era → Cuesta → Cornisa → Pilar | Un lazo que une tres regiones por arriba |
| **B11 Costa por abajo** | Magda → Marea → Cauce → Gruta → Costa; vuelta por la Cornisa | Los dos accesos a la Costa se cruzan en el pueblo |
| **B12 El regreso al Umbral** | Costa → Cala → Cauce → Metro → Pozo de los Cantores → Sótano → Puerta Tapiada → Umbral | Acto IV en ~4 min sin pisar el Cinturón |

### 2.4 Zonas "mira pero no toques"

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
| El Cauce Hundido y la barca | Cala de Mirena | Mirena, o a nado |

### 2.5 Sorpresas (cambios de región y salas que reconstruye la Herida)

1. **El Mirador (h 2:45):** se apaga la música y la Herida se ve como paisaje a unas 450 baldosas. Es fondo, no sala, y la mentira es deliberada.
2. **El Pilar de Lacre:** el jugador cree que baja al Archivo y baja a la Herida; sale por el otro lado a la Costa. Un cruce, cuatro direcciones, tres regiones.
3. **La Cornisa de Sal:** la luz pasa de ceniza a azul sal en tres pantallas; es la Costa antes de la Costa.
4. **El Archivo en Blanco (ARC-19):** el mapa no dibuja nada ahí (no revela baldosas); se confía en la luz.
5. **La Sala de los Relatores:** quita el control 2 s. Es la única del juego que lo hace.
6. **Las cinco salas reconstruidas de la Herida (HER-07 a HER-11):** versiones desordenadas de la Cisterna, la Chimenea, las Terrazas, el Scriptorium y las Galerías, cada una con un giro mecánico.
7. **La Puerta Tapiada:** el muro que se veía al principio resulta ser la entrada al sótano de los Cantores, y el sótano es el atajo de vuelta.
8. **El regreso (acto IV):** el muro de Nombres del Patio ha crecido y Aldara está en el Fogón. Cambia el estado de dos salas, no hay salas nuevas.

---

## 3. Cuadrícula y posición de cada región

### 3.1 Cajas de región (baldosas, origen en el Umbral)

| Región | Caja (x0,y0) → (x1,y1) | Tamaño | Salas | Relleno* |
|---|---|---|---|---|
| Umbral | (-96,-124) → (80,40) y tira (80,-72) → (192,-20) | 176×164 + 112×52 | 8 | 63 % |
| Cinturón bajo (construido) | (80,-21) → (524,55) | 444×76 | 7 | 56 % |
| Cinturón alto | (88,-276) → (656,80) | 568×356 | 23 | 42 % |
| Archivo (en L) | (544,-430) → (1040,-130) y ala noroeste (200,-480) → (544,-290) | 496×300 + 344×190 | 26 | 69 % |
| Minas | (-96,40) → (740,330); tira (740,270) → (1360,330); pozo (740,30) → (820,270) | 836×290 + 620×60 | 28 | 71 % |
| Cornisa y Pilar | (656,-130) → (1040,30) | 384×160 | 4 | 55 % |
| Costa (pueblo; incluye el Acantilado de Cortinas) | (1040,-130) → (1600,190) | 460×320 | 16 | 60 % |
| Herida | (820,30) → (1140,290) | 320×260 | 16 | 84 % |
| Secretas | repartidas | — | 8 | — |

\* Relleno = suma de áreas de sala / área de la caja. Por debajo del 60 % sobra sitio; entre 60 y 85 % hay que plegar la región (las Minas lo hacen en U, el Archivo apila salas en vertical); por encima de 85 % (la Herida) se dibuja primero el manifiesto de posiciones, porque las salas son teselas de una espiral descendente y no hay holgura para errores de abertura.

### 3.2 Dibujo global

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
  (cada carácter = 24 baldosas; x de -96 a 1620, y de -480 a 330; los números son la y de cada fila)
```

Leyenda: **U** Umbral · **c** Cinturón bajo (construido) · **C** Cinturón alto · **\*** Mirador · **A** Archivo (en L) · **k/K** Cornisa y Costa · **P** Pilar de Lacre · **H** Páramo y Herida · **M/m** Minas y red de Excavar (galerías largas y pozos) · **s** secretas.

Cómo se lee en el minimapa: un pico oeste (Umbral), una faja ancha que sube hacia la derecha (Cinturón alto), un bloque alto (Archivo), un bloque bajo que crece en U (Minas) y, a la derecha de todo, la Costa. **El hueco central, la Herida, queda como rectángulo sin dibujar hasta el acto V**, para que el jugador sepa dónde hay que llegar. Las Minas lo rodean por debajo.

### 3.3 Salas fijas de ensamblaje (coordenadas exactas)

Se colocan primero; las demás se encajan con ellas. Salen de `world.tscn` y de los mapas (todo múltiplo de 16 px). Dónde una abertura mide 4 baldosas en vez de 6 se indica en negrita (ver riesgo 3 de §9).

| Sala | Posición (x,y) | Tamaño | Aberturas fijadas (y absolutas) |
|---|---|---|---|
| UMB-01 Umbral | (0,0) | 80×28 | E: y 0-19 (suelo en 20); N: cols 0-79; O: muro sellado en y 6-19 |
| CIN-01 Terrazas | (80,0) | 64×24 | O: y 0-19; E: y 16-19 (**4**); S: cols 30-49 (foso) |
| CIN-02 Cisterna | (80,24) | 128×31 | N: cols 30-49; E: y 40-45 |
| CIN-03 Galerías | (208,20) | 112×34 | O y E: y 40-45 |
| CIN-04 Aljibe | (320,16) | 64×33 | O y E: y 40-45 (rastrillos) |
| CIN-05 Chimenea | (384,-21) | 40×69 | O: y 40-45; E: y -19 a -14 |
| CIN-06 Pasarela | (424,-21) | 100×24 | O: y -21 a -14; cielo abierto; Mirador al este (cota y -13) |
| CIN-07 Torre | (144,-20) | 56×44 | O: y 16-19 (**4**); cornisa del Ancla al este, y -14 (pared cerrada hoy) |
| SEC-01 Silo | (96,55) | 64×32 | N: bajo la Cisterna (Excavar) |
| ARC-01 Pozos Blancos | (544,-250) | 48×130 | S: sobre la Era (y -120) |
| COS-04 Pilar de Lacre | (960,-130) | 80×160 | N: Puente; O y E: y -110 a -104; S: Páramo |
| HER-01 Páramo Gris | (820,30) | 200×50 | N: bajo el Pilar (x 960-1020) |

Las 52 salas con posición exacta (§4: columna Tamaño, tras "@") se han comprobado con un script: **0 solapes**, y todas las conexiones declaradas entre ellas son adyacencias reales con ≥ 4 baldosas de contacto (las construidas usan los números de `world.tscn`).

### 3.4 Intervenciones mínimas en lo ya construido

| # | Sala | Cambio | Por qué | Riesgo |
|---|---|---|---|---|
| I1 | UMB-01 | Muro excavable en el oeste (y 14-19) | Puerta Tapiada | Tile nuevo `D` (§8) |
| I2 | UMB-01 | Abrir el techo sobre el 2.º Ancla (cols 56-79) con camino de tablones a UMB-02 | Pueblo alto | Ninguno: el cielo ya es abierto |
| I3 | CIN-07 | Abrir la pared derecha de la cornisa (y -19 a -14) | Cinturón alto | Probar con `sim_saltos.js` |
| I4 | CIN-05 | Puerta [1→] en la pared izquierda alta (y -10 a -4) y salida este en y 40-45 hacia SEC-06 | B3 y Establos | No toca plataformas del puzle |
| I5 | CIN-06 | Abrir 24 baldosas del techo (x 456-480) y una cuerda que se baja desde abajo | B5 | La Pasarela ya tiene cielo abierto |
| I6 | CIN-02 | Reja con grano en el suelo (Excavar), lejos de la escalera de tablones | Silo | Tile nuevo `D` |

Todo lo demás se construye nuevo.

### 3.5 Distancias (para dimensionar el viaje)

Carrera ≈ 18,75 baldosas/s; con rodeos y combate, el tiempo real sube ×2-3. Umbral → Aljibe: 400 baldosas (4-6 min reales). Aljibe → Era: 380 (6-9 min). Era → Pilar por la Cornisa: 400 (4-5 min). Pilar → Muro Blanco: 220 (3 min). **Costa → Umbral sin atajos: 1.440 baldosas (12-15 min); con Cauce y Metro, 4-5 min.** Sin los atajos de §5.3 el acto IV costaría un cuarto de hora de vuelta: es lo que los justifica.

---

## 4. Tablas de salas por región

Una idea por sala. Las columnas de enemigos usan la densidad de §1. "@(x,y)" es la posición fijada en §3.3 o propuesta (esquina superior izquierda, en baldosas); las demás regiones se colocan con el esquema de su bloque.

### 4.1 El Último Umbral (8) · tono: miedo y duelo, sin Desmemoria

Función global: enseñar, dar calma y servir de hub de los actos I y IV. Todo el pueblo alto cuelga *hacia arriba* de la primera pantalla, para que el regreso del acto IV sea un descenso a casa.

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| UMB-01 | El Último Umbral (construida) | 80×28 @(0,0) | E→CIN-01 · N→UMB-02 (sobre el 2.º Ancla) · O→UMB-07 (muro) | Tutorial, calma, Anclas | — (muro: Excavar) | Foso mortal; 2 cascarones | Nombres Ossenna, Fara, Tomás, Inés, Rubén; Página 1 de Corvel (Nombre Corvel); A01, A02 |
| UMB-02 | La Escalera del Remiendo | 80×60 @(0,-60) | S→UMB-01 · E→UMB-03 · N→UMB-05 · O→UMB-06 (tras el estandarte) | Calma + PNJ (Vael) + plataformas suaves de tablón | — | Ninguno (primera visita) | Cartel de salida; mesa de doce cuencos |
| UMB-03 | El Patio de los Nombres | 64×40 @(80,-60) | O→UMB-02 · E→UMB-04 | Hub social: Fogón, Hito grande, Iria, Aldara, Cano | — | Ninguno | Placa del Fogón; muro de Nombres (crece en el acto IV); A03 |
| UMB-04 | La Fragua del Umbral | 48×52 @(144,-72) | O→UMB-03 · N←CIN-24 (caída [1→]) | PNJ Garrán, calma | — | Ninguno | Yunque "para abrir"; mejora única del Filo |
| UMB-05 | El Rellano de la Vela | 80×64 @(0,-124) | S→UMB-02 | Calma con vista: primer atisbo del mar | — | Ninguno | Ofrenda del 3.er Ancla; Medalla del Umbral (reliquia); texto de la vela |
| UMB-06 | Detrás del Estandarte | 40×28 @(-40,-52) | E→UMB-02 (pared que se rompe al golpear) | Secreta | — | Ninguno | Jirón de la Orden y nota; FV |
| UMB-07 | La Puerta Tapiada | 32×28 @(-32,0) | E→UMB-01 (muro) · O→UMB-08 | Transición tras el muro | Excavar | Ninguno | Dintel; marcas de uñas por el lado de dentro |
| UMB-08 | El Sótano de los Cantores | 64×40 @(-96,0) | E→UMB-07 · S→MIN-18 (pozo) | Ancla-atajo, lore de Aún | Excavar | Ninguno | Grabado "Su nombre es Aún"; A34; reliquia Llave sin puerta |

### 4.2 El Cinturón Yermo (30) · tono: rutina como último vestigio, desde el cielo abierto al subsuelo

Estructura: **Bajo** (Terrazas, Cisterna, Galerías, Aljibe, Chimenea, Pasarela, Torre; construido) → **Alto** (13 salas de dos torres, bancales y acequias) → **Era y fork**. Dentro del Alto hay una rama oeste (Peón, Pozo, Lavadero) y una rama norte (Balsa, Ermita, Mojones) que se cierra sobre los Pozos Blancos del Archivo.

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| CIN-01 | Las Terrazas Secas (c.) | 64×24 @(80,0) | O→UMB-01 · S (foso ↓)→CIN-02 · E→CIN-07 | Plataformas: el foso | Dash (cruzar) | Foso de 20 baldosas; 1 cascarón | Cuenta del Rosario; aviso "no es un error" |
| CIN-02 | La Cisterna (c.) | 128×31 @(80,24) | N (↑ escalera)→CIN-01 · E→CIN-03 · S (reja)→SEC-01 | Calma al caer, luego combate | — (S: Excavar) | Lancero, cascarón, arrojador, acechador; densidad media | A04; texto de aterrizaje |
| CIN-03 | Las Galerías Bajas (c.) | 112×34 @(208,20) | O→CIN-02 · E→CIN-04 | Cima de tensión previa al jefe | — | Pinchos fijos y móviles; 7 enemigos, densidad alta | A05; inscripción del Custodio; llavero de Oriol |
| CIN-04 | El Aljibe (c.) | 64×33 @(320,16) | O→CIN-03 · E→CIN-05 | **Jefe 1: Centinela Hueco** | — | Rastrillos; el jefe | Dash; 40 Ecos; placa "Guardia del paso" |
| CIN-05 | La Chimenea (c.) | 40×69 @(384,-21) | O→CIN-04 · E (alto)→CIN-06 · O (alto) [1→]→CIN-11 · E (bajo)→SEC-06 | Puzle de Dash (3 cruces) | Dash | Pinchos; ningún enemigo | A06, A07; huella de pie con prisa |
| CIN-06 | La Pasarela de los Mensajeros y El Mirador (c.) | 100×24 @(424,-21) | O→CIN-05 · N (hueco, ↓)←CIN-23 | Puzle de Dash; vista de la Herida; **Jefe 10 (secreto)** | Dash; Nombrar (secreto) | Abismo de pinchos; Oda (secreto) | A08; Nombre: Oda Bellver; cartas; Insignia de Mensajera |
| CIN-07 | La Torre de Riego (c.) | 56×44 @(144,-20) | O→CIN-01 · E (cornisa)→CIN-08 | Escalera de tablones; Doble | Dash (llegar); Doble (cornisa) | Acechador; sin más | Doble; A09; Dedal de la Torre; Nombre: Tomasa; Medida de trigo |
| CIN-08 | El Surco Ciego | 72×36 @(200,-36) | O→CIN-07 · E→CIN-10 · N (↑)→CIN-09 | Calma + vista de la Casa Varga | Doble (cornisa de entrada) | Ninguno | Placa "Nadie recuerda qué"; Semilla gris |
| CIN-09 | La Casa Varga | 48×48 @(200,-84) | S (↑)→CIN-08 · E→CIN-12 · N→SEC-03 | Eco narrativo del Doble | Doble | Ninguno | Marcas de altura de dos niños; FV |
| CIN-10 | El Campo de los Ferrán | 72×36 @(272,-36) | O→CIN-08 · E→CIN-11 · N (↑ desde Acequia ↓)↔CIN-12 | Combate con parches grises | — | Cascarones y 1 coloso; densidad media | Nombre: Eulalia Ferrán; mojón del lindero |
| CIN-11 | El Cruce del Pan | 40×36 @(344,-36) | O→CIN-10 · N (↑)→CIN-13 · E [1→]→CIN-05 | Calma, Ancla bonita, Cano | — | Ninguno | A10; Página 2 de Corvel; trompo de Telmo |
| CIN-12 | La Acequia | 96×48 @(248,-84) | O→CIN-09 · E→CIN-13 · S (↓)→CIN-10 · N→CIN-25 | Plataformas sobre agua seca | Doble | 2 arrojadores; esqueleto con azada | Azada de madera; nota "la tierra no me dice" |
| CIN-13 | La Segunda Torre de Riego | 40×60 @(344,-96) | S→CIN-11 · O→CIN-12 · E→CIN-14 · N→CIN-15 | Puzle de Doble: torre 1 | Doble | Ninguno | Placa de la Orden; Hermano Gaspar (aparece aquí o en CIN-14) |
| CIN-14 | El Camino de Ronda | 72×40 @(384,-96) | O→CIN-13 · E→CIN-17 · N→SEC-02 y CIN-15 | Combate de puesto de guardia | — | Lanceros y coloso; densidad media | A11; placa "declarar lo que recuerda"; Lacre de silencio (Gaspar) |
| CIN-15 | Los Bancales Altos | 72×60 @(344,-156) | S→CIN-13 y CIN-14 · O→CIN-25 · E→SEC-02 · N→CIN-27 | Puzle de Doble: torre 2 en cadena | Doble | Viento (empuje); sin enemigos | Vista del Palomar |
| CIN-16 | El Molino sin Aspas | 56×60 @(456,-156) | O→SEC-02 · S→CIN-17 · N→CIN-29 | Plataformas con aspas giratorias | Doble | Aspas (daño por contacto) | Reliquia Pesa o FF si se corta la rueda a tiempo (decisión de puzle) |
| CIN-17 | El Cercado Vacío | 56×40 @(456,-96) | O→CIN-14 · E→CIN-18 · N→CIN-16 · S→CIN-23 | Calma antes del jefe, Ancla | — | Ninguno | A12; puerta del cercado abierta |
| CIN-18 | La Era | 80×64 @(512,-120) | O→CIN-17 · E→CIN-19 · S→CIN-22 · N→ARC-01 | **Jefe 2: Jacinto** | — (N: Agarre) | Arena circular; el jefe | Agarre; Nombres Jacinto Ferrán y Eloy Ferrán |
| CIN-19 | La Cuesta del Segador | 64×64 @(592,-120) | O→CIN-18 · S→CIN-20 · E→COS-01 | Respiro, bifurcación visible de 3 caminos | Agarre (salir) | Ninguno | A13; los cuatro pozos lisos a la vista |
| CIN-20 | El Brocal | 64×40 @(592,-56) | N→CIN-19 · S→CIN-21 · O→CIN-22 | Transición: el pozo | — | Ninguno | Cuerda cortada; "Hay que cavar más abajo" |
| CIN-21 | El Descenso del Brocal | 64×96 @(592,-16) | N→CIN-20 · S→MIN-01 | Caída larga que decide | Agarre (volver) | Hierba de pinchos en dos repisas | Aviso: el Ancla de abajo es lo primero que se ve |
| CIN-22 | El Almiar | 68×40 @(524,-56) | N→CIN-18 · O [1→]→CIN-23 · E→CIN-20 | Combate de sala cerrada | — | 3 cascarones + 1 lancero; densidad alta | Hoz clavada (lore) |
| CIN-23 | La Rampa de Servicio | 68×35 @(456,-56) | N→CIN-17 · E←CIN-22 · S (↓)→CIN-06 | Atajo / segunda entrada a la Pasarela | — | Ninguno | Marcas del "pie alado" de los Mensajeros |
| CIN-24 | El Granero Sin Techo | 112×64 @(88,-136) | E→SEC-03 · S (↓ [1→])→UMB-04 | Plataformas de vigas, atajo al Umbral | Doble | Arrojadores sobre vigas | Retal de estandarte |
| CIN-25 | El Pozo de Piedra Seca | 72×72 @(272,-156) | E→CIN-15 · O→SEC-03 · S→CIN-12 · N→CIN-26 | Pozo con paredes: primer uso intensivo del Agarre | Agarre | Sin enemigos; pinchos al fondo | FF o FV al fondo |
| CIN-26 | El Lavadero Seco | 72×72 @(272,-228) | S→CIN-25 · E→CIN-27 | Calma, Ancla opcional, vista al Archivo | Agarre | Ninguno | Texto sobre la ropa que ya nadie tiende |
| CIN-27 | La Balsa Seca | 72×60 @(344,-216) | S→CIN-15 · O→CIN-26 · E→CIN-28 · N→CIN-30 | Calma, lore | Doble | Ninguno | Concha-con-hilo de un niño |
| CIN-28 | La Ermita del Cruce | 40×60 @(416,-216) | O→CIN-27 · E→CIN-29 | Capilla, Gaspar (si no está en CIN-13) | Doble | Ninguno | Lacre de silencio |
| CIN-29 | El Camino de los Mojones | 88×60 @(456,-216) | O→CIN-28 · E→ARC-01 (alto) · S→CIN-16 | Combate lineal con mojones de los Mensajeros | Doble | Lanceros; arrojador; densidad media | Mojón "se cortaba cada invierno" |
| CIN-30 | La Linde Gris | 72×60 @(344,-276) | S→CIN-27 | Plataformas que se borran; secreta | Doble | Parche gris: el suelo desaparece 2 s después de pisarlo | FV; rastro del límite limpio, "como cortado con tijera" |

(c.) = construida. El Peón (SEC-03), el Palomar (SEC-02), el Silo (SEC-01) y los Establos (SEC-06) están en §4.7 pero se ven en el mapa del Cinturón.

### 4.3 El Archivo (26) · tono: ordenado e intacto junto a lo en blanco; el amor al registro convertido en pánico

Estructura: **entrada** (Pozos → Puerta → Vestíbulo → Nave) → **hub** (Estantería Nueve) → **tres alas**: Blanco (sur, lleva a Ilara), Intacta (norte, lleva al Claustro y a Relatores) y Negadores (este, optativa con el atajo del Pasaje). La llave de la fila final es la Tinta de Ilara; desde Relatores el camino es lineal hasta Hesper.

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| ARC-01 | Los Pozos Blancos | 48×130 @(544,-250) | S←CIN-18 · O (medio)←CIN-29 · E (alto)→ARC-02 | Puzle de Agarre: se agarra por contraste | Agarre | Copistas ausentes; solo pinchos de tinta | Aviso: los agarres negros sobre blanco |
| ARC-02 | La Puerta del Archivo | 64×50 | O→ARC-01 · E→ARC-03 | Entrada en calma, Ancla "tinta" | — | Ninguno | A14; placa "no se admite a quien traiga algo que olvidar" |
| ARC-03 | El Vestíbulo de las Plumas | 64×50 | O→ARC-02 · E→ARC-04 | Primer encuentro: copista (n) | — | 2 copistas (n); media | Botón de uniforme |
| ARC-04 | La Nave Raspada | 128×50 | O→ARC-03 · E→ARC-05 | Nave larga donde las paredes pierden relieve | — | Escriba ciego (n) lento, 2 lanceros | Escriba "dejé de leer…"; Pluma de escriba |
| ARC-05 | Estantería Nueve | 96×100 | O→ARC-04 · S→ARC-06 · N→ARC-09 · E→ARC-13 | **Hub** del Archivo; Sabela | — | Ninguno | A15; Página 3 de Corvel; Folio en blanco; placa "dado por perdido" |
| ARC-06 | El Pasillo Tres | 80×70 | N→ARC-05 · E→ARC-07 | Pasillo en blanco, tensión | — | Acechadores que salen de la pared; baja | Cartel "no se cierra: a veces vuelve" |
| ARC-07 | La Sala de los Lacres | 80×70 | O→ARC-06 · E→ARC-08 | Puzle ligero: balanza y lacres; Ancla pre-jefe | — | 1 coloso; media | A16; Lacre roto; cartel "lo que no consta no existe" |
| ARC-08 | El Scriptorium Callado | 84×70 | O→ARC-07 · N [1→]→ARC-15 | **Jefe 3: Sor Ilara** | — | Pupitres que se borran; el jefe | Llave de Tinta; Nombre: Ilara |
| ARC-09 | La Biblioteca Intacta | 112×80 | S→ARC-05 · N→ARC-10 · E→ARC-11 · O→ARC-24 | Plataformas: estanterías-torre | — | 2 custodios de lacre (n); media | Nombre: Aurelio (escriba zurdo) |
| ARC-10 | Los Altos del Catálogo | 96×50 | S→ARC-09 · O→ARC-24 · E→ARC-26 | Plataformas con estantes que se desplazan | — | Arrojador | Vista del sello gigante a través del suelo de cristal |
| ARC-11 | El Aula Pequeña | 64×40 | O→ARC-09 · E→ARC-12 y ARC-25 | Calma; el cuaderno hasta la C | — | Ninguno | Nombre: Lucía; Cuaderno de letras |
| ARC-12 | El Retrato Ausente | 56×40 | O→ARC-11 (pared que se rompe) | Secreta, lore de la Fundadora | — | Ninguno | Nombre: Ardena; FV; marco vacío |
| ARC-13 | El Ala de los Negadores | 96×100 | O→ARC-05 · E→ARC-14 · S→ARC-16 | Combate: el ala "al completo" | — | 3 custodios de lacre + 1 coloso; alta | Cartel "cualquier vacío es un error"; Pesa del Archivo |
| ARC-14 | El Pasaje de las Llaves | 112×40 | O→ARC-13 · E [1→]←ARC-21 | Atajo B7; puertas cerradas desde dentro | — | Ninguno | Nota "cerré yo"; llavero |
| ARC-15 | La Escalera Taponada | 40×110 | S [1→]←ARC-08 · N→ARC-26 | Subida de libros tras Ilara | Tinta | Ninguno | Cartel "no leer en voz alta bajo este arco" |
| ARC-16 | La Cripta de los Registros Quemados | 96×56 | N→ARC-13 · (grieta)→SEC-05 | Peligro: tinta sin forma; ramal | — | Escriba ciego, acechador | Aguja del Escriba |
| ARC-17 | La Sala de los Relatores | 96×60 | O←ARC-26 · E→ARC-18 | **Escena**: quita el control 2 s | Tinta | Ninguno | Fichas "A. Varga"; molde; Molde de máscara |
| ARC-18 | La Sala de Extracción | 56×40 | O→ARC-17 · E→ARC-19 | Calma pesada, silla de extracción | — | Ninguno | Placa "el sellado es voluntario" |
| ARC-19 | El Archivo en Blanco | 144×70 | O→ARC-18 · E→ARC-20 | Tensión máxima: sin mapa, sin relieve | — | Acechadores y copistas; densidad alta | Sin texto; el mapa no revela |
| ARC-20 | El Corredor de Lacre | 128×40 | O→ARC-19 · E→ARC-21 | Gauntlet de lacres que se cierran | — | Lacres móviles; 2 custodios | Ninguno |
| ARC-21 | La Antesala del Prior | 56×36 | O→ARC-20 · E→ARC-22 · S [1→]→ARC-14 | Ancla pre-jefe | — | Ninguno | A18; texto "Nadie más se perderá" en la puerta |
| ARC-22 | El Salón de Sellado | 80×70 | O→ARC-21 · E→ARC-23 | **Jefe 4: Hesper** | — | Zonas de lacre; el jefe | Sello de Cera; juramento |
| ARC-23 | El Puente de Cera | 80×180 @(960,-310) | O←ARC-22 · S→COS-04 | Respiro y gran descenso hacia el Pilar | Cera (para abrir la puerta al final) | Ninguno | Primer vistazo real de la Puerta Sin Muro |
| ARC-24 | La Galería de los Atriles | 112×50 | E→ARC-09 · N→ARC-10 · (escalera)→SEC-08 | Plataformas: atriles que giran, bucle B6 | — | 2 arrojadores | FF al final |
| ARC-25 | El Refectorio de los Escribas | 72×40 | O→ARC-11 | Calma, PNJ (Gaspar), Ancla bonita | — | Ninguno | Nota "tres escribas, un cuenco" |
| ARC-26 | El Claustro de la Tinta | 96×60 | O←ARC-10 · S←ARC-15 · E→ARC-17 | Calma antes del golpe; vista del Salón | — | Ninguno | A17; fuente de tinta; la puerta de pluma |

### 4.4 Las Minas del Origen (28) · tono: exceso (calor, lámparas, fe en lo de abajo), no vacío

Estructura: la **U de descenso** (el jugador va hacia el oeste por arriba, baja por la Cuerda y vuelve hacia el este, hacia Magda) con **dos ramales opcionales** (Casimar; lámparas e inundada) y la **red de Excavar** que solo se abre tras vencer a Magda. Las salas de la red son largas, de pocos encuentros: son rutas de viaje, no de combate.

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| MIN-01 | El Andén de los Picos | 96×50 | N←CIN-21 · O→MIN-02 | Entrada en calma, Ancla | — | Ninguno | A19; Nombre: Berenguer; Pico con nombre |
| MIN-02 | La Vagoneta Quieta | 112×50 | E→MIN-01 · O→MIN-03 · S→MIN-25 | Plataformas: vagonetas que se mueven al tocarlas | — | Saturados (n) ×2 | Nota "seguimos cargando" |
| MIN-03 | El Nicho de las Ofrendas | 64×50 | E→MIN-02 · O→MIN-04 | Calma, lore | — | Ninguno | Mechón atado; FV |
| MIN-04 | El Pasillo de las Rayas | 104×50 | E→MIN-03 · O→MIN-05 | Combate lineal con ventana a la Galería Larga | — | Cavadores (n) ×2, saturado | Pared de rayas |
| MIN-05 | La Fila de Espera | 96×50 | E→MIN-04 · S→MIN-06 | Calma, PNJ (Brunel), Ancla bonita | — | Ninguno | A20; Nombre: Rosendo (Brunel); Ficha de turno |
| MIN-06 | La Cuerda de Mil Nudos | 40×110 | N→MIN-05 · S→MIN-07 | Pozo vertical de Agarre, papel en cada nudo | Agarre | Larvas de techo (n) | Nombre: Dimas; Papel de nudo |
| MIN-07 | La Galería de los Apeos | 104×60 | O→MIN-06 · E→MIN-08 | Combate con vigas que se rompen | — | 2 lanceros, 1 saturado | Vigas "apuntalad lo que cavasteis" |
| MIN-08 | La Cámara de las Voces | 88×60 | O→MIN-07 · E→MIN-09 · N→MIN-22 | Calma inquietante, ventana al Trono | — | Ninguno | A21; Página 4 de Corvel; Vela fundida |
| MIN-09 | La Sala de Estratos | 100×60 | O→MIN-08 · E→MIN-10 · S→MIN-23 | Plataformas: capas de recuerdos que cambian | Doble | Ninguno | Texto "no intentes entender" |
| MIN-10 | El Cuarto del Capataz | 60×50 | O→MIN-09 · E→MIN-11 | Lore: diario de una sola página | — | Ninguno | Diario; escalón corto |
| MIN-11 | El Taller de Dola | 64×50 | O→MIN-10 · E→MIN-12 | Calma, PNJ (Dola), Ancla | — | Ninguno | A22; FF por el favor del pico |
| MIN-12 | Las Vetas Vivas | 100×60 | O→MIN-11 · E→MIN-13 · S→MIN-26 | Combate: criaturas saturadas | — | Saturados ×3, cavador; alta | Diente de la Mina |
| MIN-13 | El Descenso de los Zapadores | 56×90 | O→MIN-12 · E→MIN-14 | Vertical con plataformas de madera | — | Larvas de techo | Cuerda con pinchos |
| MIN-14 | La Antesala de Apuntalamiento | 56×40 | O→MIN-13 · E→MIN-15 | Ancla pre-jefe | — | Ninguno | A23; viga maestra |
| MIN-15 | La Cámara de Apuntalamiento | 72×60 | O→MIN-14 · E→MIN-16 | **Jefe 6: Magda** | — | Suelo destructible; la jefa | Excavar; Sello de Piedra; Nombre: Magda Soler |
| MIN-16 | El Hueco del Pico | 64×40 | O→MIN-15 · E→MIN-24 · S→MIN-28 | Respiro: primer suelo roto | Excavar | Ninguno | Ficha de Dola; texto "todo pico vuelve a su dueño" |
| MIN-17 | La Veta Tapiada | 64×200 @(96,87) | N→SEC-01 · S→MIN-27 | Atajo: sube a la Cisterna | Excavar | Ninguno | Placa "para que no suba lo que no debe"; hierro para Garrán |
| MIN-18 | El Pozo de los Cantores | 64×250 | N→UMB-08 · S→MIN-27 | Atajo: sube al Umbral | Excavar | Ninguno | Eco de canto |
| MIN-19 | La Galería de la Marea | 260×40 | O←MIN-24 y MIN-28 · E→MIN-20 | Viaje largo hacia la Costa | Excavar | Saturados ×2 | Grieta de agua salada |
| MIN-20 | El Cauce Hundido | 300×36 | O←MIN-19 · E→COS-17 | **La barca**: un viaje fijo con Mirena, o a nado | Excavar (llegar) | Corriente; sin enemigos | Brújula de Mirena (tras tres viajes) |
| MIN-21 | El Trono Hundido | 72×50 | O←MIN-22 | **Jefe 5: Casimar (opcional)** | — | Cortesanos que aplauden; el jefe | Corona sin Reina; Nombre: Áurea |
| MIN-22 | La Antecámara de los Cortesanos | 96×50 | S←MIN-08 · E→MIN-21 | Combate en ramal opcional | — | Cortesanos (n) ×3; alta | Pergamino "que no se olvide a la reina" |
| MIN-23 | La Cripta de las Lámparas | 80×56 | N←MIN-09 | Puzle de luz (dirigir la llama) | — | Murciélagos de tiza (n) sin daño directo | FF |
| MIN-24 | El Pozo del Latido | 80×240 @(740,30) | O←MIN-16 · E→HER-01 · S→MIN-19 | Subida a la Puerta Sin Muro; se oye el Latido | Excavar | Ninguno; sonido creciente | Nombre: ninguno; texto de una Cavadora |
| MIN-25 | La Mina Inundada | 112×60 | N←MIN-02 | Plataformas sobre agua; opcional | — | Saturados bajo el agua | Reliquia Cuenta |
| MIN-26 | La Colonia de los Hondos | 96×50 | N←MIN-12 · (grieta)→SEC-07 | Calma, neutral, Ancla | — | Ninguno (Hondos no hostiles) | A24; símbolo del pico y la vela |
| MIN-27 | La Galería Larga, oeste | 420×40 | E→MIN-28 · N→MIN-17 y MIN-18 | El Metro: red de Excavar; vagoneta de raíl opcional | Excavar | Saturados ×2 | Rayas de cuenta y textos de apuro |
| MIN-28 | La Galería Larga, este | 416×40 | O→MIN-27 · N←MIN-16 · E→MIN-19 | Conecta la red con el túnel a la Costa | Excavar | Saturados ×2 | — |

### 4.5 La Costa Retenida (20) · tono: nítido, el más vivo del mapa; el alivio es real

Estructura: **Cornisa** (cuatro salas de camino largo con Agarre, de ceniza a sal), **Acantilado de Cortinas**, el **pueblo** del Muro Blanco con sus callejuelas, el **Faro** (opcional), el **Rellano de Cal** (jefe) y el **puerto/gruta** que llevan al Cauce.

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| COS-01 | El Paso del Pastor | 100×70 @(656,-120) | O←CIN-19 · E→COS-02 | Entrada: viento, acantilado | Agarre | Gaviotas de sal (n) ×2 | Mojón "se cortaba cada invierno" |
| COS-02 | Los Escalones del Tajo | 100×70 @(756,-120) | O→COS-01 · E→COS-03 | Ascenso con Agarre por la pared | Agarre | Gaviotas; densidad baja | Cartas clavadas sin sobre |
| COS-03 | La Cornisa de Sal | 104×70 @(856,-120) | O→COS-02 · E→COS-04 | Plataformas al viento; vista del Faro y de la Puerta | Agarre | Viento; 1 arrojador | Primera vista de la Puerta Sin Muro |
| COS-04 | El Pilar de Lacre | 80×160 @(960,-130) | O←COS-03 · E→COS-05 · N←ARC-23 · S→HER-01 | **Nudo central**; Ancla | Agarre (subir); Cera, Piedra, Cal (puerta) | Pinchos de cal en el suelo; densidad baja | A25; los tres huecos de los Sellos |
| COS-05 | El Acantilado de Cortinas | 100×70 @(1040,-120) | O←COS-04 · E→COS-06 | Plataformas: sábanas colgadas; una voz canta (Ielda) | — | Gaviotas; sin enemigos de suelo | Verso "hoy salió tu nombre" |
| COS-06 | El Sendero de los Pañuelos | 96×60 | O←COS-05 · E→COS-07 | Entrada del pueblo; Descreídos no hostiles | — | Devotos (n) ×2 si se les empuja | Cartel "pase y no recoja" |
| COS-07 | El Muro Blanco | 120×60 | O←COS-06 · E→COS-08 · N→COS-09 · S→COS-14 · (cama)→SEC-04 | Pueblo, Quiteria, Vael, el sueño; Ancla | — | Ninguno | A26; Piedra blanca; cama hecha → SEC-04 |
| COS-08 | El Altar de Sal | 80×50 | O←COS-07 · E→COS-10 | Calma, ofrendas retiradas | — | Ninguno | Página 5 de Corvel; FF a cambio de una ofrenda |
| COS-09 | La Casa Atada | 56×40 | S←COS-07 | PNJ Casilda, interior | — | Ninguno | Nombre: Elvira; Peine de hueso |
| COS-10 | El Banco Doble | 64×50 | O←COS-08 · E→COS-20 · S→COS-11 · N→COS-18 | Calma, Ancla pre-jefe | — | Ninguno | A27; dos copas vacías |
| COS-11 | Los Tendederos | 110×60 | N←COS-10 · E→COS-12 | Plataformas: cuerdas de colada | Doble | Gaviotas | FV |
| COS-12 | La Playa de Nombres | 120×50 | O←COS-11 · E→COS-13 | Respiro: letras de piedra en la arena | — | Ninguno | Nombres Marta y Julián; Zapato pequeño; Concha con hilo |
| COS-13 | La Salina | 130×50 | O←COS-12 · E→COS-16 | Combate abierto, charcos de sal | — | Cangrejos de cal (n) ×4; Devotos; media | Campanilla de la Costa |
| COS-14 | La Casa de las Redes | 80×40 | N←COS-07 · E→COS-15 | Lore, Vael o Mirena | — | Ninguno | Nudo imposible; FF |
| COS-15 | La Barca Varada | 100×50 | O←COS-14 · E→COS-16 | Calma; Mirena | — | Ninguno | Red tejida a medias; Nudo del mástil |
| COS-16 | La Cala de Mirena | 96×50 | O←COS-13 y COS-15 · S→COS-17 | Embarcadero, Ancla | — | Ninguno | A29 |
| COS-17 | La Gruta de la Marea | 80×150 | N←COS-16 · E (agua)↔MIN-20 | Gruta; salida al Cauce | — | Sin enemigos | Cuerda para atar la barca |
| COS-18 | La Escalera de las Velas | 40×120 | S←COS-10 · N→COS-19 | Ascenso con una vela en cada peldaño | Doble | Gaviotas; plataformas de cal | A28 |
| COS-19 | El Faro de las Velas | 72×60 | S←COS-18 | **Jefe 7: Rufo (opcional)** | — | Espejos móviles; el jefe | Vela del Faro; Nombre: Rufo |
| COS-20 | El Rellano de Cal | 100×60 | O←COS-10 | **Jefe 8: Eudora** | — | Círculos de cal; la jefa | Sello de Cal; Nombre: Mateo |

### 4.6 La Herida (16) · tono: lo reconocible se disuelve

Estructura: **Páramo** (aproximación) → **Puerta** → **Descenso** en caracol → **salas reconstruidas** (cinco versiones desordenadas de salas anteriores) → **Eco y Mesa** → **Antesala** → **Asiento** → **Sala de Aún**. La Herida no tiene enemigos comunes de la Orden: solo los Rastros disueltos (n).

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| HER-01 | El Páramo Gris | 200×50 @(820,30) | N←COS-04 · O←MIN-24 · S→HER-02 | Aproximación en calma, Cano, Ancla | — | Ninguno | A30; el carro de Cano lleno |
| HER-02 | La Puerta Sin Muro | 96×48 | N←HER-01 · S→HER-03 | La cerradura de los tres Sellos | Cera + Piedra + Cal | Ninguno | Dintel; los tres huecos |
| HER-03 | La Escalera de Hojas | 48×120 | N←HER-02 · S→HER-04 | Descenso en peldaños-libro | — | Rastros (n) ×2 | Página 6 de Corvel (tachada) |
| HER-04 | El Círculo Colgado | 96×72 | N←HER-03 · S→HER-05 | Sillas con máscara azul, 5 Nombres | — | Ninguno | A31; Nombres Íñigo, Leocadia, Tadeo, Brígida, Álvar |
| HER-05 | La Pared Raspada | 112×40 | N←HER-04 · E→HER-06 · S→HER-07 | Cientos de nombres con raya | — | Rastros ×3 | Cartel "nadie los pierde de verdad" |
| HER-06 | El Hueco del Cuerpo | 64×36 | O←HER-05 | Alcoba del tamaño del jugador, ramal | — | Ninguno | FV; "Aquí cabías" |
| HER-07 | La Cisterna Doblada | 96×31 | N←HER-05 · E→HER-08 | Reconstrucción: suelo al revés | Excavar | Rastros ×2 | Eco de la zona de aterrizaje |
| HER-08 | La Chimenea Vuelta | 40×69 | O←HER-07 · N→HER-09 | Puzle con Dash + Doble + Agarre | Dash, Doble, Agarre | Pinchos | Huella con prisa |
| HER-09 | Las Terrazas de Ceniza | 64×24 | S←HER-08 · E→HER-10 | Reconstrucción: foso sin fondo | Dash | Ninguno | A32; aviso "no es un error" borrado |
| HER-10 | El Scriptorium Sin Tinta | 84×70 | O←HER-09 · E→HER-11 | Reconstrucción: pupitres de ceniza | — | Copistas (n) ×2 | Hoja arrancada |
| HER-11 | Las Galerías Dobladas | 84×34 | O←HER-10 · E→HER-12 | Reconstrucción: pinchos en lugar de enemigos | — | Pinchos que alternan | Cuaderno del último Custodio |
| HER-12 | El Eco Quieto | 64×50 | O←HER-11 · E→HER-13 | Figura que abre una puerta que no existe | Nombrar | Ninguno | Eco de una puerta |
| HER-13 | La Mesa de Dos | 56×40 | O←HER-12 · E→HER-14 | Calma, taza volcada | — | Ninguno | Taza volcada; nota "volveremos mañana" |
| HER-14 | La Antesala del Asiento | 56×36 | O←HER-13 · E→HER-15 | Ancla sin nombre, pre-jefe | — | Ninguno | A33; "se descansa sin nombre" |
| HER-15 | La Sala del Asiento | 80×60 | O←HER-14 · E→HER-16 | **Jefe 9: Maelis** | — | El lacre; la jefa | Máscaras; Hueco del Cuerpo (referencia) |
| HER-16 | La Sala de Aún | 90×80 | O←HER-15 | Las tres salidas: Asiento, Margen, Escalera | Nombrar + 20 Nombres (Compartir) | Ninguno | Cuerpo de Ansel; Escalera de los Nombres |

### 4.7 Secretas y atajos (8) · recompensa por mirar y volver

| ID | Sala | Tamaño | Conexiones | Función | Requiere | Enemigos / peligros | Coleccionables y textos |
|---|---|---|---|---|---|---|---|
| SEC-01 | El Silo Sin Grano | 64×32 @(96,55) | N (reja)→CIN-02 · S→MIN-17 | Atajo Minas ↔ Cisterna | Excavar | Ninguno | Reliquia Diente (o FV); "sin grano" |
| SEC-02 | El Palomar | 40×60 @(416,-156) | O←CIN-15 · E→CIN-16 · S←CIN-14 | Secreta alta | Doble + Agarre | Ninguno | FV |
| SEC-03 | La Casa del Peón | 72×72 @(200,-156) | S←CIN-09 · E→CIN-25 · O→CIN-24 | Nodo del atajo al Umbral | Doble | Ninguno | Carta; FV |
| SEC-04 | El Cuarto de la Cama Hecha | 48×36 | Dentro de COS-07 | Secreta, "Duerme" | — | Ninguno | Cama; FV |
| SEC-05 | El Depósito de lo Rechazado | 64×50 | Dentro de ARC-16 (grieta) | Secreta del Archivo | — | Escriba ciego | Libro sin autor; FV |
| SEC-06 | Los Establos de los Mensajeros | 100×26 @(424,24) | O←CIN-05 | Dash opcional; casilleros de cartas | Dash | Ninguno | FF; cartas sin entregar |
| SEC-07 | La Grieta de Rosendo | 56×40 | Dentro de MIN-26 | Secreta, Brunel | Excavar | Ninguno | Lista de picos; FV |
| SEC-08 | El Torreón de las Campanas Mudas | 40×100 | Dentro de ARC-24 | Vista del Pilar y la Herida | Doble + Agarre | Ninguno | Reliquia Pluma sin tinta |

---

## 5. Plan de Anclas y de atajos

### 5.1 Las 34 Anclas

8 existentes (A01, A02, A04-A09) y 26 nuevas. Regla: una Ancla cada 6-8 salas del camino principal como máximo, y **siempre a ≤ 1 sala de un jefe** (nunca dentro de su arena). "Bonita" = lleva un PNJ y una línea propia en el Hito.

| Ancla | Sala | Tipo | Salas desde la anterior (camino principal) |
|---|---|---|---|
| A01-A02 | UMB-01 (Hito y plataforma alta) | Inicio | — |
| A03 | UMB-03 Patio | Hub, bonita (Iria, Aldara, Cano) | 2 |
| A04 | CIN-02 Cisterna | Tras la caída | 2 |
| A05 | CIN-03 Galerías | Pre-jefe 1 | 1 |
| A06-A07 | CIN-05 Chimenea | Puzle, dos Anclas | 2 (tras el jefe) |
| A08 | CIN-06 Mirador | Calma; jefe 10 secreto | 1 |
| A09 | CIN-07 Torre (cornisa) | Premio de Doble | 3 desde A04 (Terrazas, Torre) |
| A10 | CIN-11 Cruce del Pan | Bonita (Cano) | 3 |
| A11 | CIN-14 Camino de Ronda | Bonita (Gaspar) | 2 |
| A12 | CIN-17 Cercado Vacío | Pre-jefe 2 | 1 |
| A13 | CIN-19 Cuesta del Segador | Respiro, bifurcación | 2 desde A12 |
| A14 | ARC-02 Puerta del Archivo | Entrada | 2 |
| A15 | ARC-05 Estantería Nueve | Hub, bonita (Sabela) | 3 |
| A16 | ARC-07 Lacres | Pre-jefe 3 | 2 |
| A17 | ARC-26 Claustro | Calma antes de Relatores | 3 (Ilara, Escalera, Claustro) |
| A18 | ARC-21 Antesala del Prior | Pre-jefe 4, atajo B7 | 5 desde A17 |
| A19 | MIN-01 Andén | Entrada | 3 desde A13 (Brocal, Descenso, Andén) |
| A20 | MIN-05 Fila de Espera | Bonita (Brunel) | 4 |
| A21 | MIN-08 Cámara de las Voces | Calma inquietante | 3 |
| A22 | MIN-11 Taller de Dola | Bonita (Dola) | 3 |
| A23 | MIN-14 Antesala de Apuntalamiento | Pre-jefe 6 | 3 |
| A24 | MIN-26 Colonia de los Hondos | Ramal; refugio | opcional |
| A25 | COS-04 Pilar de Lacre | Nudo de 3 regiones | 4 desde A13 |
| A26 | COS-07 Muro Blanco | Bonita (Quiteria) | 3 |
| A27 | COS-10 Banco Doble | Pre-jefe 8 | 2 |
| A28 | COS-18 Escalera de las Velas | Pre-jefe 7 (opcional) | opcional |
| A29 | COS-16 Cala de Mirena | Embarcadero, bonita (Mirena) | opcional |
| A30 | HER-01 Páramo Gris | Ante la puerta (Cano) | 1 desde A25 |
| A31 | HER-04 Círculo Colgado | Sin nombre | 3 |
| A32 | HER-09 Terrazas de Ceniza | Sin nombre | 4 |
| A33 | HER-14 Antesala del Asiento | Pre-jefe 9, última | 5 |
| A34 | UMB-08 Sótano de los Cantores | Atajo de vuelta | extremo del Metro |

Mayor distancia entre Anclas consecutivas del camino principal: **5 salas** (A17 → A18 y A32 → A33); media, 3. Con 34 Anclas hay holgura: si jugando sobran, se recortan A13, A24 y A29 sin romper la regla.

### 5.2 Distancia Ancla → jefe

| Jefe | Ancla previa | Salas hasta él | Qué se recorre si se muere |
|---|---|---|---|
| 1 Centinela | A05 (CIN-03) | 1 | Ancla en la propia sala previa, tras la puerta |
| 2 Jacinto | A12 (CIN-17) | 1 | Una pantalla |
| 3 Ilara | A16 (ARC-07) | 1 | Una pantalla |
| 4 Hesper | A18 (ARC-21) | 1 | Una pantalla |
| 5 Casimar (opc.) | A21 (MIN-08) | 2 | Dos pantallas |
| 6 Magda | A23 (MIN-14) | 1 | Una pantalla |
| 7 Rufo (opc.) | A28 (COS-18) | 1 | Una escalera |
| 8 Eudora | A27 (COS-10) | 1 | Una pantalla |
| 9 Maelis | A33 (HER-14) | 1 | Una pantalla |
| 10 Oda (sec.) | A08 (Mirador) | 0 | Se invoca desde el Ancla |

### 5.3 Atajos y su justificación

| # | Atajo | Se abre | Lo que evita |
|---|---|---|---|
| S1 | Escalera de tablones Cisterna → Terrazas (construido) | Siempre | Quedar atrapado en el aterrizaje |
| S2 | Casa del Peón → Granero → Fragua [1→] | Doble; cae al Umbral | Volver a pie desde el Cinturón alto |
| S3 | Cruce del Pan ↔ Chimenea alta [1→ desde la Chimenea] | Tras la Chimenea | Repetir el puzle de Dash |
| S4 | Rampa de Servicio ↔ Pasarela | Cuerda bajada desde abajo | Rodear por la Chimenea hasta el Mirador |
| S5 | Almiar → Rampa → Cercado [1→] | Tras Jacinto | Atravesar la arena hacia el Ancla previa |
| S6 | Pasaje de las Llaves [1→] Antesala → hub | Desde la Antesala | Cruzar otra vez el Archivo en Blanco |
| S7 | Escalera Taponada [1→] Scriptorium → Claustro | Tras Ilara | Deshacer el ala en blanco |
| S8 | Mojones ↔ Pozos Blancos | Palanca desde el Archivo | Subir los pozos cada vez |
| S9 | Veta Tapiada: Silo ↔ Cisterna | Excavar | Volver de las Minas al Cinturón |
| S10 | Pozo de los Cantores ↔ Sótano (A34) | Excavar | Volver al Umbral del acto IV |
| S11 | El Metro (Galería Larga) | Excavar | Recorrer la U de las Minas |
| S12 | Pozo del Latido: Hueco del Pico → Páramo | Excavar | Rodear por el Pilar |
| S13 | Cauce (barca): Costa ↔ Minas | Mirena; a nado si falta | 1.200 baldosas |
| S14 | Puente de Cera con palanca: Pilar → Antesala | Desde el Pilar tras Hesper | Recorrer los 9 de Relatores en sentido contrario |

Reglas: todo atajo se **ve antes de abrirse** (puerta con el lado que importa a la vista); ninguno saltea un jefe o una llave; los de sentido único avisan con una puerta de hierro con el pestillo del lado correcto; ninguno deja al jugador sin retorno (§7).

---

## 6. Ritmo espacial

### 6.1 La onda de cada región (calma → ascenso → cima → jefe → respiro → giro)

| Región | Entrada (calma) | Ascenso | Cima | Jefe | Respiro | Giro |
|---|---|---|---|---|---|---|
| Umbral | Primera pantalla | Foso, 2 cascarones | Escalera al 2.º Ancla | — | Pueblo alto | Muro del oeste |
| Cinturón bajo | Terrazas | Cisterna → Galerías | Galerías (alta densidad) | Centinela | Chimenea (sin enemigos) | Mirador |
| Cinturón alto | Surco Ciego | Campo, Acequia | Torres + Bancales | Jacinto | Cuesta | Los 3 caminos |
| Archivo | Puerta | Vestíbulo, Nave | Ilara; luego Blanco y Corredor | Ilara y Hesper | Claustro, Puente | Relatores |
| Minas | Andén | Rayas, Fila | Apeos, Vetas Vivas | Magda | Hueco del Pico | Excavar abre el Metro |
| Costa | Cornisa | Pañuelos | Salina | Eudora | Playa de Nombres | El sueño |
| Herida | Páramo | Escalera y Círculo | Fragmentos reconstruidos | Maelis | Sala de Aún | La elección |

### 6.2 Mezcla por región (clasificación de las tablas de §4; "otras" = atajo, secreta, transición, escena o vista)

| Región | Calma / PNJ | Plataformas / puzle | Combate | Jefe | Otras |
|---|---|---|---|---|---|
| Umbral | 5 | 0 | 0 | 0 | 3 |
| Cinturón | 9 | 11 | 6 | 2 | 2 |
| Archivo | 8 | 5 | 7 | 2 | 4 |
| Minas | 8 | 6 | 4 | 2 | 8 |
| Costa | 8 | 6 | 2 | 2 | 2 |
| Herida | 6 | 3 | 3 | 1 | 3 |
| Secretas | 0 | 0 | 0 | 0 | 8 |
| **Total** | **44** | **31** | **22** | **9** | **30** |

Lectura: el Cinturón es el más plataformero (lo que enseña); el Archivo es el más tenso; la Costa tiene muy poco combate a propósito (el peligro es político y el alivio es real); la Herida es casi toda "otras" porque cada sala reconstruida cambia una regla. Hay combate también dentro de las salas de plataformas. Si jugando sobra en las Minas, se reduce en la red de Excavar, no en la U.

### 6.3 Reglas de ritmo espacial

1. **No más de 3 salas de tensión seguidas** sin una calma: las Galerías, el Corredor de Lacre y las Vetas Vivas son las más largas (3 + jefe).
2. **Ninguna sala de calma sin un detalle de mundo** (objeto, inscripción, PNJ, vista); una calma vacía es un pasillo.
3. **Los jefes van tras una sala larga y un Ancla, y precedidos por una vista**: la arena nunca es lo primero que se ve de su región.
4. **Dos plataformas largas seguidas se separan por una sala de combate** (Acequia, Torre y Bancales son la excepción que prueba la regla: son tres puzles de Doble de dificultad creciente).
5. **El primer pantallazo de cada región enseña su verbo** (viento en la Cornisa, tinta en la Puerta, lámparas en el Andén, cal en el Muro, tela al aire en el Pilar).

---

## 7. Desorden, bloqueos y guía sin texto

### 7.1 Qué se puede saltar y cómo

| Escalón del canon | Desorden permitido | Salto de destreza tolerado |
|---|---|---|
| Dash → Doble → Agarre | Ninguno de movimiento: cada habilidad está tras la anterior | Casa Varga con dash desde el Surco (margen < 6 fotogramas: se tolera, no se anuncia) |
| Archivo / Minas / Costa | Cualquier orden (6 permutaciones) | — |
| Costa corta (Excavar) | Solo tras vencer a Magda | — |
| Sellos | Cualquier orden; la puerta pide los tres | — |
| Nombrar y acto IV | Solo tras tener los tres Sellos o tras Magda (el regreso) | Ninguno |

Los saltos de destreza se comprueban con `tools/sim_saltos.js`: un salto con margen < 6 fotogramas se clasifica **tolerado**; con margen ≥ 12, **previsto**. Ningún salto tolerado puede abrir una sala de la que no se pueda volver con las habilidades que ya se tienen (comprobación C6 de §8).

### 7.2 Cómo se evitan los bloqueos irrecuperables

| # | Riesgo | Prevención |
|---|---|---|
| 1 | Caer a una sala de la que no se sale | Toda caída sin retorno aterriza en una sala con Ancla a ≤ 2 salas, o con salida disponible con las habilidades obligatorias para estar ahí (Descenso del Brocal: el Agarre ya se tiene, porque Jacinto está antes) |
| 2 | Habilidad detrás de su propia cerradura | Cada recuerdo está en una sala cuya entrada **no** exige esa habilidad (comprobación C5) |
| 3 | Sentido único sin alternativa | Todo [1→] tiene un camino de vuelta con las habilidades de ese momento (C6) |
| 4 | Jefe obligatorio que cierra rastrillos | Las Anclas están fuera de la arena; los rastrillos se abren al ganar y **no** al morir (se reabren al reaparecer) |
| 5 | Mirena perdida | El Cauce se puede cruzar a nado (más duro, sin PNJ) |
| 6 | Excavar rompe algo que no se puede reconstruir | Los suelos y muros rotos quedan abiertos para siempre; nada se cierra a espaldas |
| 7 | Entrar en la Herida sin los Sellos | La puerta pide los tres; el Pilar es transitable de ida y vuelta |
| 8 | Entrar en la Sala de Aún sin Nombres | Se avisa en el último Ancla; solo se pierde el final Compartir, no el camino |
| 9 | Perder el guardado | El motor ya reaparece al principio si la Ancla guardada no existe |
| 10 | Un Nombre sin alcanzar | Ninguna sala se cierra; 28 de 30 se alcanzan sin opcionales |

Un único punto sin retorno en todo el juego: pisar el Asiento, el Margen o el primer escalón de la escalera final.

### 7.3 Guía sin texto

| Herramienta | Cómo se usa |
|---|---|
| **Luz cálida** | Toda Ancla y todo destino principal tienen una fuente de luz (vela, farol, brasa). La luz marca "hacia aquí"; el camino opcional va en sombra |
| **Marca de los Mensajeros** | El pie alado de hierro en mojones y vigas señala el camino largo del mundo (Terrazas → Mirador → Cornisa → Pilar): quien lo sigue no se pierde |
| **Arquitectura que mira a la Herida** | Los edificios de la Orden tienen la puerta orientada al centro del mapa |
| **Color de región** | Ocre quemado (Cinturón), azul de tinta (Archivo), brasa (Minas), blanco y azul sal (Costa), gris (Herida): el color del primer pantallazo dice dónde estás |
| **Sonido** | El Latido crece al acercarse a la Herida y a las Minas; el coro del Sótano suena en el Umbral desde el acto III; una campana lejana avisa de un Ancla |
| **PNJ** | Cano está donde falta algo; Aldara señala el Hito; Mirena apunta a la barca; Sabela, a la última Página |
| **Ver antes de poder** | Cada cerradura se enseña al menos una vez 10 minutos antes (§2.4) |
| **El minimapa** | El hueco central sin dibujar es el destino; los Anclas descubiertas se ven; las salas sin explorar con salida se señalan con una pestaña |

---

## 8. Lista de verificación automática

Propuesta: un **manifiesto** `tests/world_manifest.json` (hecho a mano, versionado) y un script `tools/verifica_mundo.js` (Node, sin dependencias, como `sim_saltos.js`) que lee los `.map`, `world.tscn` y el manifiesto. La prueba de humo (`tests/smoke_test.gd`) solo comprueba lo que depende del motor (C1, C3, C12, C13). El resto va en el script y se ejecuta antes de abrir un PR de mundo.

Forma del manifiesto (una entrada por sala y una por puerta):

```json
{ "rooms": { "CIN-11": { "map": "cruce_del_pan.map", "pos": [344,-36], "region": "CIN",
      "requires": [], "anchor": "A10", "enemies_max": 0 } },
  "doors": [ { "a": "CIN-10", "side": "E", "b": "CIN-11", "rows": [8,13], "oneway": null },
             { "a": "CIN-11", "side": "E", "b": "CIN-05", "rows": [-10,-4], "oneway": "b>a" } ] }
```

| # | Comprobación | Cómo | Dónde corre | Umbral |
|---|---|---|---|---|
| C1 | Salas sin solape | Rect de `pos` + tamaño del `.map` | humo (ya existe) | 0 solapes |
| C2 | Alineación de puertas | Para cada puerta, filas de aberturas libres de cada lado en y absoluta | script | Iguales, ≥ 4 baldosas (meta 6) y mismo nivel de suelo |
| C3 | Aberturas huérfanas | Toda abertura de borde está en el manifiesto o es cielo declarado | script + humo | 0 |
| C4 | Manifiesto ↔ mundo | Toda sala del manifiesto está en `world.tscn` y viceversa | humo | 100 % |
| C5 | Accesibilidad por habilidades | Superficies + `sim_saltos.js` con cada subconjunto de habilidades; cierre transitivo desde el Umbral | script | Cada sala se alcanza con exactamente `requires` (ni menos ni más) |
| C6 | Sin bloqueos | Para cada estado de habilidades, desde cada superficie alcanzable hay camino a un Ancla (componente fuertemente conexo) | script | Ninguna sala alcanzable sin retorno |
| C7 | Anclas | Distancia en salas entre Anclas y a cada jefe | script | ≤ 8 en camino principal; ≤ 1 al jefe |
| C8 | Enemigos | Distancia a puertas, techos sobre tablones, pinchos bajo spawn | script | ≥ 10 baldosas; techo ≥ 6 |
| C9 | Márgenes de puzle | `tests/puzzle_plans.json` + `sim_saltos.js` | script + humo | Margen ≥ 12 fotogramas |
| C10 | Coleccionables | Cada Nombre, FV, FF y reliquia alcanzable con las habilidades de su sala | script | 30 Nombres (28 sin opcionales), 12 FV, 3 FF |
| C11 | Caídas | Cada caída que mata no tiene sala debajo; cada caída a otra sala aterriza en suelo con retorno | script | 0 errores |
| C12 | Tamaños y leyenda | Caracteres válidos, anchura ≥ 54 (o vertical declarada) | humo | 0 |
| C13 | Sentido único | Cada puerta `oneway` tiene un camino de vuelta (C6) | script | 100 % |
| C14 | Conexiones a la Herida | Con 0 Sellos no se llega a HER-02; con los 3, sí | script | Exacto |
| C15 | Presupuesto | Salas por región y por función | script | ±2 respecto a §2.1 |

Cada fallo imprime región, sala, borde y fila, y sale con código ≠ 0. Para C5 y C6 el coste es de segundos por región (el simulador ya trabaja sobre un mapa); se puede ejecutar por región al añadir una sala. Nuevos tiles que exige el sistema: `D` (muro o suelo excavable) y las puertas [1→] (reja con palanca); el motor debe distinguirlos para que C5 los trate como "solo con Excavar" y "solo desde un lado".

---

## 9. Preguntas abiertas y riesgos

### Preguntas para el usuario

1. **Viaje rápido.** El canon no lo trae y `05-progresion` lo difiere al acto IV (Hito del Umbral como nodo de regreso). Con 1.400 baldosas de mundo, ¿se asume que bastan los 14 atajos o se quiere un viaje corto entre Anclas desde el acto III?
2. **El Pilar de Lacre.** ¿Se acepta que el Archivo desemboque en el cruce central y no en una sala propia? Cambia el guion solo en que el Puente de Cera sustituye a "la salida del Archivo".
3. **La Costa en dos entradas.** Costa corta (Cauce) y larga (Cornisa) son ya canon, pero la barca debe ser un viaje fijo. ¿Se prefiere un trayecto jugable (propuesto, 300 baldosas con Mirena) o una pantalla de corte?
4. **Corvel.** Su Nombre se lee en la página 1 (cabaña del Umbral) pero `guion-maestro` lo cuenta en el Archivo. Propongo contarlo donde se lee y reasignar un Nombre al Archivo.
5. **Fragmentos.** Doce FV y tres FF son propuesta de `05-progresion`; la tabla ya los coloca, pero son un sistema nuevo del motor.
6. **El Mirador.** ¿Es fondo de arte (propuesto) o una sala real a 450 baldosas?
7. **Archivo en Blanco sin mapa.** Requiere una bandera de sala "no revelar". ¿Se acepta el coste mínimo en `world.gd`?

### Riesgos

| # | Riesgo | Gravedad | Mitigación |
|---|---|---|---|
| 1 | **136 salas cargadas a la vez** en `world.tscn` (hoy se instancian todas): memoria y tiempo de carga | Alta | Cargar por región (el manifiesto ya la define); descargar las que están a > 2 salas |
| 2 | Producción: 136 salas × ~1 día cada una; los jefes y puzles son más caros | Alta | Orden de construcción por acto; plantilla de región (`guion-maestro` §7.1); recortes de §13 de ese documento |
| 3 | Aberturas de 4 baldosas en la Terrazas y la Torre (no 6) | Media | Ampliar a 6 en la próxima pasada o declarar la excepción en el manifiesto |
| 4 | Posiciones construidas con ligeras desviaciones respecto al manifiesto | Media | C1-C4 en cada PR de mundo |
| 5 | Salas muy verticales (Pozo de los Cantores 250, Veta 200, Latido 240) | Media | Verticales estrechas centradas; sin enemigos; Ancla cada 2 pantallas de caída |
| 6 | Minimapa demasiado grande para el radio actual (12 baldosas) | Media | Mapa en pausa con zoom por región; el minimapa solo se centra en la sala actual |
| 7 | El Metro puede ser aburrido (420 baldosas de pasillo) | Media | Vagoneta de raíl, ventanas a las salas que cruza, una sola pausa de combate |
| 8 | Herida al 84 % de relleno: una abertura mal alineada obliga a mover cuatro salas | Media | Dibujar su manifiesto primero |
| 9 | Los 14 atajos reducen el sentido de lugar | Baja | Solo se abren por el lado que importa; la primera vez siempre se hace a pie |
| 10 | Nombres de sala con acepciones vulgares | Baja | Revisión antes de fijar (los ~78 nuevos son de trabajo) |
| 11 | Duplicidad entre `01-mapa-macro`, los puzles de `03` y los enemigos de `04` | Baja | Este documento fija **dónde** y los otros **qué**; unificar IDs al cerrar |

Siguiente paso recomendado: aprobar el manifiesto de las 52 salas con posición exacta, construir `tools/verifica_mundo.js` con C1-C4 y la geometría de los atajos S2-S5, y empezar por el Cinturón alto (la única región que ya se puede encajar con lo construido).
