# Criaturas, enemigos y jefes: diseño visual implementable

Autor: diseñador de criaturas y jefes (sala de artistas). Documento de propuesta; nada de esto está aprobado hasta que lo decida el usuario. Ilustra el bestiario completo de `docs/reunion/disenadores/04-combate-enemigos-jefes.md` (28 comunes, 5 élites, 5 minijefes, 10 jefes) con la biblia visual de `01-direccion-de-arte.md` (paleta ampliada, desaturación, reglas de color), los límites reales del rig de `02-pipeline-y-herramientas.md` y los efectos de `03-interfaz-efectos-animacion.md`. Todo es original y respeta el canon de `personajes.md` e `historia.md`.

**Cuenta de diseños.** El bestiario tiene 48 entradas (28 + 5 + 5 + 10). Cinco comunes y el Centinela ya existen (cascarón, lancero, arrojador, acechador, coloso). Descontando esos cinco comunes, quedan **43 diseños por construir**: 23 comunes nuevos, 5 élites, 5 minijefes y 10 jefes (el Centinela solo recibe una animación nueva, `release`; cuenta como diseño de retoque). Los 5 comunes existentes aparecen aquí solo para fijar su lugar en el sistema y lo que les falta (fila `death`).

**Convenciones de este documento.**

- Lienzos en múltiplos de 8, orientación a la derecha, anclaje en los pies salvo que se diga otra cosa (voladores: centro de masa; colgantes: techo). "Cuerpo" = recuadro del dibujo dentro del lienzo, en píxeles nativos. Referencia de escala: jugador 24×48; cascarón 24×44.
- Las filas de animación se anotan `nombre n@fps` y siguen el orden estándar del documento 02: `idle, walk, windup, strike, hit, death` y después las extras. "Impacto f3" = fotograma en que pega (va al manifiesto `.anim.json`).
- Esfuerzo en puntos como en el documento 01 (1 punto ≈ una sesión corta): **S** = 1-2, **M** = 3-5, **L** = 6-10, **XL** = 11 o más. Cuentan el diseño y las animaciones de esa criatura **una vez disponible su tipo de cuerpo**; el coste del tipo de cuerpo se da aparte (sección 2).
- Letras de paleta como en el documento 01: piedra `1-4`, ámbar `a-d`, azul `e-h`, sangre `r-u`, musgo `m-p`, vacío `0`, grises `x y`, página `w`, tierra `5 6 7`, hueso `8`, sal `9`, mar `v`.

---

## 0. Resumen ejecutivo

1. **Seis tipos de cuerpo cubren los 43 diseños** (sección 2): H humanoide con estilo nuevo (la mayoría), A armadura vacía, Q cuadrúpedo y artrópodo, V volador y flotante, S segmentado y de línea, y P multiparte por piezas. Más de la mitad del bestiario es humanoide y cuesta poco; el trabajo duro se concentra en Q, V y P.
2. **El ataque se lee en la silueta antes que en el color.** Regla nueva de arte, "la regla de la simetría" (sección 1.2): un ataque **parable** se anuncia con una silueta **asimétrica** (arma o miembro echado hacia atrás, un solo brazo); un ataque **no parable** (aviso rojo) con una silueta **simétrica y ensanchada** (los dos brazos arriba, el cuerpo entero, el suelo). El jugador aprende "una mano = paro; todo el cuerpo = salto o dash" sin leer ningún icono.
3. **El aviso no se pinta en el sprite.** Amarillo y rojo son una capa de código (tinte aditivo y marca en el suelo), no píxeles de la hoja. Así los sprites quedan limpios de ámbar (el ámbar es memoria, no peligro), la desaturación no apaga el aviso y el modo de alto contraste de accesibilidad es cambiar un parámetro.
4. **Variación barata.** Una paleta alternativa por shader convierte cada cuerpo en 2 o 3 criaturas. Lo que **no** se resuelve con un tinte es la silueta: cada diseño añade al menos un rasgo de contorno propio (joroba, cuerno, arma, tamaño, cola).
5. **Producción:** los 43 diseños suman unos **196 puntos** más ~45 días de ingeniería de cuerpos (ya previstos en el documento 02). Con los recortes de la sección 11 se baja a un **mínimo viable de ~140 puntos**.
6. **Orden recomendado:** primero lo que reutiliza el humanoide (Jacinto, Segador, Espantapájaros), luego la armadura vacía (Archivo), luego el volador (el cuervo del Cinturón como banco de pruebas), el cuadrúpedo (el mastín primero), el segmentado (Minas) y, al final, las piezas (Maelis, Madre de Veta, Ermitaño).

---

## 1. Sistema visual común de criaturas

### 1.1 Gramática de silueta por oficio

El documento 01 define las familias (cascarón, pesado, ágil...). Para el bestiario completo se añaden **cuatro lecturas obligatorias**, de modo que dos enemigos de regiones distintas nunca se confundan a 100 px:

| Lectura | Qué dice la silueta | Ejemplos |
|---|---|---|
| **Alcance** | La longitud del arma a la vista = el alcance real (±15 %). Nada de arma pequeña con hitbox grande | Lancero 84, Novicio 100, Penitente 130, Segador 90 |
| **Peso** | Anchura y centro de gravedad bajo = lentitud. Un enemigo lento es más ancho que alto | Coloso, Armadura Vacía, Yunta |
| **Rol** | Quien invoca o apoya no lleva arma: lleva un libro, una vara, las manos abiertas | Relator Hueco, Acompañante, Hermano de Cal |
| **Estado** | Cerrado/abierto, con o sin escudo, se ve en la pieza, no en una barra | Geoda, Cangrejo, Armadura Vacía |

### 1.2 Cómo se lee un aviso (arte, no solo código)

Tres capas que siempre van juntas:

1. **Pose (la dibuja el rig).** Los fotogramas de `windup` tienen que ser reconocibles también congelados. Regla de la simetría:
   - **Parable (amarillo):** pose **asimétrica**. Arma echada atrás, un hombro adelantado, el peso sobre un pie, el centro de masa desplazado hacia atrás ("va a lanzarse hacia delante").
   - **No parable (rojo):** pose **simétrica y ensanchada**: los dos brazos arriba o abiertos, torso de frente, cabeza alzada, o el cuerpo entero comprimido o estirado. Son agarres, áreas, suelo y luz. El último fotograma del `windup` se **mantiene** (2 fotogramas de retención) para que la pose se asiente.
2. **Tinte (lo pone el código).** Parable: destello aditivo `d` sobre el sprite, 3 pulsos (alfa 0,5) durante el aviso, con el arma o miembro que golpea como parte más clara. No parable: tinte `t` más marca de suelo en `t`/`u` (decals de 2 tonos, borde recto, bandas diagonales para accesibilidad). El tinte se aplica **después** del shader de desaturación, para que nunca se apague.
3. **Sonido.** Parable: tono corto y agudo. No parable: tono grave sostenido (documento 03, 3.7).

**Duración mínima de la pose antes del daño** = el aviso del documento 04 (0,28 s mínimo): a 10 fps son 3 fotogramas de `windup`, a 12 fps 4. La fila `windup` tiene siempre 3-5 fotogramas más el retenido, nunca 2.

### 1.3 Rojo, ámbar y azul en criaturas (aplicación de la regla de oro)

- **Rojo (`r s t u`)**: solo en detalles de enemigo (vendas, cinturón, lacre, pupila) y en avisos. Pocos píxeles: un enemigo no es "rojo", *lleva* rojo (2-8 píxeles de `s`/`t`). En la Herida solo conservan rojo los cascarones y la marca de aviso.
- **Ámbar**: nunca en enemigos. Excepción deliberada ya existente: el hueco ámbar del Centinela. Quienes "llevan luz" (Cavador, Hondo) la llevan **apagada** (lámpara de grasa sin llama pintada: la llama es un halo de Godot).
- **Azul**: nunca como peligro, salvo canon (máscara azul del Relevo, Rastro de Oda, cristales de las Minas). El cristal **se enrojece** al armar un ataque (Geoda): el azul jamás avisa, el rojo sí.
- **Los no hostiles se distinguen por no llevar rojo.** Acompañante, Eudora y Oda no llevan un píxel de rojo en el cuerpo: su amenaza es de zona o estado y se ve en el suelo. El jugador aprende "sin rojo = no te pega con el cuerpo; mira el suelo".

### 1.4 Variantes: élite, minijefe, eco

- **Élite** = misma familia que su base, **+1 plantilla de tamaño** (factor 1,15-1,3 con `Z`), **un elemento nuevo en la silueta** (capa, corona, cuernos, barril) y paleta propia. Nunca solo recolor.
- **Reaparición tras descansar**: mismo aspecto (no hay "versión eco").
- **Minijefe** = plantilla "élite/miniboss" (192×128) o unidad especial (Madre de Veta, Ermitaño) con barra propia sobre el enemigo, no la grande.

---

## 2. Tipos de cuerpo y plan de extensión del rig

### 2.0 Previo común (ya en el plan del documento 02)

`tools/lib/raster.js` (Canvas, `shape`, contorno, sombreado por cadena, ruido, `trailChain`, `writeSprite`) con salida idéntica byte a byte en los `.sprite` existentes. Sin esto, cada cuerpo copia 300 líneas. Coste: 0,5 día. **Antes de cualquier tipo nuevo.**

Tres piezas transversales de Godot que no son cuerpo y que este bestiario necesita: **manifiesto `.anim.json`** con `impact` y `points` (punta del arma, boca, origen del proyectil), **shader de aviso** (tinte aditivo parametrizable, `aviso.gdshader`) y **shader de intercambio de paleta** con tabla de paletas de enemigo.

### 2.1 Los seis tipos

| Tipo | Cuerpo | Qué resuelve | Diseños que cubre | Coste de ingeniería | Riesgo |
|---|---|---|---|---|---|
| **H. Humanoide con estilo nuevo** | Esqueleto actual de `rig_lib.js` con cabezas, armas, ropas y proporciones nuevas | Casi todas las "personas vaciadas" y 8 jefes | Espantapájaros, Segador, Novicio, Sellador, Penitente, Relator, Cavador, Hondo, Zapador, Hermano de Cal, Hermano Antiguo, Acompañante, Eco Borrado, Relevo, Doble Vacío, Jacinto, Ilara, Hesper, Casimar y cortesano, Magda, Rufo, Eudora, Oda | **4 días** (cabezas, armas, `robe`, paja, escala `Z`) | Bajo |
| **A. Armadura vacía** | `head:'none'` de primera clase, piezas rígidas con desplazamiento propio y hueco visible | Formalizar lo que ya hace el Centinela | Armadura Vacía, Custodio Mayor, torso de la Quimera, Centinela (refactor opcional) | **2-3 días** (extraer `deco` de `rig_centinela.js`) | Bajo |
| **Q. Cuadrúpedo y artrópodo** | Columna horizontal de dos tramos, cuatro patas con IK, cola con `trailChain`; variantes cangrejo y bola | Fauna, bestias de tiro, cangrejos, geodas | Mastín, Chinche, Yunta (dos cuerpos), Geoda, Cangrejo, Ermitaño Mayor | **5-6 días** + 1 por especie | Medio |
| **V. Volador y flotante** | Cuerpo corto, 2 alas como cadena de 3 huesos con batido sinusoidal y membrana poligonal; variante flotante sin alas | Todo lo que vuela o levita | Cuervo, Polilla, Murciélago, Gaviota, Vela Errante | **3 días** + 1 por variante | Medio (batido a 1 px tosco por debajo de 6 fotogramas) |
| **S. Segmentado y de línea** | Cadena larga de N segmentos con radio variable que sigue una trayectoria; variante "línea" (trazo de 2 px sin relleno) | Gusanos, insectos segmentados, el Contorno | Gusano de Veta, Pez de Plata, Contorno, cuerpo de Madre de Veta | **2-3 días** | Bajo |
| **P. Multiparte por piezas** | Cada parte móvil es una hoja pequeña y un `Sprite2D` hijo con pivote; el movimiento lo hace `AnimationPlayer` con rotación por pasos | Jefes mayores de ~160×160 o no humanoides | Maelis (rostro + 2 manos), Madre de Veta, Ermitaño Mayor, Quimera | **4-5 días** del soporte + 3-5 por jefe | **Alto** |

**Dependencias.** H es el cimiento: no depende de nada y desbloquea Cinturón, parte del Archivo, parte de las Minas y ocho jefes. A depende solo de extraer el `deco`. Q, V y S son independientes entre sí; S depende de generalizar `trailChain`. P es independiente para Maelis y necesita S o Q para Madre de Veta y Ermitaño.

### 2.2 Qué añadir en `rig_lib.js`, por tipo

**H (humanoide v2).**
- Cabezas nuevas en el selector de cabeza: `veil` (velo de lino, cara oculta), `miner` (casco con cresta y visera), `mask` (máscara lisa: lacre, azul, cal), `crown` (corona rota), `scarecrow` (cuenco de paja cosido).
- Armas nuevas en `drawWeapon`: `scythe` (hoz con curvatura y hoja larga), `quill` (pluma de hierro larga y fina), `pick` (pico con peso), `lamp` (farol de grasa en la cadera, sin llama), `fan` (abanico), `staff` (vara), `chain` (cadena con peso sobre `trailChain`), `shield` (en la mano de atrás), `ember` (barra de hierro al rojo para Rufo).
- Ropas: `robe` (falda larga como `trailChain` de 4-6 segmentos anclada a la cadera), `sacks` (sacos colgados con ruido de tela), `straw` (relleno de paja: ruido vertical en `5 6 7`), `lino` (pliegues verticales en `8/9/w`).
- Parámetros de pose nuevos en `BASE`: `crouch` (doblar cadera), `armsUp` (ambos brazos arriba: la pose simétrica de los rojos), `hover` (pies separados del suelo con ondulación de falda: Hesper, Eudora), `scale` por parte (cabeza o manos grandes).

