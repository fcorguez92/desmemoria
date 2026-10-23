# 02 · Puzles de movimiento y plataformas (propuesta del diseñador de puzles de movimiento)

Estado: propuesta de la sala de diseño. No modifica el canon (`historia.md`, `guion-maestro.md`, `personajes.md`) ni el código, y no sustituye a los documentos hermanos: usa los IDs de sala y las zonas de `01-mapa-macro.md` y deja a `03-puzles-de-entorno-y-mecanicas.md` todo lo que sea palancas, compuertas, luz, carriles, viento y piedras de lectura. Aquí se diseña **el recorrido del cuerpo del jugador**: huecos, alturas, pozos, ritmo y combinación de habilidades.

## 0. Resumen

1. **Las distancias están medidas, no estimadas.** Se han comprobado con un simulador ampliado (doble salto, salto de pared, dash, pinchos laterales y paredes lisas) que reproduce `PlatformerMotor` y `DashComponent`. Sobre La Chimenea real da los mismos márgenes que `tools/sim_saltos.js` (14 a 20 fotogramas frente a 15 a 17). Los **11 mapas dibujados** (§5) son archivos `.map` reales, simulados con y sin cada habilidad. Las cifras de `03` (§0.2) son prudentes y compatibles: mis "cómodos" son algo mayores porque se miden con plataformas de aterrizaje de 6 baldosas.
2. **Hallazgo grande: con el Agarre en "cualquier pared", cualquier pared alta es una escalera.** Se comprobó que basta una sola pared: se salta, se vuelve a ella y se salta otra vez (unas 18 baldosas con tres saltos). Y un pozo de dos paredes de 4 a 14 de ancho se sube con margen de 16 a 20 fotogramas. Sin una **pared lisa** que no se pueda agarrar (glifo `%`, §3), el Agarre se salta casi todo el diseño vertical. Es la única mecánica nueva que considero imprescindible. El Archivo ya la insinúa ("agarres negros sobre blanco", `ARC-01`).
3. **El doble salto y el dash se parecen más de lo que parece**: ambos cruzan un hueco plano de 21 baldosas con margen cómodo. Para exigir de verdad una u otra hay que combinar (hueco de 25 a 30: las dos), usar alturas (de 12 a 15: solo el doble salto) o una puerta propia del dash (muro de cera, §9).
4. **El suelo bajo el puzle decide el castigo**: escalón inferior en el Cinturón, pinchos (1 de daño y vuelta al último suelo firme) en el Archivo, la Herida y los puzles duros, y la sala de abajo en la Costa. La dificultad sube por **combinación y ritmo**, no por precisión de píxel: margen mínimo de 12 fotogramas en el camino principal y de 8 en maestría.
5. **33 salas de puzle de movimiento** (4 construidas, 25 del macro de `01` y 4 nuevas), de ellas **7 opcionales de maestría** (§7). Las 4 nuevas son tres secretas (SEC-09 a SEC-11) y la rama opcional HER-17: el mundo pasa de 136 a 140 salas, dentro del tope de 150.
6. **Reglas de ruptura**: se permite saltarse una puerta hacia atrás con una habilidad posterior y se impide, con simulación, saltársela hacia delante con las anteriores (§8).
7. **Cuatro cosas nuevas para el motor, por orden de importancia**: pared lisa `%` (casi gratis), pinchos laterales `{ }`, muro de cera `&` (puerta propia del dash) y reglas de caída por región. Todo lo que `03` ya propone (grietas `$`, compuertas `=`, carriles, corrientes) se reutiliza tal cual (§9).

### Cómo leer los mapas

Leyenda de `docs/vertical-slice.md` (`T` musgo, `G` piedra, `B` ladrillo, `S` tablón de un solo sentido, `^ v ~ -` pinchos, `.` vacío). Filas y columnas se cuentan desde 0 (arriba a la izquierda), como en el simulador. Marcadores de ejemplo: `P` inicio, `A` Ancla, `!` recompensa, `n` Piedra de lectura. Glifos del catálogo de `03` que se reutilizan: `$` suelo hondo (Excavar), `=` compuerta o tablones. Glifos **nuevos y propuestos**: `%` pared lisa, `{` y `}` pinchos laterales (`{` apunta a la derecha, pegado a una pared izquierda; `}` a la izquierda), `&` muro de cera. Para no repetir filas vacías, cada dibujo indica cuántas filas de aire se omiten **arriba**; las cotas del texto se dan en baldosas **sobre el suelo de salida** para que no dependan de esa omisión. (Los archivos simulados usan `#`, `e`, `<` y `>` para estos glifos, porque `03` ya usa `#`, `<` y `>`; el cambio de letra no afecta a la física.)

## 1. La física, medida

### 1.1 Los números del motor

Baldosa de 16 px; jugador de 24×48 (1,5×3 baldosas). Velocidad horizontal 300 px/s; gravedad 2250 (×1,4 al caer). Salto: 900 px/s hacia arriba (180 px, 11,25 baldosas) y recorte a la mitad al soltar. Doble salto: 800 px/s, uno por tiempo en el aire (se recarga solo al pisar suelo). Dash: 900 px/s durante 0,15 s (135 px, 8,4 baldosas), anula la gravedad, uno por salto en el aire, enfriamiento de 0,4 s. Salto de pared: caída de 120 px/s agarrado, salto con 850 px/s hacia arriba y empuje de 350 px/s durante 0,15 s. **El salto de pared no recarga el dash ni el doble salto**; solo el suelo lo hace. Coyote de 0,1 s, buffer de salto de 0,12 s, corrección de esquina de 8 px.

### 1.2 Distancias medidas (en baldosas)

Se probaron huecos planos y subidas con aterrizaje de 6 baldosas. "Margen" es cuántos fotogramas puede equivocarse el jugador en el peor parámetro (altura del salto, momento del dash, momento del segundo salto); el simulador mide hasta 25 y a partir de ahí lo da por muy cómodo.

| Maniobra | Hueco plano cómodo (margen ≥ 15) | Máximo jugable | Subida cómoda | Subida máxima |
|---|---|---|---|---|
| Salto (sin habilidad) | 12 | 14 (margen 12) | 10 | 11 |
| Doble salto | 21 | 24 (margen 10) | 15 | 19 (margen 14); 20 (margen 9) |
| Dash en el salto | 21 | 22 (margen 15) | no sube | no sube |
| Doble salto + dash | 30 (margen ≥ 16) | 33 | subida 12 con hueco 22 (margen 14) | no medida |
| Pared, pozo de dos paredes | ancho 5 a 14: margen 20; ancho 4: 16 | ancho 3: 11; ancho 2: 6 | sin límite | sin límite |

Lecturas para diseñar:

- **Hueco "sin habilidad": 12 como máximo.** Cualquier hueco de 15 o más pide dash o doble salto. Las distancias ya construidas (20 en el foso de las Terrazas, 16 en La Chimenea, 17 en La Pasarela) caen entre 16 y 21, es decir, **las cruza cualquiera de las dos habilidades**. Está bien: el dash llega antes y el doble salto no se consigue sin haber tenido el dash.
- **Subidas: 11 es el techo del salto; de 12 a 15 son del doble salto.** La cornisa del Ancla (13 de altura) pide doble salto con holgura. Subir 20 con solo doble salto tiene margen 9: no es puzle, es precisión, y se evita.
- **Huecos de 25 a 30 exigen doble salto y dash a la vez** (de 22 a 24 se cruzan con uno solo, pero con margen de 10 a 17). Es la combinación más limpia del juego.
- **Pozo de ancho 3 o menos: maestría;** de 5 a 8: cómodo; ancho 4: intermedio.
- **El enfriamiento del dash (0,4 s) nunca estorba entre plataformas**: dos saltos seguidos distan al menos 0,7 s.
- **La pared no recarga nada.** Es una decisión que hay que tomar ya (pregunta 2); todo está medido con la regla actual. Si el Agarre recargara dash y doble salto, las combinaciones con pared serían más permisivas y habría que repasar los márgenes.
- **Las corrientes de aire de `03` (M8) cambian estas cifras**: ±180 px/s laterales mueven un hueco de 15 a unos 18 a favor o a unos 12 en contra. Toda sala con viento se simula con la corriente dentro o, más sencillo, se deja el viento solo en tramos de hueco corto (≤ 6) y nunca en el cruce principal.