**A (armadura vacía).** `head:'none'`; `plates:[{bone,shape,offset}]` (peto, hombreras, falda, escudo) que siguen a un hueso con retardo (el "muelle" visual); `gap:{x,y,w,h,fill}` para el hueco del pecho; `inner` (cascarón mínimo con vendas) como figura opcional dibujada antes de las placas. Es mover a una API el código que ya está en `rig_centinela.js`.

**Q (cuadrúpedo).** `quad(spec)` con `spine:[chest,rump]` (dos tramos con flexión), `legs[4]` (IK de dos huesos, fase desfasada: `trot` en diagonales, `gallop` en pares, `pounce`), `head` con `jaw`, `tail` (`trailChain`). Variante `crab`: seis patas laterales con ciclos alternos, dos pinzas de 3 huesos y concha intercambiable. Variante `ball`: esfera con placas que rota por pasos de 22,5° (la Chinche rodando).

**V (volador).** `flyer(spec)` con `body`, `wings:[{root,bones:3,len}]`, `flap(t)` sinusoidal con asimetría subida/bajada, `membrane` (polígono de 2 tonos entre huesos), `tail`. Variante `flame`: contorno de llama ondulado más cadena de humo hacia abajo.

**S (segmentado).** `worm(spec)` con `path(t)`, `radius(i)`, `plates` por segmento, `head` (cápsula con mandíbula) y contorno por unión de la silueta (no por segmento). Variante `line`: trazo de 2 px de `0` o `x` que sigue una curva, sin relleno, con halo `w` al lado opuesto de la luz.

**P (partes).** `renderPart(spec)` que dibuja solo los huesos pedidos con pivote declarado, y una escena de ensamblaje por jefe (`boss_*.tscn`) con un `Sprite2D` por parte. Rotaciones por pasos de 15° o 22,5°, sin interpolar (estilo del género y sin pixel mixels).

### 2.3 Lienzos y presupuesto

Plantillas del documento 02 (3.4): **pequeño 64×48**, **mediano 96×64** (144×64 con arma larga), **grande 144×96**, **élite/miniboss 192×128**, **jefe 224×128 hasta 256×192** (humanoide recortado) o por piezas (no humanoide). Presupuesto: 0,5-4 MB por hoja de criatura, jefe ≤ 16 MB tras el recorte, 150 MB residentes por sala. Los jefes humanoides de este documento caben en 6-12 MB cada uno con atlas recortado; los multiparte, en 3-6 MB.

### 2.4 Convención de tinte para variantes

Cada cuerpo declara cuatro ranuras de paleta en el manifiesto: `piel`, `tela`, `metal`, `acento`. La tabla de paletas de enemigo cambia las ranuras, no los píxeles. Ejemplo: Cascarón → `tela: 8/9` (Hermano de Cal) o `tela: x/y` (Eco Borrado) sin PNG nuevos.

---

## 3. Bestiario ilustrado: Último Umbral y Cinturón Yermo

Región de la primera lección. Desaturación 0-1 con parches de 3; rampas Piedra + Tierra + Musgo; el rojo del enemigo es lo único saturado de la capa de juego. Aquí se establece el estándar de lectura: **cuerpo pálido, vendas rojas, silueta distinta**.

### 3.1 Los cinco ya construidos (retoques)

| Id | Lienzo | Falta | Esfuerzo |
|---|---|---|---|
| `cascaron` | 96×64 | Fila `death 6@10` (caída de rodillas y deshacerse en cenizas `3/4`), `stagger 3@8` (aturdido tras parry), `alert 3@12` | S |
| `lancero` | 144×64 | `death 6@10`, `stagger` | S |
| `arrojador` | 96×64 | `death 6@10`; fotograma de lanzamiento con la mano libre abierta (el proyectil se lee mejor) | S |
| `acechador` | 96×64 | `death 6@10`; es el único que vive a ras de suelo: la muerte es un derrumbe lateral | S |
| `coloso` | 144×96 | `death 8@10` (cae de rodillas, el mazo se clava), `stagger 4@8` | S |

Son las únicas filas `death` que faltan hoy; juntas, 5 puntos que dan cierre visual a matar. Sin ellas los enemigos desaparecen por desvanecimiento y el resto del bestiario nace con muerte propia.

### 3.2 Cuervo de Rastrojo (`cuervo`)

- **Silueta y aspecto.** Corneja flaca con jirones de tela atados a una pata y a la cola; cuerpo de 28×20 px (alas abiertas 44×22). Plumaje en `1/2` con brillo `3`, cuello pelado y gris (`x`), pico largo y abierto en `y`. Un solo detalle rojo: un cabo de tela `s` anudado a la pata derecha, que cuelga y marca "esto era de alguien". La silueta clave es la **cabeza hacia abajo en picado**: en el `windup` se detiene, pliega las alas hacia atrás en V y baja el pico; el contorno pasa de "pájaro" a "flecha", y esa flecha apunta al jugador.
- **Cómo se distingue.** Es el único volador del Cinturón; su batido es lento (6 fps) con una pausa en el punto alto. Sobrevuela a 90 px de altura en círculos, con una sombra pequeña en el suelo que avisa de que está sobre ti.
- **Canon.** Los cuervos picaban el grano que nadie recogió. Hay hilachas de tela en el pico (comen de los espantapájaros).
- **Cuerpo y rig.** V (ave). Primer volador: banco de pruebas del tipo. Lienzo 64×48, anclaje en el centro de masa.
- **Animaciones.** `idle 4@7` (planeo), `walk 6@12` (vuelo), `windup 4@10 (+1)`, `strike 3@24` (picado, impacto f2), `hit 3@14`, `death 6@10` (cae en espiral y se deshace en plumas).
- **Esfuerzo.** M (4), más el tipo V.

### 3.3 Espantapájaros (`espantapajaros`)

- **Silueta y aspecto.** Muñeco de paja de 28×54 sobre un palo (el palo se ve dormido; despierto lo arrastra como bastón). Cuerpo de costales `6/7` con ruido de brizna, brazos en cruz con forma de T, cabeza de saco `7` cosida con hilo `3`, con dos aspas de hilo `s` por ojos y una boca cosida. Harapos en rojo apagado `s` sobre `r` (nunca `t`/`u`, como manda el documento 01). Dormido es **simétrico y erguido**; despierto se encorva y la T se descuelga en un brazo largo (silueta asimétrica = parable: pega con un solo brazo).
- **Cómo se distingue.** Los falsos del Cinturón (decorado) tienen el palo recto y los ojos en negro `0`; los verdaderos, al acercarse, parpadean un píxel de `s` en las aspas (0,2 s antes de "despertar").
- **Canon.** Los puso Jacinto en su era: muñecos de familia (el más pequeño lleva una chaquetita de niño).
- **Cuerpo y rig.** H con `scarecrow`, `straw`, brazos largos (`scale`). Lienzo 96×64.
- **Animaciones.** `idle 2@2` (dormido, solo viento en los harapos), `wake 8@10` (extra), `walk 6@7`, `windup 4@10`, `strike 4@24` (impacto f2), `hit 3@14` (suelta paja), `death 6@10` (se deshace en paja).
- **Esfuerzo.** S (2). La fila `wake` se reutiliza en los falsos.

### 3.4 Mastín sin Amo (`mastin`)

- **Silueta y aspecto.** Perro de pastor, flaco y largo (cuerpo 44×26, 28 de alto en la cruz). Pelo ralo `x/y`, costillas marcadas en `3`, cola baja, orejas rotas. Collar de cuero `5` con un cascabel sin badajo (detalle de "tuvo dueño") y un trapo `s` en el collar como marca de vaciado. Silueta de **arco bajo**: lomo curvo, cuello adelantado, hocico a ras.
- **Cómo se distingue.** De cuatro patas y horizontal: no se confunde con el Acechador (humanoide a rastras, de brazos largos). El mastín **ladra** (boca abierta 2 fotogramas) al detectar: el `alert` es su aviso general.
- **Canon.** Los pastores se quedaron sin amo; no son malvados, tienen hambre.
- **Cuerpo y rig.** Q (perro). Primera especie del tipo. Lienzo 96×64.
- **Animaciones.** `idle 6@6`, `walk 8@14` (trote), `alert 3@12`, `windup 4@10` (agachado, patas traseras cargadas), `strike 5@24` (salto, impacto en el aterrizaje f4; el arco lo hace el motor), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2) tras Q.

### 3.5 Segador Vaciado (`segador`, élite)

- **Silueta y aspecto.** Cascarón alto (28×54), encorvado, con la hoz **más larga que él** (hoja curva de 90 px que arrastra por el suelo en `idle`). Sombrero de paja roto `7` y capa de arpillera `5/6`; vendas rojas `s` en el antebrazo derecho. Reflejo `4` en la hoja y una mella en el filo. Es la **primera vez** que se ve la silueta "arco de hoz", que se repite en Jacinto a escala mayor.
- **Cómo se distingue de su base.** Más alto (×1,2 sobre el cascarón), sombrero, y la hoz siempre visible hasta el suelo.
- **Canon.** Un segador de la cuadrilla de Jacinto; el último.
- **Cuerpo y rig.** H con `scythe`, escala `Z` 1,2. Lienzo 160×80 (la hoz abre en `strike`).
- **Animaciones.** `idle 6@7`, `walk 8@11`, `windup 5@10 (+1)`, `strike 6@26` (barrido en arco, impacto f3; la estela es un sprite de arco aparte), `step 4@14` (paso de segador, extra), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2). Sirve de **prototipo del arma `scythe`** antes de Jacinto.

### 3.6 La Yunta (`yunta`, minijefe)

- **Silueta y aspecto.** Dos bueyes pálidos uncidos a un arado, vistos de perfil como un bloque horizontal de 112×56. Cuerpos `8/y` con costillas `3`, cabezas gachas y cuernos romos en `4`; ojos de dos puntos negros `0`. El yugo de madera `5/6` los une, con un trapo rojo `s` (el vaciado). El arado de hierro `3/4` arrastra dos cuchillas de 20 px detrás: son el **peligro** de la silueta. Una piedra suelta cuelga del arado (la del Surco).
- **Cómo se distingue.** Es la criatura más larga del Cinturón: 7 baldosas. Su `windup` rojo (no parable) sube las dos cabezas a la vez y encorva el lomo (silueta simétrica y comprimida).
- **Cuerpo y rig.** Q con **dos cuerpos** en un solo sprite (los bueyes comparten ciclo con medio fotograma de desfase) y arado rígido. Lienzo 192×96. Es el banco de pruebas del cuadrúpedo grande.
- **Animaciones.** `idle 6@5`, `walk 8@10`, `windup 5@10 (+2)` (arrancada), `strike 6@24` (arrancada en bucle a 340 px/s), `kick 5@24` (coz doble, impacto f3), `plough 5@18` (Surco), `stagger 4@8` (aturdido contra la pared, 1,6 s), `hit 3@14`, `death 8@10`.
- **Esfuerzo.** L (7).

---

## 4. Bestiario ilustrado: El Archivo

Desaturación 1-3 por sala. Selladores en ocre y lacre, Penitentes en ceniza gris, vaciados con ropa de oficio. Aquí se aprende la **lectura de estado** (escudo arriba o abajo) y la **prioridad de objetivos**. Los colores se desaturan con la sala; el rojo de aviso no.

### 4.1 Novicio Borrado (`novicio`)

- **Silueta y aspecto.** Cascarón de túnica gris `2/3` hasta los pies con la capucha caída, 24×46. La mano derecha sostiene una pluma de hierro de 60 px, fina (`quill`), con el brazo extendido y rígido como quien traza una línea. En el pecho, un cuadro vacío con esquinas `y` (un libro cosido sin letras). Vendas rojas `s` en la muñeca. La estocada deja una **línea de tinta** `e` de 0,3 s en el aire (VFX).
- **Cómo se distingue.** Es el más delgado y recto de los vaciados, sin joroba. La pluma sobresale por delante en `idle` (alcance legible: 100 px).
- **Canon.** Los novicios copiaban al dictado; la Desmemoria les dejó el gesto.
- **Cuerpo y rig.** H con `quill` y `robe` corta. Lienzo 144×64.
- **Animaciones.** `idle 6@6`, `walk 8@10`, `windup 5@10`, `strike 5@26` (impacto f2), `hit 3@14`, `death 6@10` (se deshace en hojas, no en ceniza).
- **Esfuerzo.** S (1).

### 4.2 Sellador (`sellador`)

- **Silueta y aspecto.** Capa ocre `b/6` hasta las rodillas con un hombro más alto (hombrera de cera), guantes de cera `8` y máscara de lacre `s/t` sin boca: una placa lisa con una hendidura de ojos. 26×50. La mano libre sostiene una bola de lacre `r/s` que gotea; la otra, un cuchillo de cera `8`. En el pecho, un sello partido por la mitad en `8` (sin ámbar). En el cinturón, tres botes de lacre.
- **Cómo se distingue.** Es el único con **máscara roja lisa**. Su ataque principal (lacre al suelo) es de **brazo alto lanzando**: silueta con el brazo en arco sobre la cabeza.
- **Canon.** Los soldados de Hesper. Se reconocen por los guantes: la cera sirve para sellar.
- **Cuerpo y rig.** H con `mask`, `robe` ocre y una ranura de mano para el bote. Lienzo 96×64.
- **Animaciones.** `idle 6@6`, `walk 8@10`, `throw 5@12` (aviso del lacre), `windup 4@10`, `strike 5@26` (cuchillo, impacto f2), `hit 3@14`, `death 6@10` (la máscara se resquebraja y cae; la capa queda en el suelo). La bola de lacre es un proyectil aparte de 16×16.
- **Esfuerzo.** S (2).

### 4.3 Penitente (`penitente`)

- **Silueta y aspecto.** Armadura de Custodio **sin sello** (el hueco del pecho a la vista, `0`), cubierta de **sacos de ceniza** `x/y` colgados de hombros y cintura, 30×52 (más ancho que el Sellador). Cabeza descubierta y rapada (`bare`) con una marca de ceniza en la frente; el casco, bajo el brazo. Cadena `3` con un peso de hierro `1/2` que arrastra por el suelo en `idle`. El brazo de la cadena lleva vendas `s`.
- **Cómo se distingue.** El **hueco del pecho** y los sacos (silueta redondeada y lastrada). La cadena sobre la cabeza en el `windup` dibuja un círculo: pose casi simétrica pero **parable**, así que el radio de 130 px se marca con un decal fino en `y`, no rojo.
- **Canon.** Ceniza de los registros quemados: llevan sus culpas a cuestas. Gaspar viste así.
- **Cuerpo y rig.** H con `plates` mínimos de A, `chain`, `sacks`. Lienzo 144×64.
- **Animaciones.** `idle 6@6`, `walk 8@9`, `windup 5@10 (+1)`, `strike 6@24` (impacto f3), `selfhit 3@12` (extra: se golpea a sí mismo), `hit 3@14`, `death 7@10` (los sacos se rompen y sueltan la nube de ceniza, VFX).
- **Esfuerzo.** S (2).

### 4.4 Armadura Vacía (`armadura_vacia`)

- **Silueta y aspecto.** Coraza de Custodio de 38×64, **escudo alto** (rectángulo de 22×50, más alto que el cuerpo) por delante en la mano de atrás, espada corta `3/4` baja. Hierro `3/4` con óxido `5` en las juntas, sin cabeza (`head:'none'`) y cuello hueco `0`; dentro del peto se intuye un cascarón mínimo (dos puntos pálidos y 3 px de venda `t`). El escudo es la silueta: **un rectángulo** que ocupa la mitad del cuerpo.
- **Cómo se distingue.** Del Centinela: más pequeña, sin ámbar, sin núcleo expuesto. Del resto: el único con un rectángulo plano por delante. Cuando baja el escudo (cada cuatro golpes) el rectángulo cae a la cadera y se ve el peto: estado legible sin barra.
- **Canon.** Custodios que nadie relevó, con el hueco del sello vacío.
- **Cuerpo y rig.** **A**. Primer cliente del tipo. Lienzo 144×64.
- **Animaciones.** `idle 6@5`, `walk 8@9`, `windup 5@10`, `strike 4@24` (golpe de escudo, impacto f2), `guard 2@8` (extra, bucle corto), `lower 3@12` (extra: baja el escudo, 0,4 s), `stagger 4@8` (parry: el escudo se desprende y vuelve), `hit 3@14` (por la espalda), `death 8@10` (se desmorona pieza a pieza; el escudo cae el último).
- **Esfuerzo.** M (4).

### 4.5 Polilla de Archivo (`polilla`)

- **Silueta y aspecto.** Cuerpo peludo `x` de 26×18 y alas de 56 px abiertas en `y/8` con motas `w` y un **ojo falso** en `1` en cada ala (como un lomo de libro). Antenas plumosas. Vuela en ochos con batido lento (7 fps). En picado pliega las alas en V como el cuervo, pero **suelta polvo** (VFX) y levanta las antenas.
- **Cómo se distingue.** Del cuervo: más ancha que alta, clara en vez de oscura, sin pico. Siempre cerca de estanterías.
- **Cuerpo y rig.** V (insecto): alas anchas con membrana de 2 tonos. Lienzo 64×48.
- **Animaciones.** `idle 4@6`, `walk 6@10`, `windup 4@10`, `strike 3@22` (impacto f2), `perch 2@4` (extra), `hit 3@14`, `death 6@10` (se deshace en polvo de papel `8`).
- **Esfuerzo.** S (2) tras V.

### 4.6 Pez de Plata (`pez_plata`)

- **Silueta y aspecto.** Insecto plateado y segmentado de 34×10 (tres segmentos de cuerpo y cola de dos filamentos). Cuerpo `y/w` con brillo `9`, patas diminutas `3`, sin ojos (dos puntos `x`). Al partirse, cada mitad (17×10) conserva cabeza o cola. Bajo una página solo se ve un abultamiento en el papel (decorado).
- **Cómo se distingue.** Una **línea horizontal brillante** a ras de suelo o de estante; su `windup` rojo es polvo de papel en el suelo (decal) y un arqueo del cuerpo en "n".
- **Cuerpo y rig.** S (gusano corto con dos hitbox). Lienzo 64×48, anclaje al suelo.
- **Animaciones.** `idle 4@6`, `walk 6@12`, `windup 3@10 (+2)`, `strike 4@24` (salto, impacto f3), `split 4@12` (extra), `hit 3@14`, `death 5@10`.
- **Esfuerzo.** M (3) tras S.

### 4.7 Relator Hueco (`relator`, élite)

- **Silueta y aspecto.** Cascarón con capa larga de Relator `2/3` y capucha, 28×54, con el **libro en blanco** abierto contra el pecho (`w` con líneas `x` que no son letras), sostenido con las dos manos: pose simétrica de **rol**, sin arma. Al invocar, el libro se abre hacia delante y las páginas salen como tiras `8` que se hacen novicios. Vendas rojas `s` en el borde de la capucha. Lazo de cuerda al cuello.
- **Cómo se distingue de su base.** Capa más larga, libro y ausencia de arma. Pie de escritura bordado en la capa (3 px `8`).
- **Cuerpo y rig.** H con `robe` y libro en las dos manos. Lienzo 144×96 (un élite sin arma no necesita 192×128).
- **Animaciones.** `idle 6@5` (hojea el libro), `walk 8@9`, `windup 6@10 (+2)` (invocación de 1,0 s), `strike 4@12` (las páginas se hacen novicios), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2).

### 4.8 Custodio Mayor del Pasillo en Blanco (`custodio_mayor`, minijefe)

- **Silueta y aspecto.** Armadura vacía **duplicada**: 56×88, escudo grande (36×76) y alabarda de 140 px con una cinta `w` blanca en el asta (el único trazo claro: el pasillo en blanco). Hierro más pulido que las comunes (`4` en bordes), cuello hueco `0`, cascarón visible en el peto con una venda roja más larga. En los hombros, cuernos de bronce `5/6` (insignia de Custodio mayor).
- **Cómo se distingue.** La alabarda horizontal sobre el escudo da una "T" de hierro. Su `windup` rojo (embestida de escudo) baja el escudo casi hasta el suelo y echa el peso al frente (silueta simétrica y compacta).
- **Cuerpo y rig.** A a gran escala (`Z` 1,45 como el Centinela, **sin** el `deco` a mano: las placas son piezas). Lienzo 192×128.
- **Animaciones.** `idle 6@5`, `walk 8@8`, `windup 6@10 (+2)`, `strike 6@24` (estocada larga, impacto f3), `bash 5@22` (embestida de escudo), `spin 8@20` (giro), `guard 2@8`, `stagger 5@8`, `hit 3@14`, `death 10@10`.
- **Esfuerzo.** L (7).

---

## 5. Bestiario ilustrado: Minas, Costa y Herida

### 5.1 Las Minas del Origen

Desaturación 2; roca casi toda en tonos 1-2; **el mineral conserva color** (se pinta sin el shader). Aquí el color vive en la luz: las criaturas son oscuras y se leen por una **zona clara en el pecho o el rostro** y por el rojo del aviso. Regla de oscuridad: nadie ataca desde donde no se vea; todo enemigo de las Minas lleva un **acento mineral tenue** (`f` en 3-5 píxeles) que lo recorta sin iluminar el entorno.

#### Cavador Vaciado (`cavador`)

- **Silueta y aspecto.** Obrero de 28×50 con casco de cresta (`miner`) y un candil de grasa apagado en la frente (sin llama pintada), mono de lona `5/6` con peto de cuero `5`, botas de clavos. Pico de hierro `3` sobre el hombro, de 60 px, con mango de madera `6`. Vendas rojas `s` en las muñecas. Acento mineral `f` en la punta del pico. Silueta de **"7" invertida**: el pico sobre la cabeza forma un ángulo recto que sube al `windup` y cae en el `strike`.
- **Cómo se distingue.** El casco con cresta y el pico alto son lo único con silueta en ángulo. Cuando pica la pared (extra), el cuerpo se gira de frente y se agacha ligeramente (pose rojo: simétrica).
- **Canon.** Obreros del Cavar que nadie relevó.
- **Cuerpo y rig.** H con `miner`, `pick`. Lienzo 144×64.
- **Animaciones.** `idle 6@6`, `walk 8@9`, `windup 5@10 (+1)`, `strike 5@26` (impacto f3), `dig 5@12` (extra: pica la pared), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2).

#### Chinche de Roca (`chinche`)

- **Silueta y aspecto.** Cuadrúpeda del tamaño de un perro, 36×22 sin enrollar, con coraza de placas de roca `1/2` encajadas como un armadillo; barriga pálida `y`, cuatro patas cortas con garras `4`, cola de dos placas. Acento mineral `f` entre las placas. Enrollada es una **esfera de 26 px** con las placas visibles (rodando por pasos de 22,5°). Los ojos: dos puntos `8`.
- **Cómo se distingue.** Es la única criatura **redonda** del bestiario cuando rueda; cuando camina, su silueta baja y ancha la distingue del Mastín (más alto, delgado). El `windup` es el encogimiento: patas hacia dentro, cabeza escondida (silueta que "se cierra").
- **Cuerpo y rig.** Q (armadillo) con variante `ball`. Lienzo 64×48.
- **Animaciones.** `idle 4@5`, `walk 6@10`, `windup 4@10` (se enrolla), `roll 4@24` (el `strike`, bucle), `unroll 4@12` (aturdido 1,3 s), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** M (3).

#### Gusano de Veta (`gusano_veta`)

- **Silueta y aspecto.** Serpiente de roca de 5 segmentos, 18 px de grosor, que asoma 48 px por encima de la veta: cada segmento es un anillo de roca `1/2` con un reborde `3`, cabeza con mandíbula doble y sin ojos, cuerpo pálido `y` entre anillos. La veta (decorado fijo) es una hendidura con halo mineral tenue `f`, la señal de "aquí hay uno".
- **Cómo se distingue.** Siempre sale **de una veta marcada**; el `windup` rojo es el suelo vibrando (decal) más una cabeza que se retrae y se estira (silueta vertical simétrica).
- **Cuerpo y rig.** S (gusano vertical con 5 segmentos). Lienzo 64×64 anclado al suelo.
- **Animaciones.** `idle 4@5` (oculto/asomado), `emerge 5@12`, `windup 4@10 (+1)`, `strike 4@24` (golpe de cabeza, impacto f2), `retreat 4@12`, `hit 3@14`, `death 6@10`.
- **Esfuerzo.** M (4).

#### Murciélago de Cueva (`murcielago`)

- **Silueta y aspecto.** Murciélago de 20×14 plegado, 44×16 con las alas abiertas; membrana `1/2` con huesos `3`, ojos cosidos con un hilo `s` en cruz (la marca roja), orejas largas. Colgado del techo es un **huevo oscuro invertido** con alas como capa.
- **Cómo se distingue.** Anclado al techo (anclaje superior). El `windup` abre las alas de golpe (silueta simétrica y ensanchada: aviso corto por ser un picado rápido; **parable**, pero la simetría se compensa con la caída desde el techo). Cuando oye, gira la cabeza y las orejas se levantan.
- **Cuerpo y rig.** V (murciélago). Lienzo 64×48, anclaje en el techo.
- **Animaciones.** `idle 2@3` (colgado), `walk 6@12` (vuelo), `windup 3@10`, `strike 3@22` (picado, impacto f2), `hit 3@14`, `death 5@10`.
- **Esfuerzo.** S (2) tras V.

#### Hondo (`hondo`)

- **Silueta y aspecto.** Fibroso y delgado, 26×52, de ojos **enormes** (6×6 px, `8` con pupila `0`), trapo gris `x` sobre la boca, mono de lana `3` remendado. En la mano izquierda lleva una lámpara de grasa de latón `5` (apagada; la llama es un halo) y en la derecha un pico corto o una cuchilla. Cuerpo ligeramente encogido (sale de una galería baja). Acento mineral `f` en las uñas.
- **Cómo se distingue.** Los ojos y la lámpara. No lleva venda roja (no es enemigo por defecto): su rojo aparece solo en el aviso de la llama. **Se retira** si el jugador lo mira de cerca, y el `retreat` es una animación propia: de espaldas, una mano levantada en "stop".
- **Canon.** Descendiente de los Cavadores que se quedaron bajo tierra. Pico cruzado con vela en el cinturón (3 px).
- **Cuerpo y rig.** H con `lamp` y mascarilla. Lienzo 96×64.
- **Animaciones.** `idle 6@5`, `walk 8@9`, `windup 5@10`, `strike 4@22` (lanza la lámpara, impacto f2), `retreat 4@12` (extra), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2).

#### Geoda Saturada (`geoda`)