### 1.3 Qué lleva el jugador en cada momento

Una sala de puerta debe ser **imposible con el inventario anterior y posible con el exacto** (§11).

| Tramo | Inventario | Qué puede exigir una sala |
|---|---|---|
| Umbral y Terrazas hasta el foso | salto | hueco ≤ 12, altura ≤ 11 |
| Tras el Centinela Hueco | + dash | huecos de 15 a 21 |
| Tras la Torre de Riego | + doble salto | alturas de 12 a 15, huecos hasta 30 |
| Tras Jacinto (CIN-18) | + Agarre | pozos, paredes lisas, pinchos laterales |
| Archivo, Minas, Costa (orden libre) | + Agarre; **Excavar solo en las Minas tras Magda** | **en el Archivo y la Costa no se puede exigir Excavar**; la Costa ofrece camino largo (sin Excavar) y atajo con él |
| Herida y atajos | + Excavar | suelos hondos `$` |
| Acto IV (Umbral) | + Nombrar | Piedras de lectura (ver `03` §3) |

Consecuencia: **Nombrar no puede bloquear el camino de la Herida** (el guion permite entrar sin Nombrar y volver). Las salas con Nombrar de este documento son ramas opcionales.

## 2. Gramática de puzles por habilidad

Cinco peldaños: **introducir** (verlo antes de poder, usarlo sin riesgo), **desarrollar** (repetirlo cambiando una dimensión), **retorcer** (una condición que lo hace pensar), **combinar** y **maestría** (opcional). Las cifras son baldosas y salen de §1.2.

### 2.1 Dash (la Carrera)

| Peldaño | Qué se plantea | Medidas | Sala |
|---|---|---|---|
| Introducir | Un foso que se ve antes de tener el poder y se cruza después, con un mojón de Mensajero (pie alado) en el borde | hueco 20, suelo ancho | CIN-01 Terrazas Secas (hecha) |
| Desarrollar | Cruces repetidos cambiando distancia y dirección | 16 y 17, tres veces, escalones anchos | CIN-05 Chimenea, CIN-06 Pasarela (hechas) |
| Retorcer | Dash en el suelo para cruzar pinchos que salen y se retraen; dash hacia atrás | hilera de pulsantes de 24; cruces en zigzag de 22 | HER-11 Galerías Dobladas; HER-08 Chimenea Vuelta |
| Combinar | Dash más doble salto | huecos de 26 a 30; con subida de 12, hueco 22 | CIN-12 La Acequia; COS-03 Cornisa de Sal |
| Maestría | Cadena larga con ritmo sostenido | 3 a 5 huecos de 17 a 21, plataformas de 6 | SEC-06 Establos de los Mensajeros |

Trampa conocida: el dash y el doble salto **no son excluyentes** hasta 21 de hueco (24 con margen justo). Una vez se tiene el doble salto, el dash solo es llave propia con el muro de cera `&` (§9); si no, las llaves se diseñan como "dash o doble salto" y se combinan a partir de 25.

### 2.2 Doble salto (el Segundo Aliento)

| Peldaño | Qué se plantea | Medidas | Sala |
|---|---|---|---|
| Introducir | Una cornisa con luz (el Ancla) visible desde la escalera, más alta que el salto | subida 13, lado 6 | CIN-07 Torre de Riego (hecha) |
| Desarrollar | Subir, cruzar y subir en terrazas | subidas 13, 12, 13; hueco 15 | CIN-15 Los Bancales Altos |
| Retorcer | Torres de paredes lisas, donde el Agarre no ayuda, con tablones de rescate | subidas de 14, huecos de 8 | ARC-09 La Biblioteca Intacta |
| Combinar | Con dash (huecos largos) y con pared | huecos de 26 a 30 | CIN-12 La Acequia; HER-08 |
| Maestría | Torres lisas seguidas, un hueco de 30 y un tramo con parches | subidas 15 a 16; hueco 30 | SEC-08 Torreón de las Campanas Mudas |

Regla: el doble salto es **apoyo antes de ser obligatorio**. En la Torre de Riego el recuerdo está en lo alto de una escalera de tablones que se sube con salto normal; solo lo siguiente (la cornisa) lo exige.

### 2.3 Salto de pared (el Agarre)

| Peldaño | Qué se plantea | Medidas | Sala |
|---|---|---|---|
| Introducir | Pozo ancho con las paredes iluminadas y marcas de hoz, con pinchos al fondo que solo devuelven | ancho 6; altos 22 y 17 | CIN-25 Pozo de Piedra Seca |
| Desarrollar | Subidas largas con el Agarre como único medio (ver `03` P20 para el pozo en blanco) | anchos 6, 5, 4 | COS-02 Escalones del Tajo; ARC-01 Pozos Blancos |
| Retorcer | Pinchos en una pared (se usa la otra), tablones de rescate cada 21, tramos de pared lisa | tiras de 6; ancho 7; tramos lisos de 6 | MIN-13 Descenso de los Zapadores; COS-04 Pilar de Lacre |
| Combinar | Con doble salto (cruzar un tramo liso) y con dash (salir del pozo hacia un hueco) | pozo 7; hueco 22 | HER-08 Chimenea Vuelta |
| Maestría | Parches agarrables de 3 baldosas entre paredes lisas | ancho 9; parches cada 9 filas | SEC-09 La Pared de Sal |

### 2.4 Excavar (el Golpe Hondo)

Se usa la definición de `03` (M2): **abajo + atacar sobre un suelo hondo `$`, dos golpes**, y la pieza entera desaparece para siempre. Eso fija el diseño: no hay estratos que romper uno a uno, hay **piezas**.

| Peldaño | Qué se plantea | Medidas | Sala |
|---|---|---|---|
| Introducir | Un muro imposible de pasar y un tapón de veta ámbar delante: se rompe y se pasa por debajo | pieza 3×3; túnel de 6 de alto | MIN-16 El Hueco del Pico |
| Desarrollar | Pozos y galerías de atajo que unen regiones | piezas de 3 de ancho; pozos de 64×200 y 80×240 | MIN-17 Veta Tapiada; MIN-24 Pozo del Latido |
| Retorcer | Romper el suelo correcto: el contiguo sin veta no cede; el suelo al revés de una sala reconstruida | piezas de 3 a 5 | HER-07 Cisterna Doblada |
| Combinar | Con pared (volver a subir por el hueco) | pozo de 3 de ancho | SEC-07 Grieta de Rosendo |
| Maestría | Un nivel sin suelo fijo: cada pieza rota abre un camino y cierra otro | ver §7 | SEC-11 La Sala Sin Suelo |

Como `$` queda roto para siempre, **el túnel de debajo de un muro (como en MIN-16) debe tener siempre una salida de vuelta**: un agujero de 4 de ancho en su techo al otro lado y, sobre todo, nunca un hueco sin salida. La simulación comprueba la sala ya rota (§5, MIN-16).

### 2.5 Nombrar

No se mueve, se dice. El diseño de las Piedras de lectura está en `03` §3.1 y el del Mirador en §3.3. Lo que añade este documento es el **hueco que solo cruza un tablón de memoria**: la Piedra enciende una compuerta `=` de tablones que dejan un hueco de 40 reducido a tres de 12. Tres peldaños:

| Peldaño | Qué se plantea | Sala |
|---|---|---|
| Introducir | Un hueco de 40 sobre el abismo, la Piedra de lectura en el borde y la silueta de Oda del otro lado | CIN-06 El Mirador (`03` P12) |
| Desarrollar | Los peldaños que se encienden con cada Nombre sostenido | HER-16 (`03` §3.6) |
| Combinar | Tablones de memoria que acortan un hueco que sigue exigiendo dash y doble salto | HER-17 La Sala Desmontada (opcional) |

### 2.6 Combinaciones

| Combinación | Problema nuevo | Medida de referencia | Ejemplo |
|---|---|---|---|
| Dash + doble salto | Alcanza donde ninguna llega sola | huecos de 26 a 30; con subida de 12, hueco 22 | CIN-12, COS-03, HER-08 |
| Doble salto + pared | Cruzar un tramo liso o entrar a un pozo desde una repisa | pozo de 4 a 8; tramo liso de 6 | SEC-08, SEC-09 |
| Dash + pared | Salir de un pozo hacia un hueco; no recarga entre medias | hueco de salida 12 a 20 | HER-08 |
| Excavar + dash | Dos soluciones al mismo obstáculo (cruzar a ras o romper por debajo) | hilera de 24 | HER-11 |
| Excavar + pared | Bajar rompiendo y volver subiendo | pozo de 3 de ancho | SEC-07 |
| Dash + doble salto + pared | Maestría: el jugador diseña su ruta | ver §7 | SEC-09, SEC-08 |

Orden pedagógico: primero la combinación de las dos habilidades recién conseguidas (dash + doble salto, antes de la pared), luego cada una con la pared, y las de tres solo en maestría.

## 3. Mecánicas y glifos nuevos (resumen; detalle y coste en §9)

| Glifo | Qué es | Por qué |
|---|---|---|
| `%` | Pared lisa: sólida, no se puede agarrar | Sin ella el Agarre rompe todo el diseño vertical (hallazgo 2) |
| `{` `}` | Pinchos laterales (1 de daño, vuelta al último suelo firme) | Dan sentido a alternar paredes y son la versión vertical de los pinchos que ya hay |
| `&` | Muro de cera: solo se rompe con dash | Hace al dash llave propia una vez existe el doble salto |
| `$`, `=`, `n` | De `03`: suelo hondo, compuerta, Piedra de lectura | Se reutilizan sin cambios |

## 4. Catálogo de salas de puzle (33)

Dificultad: 1 = a la primera; 2 = 1 a 3 intentos; 3 = exige combinar y ritmo; 4 = opcional o avanzado; 5 = maestría. "Fallo" = qué cuesta equivocarse. IDs y tamaños son los de `01` (los marcados con * son propuestos aquí). Las salas con (c.) ya están construidas.

| ID | Sala | Hab. | Tamaño | Dif. | Fallo | Camino principal / maestría | Recompensa |
|---|---|---|---|---|---|---|---|
| CIN-01 | Las Terrazas Secas (c.) | D | 64×24 | 2 | cae a la Cisterna | foso de 20 / — | acceso a la Torre; Cuenta del Rosario (`03` P05) |
| CIN-05 | La Chimenea (c.) | D | 40×69 | 3 | escalón o pinchos | 3 cruces de 16 / — | salida alta |
| CIN-06 | La Pasarela y El Mirador (c.) | D (N) | 100×24 | 3 | pinchos | 3 huecos de 17 / hueco 40 con Nombrar (`03` P12) | Ancla; Insignia (secreto) |
| CIN-07 | La Torre de Riego (c.) | DJ | 56×44 | 2 | escalón | escalera + cornisa de 13 / — | Doble salto; Dedal de la Torre |
| CIN-12 | La Acequia | D+J | 96×48 | 3 | pinchos | 3 huecos de 17, 27 y 21 / — | paso a CIN-13 y CIN-25 |
| CIN-15 | Los Bancales Altos | J | 72×60 | 2 | escalón | 5 terrazas: 13, 15, 12, 13 / — | vista del Palomar |
| CIN-24 | El Granero Sin Techo | J | 112×64 | 3 | escalón | vigas con huecos de 14 a 19 y subidas de 5 a 12 / — | retal; atajo al Umbral |
| CIN-25 | El Pozo de Piedra Seca | W | 72×72 | 2 | pinchos al fondo | pozo ancho 6 de 22 y 17 / — | FF o FV; paso a CIN-26 |
| CIN-21 | El Descenso del Brocal | W (volver) | 64×96 | 2 | pinchos en repisas | subida con pared en dos pozos de 5 / — | vuelta del descenso |
| COS-02 | Los Escalones del Tajo | W | 100×70 | 3 | cae al tramo anterior | 3 pozos de ancho 6, 5 y 4 / — | cartas |
| COS-03 | La Cornisa de Sal | D+J | 104×70 | 3 | sala inferior | 4 cruces: 17, 19, 28, 2 con subida 12 / — | vista de la Puerta |
| COS-04 | El Pilar de Lacre | W | 80×160 | 3 | pinchos de cal | subida de 160 con tramos lisos de 6 / — | nudo central; A25 |
| COS-11 | Los Tendederos | D+J | 110×60 | 3 | sala inferior | cuerdas de colada: huecos 12 a 22 / — | FV |
| ARC-09 | La Biblioteca Intacta | J | 112×80 | 3 | tablón de rescate | 4 torres lisas de subida 14 / — | Nombre Aurelio |
| ARC-19 | El Archivo en Blanco | D+J | 144×70 | 4 | pinchos | plataformas solo con borde pálido: 16 a 26 / — | (tensión, sin mapa) |
| MIN-09 | La Sala de Estratos | J | 100×60 | 3 | escalón | capas que cambian: subidas 12 a 15 / — | texto |
| MIN-13 | El Descenso de los Zapadores | W | 56×90 | 3 | tablón de rescate | pozo de ancho 7, 74 de alto, tiras de pinchos / — | acceso a la antecámara |
| MIN-16 | El Hueco del Pico | E | 64×40 | 1 | ninguno | muro + túnel / — | primer suelo roto |
| MIN-17 | La Veta Tapiada | E | 64×200 | 2 | ninguno | atajo hacia la Cisterna / — | atajo |
| MIN-24 | El Pozo del Latido | E | 80×240 | 2 | ninguno | subida a la Puerta Sin Muro / — | atajo |
| MIN-25 | La Mina Inundada | D+J | 112×60 | 3 | sala inferior | plataformas sobre agua: huecos 14 a 26 / — | reliquia (`01`) |
| HER-07 | La Cisterna Doblada | E | 96×31 | 3 | pinchos | suelo al revés, piezas de 3 a 5 / — | eco del aterrizaje |
| HER-08 | La Chimenea Vuelta | D+J+W | 40×69 | 4 | pinchos | pozo de 24 y 2 cruces de 22 / — | huella con prisa |
| HER-09 | Las Terrazas de Ceniza | D | 64×24 | 3 | pinchos | foso sin fondo de 20 / — | A32 |
| HER-11 | Las Galerías Dobladas | D (E) | 84×34 | 4 | pinchos | hilera de pulsantes de 24 / a ras o por debajo | cuaderno del Custodio |
| HER-17* | La Sala Desmontada | D+J+W+N | 130×62 | 5 | pinchos | tubo, hueco de 26 y torre lisa / hueco de 40 con tablones | Ecos y Página de Corvel (Herida) |
| SEC-06 | Los Establos de los Mensajeros | D | 100×26 | 3 | pinchos | opcional: huecos 17, 19, 20 / — | FF; cartas |
| SEC-08 | Torreón de las Campanas Mudas | J+W | 40×100 | 5 | pinchos | opcional / maestría pura | Pluma sin tinta |
| SEC-02 | El Palomar | J+W | 40×60 | 4 | escalón | opcional | FV |
| SEC-07 | La Grieta de Rosendo | E+W | 56×40 | 4 | ninguno | opcional | FV |
| SEC-09* | La Pared de Sal | W (+J, D) | 40×72 | 5 | pinchos | opcional | bolsa de Ecos y objeto con lore |
| SEC-10* | Los Peldaños del Ascenso | J+W | 48×80 | 4 | pinchos | opcional (Cinturón alto) | Ecos y objeto con lore |
| SEC-11* | La Sala Sin Suelo | E+D+J+W | 80×60 | 5 | pinchos | opcional | Ecos y objeto con lore |

Reparto: Cinturón 9 (4 hechas), Costa 4, Archivo 2, Minas 6, Herida 5 y secretas 7. Cada región tiene una voz propia (§6.1).

## 5. Las once salas dibujadas y simuladas

Cada ficha lleva el dibujo (archivo `.map` real, ver §11 para repetir la comprobación), las cotas en baldosas sobre el suelo de salida y el resultado del simulador: **margen mínimo del peor tramo, en fotogramas**, con el inventario exacto y con el inventario anterior (que debe fallar). "Fallo" es lo que cuesta equivocarse.

### 5.1 CIN-15 · Los Bancales Altos (Cinturón alto, doble salto, dificultad 2)

Objetivo: llegar a la terraza más alta, desde la que se ve el Palomar. Tamaño 72×60.

Mapa 72×60; se omiten 3 filas de aire arriba.