- **Silueta y aspecto.** Roca de 40×32 con cuatro patas cortas y cristales de recuerdo `f/g` que sobresalen como erizo, con dos rendijas por ojos que se abren de lado a lado. **Estado cerrada**: bloque liso de `1/2` con los cristales plegados (silueta de piedra, sin brillo); **abierta**: la parte superior se abre en dos mitades y deja ver el interior de cristales `g/h`. Al armar el ataque, los cristales se **enrojecen** (el código aplica tinte `t` a los cristales; el azul nunca avisa).
- **Cómo se distingue.** Es el único "mueble" vivo: parece un decorado hasta que se abre. La mitad superior es la zona golpeable para el pogo.
- **Cuerpo y rig.** Q (variante `ball` en reposo, sin rodar) o P simple con 2 piezas (tapa + cuerpo) para animar apertura sin 40 fotogramas. Recomendado P. Lienzo 96×64.
- **Animaciones.** `idle 2@3` (cerrada), `open 5@12`, `windup 4@10` (abierta, esquirlas en tensión), `strike 3@24` (abanico de cuatro, impacto f1), `close 4@12`, `hit 3@14`, `death 6@10 (+explosión)` (aviso de 0,6 s: hay una fila `windup` extra de 3 fotogramas rojos).
- **Esfuerzo.** M (4).

#### Zapador Eterno (`zapador`, élite)

- **Silueta y aspecto.** Cavador ampliado (×1,2) con un **barril de pólvora a la espalda** (20×24, listones `5/6` y aros de hierro `3`, con una mecha corta `s/u`). Casco con visera de hierro `3/4`, mono de lona quemado en `1`, chaleco de bolsillos con cartuchos. Manos enguantadas. Vendas `s` en el barril. La silueta es una **joroba redonda**: el barril.
- **Cómo se distingue de su base.** Barril. Cuando lo lanza, la espalda queda hundida: el hueco es el aviso.
- **Cuerpo y rig.** H con `barrel` como accesorio (nuevo). Lienzo 144×96.
- **Animaciones.** `idle 6@6`, `walk 8@9`, `windup 5@10`, `strike 5@22` (lanza el barril, impacto f3), `fuse 3@12` (extra), `hit 3@14`, `death 7@10` (si muere con barril, explosión VFX).
- **Esfuerzo.** S (2).

#### Madre de Veta (`madre_veta`, minijefe)

- **Silueta y aspecto.** Gusano de roca de 8 segmentos que ocupa una sala vertical (hasta 8 baldosas de alto), de **48 px de grosor** en el tronco. Cabeza de 80×64 con mandíbula que se abre en cruz, anillos de roca `1/2` con costras `3`, tripas pálidas `y` entre anillos. Tres **bolsas de recuerdo** (24×24 cada una) incrustadas en el cuerpo, translúcidas `f/g/h`, que laten con el Latido de la sala (puntos débiles; al romperse sueltan una luz azul). La sala se la lee por esas tres luces.
- **Cómo se distingue.** Es la única criatura que atraviesa el decorado: las paredes tienen agujeros de su tamaño.
- **Cuerpo y rig.** **S + P**: cadena de 8 segmentos (reutiliza `worm`) con cabeza de pieza propia y bolsas como piezas golpeables (`hurt_zone`). Lienzo de la cabeza 128×96; segmento 64×64 (se repite por código); bolsa 32×32 con 3 estados.
- **Animaciones.** Cabeza: `idle 6@5`, `emerge 6@12`, `windup 6@10 (+2)`, `strike 5@22` (aplastamiento, impacto f3), `spit 4@18`, `stagger 5@8`, `hit 3@14`, `death 12@10`. Bolsa: `idle 4@3`, `burst 5@14`.
- **Esfuerzo.** XL (12).

### 5.2 La Costa Retenida

Desaturación 0, tinte cian; la región más luminosa. Los enemigos van de **lino blanco** (`8/9/w`) o de **algas y bronce** (`v`). El peligro no está en el cuerpo sino en las **marcas de suelo** (círculos de cal), así que el aviso rojo se vuelve más grande y limpio que en otras regiones. La fauna (gaviota, cangrejo, vela) usa el mar como paleta: `9`, `v`, `4`.

#### Hermano de Cal (`hermano_cal`)

- **Silueta y aspecto.** Lino blanco manchado `8/9` hasta los tobillos, 26×52, cara cubierta por un paño `9` anudado, manos tiznadas de cal `w` hasta el codo. La mano derecha extendida con la palma al suelo cuando pinta el círculo. Un cordón de cáñamo `6` en la cintura con una cuenta `s` (única marca de enemigo, de 2 px). Ligeramente encorvado y sin arma. Silueta de **campana**: túnica ancha que se abre abajo.
- **Cómo se distingue.** Lino y círculo. Del Acompañante: manos tiznadas de cal `w` (blanco más puro) y la cuenta roja; el Acompañante lleva las manos limpias y sin cuenta.
- **Canon.** Los que ya han olvidado mucho. Se cubren el rostro al hablar de un muerto.
- **Cuerpo y rig.** H con `veil`, `lino`. Lienzo 96×64.
- **Animaciones.** `idle 6@5`, `walk 8@8`, `paint 6@10 (+2)` (el `windup` rojo: se agacha y extiende ambas manos: simétrica), `push 4@24` (empujón, impacto f2), `hit 3@14`, `death 6@10` (se derrumba y la tela se queda).
- **Esfuerzo.** S (2).

#### Acompañante (`acompanante`)

- **Silueta y aspecto.** Lino blanco limpio, cálido, 26×52, **manos abiertas** `w`, velo ligero sobre la cabeza `9`, sonrisa tallada (la única cara visible de la región: una línea `x`). Cero rojo en el cuerpo. Un cordón de cáñamo `6` sin cuenta. Alrededor de un aliado protegido aparece un **aura de Calma** (anillo `9/w` de 3 px que se gasta; VFX/sprite aparte). Silueta de **abrazo**: brazos abiertos en `idle`.
- **Cómo se distingue.** El único sin rojo y con la postura de abrazo: el jugador aprende que es prioridad. Su agarrón (rojo) es una animación en la que se abalanza con los brazos extendidos.
- **Cuerpo y rig.** H con `veil`, `lino`, `armsUp` medio. Lienzo 96×64.
- **Animaciones.** `idle 6@5` (brazos abiertos), `walk 8@8`, `calm 5@10` (extra: da Calma al aliado), `windup 5@10 (+2)` (abalanzarse), `strike 4@18` (agarrón, impacto f2), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2).

#### Gaviota Rapaz (`gaviota`)

- **Silueta y aspecto.** Gaviota flaca de 30×18, alas de 56 px, plumaje `9` sucio con la espalda en `y`, pico amarillento `7` ganchudo, ojos hundidos en `0`. Una cinta `s` atada a la pata. Vuela en círculos contra el viento y planea con las alas arqueadas; el picado pliega las alas hacia atrás. Silueta de **"m"**: alas arqueadas.
- **Cómo se distingue.** Del cuervo: clara en fondo oscuro, más larga y de alas en "m". Tiene un graznido (sonido) que avisa antes del picado.
- **Cuerpo y rig.** V (ave marina), variante del cuervo con alas más largas. Lienzo 64×48.
- **Animaciones.** `idle 4@7`, `walk 6@12`, `windup 4@10`, `strike 3@24` (impacto f2), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (1) tras el cuervo.

#### Cangrejo Ermitaño (`cangrejo`)

- **Silueta y aspecto.** Cangrejo de 40×30 con una **campana rota** de bronce `v/5` como concha (la boca de la campana hacia delante, resquebrajada, con un badajo roto que cuelga), patas `v/3` (seis, cortas), pinzas desiguales (una grande de 18 px). Ojos de tallo `8`. La concha es el **escudo frontal**: cuando está cerrado solo se ve la campana con una rendija. Cuenta roja `s` en la pinza grande.
- **Cómo se distingue.** La campana: es lo único redondeado y de bronce de la Costa. Cuando pierde la concha queda pálido y desnudo (`y/8`), con un fotograma de pánico.
- **Cuerpo y rig.** Q (variante `crab`), concha intercambiable. Lienzo 96×64.
- **Animaciones.** `idle 4@5`, `walk 6@10`, `hide 3@10` (extra: cerrarse), `windup 4@10`, `strike 4@24` (tenaza, impacto f2), `naked 4@6` (extra: indefenso), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** M (4).

#### Vela Errante (`vela_errante`)

- **Silueta y aspecto.** Llama azulada `g/h` en una gota alargada de 16×26 (tamaño de una mano), sostenida por un hilo de humo `x/y` de 14 px que se enrosca hacia abajo. Dos puntos negros `0` por ojos (el único rostro). Sin cuerpo, sin armas. Cuando la zona de luz se arma, el contorno de la llama se agranda y se **enrojece** (tinte de aviso); la luz quemante es el decal circular de 140 px.
- **Cómo se distingue.** Es lo único flotante sin alas. Se pone cerca de los faroles apagados.
- **Cuerpo y rig.** V (variante `flame`). Lienzo 48×48 (centro de masa).
- **Animaciones.** `idle 6@8` (la llama titila), `walk 6@8` (flota), `windup 4@10` (se agranda), `strike 3@16` (zona de luz), `hit 3@14`, `death 6@10` (se apaga y suelta humo).
- **Esfuerzo.** S (2).

#### Hermano de Cal Antiguo (`hermano_antiguo`, élite)

- **Silueta y aspecto.** Hermano muy anciano, ×1,2, 30×60, encorvado y apoyado en una **vara de coral blanco** `9` de 80 px, lino casi blanco por completo (`w`), con el paño sobre el rostro roto en jirones. Tres cuentas `s` en el cordón. El círculo que pinta es el doble de grande. La silueta se parece a un **pastor**: una vara y un manto largo.
- **Cómo se distingue de su base.** Vara, tamaño y las tres cuentas; ya no mira al suelo sino al horizonte.
- **Cuerpo y rig.** H con `veil`, `lino`, `staff`. Lienzo 144×96.
- **Animaciones.** `idle 6@4`, `walk 8@7`, `paint 7@10 (+2)`, `strike 6@20` (golpe amplio, impacto f3), `hit 3@14`, `death 8@10`.
- **Esfuerzo.** S (2).

#### El Ermitaño Mayor (`ermitano_mayor`, minijefe)

- **Silueta y aspecto.** Cangrejo enorme de 120×72 con una **barca de pesca varada** como concha: casco `5/6` con costillas visibles, mástil roto `5` y una vela rasgada `8/9` que cuelga (la vela se mueve en `idle`). Seis patas gruesas de bronce `v/3` y dos pinzas de 32 px, una hecha de un ancla `3/4`. La concha tiene **seis grietas** que se corresponden con los seis puntos de escudo (cada golpe en el escudo cierra o abre una grieta: estado legible sin barra). Ojos de tallo en `8`.
- **Cómo se distingue.** La barca. Su ola (Marea, rojo no parable) se anuncia con la criatura **alzándose sobre las patas traseras** y los dos brazos arriba (pose simétrica).
- **Cuerpo y rig.** **Q + P**: cuerpo y patas en una hoja (variante `crab`), pinzas y concha como piezas con pivote. Lienzo 256×160 (hoja grande, recortar).
- **Animaciones.** Cuerpo: `idle 6@5`, `walk 8@8`, `windup 6@10 (+2)`, `strike 6@22` (tenaza, impacto f3), `tide 6@10` (rojo), `roll 6@22` (concha giratoria), `stagger 5@8`, `hit 3@14`, `death 10@10`. Concha: `shell 7@0` (7 estados de grietas).
- **Esfuerzo.** L (8).

### 5.3 La Herida

Desaturación 3; paleta solo neutros (`0 x y w`) más Piedra. **Los bordes pierden resolución**: los enemigos se dibujan a píxeles de 1 px pero con contorno `x` (más claro) y relleno plano, sin sombreado de tres tonos (solo dos). Solo conservan rojo los cascarones (vendas) y los avisos. Es la región más barata de pintar y la que más se lee por silueta.

#### Eco Borrado (`eco_borrado`)

- **Silueta y aspecto.** Cascarón al que le falta el contorno: relleno plano `y`, borde de 1 px en `x` interrumpido en algunos tramos (una pierna sin borde, la cabeza sin trazo). 24×44. Dos vendas rojas `s` (las únicas dos manchas de color). El brazo que golpea tiene el borde completo para destacar. Al teletransportarse, parpadea: 3 fotogramas alternando silueta completa y solo el contorno `x`.
- **Cómo se distingue.** Es un cascarón "mal impreso". Sin sombra proyectada, sin ruido.
- **Cuerpo y rig.** H con **estilo "plano"**: el sombreado a 2 tonos y contorno `x` (opción `flat:true` del rig, ~0,5 día). Lienzo 96×64.
- **Animaciones.** `idle 6@6`, `walk 8@10`, `blink 4@16` (extra: desaparece), `appear 4@16` (extra), `windup 4@10`, `strike 4@26` (impacto f2), `hit 3@14`, `death 5@10` (se borra de abajo arriba).
- **Esfuerzo.** S (2).

#### Contorno (`contorno`)

- **Silueta y aspecto.** Un **trazo negro** `0` de 2 px de grosor que dibuja la silueta de lo que fue (serpiente, mano, pájaro), con un halo `w` a un lado. No hay relleno. 80×40 de ancho en promedio; se mueve como una línea que se dibuja a sí misma, dejando atrás el trazo que se desvanece. Cuando borra el suelo, la línea baja y el decal rojo (rectángulo recto) marca la zona.
- **Cómo se distingue.** Es el único enemigo **sin masa**. No tiene vendas rojas (no hay cuerpo): el rojo aparece solo en el aviso del suelo.
- **Cuerpo y rig.** S (variante `line`) con tres siluetas (serpiente, mano, pájaro) como plantillas de trayectoria. Lienzo 96×64.
- **Animaciones.** `idle 6@6` (la línea tiembla), `walk 8@10`, `windup 4@10`, `strike 4@22`, `hit 3@14`, `death 6@10` (el trazo se deshace en segmentos).
- **Esfuerzo.** M (4).