```
BB....................................................................BB
BB....................................................................BB
BB................................................................!...BB
BB..........................................................TTTTTTTTTTBB
BB..........................................................GGGGGGGGGGBB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB................................................TTTTTTT.............BB
BB................................................GGGGGGG.............BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB......................................TTTTTTT.......................BB
BB......................................GGGGGGG.......................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB......TTTTTTT...............TTTTTTT.................................BB
BB......GGGGGGG...............GGGGGGG.................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB....................................................................BB
BB..P.................................................................BB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Suelo (fila 57); terraza 1 a **13** de altura (cols 8-14); hueco de **15** hasta la terraza 2 (cols 30-36, mismo nivel); luego subidas de **12**, **13** y **13** con huecos de 3 (terrazas de 7, 7 y 10 de ancho).
- **Enseña** las tres dimensiones del doble salto en orden: altura, distancia, altura. Cada terraza es una frase; no hay enemigos.
- **Fallo.** Caer al suelo de abajo y volver a subir: unos 6 s.
- **Viento** (`01` lo prevé): solo en las dos últimas subidas, huecos de 3; nunca en el hueco de 15.
- **Simulador.** Con doble salto: margen **19**. Sin habilidades o solo con dash: imposible. Con Agarre y dash (después de La Era) también se llega, con margen 15: es una ruptura hacia atrás permitida (§8).

### 5.2 CIN-12 · La Acequia (Cinturón alto, doble salto + dash, dificultad 3)

Objetivo: cruzar el cauce seco hasta la compuerta de Tomasa. Tamaño 96×48.

Mapa 96×48; se omiten 39 filas de aire arriba.

```
BB............................................................................................BB
BB............................................................................................BB
BB..P.....................................................................................A...BB
BBTTTTTTTTT.................TTTTTTT...........................TTTTTTT.................TTTTTTTTBB
BBGGGGGGGGG.................GGGGGGG...........................GGGGGGG.................GGGGGGGGBB
BBGGGGGGGGG.................GGGGGGG...........................GGGGGGG.................GGGGGGGGBB
BBGGGGGGGGG.................GGGGGGG...........................GGGGGGG.................GGGGGGGGBB
BB.........^^^^^^^^^^^^^^^^^.......^^^^^^^^^^^^^^^^^^^^^^^^^^^.......^^^^^^^^^^^^^^^^^........BB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Cuatro pilares de 4 de grosor. Huecos de **17**, **27** y **17**; plataformas de 7, 7, 7 y 8 de ancho; abajo, pinchos.
- **Enseña** el cambio de oficio: el primer hueco (17) se cruza con dash o con doble salto, a gusto del jugador; el segundo (**27**) pide **las dos a la vez**; el tercero es la vuelta de honor. Es la primera vez que el juego exige combinar.
- **Fallo.** 1 de daño y de vuelta al último pilar firme.
- **Simulador.** Con las dos: margen **20**. Solo dash: se llega al segundo pilar y no al tercero; solo doble salto: igual. Con dash y Agarre (sin doble salto) se llega con margen 8, saltando por las caras de los pilares: ruptura hacia atrás permitida y difícil (§8).

### 5.3 CIN-25 · El Pozo de Piedra Seca (Cinturón alto, Agarre, dificultad 2)

Objetivo: subir al Lavadero Seco. Tamaño 72×72. Es el primer pozo del juego.

Mapa 72×72; se omiten 27 filas de aire arriba.