#### Quimera de Rastros (`quimera`)

- **Silueta y aspecto.** Torso de coloso `x/y` (48×64), con las manos de un lancero (alargadas, con garra) y la **cabeza de un cuervo** (pico enorme `y`, ojo `0`), ensamblada con piezas de otros enemigos: se ven las juntas (costuras rectas en `w`). Una pierna es de cascarón, otra de armadura; las proporciones están mal a propósito. Vendas rojas `s` en el cuello y en un brazo. Punto débil: cabeza.
- **Cómo se distingue.** Desproporción. Su secuencia de ataques copia los tres ataques ya vistos (mazazo, estocada, picado), y **cada uno viene con la pose de su enemigo original**, así que el jugador reconoce lo que va a hacer por la parte que se mueve.
- **Cuerpo y rig.** **A + P**: torso A y cabeza y manos como piezas. Lienzo 192×128.
- **Animaciones.** `idle 6@5`, `walk 8@8`, `windup_maul 6@10`, `strike_maul 6@22`, `windup_spear 4@10`, `strike_spear 5@26`, `windup_peck 4@10`, `strike_peck 4@24`, `stagger 5@8`, `hit 3@14`, `death 8@10`.
- **Esfuerzo.** L (7).

#### Relevo Vacío (`relevo_vacio`, élite)

- **Silueta y aspecto.** Humanoide ágil de 26×54, **máscara azul** `g` lisa (canon del Relevo), túnica corta de lino gris `x/y`, brazalete de hierro `3`, botas ligeras. Se encorva 0,3 s para dar el dash (silueta en "C"). Rastro de dos imágenes residuales cian tenues `f` (el dash). Cinta `s` en el brazo que ataca.
- **Cómo se distingue de su base.** Máscara azul, postura baja y la carrera con estela. La finta se dibuja con un fotograma extra de "casi" (se detiene a medio paso).
- **Cuerpo y rig.** H sobre el rig del jugador (comparte pose de dash). Lienzo 112×64 (igual que el Caminante).
- **Animaciones.** `idle 6@7`, `walk 10@14`, `windup 4@12`, `strike 5@28` (impacto f2), `dash 4@30`, `feint 4@16` (extra), `hit 3@14`, `death 6@10`.
- **Esfuerzo.** S (2).

#### El Doble Vacío (`doble_vacio`, minijefe)

- **Silueta y aspecto.** El Caminante sin color: **misma silueta y proporciones** (24×48) con capa y capucha en `x/y`, ribete `w` en lugar de ámbar, y la máscara sin brillo azul (lisa, `y`). No lleva rojo: su amenaza se lee solo por el aviso. Es el único que usa el rig del jugador **sin** parches propios, aunque con su repertorio fijo de cuatro ataques.
- **Cómo se distingue.** Del Caminante: gris, sin ámbar ni azul, sin sombra proyectada, ojos apagados.
- **Cuerpo y rig.** H = clon del rig del jugador con paleta `x/y/w`. Lienzo 112×64.
- **Animaciones.** `idle 10@7`, `walk 14@16`, `windup 5@12`, `strike 12@30` (impacto f5), `guard 4@12`, `dash 6@30`, `hit 4@14`, `death 8@10`, `speak 4@6` (extra: la línea de diálogo).
- **Esfuerzo.** M (4).

---

## 6. Los diez jefes

Cada jefe es **una persona con nombre y un verbo**, y el arte tiene que mostrar las dos cosas: *quién fue* (un objeto personal que se ve siempre) y *qué hace* (una silueta que cambia con el ataque). Regla común: **los jefes llevan la menor cantidad de rojo posible**; su amenaza se lee por la pose y por la sala. Todos se leen a 160 px por su silueta (a tamaño real 1:1 de pantalla) y se prueban en escala de grises antes de aprobarse.

Convención de fases: la fase 2 añade un **rasgo visual** (rotura, mancha, grieta) sin cambiar de hoja (se pinta una capa de "daño" superpuesta por shader o por fotogramas alternos del mismo dibujo).

### 6.0 El Centinela Hueco (`centinela`, construido)

Referencia de calidad: 384×256 por celda, cuerpo 112×160 (K 1,45 sobre el coloso), 11 filas, hueco ámbar del pecho. Pendiente de arte:

- **`release`** (6 fotogramas a 10 fps): el cascarón sale del hueco del pecho, corre hacia el este (unos 6 pasos, la silueta de Oda: capa corta y zancada larga) y se apaga a mitad de carrera. La coraza queda arrodillada. Esfuerzo M (3), ya contado.
- **Recorte de hoja** (49,5 MB → ~15 MB) y manifiesto: tarea del documento 02, 4.3.
- **Dos barras legibles**: gris para armadura, rojo para núcleo (documento 03, 1.9).

### 6.1 Jacinto, el Último Segador (`jacinto`)

- **Silueta y aspecto.** Hombre alto y encorvado de **34×64** (1,3× el jugador), cuerpo duro de trabajo: antebrazos anchos, manos grandes, espalda curvada, 60 años. Ropa de campo en tierra `5/6/7` con remiendos, sombrero de paja `7` colgado a la espalda con un cordón (símbolo de que "ya no hay sol"), faja `s` roja apagada en la cintura (la única nota de rojo, sobre `r`). Cabeza descubierta, pelo blanco `w/8`, barba corta. La **hoz** es la silueta: mango de 70 px y hoja de 60 px curvada, con la hoja en `4` y el filo en `w`. Atada al mango lleva una espiga seca `7` (lo que segaba). Chaqueta de niño anudada a la cintura (es de Eloy) en `6`, el detalle emocional.
- **Cómo se lee la amenaza.** El **arco** manda. El `windup` de la Vuelta amplia lo agacha hasta la rodilla con la hoz arrastrando: silueta baja y ancha, simétrica (los dos brazos juntos): **parable por excepción**, y por eso lleva una estela de trigo `7` detrás de la hoja que dibuja el radio de 130 px (VFX). El Paso de segador es asimétrico (hoz atrás a una mano). Los avisos rojos (picado, Tres vueltas final) se anuncian trepando o con los brazos arriba sobre la cabeza.
- **Partes.** Sin armadura. Sin núcleo. La vida se lee por el desgaste: en fase 2 pierde el sombrero (cae al suelo) y se le abre la camisa; en fase 3 la hoz pierde la punta y el cordón del sombrero cuelga.
- **Canon.** Jacinto Ferrán, segador de un campo vacío. La era vuelve a tener trigo al final: una animación `release` en la que se apoya en el muro (postura del agarre) y brotan 6 espigas `7/d` que mueren en un parpadeo.
- **Cuerpo y rig.** H con `scythe` grande, `crouch`, `armsUp`, cabeza descubierta con barba, sombrero como pieza colgante (`trailChain`). Lienzo 224×128. Trepa: se usa el pose de agarre del jugador con proporciones de Jacinto.
- **Animaciones (17 filas).** `idle 8@6`, `walk 8@10`, `windup_low 5@10`, `swing_low 6@26`, `windup_spin 6@10 (+2)`, `spin 10@28`, `step_slash 6@24`, `throw 5@12`, `catch 4@14`, `climb 6@12`, `wall_hold 2@6`, `dive 5@22`, `summon 6@10`, `hit 3@14`, `stagger 5@8`, `death 10@10`, `release 8@8`.
- **Esfuerzo.** L (10).

### 6.2 Sor Ilara, la Copista (`ilara`)

- **Silueta y aspecto.** Mujer de **30×60**, estrecha, con hábito gris azulado `2/3` hasta el suelo, tocado ancho de lino `8` caído sobre un hombro y **manchas de tinta** `e/1` en dedos, puños y el borde del hábito (cuanto más abajo, más tinta). Pluma de hierro de **90 px** de largo en la mano derecha (en reposo, como un bastón fino), un libro grande con tapas `5/6` en la izquierda. Ojeras de tinta `e` bajo los ojos y una pluma menor detrás de la oreja. Rojo: una cinta `s` en el hábito, mínima.
- **Cómo se lee la amenaza.** La pluma es el alcance (200 px). **Las copias** son su identidad: un silueta idéntica en azul tinta `e/f/g` translúcida (alfa 0,55) con un **trazo** `h` entre la copia y Ilara (línea de tinta). Cuando alza el libro para la Lista (remate), los dos brazos suben: silueta simétrica y aviso rojo.
- **Partes.** Sin armadura. Fase 2: la tinta le gotea desde el puño; fase 3: el hábito está casi negro de tinta y el libro, en blanco.
- **Canon.** La mejor copista; cuanto más copió menos nombres le quedaron. Final: la última página copiada es una hoja en blanco `w`, la cámara se queda en ella. Animación `death` termina con ella mirando una hoja vacía.
- **Cuerpo y rig.** H con `robe`, `quill` larga, libro en la mano izquierda. Las **copias** reutilizan los fotogramas con tinte y alfa (sin hoja nueva). Lienzo 192×128.
- **Animaciones (13 filas).** `idle 8@6`, `walk 8@9`, `windup_pluma 5@10`, `pluma 5@26`, `throw_page 5@12`, `cast_drops 6@10 (+2)`, `vanish 5@16`, `appear 4@16`, `lift_desk 6@10`, `raise_book 7@10 (+2)`, `hit 3@14`, `stagger 5@8`, `death 10@10`.
- **Esfuerzo.** L (10). La parte de copias es código, no arte.

### 6.3 Hesper, el Prior (`hesper`)

- **Silueta y aspecto.** Hombre de 47 años, **32×62**, que **levita**: el hábito ocre `b/6` cae hasta unos centímetros del suelo y ondea sin tocarlo (`robe` + `hover`). Casulla ocre con **sello partido** cosido en el pecho (`8`), cuello alto, manos enguantadas de cera `8` con anillos de lacre. Cabeza descubierta, pelo gris cuidado, rostro amable y cansado (lo único amable del Archivo); a la espalda, una capa de lacre `r/s` en forma de **gran sello de cera** (un círculo de 40 px que gira detrás de la cabeza como un halo, atado al hombro). Rojo: el sello trasero es la única superficie roja `s/t`, y es decorado del personaje, no aviso; por eso en el aviso el sello se **apaga** (pasa a `r`) y el aviso se pinta en el suelo.
- **Cómo se lee la amenaza.** Cuando sella, extiende **las dos manos al suelo** con el sello trasero girando más rápido: silueta simétrica y aviso rojo. Cuando ataca con la Mano de cera, un solo brazo con un cuchillo de lacre largo (parable).
- **Partes.** Sin armadura. Los bloques de lacre del suelo son sprites sueltos (2×3 baldosas, 3 estados de grieta). Fase 2: el hábito empieza a mancharse de cera; fase 3: el sello trasero se resquebraja.
- **Canon.** Novicio que calló. Final: su sello se resquebraja y se vacía el ala (la animación `death` termina en el sello partido en el aire que cae).
- **Cuerpo y rig.** H con `robe`, `hover`, `mask` descubierta (rostro amable `bare`), sello trasero como pieza. Lienzo 192×128.
- **Animaciones (8 filas).** `idle 8@5` (levita), `cast_seal 6@10 (+2)`, `dagger 5@24`, `call 6@10`, `drops 6@12`, `drop_pillar 6@10`, `stagger 5@8`, `death 10@10`. Más `hit 3@14` (extra).
- **Esfuerzo.** M-L (8).

### 6.4 Casimar, el Rey sin Reina (`casimar`)

- **Silueta y aspecto.** Hombre corpulento de **48×72**, enorme y hundido, con un manto de rey de pieles `5/6` ya podridas sobre un traje de brocado en `5/6` con hilos de paja `7` (sin ámbar: la riqueza se lee por el volumen y el bordado, no por el color). Corona rota `3/4` de la que cuelgan dos puntas, sostenida sobre el pelo largo `x/y`. En los brazos **abraza una página** grande `w` (24×32) contra el pecho: es Áurea. Un cetro de hierro `3/4` de 90 px con cabeza de martillo (golpea, no es decorativo). Rostro hundido, barba, ojos `8` muy abiertos. Rojo: una cinta `s` de la corona.
- **Cómo se lee la amenaza.** Su `windup` del Cetro es lentísimo (1,0 s): el cetro sube por encima de la cabeza a dos manos (**parable por excepción** de peso) y el cuerpo entero se echa atrás. El **abrazo** (inmunidad) se lee: encoge los hombros y cruza ambos brazos sobre la página; hay un halo `w` suave de 2 px en la página mientras se cura. Es el estado "no ataques".
- **Cortesano (acompañante de la sala).** Cascarón de 22×44, traje de gala `8/9` raído, **abanico** en la mano (un semicírculo `w`), máscara de sonrisa tallada `8`, vendas `s` en el abanico. 4 filas: `idle 6@6`, `clap 4@10` (aplaude), `fan 5@24`, `hit/death`.
- **Partes.** Sin armadura. Coro y aplauso son entidades externas.
- **Canon.** Casimar ordenó el Cavar por Áurea. Final: la página se deshace (se pierde en motas `w`) y se oye reír a una mujer.
- **Cuerpo y rig.** H grande (`Z` 1,3, hombros anchos) con `crown`, `scepter` (`maul` modificado) y pieza de página como accesorio. Trono: sprite de escenario 96×112. Lienzo 224×160.
- **Animaciones (9 filas Casimar + 4 cortesano).** Casimar: `idle 8@4` (sentado), `stand 6@8`, `walk 8@7`, `windup_cetro 7@10 (+2)`, `cetro 5@22`, `decreto 6@10`, `embrace 4@8` (bucle de curación), `hit 3@14`, `stagger 5@8`, `death 12@10`.
- **Esfuerzo.** L (9).

### 6.5 Magda Soler, la Capataz (`magda`)

- **Silueta y aspecto.** Mujer robusta de **40×64**, hombros anchos, brazos de picadora, 50 años. Casco de minera con cresta (`miner`) y candil apagado, chaqueta de lona `5/6` con **tarjeta de turno** clavada (rectángulo `8` con rayas), botas de clavos, guantes de cuero `5`. Cabello gris recogido. El **pico** es enorme: mango de 80 px, cabeza de hierro `3/4` de 30 px; el arma se lee como una "T" al hombro. Acento mineral `f` en la punta. Rojo: una cinta `s` en el casco (el color de su cuadrilla).
- **Cómo se lee la amenaza.** Golpe vertical: el pico por encima de la cabeza a dos manos; Golpe Hondo (rojo): **clava el pico en el suelo** y el cuerpo se queda agachado y simétrico, con el decal de losas parpadeando en rojo. La carga (rojo): hombro adelantado y cuerpo inclinado 40°.
- **Partes.** Sin armadura. El pico clavado es un estado (la mano queda sobre el mango, 1,6 s: exposición). Fase 2: pierde el casco; fase 3: la chaqueta rota y la tarjeta de turno colgando.
- **Canon.** Última orden de cavar; la primera en oír el Latido. Final: deja el pico y camina hacia el jugador (animación `drop_pico` + `walk`).
- **Cuerpo y rig.** H robusto (`pick`, `miner`, escala `Z`). Lienzo 224×144. Losas frágiles y vigas: sprites de escenario con 3 estados.
- **Animaciones (12 filas).** `idle 8@6`, `walk 8@9`, `windup_pico 6@10 (+1)`, `pico 5@24`, `sweep 5@26`, `plant 6@10 (+2)`, `pull 5@12`, `charge 6@20`, `hit 3@14`, `stagger 5@8`, `death 12@10`, `drop_pico 8@8`.
- **Esfuerzo.** L (9).

### 6.6 Rufo, el Farero (`rufo`)

- **Silueta y aspecto.** Hombre delgado y reseco de **28×56**, curtido de humo, con un **delantal de cuero** `5` chamuscado, manguitos de lona, barba corta amarillenta `7`. Lleva un guante de soldador `3` y una **barra de tizón** (hierro al rojo) de 60 px: es el único con hierro en brasa visible (`t/u` en la punta, **permitido porque es un arma enemiga encendida**, y se enciende solo durante el `windup`). Un hatillo de cartas quemadas a la cintura (papel `8` con bordes `1`) y un juguete roto asomando (el detalle emocional). Gorra de marinero `x` caída. Rojo: la punta del tizón.
- **Cómo se lee la amenaza.** Es el jefe más pasivo: ataca poco y se esconde en la sombra de la lente. El peligro son los espejos. Por eso **el cuerpo de Rufo es oscuro** `1/2` y lo único claro es la punta del tizón: se pierde en la sala (a propósito) y la atención va a los espejos.
- **Partes.** Sin armadura. **Elementos de sala**: 4 espejos de 32×32 con 4 ángulos (0, 45°, 90°, 135°) y 3 estados (reposo: marco `3` y cristal `x`; cargando: marco `y` y centro `w`; disparando: centro `t`), una **lente** central de 128×128 como pieza de escenario.
- **Canon.** Guardián del faro; quema lo que los Descreídos quieren soltar. Dilema: vencerlo no resuelve nada, así que la `death` es sin cámara lenta: se sienta junto a la lente y deja caer el tizón.
- **Cuerpo y rig.** H con `ember` (barra de tizón). Lienzo 160×96. Espejos: sprites de objeto (rotación por pasos).
- **Animaciones (7 filas).** `idle 8@5`, `walk 8@9`, `tizon 5@24`, `throw 5@12`, `dazzled 4@8`, `hit 3@14`, `death 8@10`. Espejo: `idle`, `charge 4@8`, `fire 3@20`, `turn 4@14`. Lente: `idle 4@3`, `sweep 8@14`.
- **Esfuerzo.** M (6).

### 6.7 Eudora, la Piadosa (`eudora`)

- **Silueta y aspecto.** Mujer de **28×60**, serena, de unos 60 años, con **lino blanco** `8/9/w` hasta los pies, plisado y manchado de cal, manos tiznadas de cal `w` hasta el codo y **el rostro descubierto** (a diferencia de sus Hermanos): rasgos suaves, pelo blanco largo. Levita unos píxeles (`hover` ligero). Un **cordón de cáñamo** `6` en la cintura con un nudo (por Mateo, que ya no sabe). **Cero rojo en el cuerpo**: el aviso se lee en el suelo. Alrededor suyo, un **anillo de Calma** `9/w` de 3 px, de radio 38 px, que **gira despacio** y se rompe en fragmentos cuando la Calma baja a 0 (estado inquieto: el anillo se agrieta y ella parpadea).
- **Cómo se lee la amenaza.** Todo es lento y simétrico: brazos abiertos (Nana), dos manos en la cintura (Círculo), una mano hacia delante (Mano abierta, parable, la única asimétrica). El jugador tiene que aprender que **aquí lo simétrico no es siempre rojo**; para evitar el conflicto con la regla de la simetría, los ataques de Eudora que sean parables llevan la mano abierta delante, y el decal del suelo de los rojos es un círculo de cal con borde rojo.
- **Partes.** Calma (anillo) y vida (cuerpo): el anillo es el equivalente a la armadura del Centinela y se pinta como pieza aparte (24 fotogramas del anillo por estados 100/75/50/25/0 con un shader de ángulo).
- **Canon.** Practicó el Primer Olvido con cal para dejar de recordar a Mateo. Al morir, **olvida al jugador y le sonríe** (`smile`).
- **Cuerpo y rig.** H con `robe`, `lino`, `hover`, cabeza descubierta `bare` con pelo largo, anillo como pieza. Lienzo 160×112.
- **Animaciones (11 filas).** `idle 8@5`, `walk 8@7`, `draw_circle 6@10 (+2)`, `hand 6@12`, `sing 6@8`, `embrace 6@10 (+2)`, `call 6@10`, `hit 3@14`, `stagger 5@8` (inquieta), `death 10@10`, `smile 6@6`.
- **Esfuerzo.** L (8).

### 6.8 Maelis, la Priora Sellada (`maelis`)

- **Silueta y aspecto.** **Busto de piedra** que emerge de la pared del fondo, con **rostro** de 128×160 (la cara de una mujer de 60 años, labios cerrados, ojos cerrados, el cabello recogido en piedra `2/3`, grietas `1`), y **dos manos enormes** de 128×112 (cada una, ocho baldosas), de piedra `2/3/4` con **lacre `r/s`** en las uniones de los dedos y venas de lacre en las muñecas. El busto lleva el hábito de Priora en relieve y, en el pecho, un **sello partido** `0/1` con un hueco. Las manos tienen dedos largos y falanges visibles: **cuatro dedos y un pulgar**, con un hueco de 24 px entre los dedos (el "hueco entre dedos" que salva del Cierre). Los ojos cerrados se abren solo en la última fase (dos puntos `w`).
- **Cómo se lee la amenaza.** Es una **pared**. Todo lo rojo es del suelo: la sombra de la mano que cae, las gotas de lacre. La palma que aplasta se anuncia con la mano **abierta y plana** sobre la zona (simétrica con el eje del brazo). El Cierre (remate): las dos manos se curvan hacia dentro, dejando un hueco entre los dedos marcado con un trazo en blanco `w` en el suelo.
- **Partes.** Tres: mano izquierda (24 pts), mano derecha (24), rostro (32). **Cada una es una pieza con su hoja y su barra** (`hurt_zone`); romper una mano es un fotograma de rotura (cae un trozo) y un estado de `broken` (muñón con lacre goteando); el rostro tiene `idle` (ojos cerrados), `hit` (se resquebraja un tramo) y `death`. Al caer las manos se deshacen en polvo, sin gesto.
- **Canon.** Selló a Aún con sus manos y luego a sí misma; no dice una palabra. Las manos que sostenían dejan de sostener.
- **Cuerpo y rig.** **P**: tres hojas pequeñas (rostro, mano, mano espejada) más un `AnimationPlayer` con rotaciones por pasos de 15°. La mano izquierda es la derecha espejada con el lacre en otra posición. Sala: sillas con máscaras azules (5 sprites de 32×48, la sexta vacía).
- **Animaciones.** Rostro: `idle 6@3`, `hit 3@14`, `death 10@8`, `open_eyes 4@8`. Mano (×2): `idle 6@4`, `sweep 5@22`, `palm 6@10 (+2)` (aviso rojo), `close 6@10`, `fist 5@22`, `hurt 4@12` (hundida 2,0 s), `break 8@10`.
- **Esfuerzo.** XL (14).

### 6.9 Oda, la Última Mensajera (`oda`)

- **Silueta y aspecto.** El **Rastro de la prisa** de Oda Bellver, no su cuerpo: una silueta en la **rampa azul** `e/f/g/h`, 24×50, translúcida (alfa 0,8) con el borde `h` casi blanco, sin rostro: solo una forma de capucha corta de mensajera y una **coraza ligera** que se insinúa (placas en `g` que se desvanecen hacia los pies). Capa corta que ondea hacia atrás con una cadena de 5 segmentos, bandolera con una carta `w` en la cadera. La **insignia de pie alado** en el pecho, de 6×6 px `h`. Piernas largas, de **zancada enorme**. Cero rojo, cero ámbar.
- **Cómo se lee.** Todo lo que no es combate: no hay `windup`. Sus gestos (parar a mitad del hueco y repetir) son la señal. Deja una **estela de azul** `f` de 3 imágenes residuales. Cuando espera, se queda de pie, mirándote.
- **Partes.** Ninguna.
- **Canon.** El Rastro de su prisa; el Centinela la tenía dentro. Entrega la insignia al final, la animación `hand` (extiende la mano con la insignia).
- **Cuerpo y rig.** H = clon del rig del jugador con carrera más larga y paleta azul. Lienzo 112×64.
- **Animaciones (6 filas).** `idle 8@6`, `run 10@18`, `dash 6@30`, `jump 4@14`, `wait 6@6`, `hand 6@8`.
- **Esfuerzo.** S (3).

---

## 7. Las arenas de jefe vistas como arte

### 7.1 Reglas comunes de arena

Aplican la biblia visual (documento 01) y la regla 5 del diseño de combate ("la arena se lee de un vistazo"):

1. **Contraste de sala de jefe.** El fondo de una arena baja un tono respecto al de la región (tono 1 casi todo) y el **suelo mantiene el labio de luz** en tono 4. Es lo único claro además del jefe. El jugador y el jefe se recortan sobre un fondo más oscuro que el de las salas normales.
2. **El suelo es el cuadro de mando.** Todo aviso rojo se pinta **en el suelo o en el aire sobre el suelo**, no en el fondo: decals de borde recto y dos tonos (`t` relleno con rayas diagonales `u`), el mismo lenguaje en las nueve arenas. Los avisos amarillos (parables) son un tinte sobre el jefe, nunca un decal.
3. **Ninguna decoración roja ni ámbar de peligro.** Los ámbar de la sala (faroles, ventanas) son estables y pequeños. Lo que parpadea es peligro.
4. **Rastrillos o cierres visibles** (`arena_gate`) con la misma pieza en todas las arenas: reja de hierro `3/4` con aros de remache. Aprende el jugador "esto se cierra".
5. **Pose antes que color en la lejanía.** Los bordes de pantalla tienen primer plano oscuro (columnas, vigas) para encuadrar; ninguno tapa el suelo.
6. **Un solo foco narrativo** por sala (la hoz, el libro, el sello, el trono, el pozo, la lente, el mar, la silla), iluminado por la única luz cálida de la sala.

### 7.2 Las nueve arenas

**La Era (Jacinto).** 48×22 baldosas. *Composición:* un disco de trillar de piedra clara en el centro (el único suelo en tono 4 completo), dos muros de bancal de piedra seca de 14 baldosas que enmarcan a izquierda y derecha, y detrás un cielo abierto con el horizonte a un tercio. *Fondo:* colinas escalonadas muy lejanas, torres de riego, seis espantapájaros de decorado (palo recto, ojos negros `0`) en la línea media, y trigo seco `7` que ondea con el viento en primer plano. *Luz:* mediodía lavado sin sol, sombras largas hacia abajo; la única nota cálida es la hoz de Jacinto con el reflejo `d`. *Peligros:* la sombra de la Trepa es un óvalo rojo; los muros muestran **muescas verticales** (son escalables, como en las paredes de salto de pared del documento 01). *Parable / no parable:* los arcos de hoz (parables) llevan una estela de trigo; el rojo es solo la sombra del picado y la tercera vuelta.

**El Scriptorium Callado (Ilara).** 56×26. *Composición:* una gran mesa central de 10 baldosas como isla elevada y ocho pupitres en dos filas que sirven de plataformas; el techo con vigas se pierde en la oscuridad. *Fondo:* estanterías-torre en perspectiva, ventanales altos con **haces de luz polvorientos** `8`, plumas colgadas del techo. *Luz:* haces verticales fríos y velas pequeñas en los pupitres. Los pupitres que se borran se **pintan de tinta** `e` antes de desvanecerse (1,0 s): el jugador ve el cambio en el color de la superficie. *Peligros:* los tachones son círculos oscuros `1` con borde rojo en el suelo (rojo no parable); las copias son siluetas azul tinta con un trazo hasta Ilara. *Parable / no parable:* Pluma (amarillo en la mano) frente a Tachón (rojo en el suelo). Una copia **se lee como atacante** por el trazo que la une a Ilara.