```
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB..................A..........BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......TTTTTTTTTTTTTTTTTTTTTTTBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......TTTTTTTTTTTTTTTTTTTTTTTBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.P..^^BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Tubo de ancho **6** (cols 2-7); primera repisa a **22** (fila 47), segunda a **17** más (fila 30). Pinchos solo en el fondo del tubo (cols 6-7), con un hueco de salida de 4 baldosas seguro.
- **Enseña** el Agarre con dos paredes, sin pinchos laterales, sin lisas y con repisas amplias. Sale de La Era con el gesto de Jacinto aún fresco; las paredes llevan hendiduras de hoz (§10).
- **Fallo.** Caer al fondo; con pinchos, 1 de daño y vuelta al suelo seguro del tubo.
- **Simulador.** Con Agarre: margen **16**. Con doble salto y dash: imposible (22 supera el techo de 20).

### 5.4 ARC-09 · La Biblioteca Intacta (Archivo, doble salto, dificultad 3)

Objetivo: cruzar la sala por las estanterías-torre. Tamaño 112×80.

Mapa 112×80; se omiten 5 filas de aire arriba.

```
%%............................................................................................................%%
%%............................................................................................................%%
%%...............................................................!............................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%............................................................%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%..SSSS..%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%..............................................%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%..SSSS..%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%................................%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%..SSSS..%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..................%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%..SSSS..%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%....%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%..P.%%%%%%........%%%%%%........%%%%%%........%%%%%%........%%%%%%%%........................................%%
%%TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT%%
%%GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG%%
%%GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG%%
```

- **Cotas.** Torres de 6 de ancho con **subidas de 14** (cols 6-11, 20-25, 34-39, 48-53), última subida de 13 a una meta de 8 de ancho; huecos de **8** entre torres. Tablones de rescate a 7 por encima del suelo, 14, 21 y 28 bajo cada salto.
- **Por qué las paredes son lisas.** Con ladrillo, el Agarre salta las torres (se probó). Con `%` el Agarre no ayuda y las paredes del Archivo (blancas) lo dicen.
- **Enseña** el doble salto como ritmo: salto, segundo salto, aterrizaje, y otra vez.
- **Fallo.** Un tablón de rescate; solo un fallo muy temprano cuesta volver al suelo.
- **Simulador.** Doble salto: margen **14**. Solo Agarre o Agarre y dash: imposible; doble salto y Agarre: 15.

### 5.5 MIN-13 · El Descenso de los Zapadores (Minas, Agarre, dificultad 3)

Objetivo: subir (o bajar, según el sentido) el pozo de madera. Tamaño 56×90.

Mapa 56×90; se omiten 11 filas de aire arriba.

```
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBB
BB.............................BBBBBBBBBBBBBBBBBBBBBBBBB
BB.......TTTTTTTTTTTTTTTTTTTTTTBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB...SSS.BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB...SSS.BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB......}BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB...SSS.BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB{......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.......BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BB.P.....BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
```

- **Cotas.** Tubo de ancho **7** y **74** de alto. Tablones de rescate cada **21** (filas 66, 45 y 24): a esa distancia no se saltan con doble salto. **Pinchos laterales**: `{` en la pared izquierda (filas 76-81 y 33-38), `}` en la derecha (54-59 y 15-20); cada tira mide 6.
- **Enseña** a leer la pared que se puede usar: la que no tiene pinchos. Es el primer puzle de pared que pide decidir.
- **Fallo.** 1 de daño y de vuelta al último tablón.
- **Simulador.** Agarre: margen **20**. Doble salto y dash: imposible (1 de 5 superficies).
- **Requiere** el glifo nuevo de pinchos laterales (§9).

### 5.6 MIN-16 · El Hueco del Pico (Minas, Excavar, dificultad 1)

Objetivo: pasar bajo un muro que no se salta. Tamaño 64×40. Aparece justo después de vencer a Magda: primer uso con sentido del Golpe Hondo.

Mapa 64×40; se omiten 0 filas de aire arriba y 4 de relleno abajo.

```
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB............................BBBBBB..........................BB
BB..P.........................BBBBBB..............A...........BB
BBTTTTTTTTTT$$$TTTTTTTTTTTTTTTBBBBBBTTTT....TTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGG$$$GGGGGGGGGGGGGGGBBBBBBGGGG....GGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGG$$$GGGGGGGGGGGGGGGBBBBBBGGGG....GGGGGGGGGGGGGGGGGGBB
BB............................................................BB
BB............................................................BB
BB............................................................BB
BB............................................................BB
BB............................................................BB
BB............................................................BB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Muro de ladrillo de 6 de ancho y más de 26 de alto: ninguna combinación de saltos lo pasa. Delante, una pieza `$` de **3×3** con la veta ámbar y marcas de pico. Túnel inferior de **6** de alto (cumple la regla de techo de la prueba de humo). Al otro lado, un boquete de **4** de ancho para volver a subir.
- **Enseña** el Golpe Hondo sin texto: la pieza se ve desde la entrada y el muro no deja otra salida.
- **Fallo.** Ninguno; no hay pinchos.
- **Simulador.** Con la pieza (`$` tratada como sólida): ni con las tres habilidades de movimiento se llega al otro lado. Con la pieza rota: cae por el agujero con margen 12 y sale por el boquete con margen 16, **sin ninguna habilidad**.

### 5.7 COS-03 · La Cornisa de Sal (Costa, doble salto + dash, dificultad 3)

Objetivo: cruzar los acantilados hasta la vista de la Puerta Sin Muro. Tamaño 104×70.

Mapa 104×70; se omiten 35 filas de aire arriba y 1 de relleno abajo.

```
BB....................................................................................................BB
BB....................................................................................................BB
BB.................................................................................................A..BB
BB..............................................................................................TTTTTTBB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB..............................................................................................%%%%%%BB
BB....................................................TTTTTT............................TTTTTT..%%%%%%BB
BB....................................................%%%%%%............................%%%%%%..%%%%%%BB
BB....................................................%%%%%%............................%%%%%%..%%%%%%BB
BB....................................................%%%%%%............................%%%%%%..%%%%%%BB
BB....................................................%%%%%%............................%%%%%%..%%%%%%BB
BB...P................................................%%%%%%............................%%%%%%..%%%%%%BB
BBTTTTTTTTT.................TTTTTTT...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%.................%%%%%%%...................%%%%%%............................%%%%%%..%%%%%%BB
BB%%%%%%%%%^^^^^^^^^^^^^^^^^%%%%%%%^^^^^^^^^^^^^^^^^^^%%%%%%^^^^^^^^^^^^^^^^^^^^^^^^^^^^%%%%%%^^%%%%%%BB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Pilares de sal lisa. Huecos de **17**, **19** (con subida de 6), **28** y un salto final de **2** con **subida de 12**. Plataformas de 7, 7, 6, 6 y 6.
- **Enseña** la progresión entera del Cinturón en una sala: dash o doble salto, luego las dos (28) y, al final, altura con doble salto. El mar sustituye a los pinchos: caer lleva a la sala inferior.
- **Fallo.** Caída a la playa de abajo y vuelta por la escalera: unos 25 s. Es la sala más cara de repetir; el dibujo pone pinchos donde en el juego habría mar (para poder simularla) y la decisión de un tablón de rescate bajo el hueco de 28 queda en la pregunta 8.
- **Viento.** `01` marca "viento"; ver §1.2. La sala se simuló sin corriente.
- **Simulador.** Dash y doble salto: margen **20**. Cada habilidad sola, o con Agarre, falla: **el Agarre no la salta** gracias a las paredes lisas.

### 5.8 HER-08 · La Chimenea Vuelta (Herida, dash + doble salto + Agarre, dificultad 4)

Objetivo: subir. Tamaño 40×69. Es La Chimenea, reconstruida "del revés": ahora se empieza en un pozo y se acaba en los cruces.

Mapa 40×69; se omiten 14 filas de aire arriba y 1 de relleno abajo.

```
BB....................................BB
BB....................................BB
BB................................A...BB
BB............................TTTTTTTTBB
BB............................%%%%%%%%BB
BB............................%%%%%%%%BB
BB............................%%%%%%%%BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BBTTTTTTTT............................BB
BB%%%%%%%%............................BB
BB%%%%%%%%............................BB
BB%%%%%%%%............................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB....................................BB
BB.......TTTTTT..................TTTTTBB
BB.......BBBBBB..................%%%%%BB
BB.......BBBBBB..................%%%%%BB
BB.......BBBBBB..................%%%%%BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.......BBBBBB.......................BB
BB.P.....BBBBBB^^^^^^^^^^^^^^^^^^^^^^^BB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Pozo de ancho **7** hasta una repisa a **24**; subida de **12** hasta una repisa lisa a la izquierda (cols 2-9); hueco de **20** con subida de **12** hasta la meta (cols 30-37). Pinchos abajo del todo. La repisa de la derecha (fila 41) es un descanso.
- **Enseña** a encadenar tres habilidades: pared, doble salto, dash más doble salto. Cuenta, sin decirlo, que la Herida recuerda la Chimenea mal.
- **Fallo.** Pinchos: 1 de daño y vuelta al último suelo firme.
- **Simulador.** Las tres: margen **20**. Sin Agarre: imposible; solo Agarre: imposible. Agarre con solo dash (12) o con solo doble salto (15) también llegan: se acepta como ruptura permitida.

### 5.9 HER-17 · La Sala Desmontada (Herida, todo + Nombrar, dificultad 5, opcional)

Objetivo: cruzar los tres fragmentos de sala hasta la Página de Corvel de la Herida. Tamaño 130×62. Es la prueba de `03` M6 aplicada al movimiento.

Mapa 130×62; se omiten 13 filas de aire arriba y 1 de relleno abajo.

```
BB..............................................................................................................................BB
BB..............................................................................................................................BB
BB..................................................................n......................................................A....BB
BB................................................................%%%%%%............========............========........TTTTTTTTBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB................................................................%%%%%%................................................GGGGGGGGBB
BB......TTTTTTTTTTTT..........................TTTTTTTT............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB......BBBBBBBBBBBB..........................GGGGGGGG............%%%%%%................................................GGGGGGGGBB
BB..P...BBBBBBBBBBBB^^^^^^^^^^^^^^^^^^^^^^^^^^GGGGGGGG^^^^^^^^^^^^%%%%%%^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^GGGGGGGGBB
BBTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Fragmento 1: pozo de ancho 6 y **30** de alto. Fragmento 2: hueco de **26** (dash y doble salto). Fragmento 3: subida de 12 a una torre lisa. Después, un hueco de **48**: no se cruza con nada. La Piedra de lectura `n` (en la torre) hace aparecer dos tablones `=` de 8 de ancho que lo parten en tres huecos de 12, 12 y 8.
- **Enseña** que Nombrar también es movimiento y que el hueco imposible tiene solución si se vuelve a leer lo aprendido.
- **Fallo.** Pinchos.
- **Simulador.** Con los tablones y las cuatro de movimiento: margen **18**. Sin los tablones, ni con las tres habilidades de movimiento se llega.
- **Condición de canon.** Es rama opcional: el camino de la Herida nunca exige Nombrar.

### 5.10 SEC-09 · La Pared de Sal (secreta, maestría, dificultad 5)

Objetivo: subir un pozo de paredes lisas con parches agarrables de 3 baldosas. Tamaño 40×72. Es la sala "tipo Camino Blanco" de la Costa, con márgenes de este proyecto.

Mapa 40×72; se omiten 0 filas de aire arriba y 1 de relleno abajo.

```
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%......................................
%%......................................
%%......................................
%%......................................
%%......................................
%%.......................!..............
%%..........TTTTTTTTTTTTTTTTTTTTTTTTTTTT
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BBTT........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%...SSSS...%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
BB..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.........BB%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%..........%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%.P.^^^^^^^%%GGGGGGGGGGGGGGGGGGGGGGGGGG
%%TTTGGGGGGG%%GGGGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
GGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGG
```

- **Cotas.** Pozo de ancho **9**. Parches de **3** alternos (derecha 58-60, izquierda 49-51, derecha 40-42, izquierda 31-33, derecha 22-24, izquierda 13-15), uno cada 9 filas. Un tablón de descanso (fila 36) y una repisa de 2 al final. Pinchos al fondo, con la salida en una repisa de 3.
- **Fallo.** Pinchos: 1 de daño y de vuelta a la salida. Nada más.
- **Simulador.** Solo Agarre: margen **5** (muy difícil, ruta de experto); Agarre y doble salto: **8**; las tres: **10**. Sin Agarre: imposible.
- **Camino principal / maestría.** No es camino principal. La curva está en §7.

### 5.11 SEC-06 · Los Establos de los Mensajeros (secreta, dash, dificultad 3)

Objetivo: cruzar los casilleros de cartas. Tamaño 100×26.

Mapa 100×26; se omiten 17 filas de aire arriba.

```
BB................................................................................................BB
BB................................................................................................BB
BB...P......................................................................................A.....BB
BBTTTTTTT.................TTTTTTT...................TTTTTTT....................TTTTTTTTTTTTTTTTTTTTB
BBGGGGGGG.................GGGGGGG...................GGGGGGG....................GGGGGGGGGGGGGGGGGGGGB
BBGGGGGGG.................GGGGGGG...................GGGGGGG....................GGGGGGGGGGGGGGGGGGGGB
BBGGGGGGG.................GGGGGGG...................GGGGGGG....................GGGGGGGGGGGGGGGGGGGGB
BB.......^^^^^^^^^^^^^^^^^.......^^^^^^^^^^^^^^^^^^^.......^^^^^^^^^^^^^^^^^^^^...................BB
BBGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGGBB
```

- **Cotas.** Cuatro plataformas con huecos de **17**, **19** y **20** (la última, de 20 de ancho). Pinchos debajo.
- **Enseña** el ritmo de aterrizar y dar el dash inmediatamente: tres cruces seguidos en 15 s.
- **Simulador.** Dash: margen **20**. Sin habilidades: imposible. **También** se cruza con solo el doble salto (margen 17): `01` la marca "Dash opcional", y así se queda, pero no es llave propia (ver `&`, §9).

## 6. Las demás salas, dimensionadas

Estas salas siguen las mismas reglas y se dibujarán al construirlas; las cotas salen de las tablas de §1.2 y **no están aún simuladas**.

### 6.1 La voz de cada región

| Región | Cómo se mueve el jugador | Suelo del fallo | Mezcla |
|---|---|---|---|
| Cinturón | Aire libre, escalones anchos, dash y doble salto por turnos | escalón o suelo de abajo | 70 % huecos y alturas |
| Archivo | Pasillos blancos y torres lisas: el contraste decide por dónde se va | pinchos de tinta | 50 % lisas, 30 % huecos |
| Minas | Pozos con tablones y pinchos laterales; vías rotas con dash | tablón de rescate o pinchos | 60 % pared, 30 % dash |
| Costa | Acantilados, cornisas largas, pilares lisos de sal | sala de abajo (playa) | 60 % huecos largos |
| Herida | Fragmentos mal recordados: salas conocidas con la regla cambiada | pinchos | combinaciones |
| Umbral | Casi nada: sube y baja tablones; las puertas excavables son de `03` | caída corta | — |

### 6.2 Cinturón

- **CIN-24 · El Granero Sin Techo (112×64, doble salto, dif. 3).** Siete vigas (tablones de 6 de ancho) con huecos de **14, 16, 15, 18, 6 y 19** y alturas relativas de +5, +6, +4, −4, +13 (aquí el doble salto), 0 y −8. Los tablones se atraviesan desde abajo, así que el fallo solo cuesta una viga. Cierra con la caída de sentido único al Umbral.
- **CIN-21 · El Descenso del Brocal (64×96, Agarre, dif. 2).** Vuelta del descenso: pozo de ancho 8 en dos tramos de 40, con una repisa de descanso de 10 entre ambos; hierba de pinchos en la mitad de cada repisa (un lado seguro de 5). Sin lisas.
- **CIN-01, CIN-05, CIN-06, CIN-07**: ya construidas. La Chimenea, simulada con el simulador ampliado, da márgenes de 14 a 20 (ver §11.1).

### 6.3 Costa

- **COS-02 · Los Escalones del Tajo (100×70, Agarre, dif. 3).** Tres pozos de ancho **6, 5 y 4** y alturas 14, 16 y 18, unidos por rellanos de 8. En el tercero aparece el primer tramo liso (6 en una pared). Tramos con luz de faro.
- **COS-04 · El Pilar de Lacre (80×160, Agarre, dif. 3).** Subida de cuatro tramos de 36 con rellanos de 10; en cada tramo, un pozo de ancho 7 con un tramo liso de 6 alternando de pared. Pinchos de cal solo en el suelo de los rellanos, nunca en las paredes. Ancla en el rellano superior (A25). Es el único nudo del mundo; las cuatro puertas se ven desde el primer rellano.
- **COS-11 · Los Tendederos (110×60, dash + doble salto, dif. 3).** Cuerdas de colada de 5 de ancho (tablones) con huecos de **12, 14, 17, 19, 22** y un último de **26** (las dos habilidades), con desniveles de ±4. Cae a la sala de abajo; las gaviotas se colocan lejos de los saltos.

### 6.4 Archivo

- **ARC-19 · El Archivo en Blanco (144×70, dash + doble salto, dif. 4).** Siete plataformas de 6 de ancho, **sin relleno visible: solo un borde pálido** (§10). Huecos de **16, 18, 20, 17** y **26**, y una subida final de 13. Sin mapa. Debajo, pinchos de tinta.

### 6.5 Minas

- **MIN-09 · La Sala de Estratos (100×60, doble salto, dif. 3).** Tres capas de plataformas que "cambian" (el dibujo, no la colisión): subidas de 12 y 15 alternando con huecos de 8 a 14. No exige dash.
- **MIN-17 · La Veta Tapiada (64×200, Excavar, dif. 2).** Atajo hacia la Cisterna: una pieza `$` de 3×3 como cerradura y, tras ella, seis tramos de pozo de ancho 8 con rellanos de 10; sin pinchos ni enemigos.
- **MIN-24 · El Pozo del Latido (80×240, Excavar, dif. 2).** Subida a la Puerta Sin Muro: ocho tramos de 30; el ancho se estrecha de 8 a 5 según se sube y el sonido del Latido crece. Rellanos de descanso de 10.
- **MIN-25 · La Mina Inundada (112×60, dash + doble salto, dif. 3).** Plataformas sobre agua con huecos de **14, 16, 18, 20, 24 y 26** y desniveles de ±3. Caer al agua no mata: sala de abajo con saturados.

### 6.6 Herida

- **HER-07 · La Cisterna Doblada (96×31, Excavar, dif. 3).** La escalera de la Cisterna, pero hacia abajo: tres suelos con **piezas `$` de 3 a 5** y, junto a cada una, una pieza igual de aspecto pero de ladrillo que no cede. Elegir mal solo cuesta dos golpes de Filo que rebotan.
- **HER-09 · Las Terrazas de Ceniza (64×24, dash, dif. 3).** Foso de **20**, isla de 6 y un segundo foso de **22**. Sin fondo: pinchos.
- **HER-11 · Las Galerías Dobladas (84×34, dash/Excavar, dif. 4).** Hilera de **24** de pinchos que salen y se retraen (grupos alternos; el ciclo de `Hazard` es de 2,4 s y 1,2 s de ventana). A pie hay que esperar la fase; con **dash a ras** se cruza en 0,15 s; con `$` debajo se cruza por un túnel paralelo.

## 7. Puzles de maestría (opcionales)

Siete salas secretas o ramas opcionales, en el espíritu del Camino Blanco y el Palacio Blanco de Hollow Knight, pero con los márgenes de este proyecto. Todas respetan estas reglas, que son las que las separan de "casi imposibles":

1. **Curva de cinco tramos**: calentamiento (margen ≥ 15, igual que el camino principal), núcleo (≥ 12), giro (≥ 10), cumbre (≥ 8 fotogramas y ± 16 px) y salida con descanso. Solo la cumbre baja de 12.
2. **Fallo barato**: 1 de daño y de vuelta al último suelo firme, o un tablón de rescate cada 21 de altura. Repetir una sala no debe costar más de 20 s.
3. **Sin enemigos, sin tiempo, sin techos bajos**, y con un Ancla o atajo de vuelta al empezar el último tramo.
4. **Premios ya previstos por `01`** (reliquia, FV, FF) o, donde `01` no los fija, una bolsa de Ecos y un objeto con lore. **Ningún Nombre**: los Nombres no dependen de la maestría, y así siguen alcanzables 28 sin opcionales (pregunta 5).
5. **Se ven desde el camino principal** (una repisa inalcanzable, una luz) y llevan una pista sin texto de la habilidad que piden.

| ID | Sala | Habilidades | Curva (margen medido o previsto) | Premio |
|---|---|---|---|---|
| SEC-06 | Los Establos de los Mensajeros (100×26) | Dash | huecos 17, 19, 20: margen 20; es el calentamiento del dash | FF; cartas sin entregar |
| SEC-09 | La Pared de Sal (40×72) | Agarre, doble salto, dash | parches de 3 cada 9 filas: margen **10** con las tres, **8** con dos, **5** con solo el Agarre | Ecos y un objeto con lore |
| SEC-08 | Torreón de las Campanas Mudas (40×100) | Doble salto, Agarre | cuatro tramos de 25: pared ancha de 7 (15), tramo liso de 6 (12), lisas alternas con doble salto (10), parches de 3 y salto de 16 al pináculo (8) | Pluma sin tinta (`01`) |
| SEC-02 | El Palomar (40×60) | Doble salto, Agarre | tres palomares de 4 de ancho en zigzag; subidas de 13, 13 y 12; pozos de ancho 5 entre ellos; margen previsto 12 | FV |
| SEC-07 | La Grieta de Rosendo (56×40) | Excavar, Agarre | pieza `$` de 3×3 sobre un pozo de 20 con pinchos laterales; hay que bajar, rodear y subir con ancho 5; margen previsto 12 | FV; lista de picos |
| SEC-10* | Los Peldaños del Ascenso (48×80, Cinturón alto) | Doble salto, Agarre | dos pozos de ancho 4 unidos por un salto de 18 sobre vacío; tres pisos; margen previsto 10 | Ecos y un objeto con lore |
| SEC-11* | La Sala Sin Suelo (80×60) | Excavar, dash, doble salto, Agarre | tres suelos de cinco piezas `$`; cada pieza cae a una cámara distinta (dash, doble salto, pared, pinchos, descanso) y la salida está en la cámara central de abajo; ninguna ruta es imposible, solo más o menos larga; margen previsto 8 | Ecos y un objeto con lore |

HER-17 La Sala Desmontada (§5.9) es una octava rama opcional, de Nombrar, que da la Página de Corvel de la Herida.

Cada sala secreta se **anuncia en una región anterior**: una repisa con una luz azul que no se alcanza hasta tener la habilidad, un mojón de Mensajero, una veta ámbar. La entrada vuelve a verse al regresar con todas las habilidades; no hay secretos "para siempre perdidos".

## 8. Secuencias de ruptura

Una ruptura es llegar a un sitio sin la habilidad prevista. La regla es: **hacia atrás se permite, hacia delante se impide**.

### 8.1 Permitidas a propósito (probadas con el simulador)

| Ruptura | Cuándo | Margen medido | Veredicto |
|---|---|---|---|
| Cornisa del Ancla de la Torre de Riego sin doble salto, con Agarre y dash | tras La Era | 15 con las dos; **3 solo con Agarre** | Permitida; la de solo Agarre es de experto y no se corrige |
| Los Bancales Altos con Agarre y dash | tras La Era | 15 | Permitida |
| La Acequia con Agarre y dash (sin doble salto) | tras La Era | 8 | Permitida, ruta de experto |
| La Chimenea Vuelta con Agarre y solo dash o solo doble salto | en la Herida | 12 y 15 | Permitida |
| Los Establos con doble salto en vez de dash | tras la Torre | 17 | Permitida; si se quiere cerrarla, el muro de cera (§9) |
| La Pared de Sal con solo Agarre | cualquier orden | 5 | Permitida: es la ruta de experto del puzle |

Son los **saltos "pixel-perfect opcionales hacia atrás"**: el que vuelve con más habilidades puede tomar atajos, y eso es el metroidvania. Todos tienen margen ≥ 3 fotogramas (físicamente posibles) y ninguno está en el camino principal.

### 8.2 Impedidas (con regla y con prueba)

- **Saltarse una puerta con una habilidad anterior.** Cada sala de puerta se simula con el inventario anterior (§1.3) y debe dar "meta no alcanzable". Resultados: Pozo de Piedra Seca no se pasa con doble salto y dash; Biblioteca Intacta no con Agarre; Chimenea Vuelta no sin Agarre; Hueco del Pico no con ninguna habilidad de movimiento.
- **Paredes de ladrillo alrededor de puertas de doble salto o dash en salas de orden libre** (Archivo y Costa): se cambian por `%`. En el Cinturón alto no hace falta (el jugador aún no tiene el Agarre) pero al volver sí se rompen, y es lo permitido de §8.1.
- **Obligar a Excavar en el Archivo o la Costa**: las dos regiones deben poder terminarse sin ella (el Pilar de Lacre solo exige Agarre).
- **Pixel-perfect obligatorio.** Ninguna ruta del camino principal baja de 12 fotogramas; en el simulador, la prueba automática falla por debajo.
- **Corrección de esquina y borde**: los huecos de 1 baldosa de alto bajo una esquina no se usan como puerta (la corrección de 8 px los abre).
- **Callejones `$`**: todo túnel de debajo de una pieza `$` tiene una salida que no exige Excavar para volver (MIN-16 lo cumple por simulación).
- **Técnica del dash al principio del salto**: anula la subida (el dash fija la velocidad vertical a 0). No es una ruptura, pero evita el "dash para bajar": las alturas de doble salto no se pueden saltar con dash.

## 9. Mecánicas nuevas propuestas

Se prefiere reutilizar lo que existe y lo que `03` ya propone. Lo nuevo, por prioridad:

| # | Mecánica | Glifo | Por qué | Coste | Usos (regiones) |
|---|---|---|---|---|---|
| 1 | **Pared lisa**: sólida, el Agarre no se queda | `%` | sin ella el Agarre rompe el diseño vertical (§0, hallazgo 2) | S: una baldosa nueva con un dato en el `TileSet` (como el de "un solo sentido"), una comprobación en `PlatformerMotor` y una prueba | 8 salas, 4 regiones |
| 2 | **Pinchos laterales**: dañan 1 y devuelven al último suelo firme | `{` `}` | alternar paredes necesita castigo en la pared; es la versión lateral de lo que ya hay | S a M: `Hazard` con forma girada y su dibujo | 5 salas, 3 regiones |
| 3 | **Muro de cera**: se rompe solo con dash | `&` | única forma de que el dash sea llave propia con el doble salto | M: un objeto que consulta `dash.is_dashing`, como `BreakableProp` | 3 salas (Archivo, Establos, Costa) |
| 4 | **Reglas de caída por región** | — | convención de diseño, sin código | 0 | todas |

Reutilizados sin cambios de `03`: suelo hondo `$` (M2) para Excavar, compuerta `=` (M3) y Piedra de lectura `n` (M6) para el tablón de memoria, plataforma sobre carril (M7) y corrientes (M8) si el diseño de entorno las quiere en estas salas (la física de §1.2 cambia, ver nota).

**Descartadas** (coste mayor que valor para un proyecto pequeño): ganchos y balancines (otro sistema de control entero); rebote en pinchos o enemigos (pogo): útil pero obliga a diseñar con el ataque hacia abajo para todo, y multiplica los márgenes por dos; columnas que caen como mecánica de movimiento (ya existe M10 para entorno); cintas y gravedad invertida.

## 10. Reglas de legibilidad

### 10.1 Qué se puede pisar y qué es decorado

1. **El borde superior de todo lo sólido lleva una línea clara de 1 píxel** (`T`, `B`, `C` y tablón). El decorado (columnas, estanterías de fondo, arcos) nunca la lleva y es siempre dos pasos más oscuro que lo sólido.
2. **Los tablones** tienen color propio (madera cálida), soportes visibles y bordes sin musgo; si el jugador puede atravesarlos, se ve la luz por debajo.
3. **Primer plano sin ambigüedad**: lo que está por delante del jugador (hierba, huesos) es bajo y estrecho; nunca tapa un salto.
4. **Las plataformas de aterrizaje de un puzle son más anchas de lo que parecen necesarias** (≥ 6; ≥ 5 solo en maestría) y llevan una marca: un mojón, una lámpara o una reja.

### 10.2 Cómo se señala el peligro

- Pinchos de hueso con silueta propia (tono rojo óseo), nunca camuflados con el fondo; los pulsantes avisan 0,35 s antes (ya existe en `Hazard`).
- **Pinchos laterales** con la misma silueta girada; cada tira mide 6 y tiene siempre dos tiras vecinas de pared libre.
- El abismo que lleva a otra sala (Costa) se anuncia con niebla en el borde y una luz abajo (la playa), para que sea "una caída", no "una trampa".
- El suelo seguro de una repisa de pinchos es siempre el lado cercano a la entrada.

### 10.3 Pared lisa y pared agarrable (convención por región)

| Región | Lisa (`%`) | Agarrable |
|---|---|---|
| Cinturón | no hay (se sube con ladrillo viejo y hendiduras de hoz) | ladrillo con musgo y hoz grabada |
| Archivo | **blanco** liso con juntas finas | agarres **negros** sobre blanco (como en `ARC-01`) |
| Minas | roca pulida por la carga con brillo de cuerda | roca con vetas y clavos |
| Costa | **sal** blanca, casi azul | ceniza con grietas |
| Herida | lo que "se recuerda mal": brillo sin textura | lo que aún tiene detalle |

Una sola regla: **brillo sin grieta = no se agarra**. Si una `%` lleva una grieta dibujada es un fallo de arte.

### 10.4 Enseñar cada habilidad sin texto

1. **Mostrar**: una huella de polvo o un objeto del dueño del recuerdo en el sitio imposible (la hoz clavada en la pared del primer pozo; una pluma en la cornisa del Ancla; un pie alado de hierro en el borde del foso; una veta ámbar en el muro del Hueco del Pico).
2. **Probar sin riesgo**: la primera vez, suelo debajo, sin enemigos, con la repisa visible.
3. **Torcer**: la condición nueva (un pincho, una lisa, un hueco más ancho) aparece en una segunda sala, nunca en la primera.
4. **Combinar** solo cuando las dos piezas se han jugado por separado.
5. **"Ver antes de poder"**: la meta o el hueco que exige una habilidad nueva se ve al menos una sala antes (el foso de las Terrazas, la cornisa de la Torre, los pozos lisos de `CIN-19`, el Pilar de Lacre desde la Cornisa de Sal). En salas más altas de una pantalla (30 filas) hay un **foco de luz** o un banderín en lo alto.
6. **Una pantalla, o dos contiguas, bastan** para ver causa y consecuencia (la cámara es de 54×30 baldosas): los saltos largos (de 26 en adelante) siempre muestran la plataforma de destino antes de despegar, así que las salas con huecos largos son anchas (≥ 96) y no altas.

## 11. Comprobaciones

### 11.1 El simulador

`tools/sim_saltos.js` hoy solo conoce el dash (`node tools/sim_saltos.js mapa.map 1 fila col`). Para validar las salas de este documento **hay que ampliarlo**; lo hice como prototipo fuera del repositorio (en el directorio temporal) con estas diferencias:

- Parámetros de la maniobra nuevos: `djAt` (fotograma del segundo salto), `wj` (saltos de pared), `wjDelay` (fotogramas agarrado antes de saltar), `wjAway` y `wjHold`. La pared sólo se agarra si se pulsa hacia ella y la baldosa no es `%`.
- Pinchos laterales (`{` `}`), suelo hondo (`$` tratado como sólido) y pared lisa (`%`, sólida y sin agarre).
- Margen por parámetro, como el original, más `dj` y `wj`.
- Interfaz: `node sim.js sala.map HABILIDADES fila_inicio col_inicio [fila_meta]`, con `HABILIDADES` una combinación de `D` (dash), `J` (doble salto) y `W` (Agarre); vacío es "sin ninguna".

Comprobación cruzada con La Chimenea real y dash: margen **14** en el primer cruce y de 14 a 20 en el resto; el simulador original da 15 a 17.

### 11.2 Resultados (peor margen del camino, en fotogramas; "—" = no alcanzable)

| Sala | Con el inventario exacto | Con el anterior | Otras |
|---|---|---|---|
| CIN-15 Bancales Altos | J: 19 | sin habilidades: —; D: — | D+W: 15 |
| CIN-12 La Acequia | D+J: 20 | D: — (llega al pilar 2); J: — | D+W: 8 |
| CIN-25 Pozo de Piedra Seca | W: 16 | D+J: — | — |
| ARC-09 Biblioteca Intacta | J: 14 | W: —; D+W: — | J+W: 15 |
| MIN-13 Zapadores | W: 20 | D+J: — | — |
| MIN-16 Hueco del Pico | sin habilidades, `$` rota: 12 y 16 | con `$` sólida y las tres: — | — |
| COS-03 Cornisa de Sal | D+J: 20 | D, J, W, J+W, D+W: — | D+J+W: 20 |
| HER-08 Chimenea Vuelta | D+J+W: 20 | D+J: —; W: — | D+W: 12; J+W: 15 |
| HER-17 Sala Desmontada | con `=`: D+J+W: 18 | sin `=`: —; W: — | — |
| SEC-09 Pared de Sal | D+J+W: 10 | D+J: — | J+W: 8; W: 5 |
| SEC-06 Establos | D: 20 | sin habilidades: — | J: 17 |

### 11.3 Margen mínimo exigido

- **Camino principal**: 12 fotogramas en todos los parámetros y ± 18 px de posición inicial (ventana de 36); la mayoría sale de 15 a 20.
- **Maestría**: 8 fotogramas y ± 16 px (ventana de 32), sólo en el tramo "cumbre".
- **Aterrizaje**: ancho ≥ 6 en el camino principal; ≥ 5 en maestría; ≥ 4 en tablones de rescate.
- **Pozos de pared**: ancho ≥ 4 en el camino principal; 3 sólo en maestría.

### 11.4 Qué añadir a la prueba de humo (`tests/smoke_test.gd`)

1. **Planes de maniobras por fotograma.** `tests/puzzle_plans.json` hoy guarda parámetros de dash; para doble salto y pared es mejor guardar la lista de entradas por fotograma (`{f, accion, pulsa}`) que genera el simulador, y que `_replay_plan` la repita en el motor. Es el mismo mecanismo (pulsar un fotograma antes, `Input.action_press` sólo al cambiar).
2. **Prueba de puerta por sala**: repetir el primer plan clave sin la habilidad (`unlock_ability` falso) y comprobar que no llega, como hace `_test_dash_puzzle_needs_dash` para la Chimenea.
3. **Techos**: `_test_no_platform_has_a_cramped_ceiling` tiene la lista de salas fija y sólo mira `TGBC`; hay que añadir las salas nuevas y los caracteres `%` y `$`.
4. **Aterrizajes anchos**: recorrer cada `.map`, hallar las superficies del camino principal y comprobar que miden ≥ 6 (lista blanca de maestría).
5. **Pozos**: comprobar que el ancho de un pozo de pared es ≥ 4 (lista blanca de maestría).
6. **`%` no se agarra**: un cuerpo caído junto a `%` mantiene la velocidad de caída.
7. **Pinchos laterales**: dañan 1, devuelven al suelo firme y no matan (como `_test_spikes_hurt_and_return_to_safe_ground`).
8. **Salidas de `$`**: tras romper una pieza, el jugador puede volver a su sala sin Excavar.
9. **Manifiesto** (`tests/world_manifest.json`, propuesto en `01` §8): añadir `requiere` por sala y verificar con el simulador que cada sala de puerta se supera con ese inventario y no con el anterior.
10. **Ejecución obligatoria**: `godot --headless --path . --script res://tests/smoke_test.gd` con código 0, además de jugarlo.

## 12. Preguntas abiertas

1. **¿Se aprueba la pared lisa `%`?** Es el cambio más barato y el que más protege el diseño; la alternativa es aceptar que el Agarre trivializa los pozos y diseñar a favor.
2. **¿El Agarre recarga el dash y el doble salto?** Hoy no. Con recarga, las combinaciones con pared serían más generosas; los márgenes de §11 habría que rehacerlos.
3. **¿Se aprueban los pinchos laterales `{ }`?** Sin ellos, MIN-13 y SEC-07 se quedan sin su giro; la alternativa son tiras de `^` y `v` en repisas.
4. **¿El Golpe Hondo es un ataque hacia abajo en el suelo, como en `03` M2?** Aquí se asume que sí. Si se quiere "descenso en picado" en el aire, cambian MIN-16 y SEC-07.
5. **¿Pueden los Nombres colgar de una maestría?** Se ha evitado (28 alcanzables sin opcionales). Si se aceptara, el candidato natural es Ardena, que `03` P18 ya esconde tras un marco.
6. **¿Se necesita el muro de cera?** Sólo si se quiere que el dash sea llave por sí mismo una vez existe el doble salto. Si no, los puzles de dash se leen como "dash o doble salto".
7. **Viento y plataformas móviles de `03`.** ¿Se permiten en las salas de este documento? Cambian los alcances (§1.2) y obligan a simular con corriente.
8. **¿Un tablón de rescate bajo cada hueco de la Costa?** Caer lleva a una sala inferior y repetir cuesta ~25 s; el margen de §7 pide ≤ 20 s.
9. **Salas extra (140 en lugar de 136).** SEC-09, SEC-10, SEC-11 y HER-17 se añaden; si no caben, se pueden convertir en habitaciones de otras secretas.
10. **¿Dificultad asistida?** Coyote ampliado o buffer más largo como opción de accesibilidad: no cambia ninguna sala, pero los márgenes de §11 serían todavía mayores.