**El Salón de Sellado (Hesper).** 60×30. *Composición:* estanterías-torre en los extremos, un **sello de cera gigante** (decorado, 160 px de diámetro) en el centro del techo y cuatro pilares de lacre rompibles; dos escalones laterales a 3 baldosas. *Fondo:* arcos apuntados, sellos azules de las salas de sellado en las paredes (`f/g` tenues), cortinajes. *Luz:* luz azul tenue de las runas y velas ámbar pequeñas; el sello gigante lleva un **halo rojo apagado** `r` que se enciende (tinte `t`) cuando Hesper sella. *Peligros:* los Sellos del suelo son círculos con símbolo en `t/u`, siempre con la **marca de un sello partido** al centro; los bloques de lacre (sprites) tienen grieta visible `1`: golpeables. *Parable / no parable:* la Mano de cera es un destello amarillo en el cuchillo; Sello, Estampa y Cierre, rojos. Hesper levita sobre una sombra ovalada en el suelo (para saber su posición vertical).

**El Trono Hundido (Casimar).** 52×28. *Composición:* un trono al fondo sobre tres escalones, dos filas de **gradas laterales** donde se sientan los cortesanos, alfombra raída `s/r` en el centro (la única superficie roja grande de la sala, decorado muy apagado `r`; excepción de la regla de rojo: se **desatura al máximo** y el aviso rojo de suelo se separa de ella con borde blanco `w`). *Fondo:* bóveda alta con pasarela, tapices rotos `x`, columnas con la cara de la reina tallada y borrada. *Luz:* una sola luz cálida (un candelabro caído) a los pies del trono. *Peligros:* el Decreto (rojo) es una fila de losas que parpadea en `t/u` con **borde `w`** para separarse de la alfombra. *Parable / no parable:* Cetro (amarillo, a dos manos pero parable por su aviso largo) y Corona (rojo, seis puntos de luz dorada `7` pintados en el suelo en abanico antes de salir).

**La Cámara de Apuntalamiento (Magda).** 56×34. *Composición:* dos niveles: suelo principal con **losas frágiles** y debajo una galería de 6 baldosas de profundidad con pinchos solo en los extremos; en el centro, el **pozo** de 8 baldosas de ancho; seis vigas de madera que sostienen el techo. *Fondo:* roca estratificada, raíles que bajan, farolillos ámbar de la Orden muy pequeños, un **reflejo rojo lejano** en el fondo (el Latido; único rojo de decorado en el juego, justificado por canon y limitado a 6×6 px que pulsan con el Latido). *Luz:* oscuridad casi total (desaturación 2); los minerales y la linterna del jugador. *Peligros:* las losas por romper **agrietan en amarillo** `d` 0,4 s antes y pasan a rojo parpadeante si el Golpe Hondo las va a romper; el techo que cae lleva polvo fino (aviso 0,4 s) y un círculo de sombra en el suelo. *Parable / no parable:* el Pico (amarillo en el pico); Golpe Hondo y Carga (rojos, suelo marcado).

**El Faro de las Velas (Rufo).** 44×34. *Composición:* sala de la lámpara circular con una gran **lente** central, una plataforma circular de hierro `3/4` y **cuatro espejos** en los bordes con ángulo visible. *Fondo:* noche, mar con horizonte y rayas de espuma `9`, nubes en bandas; las velas rasgadas fuera de las ventanas. *Luz:* la lente y los haces; el resto, en sombra. Los **haces** son líneas de 3 px: aviso amarillo fino `d` (0,8 s) y haz rojo `t/u` (0,5 s); la sombra detrás de cada espejo es un rectángulo `1` plano que se **lee como refugio**. *Peligros:* solo los haces, el tizón y las brasas. *Parable / no parable:* la Barra de tizón (amarillo); todo lo que sea luz es rojo no parable.

**El Rellano de Cal (Eudora).** 60×28. *Composición:* abierto al mar por el lado derecho, plataformas de cal blanca `8/9`, **círculos de cal** pintados en el suelo que aparecen y desaparecen. *Fondo:* mar con horizonte, cielo despejado con luz clara, gaviotas lejanas (siluetas, no partículas). *Luz:* **la sala más clara del juego**: luz de día, sin sombras duras; los círculos de cal `w` brillan suavemente. El contraste con el resto de arenas es intencionado: el peligro es la calma. *Peligros:* el círculo de aviso es blanco con **borde rojo fino** y bandas diagonales (la combinación "blanco + rojo" se reserva para ella); la Nana es una lluvia de partículas `w` con un hueco visible. *Parable / no parable:* Mano abierta (amarillo en la mano); Círculo, Abrazo y Olvido (rojos).

**La Sala del Asiento (Maelis).** 64×36, circular. *Composición:* cinco sillas con máscaras azules `g` en círculo y una sexta vacía al fondo con la medida del Caminante; suelo de baldosas con **lacre incrustado** `s/r` en rosetones; Maelis (busto y manos) emerge de la pared del fondo. *Fondo:* paredes de piedra plana `x/y` (sin textura), sin parallax; el blanco sin origen de la Herida en el techo. *Luz:* blanca sin fuente, sin sombras, **sin halos**: la única mancha de color son las máscaras azules de las sillas y el Caminante. *Peligros:* la sombra de la mano que cae es un óvalo rojo grande con el hueco entre los dedos marcado en blanco `w`; las gotas de lacre son puntos de 2 baldosas. *Parable / no parable:* casi todo es rojo y de suelo; el único aviso amarillo es el golpe contra la pared (Mano cerrada). El **lacre que fija** es un charco ya pintado en el suelo (no aparece de golpe): se lee por quieto.

**La Pasarela de los Mensajeros (Oda).** Los tres huecos de 17 baldosas. *Composición:* la pasarela con un **velo** sobre el abismo (los pinchos se retraen: sobre el velo hay una trama de líneas `w` 1 px, como un papel rayado). *Fondo:* cielo abierto sobre el abismo, mojones de mensajeros (pie alado) a lo largo del camino, cartas clavadas en las vigas. *Luz:* amanecer frío; el Rastro de Oda es la única luz azul. *Peligros:* ninguno. Los tres puntos de control son mojones con una carta. *Parable / no parable:* no aplica. La **estela azul** de Oda es la guía; cuando espera, se queda de pie y el decal de su siguiente salto aparece como una línea de puntos `h`.

### 7.3 Nota: la arena de referencia

El Aljibe (Centinela) ya sigue estas reglas salvo el borde `w` entre avisos y decorado; se le añade al retoque `release` como tarea de 1 punto (revisión de decals).

---

## 8. VFX propios de cada jefe

Se hacen con `CPUParticles2D`, polígonos en `_draw` y sprites sueltos de la hoja de efectos, no con sprites de partículas (documento 02, 2.6). Tope: 20 partículas por impacto y 200 vivas en pantalla (documento 03). Coste: B bajo, M medio, A alto.

| Jefe | Impacto | Ataque especial | Muerte |
|---|---|---|---|
| **Centinela** | Polvo y grietas (existen); chispas `d` en armadura (B) | Rocas con polvo de aviso (existe); brasas `t/u/c` ascendentes (B) | `release`: la figura corre y se apaga en motas `h` (M) |
| **Jacinto** | Corte de trigo: 5 briznas `7` que saltan en el impacto (B) | Estela de trigo `7` en el arco de la hoz (arco aparte de 8 fotogramas, M); onda de polvo al aterrizar el picado (B) | Brotan 6 espigas `7/d` que se apagan; hoz que se deshace en paja (M) |
| **Ilara** | Salpicadura de tinta `e` (6 gotas con gravedad) (B) | Copias: silueta translúcida y trazo `h` entre copia e Ilara (M); gotas de tinta que dejan charco (B); lluvia de la Lista (A: 3 oleadas de 4 gotas con aviso) | Se deshace en hojas `w`; la última hoja queda flotando en blanco 2 s (M) |
| **Hesper** | Fragmentos de cera `8/s` al romper un bloque, en cámara lenta 0,12 s (M) | Sello: círculo de lacre con símbolo (decal animado de 5 fotogramas) y bloque que emerge (M); Estampa: sombra y polvo (B); Cierre: cuatro sellos a la vez (M) | El sello trasero se resquebraja y cae en trozos; el ala se vacía (pasillos que se borran por tramos) (A) |
| **Casimar** | Chispa de oro `7` al golpear el cetro (B) | Decreto: onda de losas en fila con grietas (M); Corona: seis proyectiles dorados `7` en abanico con aviso en el suelo (M); halo `w` de curación al abrazar (B) | La página se deshace en motas `w`; sonido de risa; no hay explosión (M) |
| **Magda** | Esquirlas `3/4` y polvo del pico (B) | Golpe Hondo: onda de suelo con grietas amarillas→rojas (M); losas que se hunden (sprite de 3 estados); techo que cae con polvo de aviso (M); Latido: onda circular desde el pozo (M) | Deja el pico; polvo asentándose; sin cámara lenta (B) |
| **Rufo** | Chispas del tizón `u/d` (B) | Haces: línea amarilla fina→roja con "ruido" de luz (A: 4 haces con reflejo y deslumbramiento de pantalla acotado al 0,15 s); brasas con fuego en el suelo (M) | Se sienta y deja caer el tizón; la lente baja su brillo; sin cámara lenta (B) |
| **Eudora** | Motas de cal `w` que flotan y se disuelven (B) | Círculo de cal con borde rojo (decal, M); Nana: lluvia de partículas `w` con hueco (M); estado Olvido: **difuminado de la barra de vida** (UI, A); anillo de Calma que se rompe (M) | Olvida al jugador: la imagen se desatura un 40 % y ella sonríe; se desvanece en cal `w` (M) |
| **Maelis** | Polvo de piedra y grietas en las manos (B) | Palma: sombra roja y onda (M); Corriente de lacre: partículas `s` hacia el asiento (M); gotas de lacre (B); Cierre: manos que se cierran con polvo masivo (A) | Las manos se aflojan y caen en bloques con polvo; **sin cámara lenta ni fanfarria** (M) |
| **Oda** | — | Estela azul de 3 imágenes residuales `f` y línea de puntos de siguiente salto (B) | Se detiene, extiende la mano y entrega la insignia: un destello suave `h` (B) |

**Comunes con VFX propio** (breve): Sellador (charco de lacre en el suelo, decal con 3 estados de limpieza), Penitente (nube de ceniza al morir), Hondo (llama en el suelo, roja `t/u`, no ámbar), Geoda (esquirlas y explosión de aviso rojo), Hermano de Cal (círculo de cal `w` con borde rojo), Vela Errante (zona de luz circular que se agranda), Eco Borrado (parpadeo de silueta y contorno), Contorno (borrado del suelo en un rectángulo recto), Zapador (mecha y explosión). Todos reutilizan los mismos decals (círculo, rectángulo, sector) con tamaño y color de aviso.

---

## 9. Tabla resumen de los 43 diseños

Sig.: tipo H/A/Q/V/S/P; "Anim." = filas × fotogramas totales aproximados (sin contar `death` salvo en los comunes); esfuerzo en puntos. (Los cinco comunes construidos, `cascaron`, `lancero`, `arrojador`, `acechador` y `coloso`, solo reciben la fila `death`: 5 puntos en total; no aparecen en la tabla.)

| # | Id | Nombre | Región | Cat. | Tipo | Lienzo | Animaciones principales | Esf. |
|---|---|---|---|---|---|---|---|---|
| 1 | `cuervo` | Cuervo de Rastrojo | Cinturón | común | V | 64×48 | idle, walk, windup, strike, hit, death | M 4 |
| 2 | `espantapajaros` | Espantapájaros | Cinturón | común | H | 96×64 | idle, wake, walk, windup, strike, hit, death | S 2 |
| 3 | `mastin` | Mastín sin Amo | Cinturón | común | Q | 96×64 | idle, walk, alert, windup, strike, hit, death | S 2 |
| 4 | `segador` | Segador Vaciado | Cinturón | élite | H | 160×80 | idle, walk, windup, strike, step, hit, death | S 2 |
| 5 | `yunta` | La Yunta | Cinturón | minijefe | Q | 192×96 | idle, walk, windup, strike(charge), kick, plough, stagger, hit, death | L 7 |
| 6 | `novicio` | Novicio Borrado | Archivo | común | H | 144×64 | idle, walk, windup, strike, hit, death | S 1 |
| 7 | `sellador` | Sellador | Archivo | común | H | 96×64 | idle, walk, throw, windup, strike, hit, death | S 2 |
| 8 | `penitente` | Penitente | Archivo | común | H | 144×64 | idle, walk, windup, strike, selfhit, hit, death | S 2 |
| 9 | `armadura_vacia` | Armadura Vacía | Archivo | común | A | 144×64 | idle, walk, windup, strike, guard, lower, stagger, hit, death | M 4 |
| 10 | `polilla` | Polilla de Archivo | Archivo | común | V | 64×48 | idle, walk, windup, strike, perch, hit, death | S 2 |
| 11 | `pez_plata` | Pez de Plata | Archivo | común | S | 64×48 | idle, walk, windup, strike, split, hit, death | M 3 |
| 12 | `relator` | Relator Hueco | Archivo | élite | H | 144×96 | idle, walk, summon(windup), strike, hit, death | S 2 |
| 13 | `custodio_mayor` | Custodio Mayor del Pasillo en Blanco | Archivo | minijefe | A | 192×128 | idle, walk, windup, strike, bash, spin, guard, stagger, hit, death | L 7 |
| 14 | `cavador` | Cavador Vaciado | Minas | común | H | 144×64 | idle, walk, windup, strike, dig, hit, death | S 2 |
| 15 | `chinche` | Chinche de Roca | Minas | común | Q | 64×48 | idle, walk, windup, roll, unroll, hit, death | M 3 |
| 16 | `gusano_veta` | Gusano de Veta | Minas | común | S | 64×64 | idle, emerge, windup, strike, retreat, hit, death | M 4 |
| 17 | `murcielago` | Murciélago de Cueva | Minas | común | V | 64×48 | idle, walk, windup, strike, hit, death | S 2 |
| 18 | `hondo` | Hondo | Minas | común | H | 96×64 | idle, walk, windup, strike, retreat, hit, death | S 2 |
| 19 | `geoda` | Geoda Saturada | Minas | común | Q/P | 96×64 | idle, open, windup, strike, close, hit, death | M 4 |
| 20 | `zapador` | Zapador Eterno | Minas | élite | H | 144×96 | idle, walk, windup, strike, fuse, hit, death | S 2 |
| 21 | `madre_veta` | Madre de Veta | Minas | minijefe | S+P | cabeza 128×96, segmento 64×64 | idle, emerge, windup, strike, spit, stagger, hit, death; bolsa idle/burst | XL 12 |
| 22 | `hermano_cal` | Hermano de Cal | Costa | común | H | 96×64 | idle, walk, paint, push, hit, death | S 2 |
| 23 | `acompanante` | Acompañante | Costa | común | H | 96×64 | idle, walk, calm, windup, strike, hit, death | S 2 |
| 24 | `gaviota` | Gaviota Rapaz | Costa | común | V | 64×48 | idle, walk, windup, strike, hit, death | S 1 |
| 25 | `cangrejo` | Cangrejo Ermitaño | Costa | común | Q | 96×64 | idle, walk, hide, windup, strike, naked, hit, death | M 4 |
| 26 | `vela_errante` | Vela Errante | Costa | común | V | 48×48 | idle, walk, windup, strike, hit, death | S 2 |
| 27 | `hermano_antiguo` | Hermano de Cal Antiguo | Costa | élite | H | 144×96 | idle, walk, paint, strike, hit, death | S 2 |
| 28 | `ermitano_mayor` | El Ermitaño Mayor | Costa | minijefe | Q+P | 256×160 | idle, walk, windup, strike, tide, roll, stagger, hit, death; concha ×7 | L 8 |
| 29 | `eco_borrado` | Eco Borrado | Herida | común | H (plano) | 96×64 | idle, walk, blink, appear, windup, strike, hit, death | S 2 |
| 30 | `contorno` | Contorno | Herida | común | S (línea) | 96×64 | idle, walk, windup, strike, hit, death | M 4 |
| 31 | `quimera` | Quimera de Rastros | Herida | común | A+P | 192×128 | idle, walk, 3 pares windup/strike, stagger, hit, death | L 7 |
| 32 | `relevo_vacio` | Relevo Vacío | Herida | élite | H (rig jugador) | 112×64 | idle, walk, windup, strike, dash, feint, hit, death | S 2 |
| 33 | `doble_vacio` | El Doble Vacío | Herida | minijefe | H (rig jugador) | 112×64 | idle, walk, windup, strike, guard, dash, speak, hit, death | M 4 |
| 34 | `centinela` | El Centinela Hueco (retoque `release`) | Cinturón | jefe | A | 384×256 | + release 6@10 | M 3 |
| 35 | `jacinto` | Jacinto, el Último Segador | Cinturón | jefe | H | 224×128 | 17 filas | L 10 |
| 36 | `ilara` | Sor Ilara, la Copista | Archivo | jefe | H | 192×128 | 13 filas | L 10 |
| 37 | `hesper` | Hesper, el Prior | Archivo | jefe | H | 192×128 | 8 filas + hit | L 8 |
| 38 | `casimar` | Casimar, el Rey sin Reina (+ cortesano) | Minas | jefe | H | 224×160 / 96×64 | 9 filas + 4 | L 9 |
| 39 | `magda` | Magda Soler, la Capataz | Minas | jefe | H | 224×144 | 12 filas | L 9 |
| 40 | `rufo` | Rufo, el Farero (+ espejos y lente) | Costa | jefe | H | 160×96 | 7 filas + objetos | M 6 |
| 41 | `eudora` | Eudora, la Piadosa | Costa | jefe | H | 160×112 | 11 filas | L 8 |
| 42 | `maelis` | Maelis, la Priora Sellada | Herida | jefe | P | rostro 128×160, mano 128×112 ×2 | rostro 4, mano 7 | XL 14 |
| 43 | `oda` | Oda, la Última Mensajera | Cinturón (secreto) | jefe | H (rig jugador) | 112×64 | 6 filas | S 3 |

**Total:** 191 puntos de los 43 diseños + 5 de las filas `death` de los comunes existentes = **196 puntos**. Reparto por tipo: H 23 diseños con 94 puntos; A 3 con 14 (Armadura, Custodio Mayor, Centinela); Q 6 con 28 (el Ermitaño y la Yunta en cabeza); V 5 con 11; S 3 con 11; mixtos con pieza propia (Madre de Veta S+P, Quimera A+P) 19; P puro (Maelis) 14.

---

## 10. Orden de producción por región

Dentro de cada región: **primero los comunes que establecen la lectura, luego el élite, luego el minijefe, por último el jefe** (así el jefe se prueba contra enemigos ya vistos y el jugador llega a él con el vocabulario aprendido). Los números son puntos; "Ing." es el trabajo de ingeniería de cuerpos (días) que hay que tener hecho antes.

| Fase | Región | Orden | Puntos | Ing. previa |
|---|---|---|---|---|
| 0 | Previo | `raster.js` (0,5 d), manifiesto y shader de aviso (1,5 d), shader de paleta (2 d), filas `death` de los 5 comunes (5 pt) | 5 | 4 d |
| 1 | **Último Umbral / Cinturón** | Espantapájaros (2) → Segador (2, prueba del arma `scythe`) → Mastín (2, tras Q mínimo) → Cuervo (4, banco de pruebas de V) → Yunta (7) → **Jacinto** (10); retoque Centinela `release` (3); Oda (3, secreto) | 38 | H 4 d, Q 5-6 d, V 3 d |
| 2 | **Archivo** | Novicio (1) → Sellador (2) → Penitente (2) → Armadura Vacía (4) → Polilla (2) → Pez de Plata (3) → Relator (2) → Custodio Mayor (7) → **Ilara** (10) → **Hesper** (8) | 41 | A 2-3 d, S 2-3 d |
| 3 | **Minas** | Cavador (2) → Hondo (2) → Murciélago (2) → Chinche (3) → Gusano de Veta (4) → Geoda (4) → Zapador (2) → Madre de Veta (12) → **Magda** (9) → **Casimar** (9, opcional) | 49 | P 4-5 d |
| 4 | **Costa** | Hermano de Cal (2) → Acompañante (2) → Gaviota (1) → Vela Errante (2) → Cangrejo (4) → Hermano Antiguo (2) → Ermitaño Mayor (8) → **Eudora** (8) → **Rufo** (6, opcional) | 35 | ninguna |
| 5 | **Herida** | Eco Borrado (2) → Relevo Vacío (2) → Contorno (4) → Doble Vacío (4) → Quimera (7) → **Maelis** (14) | 33 | `flat:true` (0,5 d) |

**Por qué este orden.**
- **Cinturón primero**: los diseños son baratos y cada uno estrena un tipo de cuerpo con riesgo bajo (Segador para el arma, Mastín para Q, Cuervo para V). Jacinto se construye cuando el Segador ya ha probado la hoz.
- **Archivo segundo**: la Armadura Vacía y el Custodio Mayor son los dos únicos usuarios de A y lo estrenan; Pez de Plata prueba S antes de las Minas.
- **Minas tercero**: aprovecha S ya resuelto; Madre de Veta es la prueba general de P. Magda es humanoide y barata si H está pulido.
- **Costa cuarta**: casi todo H y V; su coste real es el Ermitaño, que reutiliza Q y P.
- **Herida al final**: es la más barata en estilo (plano, sin sombreado) pero tiene el jefe más caro (Maelis). Se pueden pintar los comunes de la Herida antes (son rápidos) y dejar Maelis para el final del proyecto.
- **Hito de "corte"**: si hay que parar, el proyecto es presentable con las fases 0, 1 y 2 (Cinturón y Archivo completos, 84 puntos), tal como recomienda el documento 01.

---

## 11. Recortes: del plan completo al mínimo viable

El plan completo (196 puntos) es mucho para un solo autor con herramientas de código. Cada recorte mantiene la lectura de la región y se anota qué pierde el jugador.

| Recorte | Ahorro | Qué se pierde | Qué queda |
|---|---|---|---|
| Aplazar los jefes opcionales Casimar y Rufo | 15 | Dos peleas con identidad propia (coro, luz) | Las 8 obligatorias |
| La Yunta = dos Colosos en pareja con yugo y arado dibujado encima (sin Q propio) | 6 | La silueta de bueyes | Una pelea de embestida contra pared |
| Custodio Mayor = Armadura Vacía a `Z` 1,45, recolor y alabarda | 4 | Cuernos de bronce y detalle propio | Un escudo más grande |
| Ermitaño Mayor = Cangrejo escalado ×2 con una barca dibujada sobre la concha | 5 | Pinzas como piezas | Cangrejo grande con barca |
| Madre de Veta con 5 segmentos y 2 bolsas | 4 | Una bolsa | Pelea de partes igual |
| Quimera = Eco Borrado ×1,3 con las tres poses de ataque | 4 | Las juntas visibles | El reconocimiento de patrones |
| Élites como escala + paleta (Relator, Zapador, Hermano Antiguo, Relevo) | 4 | Detalle de silueta propio | Las mecánicas intactas |
| Eliminar Pez de Plata, Murciélago, Vela Errante y Contorno (sustituir por variantes de Polilla, Cuervo y Eco Borrado) | 11 | Cuatro comportamientos | Todas las mecánicas de combate se cubren con otro enemigo |
| Maelis con rostro estático (un solo fotograma de golpe) | 3 | Animación del rostro | Manos completas |

Suma: unos 56 puntos. **Mínimo viable ≈ 140 puntos**, con los 8 jefes obligatorios más Oda, 3 minijefes reducidos y 3-4 comunes por región. Si hace falta bajar más, el orden de sacrificio es: opcionales → élites → minijefes → comunes de relleno. **Nunca** los jefes obligatorios ni la fila `death` de los comunes.

---

## 12. Preguntas abiertas

1. **Aviso amarillo y ámbar.** El aviso parable es un tinte `d` (ámbar 4), pero el ámbar significa memoria. El plan lo resuelve pintándolo solo por código y nunca en sprites; ¿se acepta que el único ámbar "de peligro" sea esa capa, o se prefiere otro tono (por ejemplo `7` paja) para el aviso parable?
2. **La regla de la simetría.** ¿Se acepta como contrato de arte para todos los ataques (pose asimétrica = parable, simétrica = rojo)? Obliga al animador a respetarlo en cada `windup`; Eudora, Casimar y Jacinto la tensan en tres casos que se resuelven con decal y estela. Conviene probarla con un jugador que no conozca el diseño.
3. **Rojo en el decorado de la Cámara de Magda.** Se propone un único píxel grande de rojo apagado `r` (6×6, el Latido). Rompe la regla "ningún rojo en el fondo". ¿Excepción aprobada, o se pasa a azul oscuro?
4. **Alfombra roja de Casimar.** Se justifica por canon (el rey) pero choca con la lectura de los decals de suelo; se resuelve con borde blanco `w`. Alternativa: alfombra gris `x/y` (la monarquía borrada). ¿Cuál se prefiere?
5. **Estilo plano en la Herida (`flat:true`).** Los bordes en `x` y el relleno plano ahorran trabajo pero cambian la gramática del contorno `1`. ¿Se acepta que los comunes de la Herida rompan la regla del contorno negro?
6. **Pixel mixels por rotación.** Maelis, Madre de Veta, Ermitaño y la Geoda se mueven por rotación de piezas. ¿Se acepta rotar solo en pasos de 15° (más tosco, estilo del género) para evitar interpolación?
7. **Muertes con restos.** Las muertes que dejan restos persistentes (capa del Sellador, tela del Hermano de Cal) cuestan memoria de sprites en la sala. ¿Se limitan a 3 restos vivos?
8. **Número de variantes de silueta por tipo H.** Hay 30 humanoides; el riesgo de repetición es alto. ¿Se pone un tope de cabezas y armas (por ejemplo, máximo 3 enemigos con la misma cabeza en una región)?
9. **Doble Vacío = rig del jugador.** Reutilizar el rig del Caminante abarata, pero acopla un minijefe y el Relevo al arte del protagonista; si se rehace el Caminante, hay que regenerar. ¿Se acepta el acoplamiento?
10. **Sombra del jefe en el suelo.** Hesper y Eudora levitan; se propone una sombra ovalada en el suelo como pista de posición. ¿Vale como convención para voladores y flotantes (no solo jefes)?
11. **Retratos y rostros.** Casimar, Eudora y Hesper tienen rostro visible a 3-4 px de ojos. El documento 02 recomienda dibujar a mano lo icónico: ¿los rostros de los jefes con cara (Jacinto, Hesper, Eudora, Casimar, Magda) se retocan a mano sobre el rig, perdiendo la fuente única?
12. **Presupuesto de VRAM de Maelis.** Tres hojas pequeñas caben de sobra (3-6 MB), pero la sala necesita además sillas, lacre y rosetones. ¿Se fija un tope de 20 MB para la sala del jefe final?
13. **Orden libre Minas/Costa.** Si el jugador puede ir a la Costa antes de las Minas, los comunes de ambas regiones deben cargarse sin depender del orden de tipos (Q y V ya estarán). ¿Se garantiza que ninguna de las dos dependa de P antes de que exista?

