# Personajes: el Caminante y los PNJ

Autor: diseñador de personajes (sala de artistas). Estado: propuesta para la reunión; nada de esto está aprobado hasta que lo decida el usuario. Se apoya en `docs/historia.md`, `docs/personajes.md`, `docs/guion-maestro.md`, `docs/arte.md`, los informes 01 (biblia visual), 02 (pipeline) y 03 (interfaz, efectos y animación), y en la lectura directa de `tools/rig_lib.js`, `tools/rig_caminante.js` y `tools/rig_enemigos.js`.

Referencias como lenguaje, no como modelo: de *Hollow Knight*, la silueta que se lee en un parpadeo; de *Blasphemous*, la ropa que cuenta una orden y una culpa; de *Death's Gambit* y *Salt and Sanctuary*, la pobreza material creíble; de *Dead Cells*, la animación como carácter. La identidad propia sigue siendo la del informe 01: **el color es memoria**.

---

## 0. Resumen de decisiones que propongo

1. **El Caminante no cambia de personaje: cambia de oficio.** Seis cambios acumulativos, cada uno con dueño (Oda, Tomasa, Jacinto, el Archivo, Magda, Linde) y legibles en silueta o en dos píxeles de acento. Se hornean en el rig (cinco hojas) y los trapos de Nombrar se superponen como pequeño sprite aparte.
2. **El lienzo del Caminante tiene que crecer de 112×64 a 112×96.** Es el hallazgo técnico más importante de este informe (sección 1.5): el golpe hacia arriba y el Golpe Hondo se salen hoy del lienzo.
3. **Le faltan 24 animaciones** (unos 120 fotogramas nuevos). Casi todas salen solo con poses nuevas; hay seis cambios de esqueleto pequeños (sección 1.6) y ninguno obliga a rehacer el rig.
4. **Los PNJ se hacen con el humanoide actual más seis estilos nuevos** (erguido, encorvado, niño, corpulento, armadura y túnica larga, más "sentado" como postura). Hace falta una cabeza **con rostro** (`face`), porque la actual `bare` es la del cascarón: sin rasgos.
5. **Regla de legibilidad principal: piel cálida contra piel gris.** Los vivos tienen piel `8/6/5` y un píxel de brillo en el ojo; los cascarones, piel `4/3/2` sin brillo. Ningún PNJ lleva rojo.
6. **La saturación de un PNJ mide cuánto recuerda.** El mismo sombreador de desaturación del informe 01 se aplica por PNJ según su fase de arco: Iria, Quiteria y Casilda se apagan literalmente al olvidar. No cuesta arte nuevo.
7. **Retratos de 48×48 generados por capas** (base de busto + cabello/rasgos/expresión) con un generador pequeño, y retoque a mano solo de los cuatro PNJ principales. Hasta que exista, el diálogo funciona con un emblema de 16×16 junto al nombre.

---

## 1. El protagonista: Ansel Varga, el Caminante

### 1.1 Ficha de diseño definitiva

**Quién es, visto desde fuera.** El Eco de un Relator que fue Raspador de la Orden. No habla. Se le conoce por lo que otros dicen de él y por cómo se mueve. Todo en su diseño dice tres cosas: *sirvió de cuchillo* (capucha, daga del revés, agazapado), *fue elegido para no olvidar* (máscara azul del Relevo) y *aún conserva algo de calor humano* (ribete ámbar, bolsa, cinto). La paleta ya lo cuenta: oscuro como la piedra, con el azul de lo recordado y el ámbar de lo vivo.

**Medidas (lo que dibuja hoy el rig, con `HERO`).**

| Parte | Medida en px | Origen en el rig |
|---|---|---|
| Altura agazapado (reposo) | ~42, con la punta de la capucha ~44 | `legLen` 9,6 por hueso, `waistLen` 7, `chestLen` 6,5, `lean` 24 |
| Altura erguido (hipotética) | ~48 | misma suma sin inclinación |
| Ancho del cuerpo | ~20; con la capa en carrera, hasta ~38 | `torsoR` 4,4-5,4 |
| Cabeza | radio 5,6; capucha con punta de 9,5 | `headR`, `hood` |
| Rostro visible | óvalo de 3×4 px con **máscara en la mitad inferior** (2 filas `g` y `f`) y ojo `h`/`g` | `Hd.mask`, `Hd.eye` |
| Arma | daga curva de 24 px con guarda ámbar `c/d` | `weaponLen` 24, `curve` -48 |
| Capa | 5 segmentos de 6,2 px, base `2`, pliegues `1`, borde `3` | `cape` |
| Bufanda | 4 segmentos de 4,6 px, azul `f g h` | `scarf` |
| Colisión | 24×48 (el dibujo agazapado queda 4-6 px por debajo del techo de la colisión) | `docs/arte.md` |

**Silueta.** Diagonal agazapada con la capucha como punta delantera y la capa como contrapeso trasero: una "flecha tumbada". A 864×486, el Caminante ocupa 44 de 486 píxeles de alto (el 9 %): es pequeño, así que **la silueta debe sobrevivir a la escala de grises** (prueba obligatoria del informe 01) y los acentos de color son lo que lo recorta del fondo.

**Los cinco rasgos que no se tocan nunca** (si se pierden, deja de ser él):
1. Capucha puntiaguda con ribete ámbar.
2. Máscara azul en la mitad inferior del rostro.
3. Bufanda azul con inercia.
4. Daga curva empuñada del revés, con el puño junto a la cadera.
5. Postura agazapada con el torso adelantado.

**Reglas de color propias** (excepción deliberada a la "regla de oro" del informe 01: ámbar y azul en un mismo objeto):

- **Azul = Eco**: máscara, bufanda, filo, estela, imágenes residuales. Es lo que lo une al Eco de muerte y a las reliquias.
- **Ámbar = lo humano que sobrevive**: ribete de la capucha, guarda de la daga, cinto, bolsa. Es el único ámbar "personal" del juego, y por eso cada etapa de evolución añade ámbar o calor, nunca rojo.
- **Rojo: jamás.** Lo único rojo que lleva el Caminante son los destellos de daño recibido, que son del sistema de feedback, no del sprite.
- **No se desatura nunca** (informe 01, 3.1.2). Cuanto más gris está el mundo, más se lee.

**Identidad en pequeño.** Para el HUD, la pausa y el retrato: la **máscara** es el emblema del personaje (media máscara azul con un ojo). Un icono de 16×16 del emblema sirve para el menú de personaje y para el marcador del mapa del jugador.

### 1.2 Principios de la evolución visual

La evolución debe respetar tres restricciones: lo que el rig puede dibujar, lo que cuesta mantener un autor único y lo que el jugador puede ver a 864×486.

1. **Regla de los 4 píxeles.** Un cambio que deba verse jugando tiene que alterar la silueta en **≥ 4 px** o añadir **≥ 2 px de un acento de color**. Los micro-cambios (una grieta de 1 px en la máscara) se reservan para retrato y pausa.
2. **Cada cambio tiene dueño.** El jugador debe poder preguntar "¿de quién es ese trapo?" y obtener respuesta del mundo. Es la regla narrativa de `guion-maestro.md`: *toda técnica era de alguien*.
3. **Se acumula, no se sustituye.** No se pierde nada de lo anterior; al final el Caminante lleva encima las huellas de cinco vidas ajenas. Visualmente es un collar de pequeños objetos de oficio sobre una figura de asesino.
4. **El cambio se produce en la "gran escena"** de la habilidad (informe 03, 2.11), que ya fija un momento en que el mundo se desatura y el jugador no controla: es el sitio natural para cambiar de hoja sin que se note el salto.
5. **Nunca tapar los cinco rasgos fijos.**

### 1.3 Tabla de evolución

Cada etapa se hornea con parámetros nuevos del estilo (`mods`, ver 1.6) salvo donde se indica "superposición".

| Etapa | Momento | Qué cambia (descripción de píxeles) | Dueño | Implementación | Visible jugando |
|---|---|---|---|---|---|
| **E0 Despertar** | Inicio | El sprite actual, sin tocar. | — | Ya existe | Base |
| **E1 La prisa** | Tras el Dash (Aljibe) | La bufanda pasa de 4 a 6 segmentos y su punta se vuelve `h` brillante: más estela en el dash y la carrera (+8 px de silueta hacia atrás). | Oda | `scarfSegs: 6`, `scarfTip: 'h'` | Sí (silueta) |
| **E2 El vigía** | Tras el Doble salto | Una cuerda de vigía (`6/5`) cruzada en bandolera, con un lazo que cuelga 6 px del costado y se balancea con inercia propia (cadena corta). | Tomasa | `strap: '6'`, `ropeLoop: true` (cadena `trailChain` de 3 tramos) | Sí (silueta y acento) |
| **E3 El trigo** | Tras el Salto de pared | Antebrazos y manos con vendas de paja `7/6` (solo brazos, no piernas) y una espiga seca `7` de 5 px atada al cinto. | Jacinto | `wrapsArms: ['7','6']`, `ear: true` | Sí (acento de 2 px) |
| **E4 La tinta** | Tras la Sala de los Relatores (Archivo) | El puño de la daga pasa de gris a azul tinta (`f/e`) y los dedos de la mano lejana, también. Es la mano de un Relator. | El Archivo | `handCol: ['f','e']` | Poco: se ve en pausa y retrato; se refuerza en E5 |
| **E5 El pico** | Tras Excavar (Minas) | Muñequera de cuero `6/5` de 4 px en el antebrazo cercano; el borde inferior de la capa se aclara dos tonos (polvo de roca, `3` sobre `2`); una veta azul `g` en la hoja, junto a la guarda. | Magda | `bracer`, `capeDust`, `bladeVein: 'g'` | Sí (muñequera) |
| **E6 El oficio** | Tras Nombrar (Umbral, acto IV) | **El ojo pasa de azul `h/g` a ámbar `d/c`** (1-2 px, ver el ojo en la pausa y en la animación de Nombrar) y aparecen los **trapos de nombres** en la muñeca. | Linde y los Que quedan | `eye: ['d','c']`; trapos como superposición (1.4) | Sí (trapos) |

**Por qué el ojo ámbar.** Es el único cambio que toca el rostro y el que más dice: el Eco azul empieza a tener el calor de una persona. Sigue la regla del informe 01: ámbar es lo que alguien recuerda.

**Finales (sprites de epílogo, no del juego principal).** Tres mini-conjuntos, uno por final, todos a partir del estilo E6:

| Final | Aspecto | Contenido |
|---|---|---|
| **Sellar** | Sentado en el asiento de Maelis; capucha puesta; máscara completa y sin ámbar (el ribete pasa a `2`: se apaga). | 1 pose sentada + 4 fotogramas de respiración lenta |
| **Soltar** | De pie, de frente al Margen. El sombreador lo desvanece hacia `w` desde los pies. | Sin arte nuevo: idle + sombreador |
| **Compartir** | **Sin máscara y con la capucha caída**: rostro visible (cabeza `face`, ver 2.0), piel cálida, ojo ámbar, trapos de muñeca. Envejece: sin capa. | idle (4) + andar (8) con estilo `mortal` y retrato en 3 expresiones |

Esta es la única vez que el jugador ve el rostro de Ansel: por eso el estilo `face` se construye una vez y se reutiliza en los PNJ.

### 1.4 Cómo se hornean los cambios: hojas y superposiciones

**Problema.** Todo lo que cambia en el cuerpo (bufanda, cuerda, vendas, manos) está *dentro* de la figura que el rig dibuja fotograma a fotograma: no se puede añadir como capa sin que el movimiento no case. Lo que sí se puede superponer son objetos pequeños con su propio movimiento (los trapos).

**Recomendación.**

| Concepto | Solución | Coste |
|---|---|---|
| E1-E5 (cambios del cuerpo) | **Una hoja por etapa**, generada por el mismo rig con `mods` acumulativos: `player_e0.sprite` ... `player_e5.sprite` (cada una con su PNG). Solo una está residente: el cambio de textura ocurre en la gran escena de la habilidad. | 1 enum + 1 textura; el generador corre 5 veces |
| E6 (trapos) | **Superposición**: un `Sprite2D` hijo de 8×16 con 1 a 6 trapos, anclado a la muñeca cercana (`fist`), con su propio vaivén de 4 fotogramas en bucle. | 1 hoja de 4 fotogramas por nº de trapos |
| Ojo ámbar | Se hornea en la hoja E6 (el ojo es 1-2 px de la cabeza). | 0 |

**Presupuesto de memoria.** Con lienzo 112×96 y unos 175 fotogramas por hoja, cada hoja pesa ~7,5 MB empaquetada (atlas, informe 02, 4.3) o ~16 MB en rejilla rectangular. Solo hay una cargada. En disco: los `.sprite` generados no deberían versionarse (informe 02, 4.4); se versionan el generador y el PNG.

**Opción barata.** Fusionar E1+E2 y E3+E4+E5 en tres hojas en total (inicio, tras Doble salto, tras Excavar+Nombrar). Se pierde el cambio inmediato tras el Dash y tras Jacinto, pero se ahorran dos hojas. Es una decisión de calendario; ver preguntas.

**Anclajes necesarios.** El manifiesto por fotograma (informe 02, 3.3) debe exportar los puntos: `fist` (ya lo devuelve `render`), `head`, y añadir `neck`, `shoulder`, `hip`. Sirven para trapos, para el frasco al curarse, para la luz de Nombrar y para los efectos del golpe.

### 1.5 Lista completa de animaciones

**Hallazgo de lienzo.** El lienzo actual (112×64, pies en la fila de abajo) deja ~20 px sobre la capucha en reposo. Un golpe hacia arriba pide: hombro a ~34 px del suelo, brazo de 13,6 px extendido hacia arriba y daga de 24 px: la punta queda a ~-4 px, **fuera del lienzo**. El Golpe Hondo, con la daga alzada sobre la cabeza antes de caer, igual. **Propuesta: lienzo de 112×96** (múltiplo de 8, informe 02, 3.1), pies en la última fila. La colisión no cambia (24×48); solo hay que desplazar el `Sprite2D` 16 px y regenerar todo. Coste: S, pero **primero, antes de dibujar nada nuevo**. Alternativa: 112×80 y limitar el golpe hacia arriba a un arco frontal inclinado 45° (pierde el efecto de "tajo sobre la cabeza").

**Convenciones.** Orientación a la derecha. `lean` 0 = vertical, positivo hacia delante; `blade` 0 = hacia delante, 90 = abajo, -90 = arriba, 180 = atrás; `fx,fy` = destino de la mano cercana respecto al hombro (x a la derecha, y hacia abajo); `hipy` negativo = cadera sobre el suelo. Los números son orientativos: se ajustan jugando.

**Lo que existe (58 fotogramas):**

| Animación | Fotogramas | fps | Bucle |
|---|---|---|---|
| `idle` | 10 | 10 | sí |
| `run` | 14 | 40 | sí |
| `jump` | 4 | 24 | no |
| `fall` | 4 | 16 | sí |
| `attack` | 12 | 40 | no |
| `parry` | 4 | 20 | no |
| `hit` | 4 | 16 | no |
| `dash` | 6 | 40 | no |

**Lo que falta (24 animaciones, ~116 fotogramas nuevos).** Prioridad: A alta (bloquea el juego), M media, B baja. Los fotogramas se cuentan sin duplicar los que se pueden obtener invirtiendo otra animación.

| # | Nombre | Fotogramas | fps | Bucle | Prio. | Cambio de rig | Pose clave y descripción |
|---|---|---|---|---|---|---|---|
| 1 | `land` | 3 | 18 | no | A | ninguno | **Impacto:** `hipy` -13, `lean` 40, rodillas dobladas (`nfx` 11, `ffx` -9), capa subiendo (`capeTy` -0,6), daga atrás. Fotograma 2 recupera; fotograma 3 enlaza con `idle`. |
| 2 | `wall_grab` | 2 | 6 | no | A | ninguno | **Entrada al muro** (el muro está a 12 px del centro, delante): `lean` 10, pecho hacia la piedra; mano cercana alta pegada al muro (`fx` 7, `fy` -12); pie cercano apoyado en el muro (`nfx` 11, `nfy` -9, `nfa` -80); pie lejano más bajo; daga **recogida atrás** (`blade` 190) para que no toque la piedra. |
| 3 | `wall_slide` | 4 | 8 | sí | A | ninguno | **Deslizamiento:** igual que el agarre, con 1 px de vaivén de cadera y el pie cercano arrastrando; la **capa sube** y se pega al torso (`capeTy` -1, `capeAmt` 1): le da sensación de caída. Polvo del informe 03 (2.5) en la mano. |
| 4 | `wall_jump` | 3 | 14 | no | A | ninguno | Fotograma 1: cuerpo estirado separándose del muro; 2: giro de torso 180° de hombros (`lean` -12 → 28); 3: pose de `jump` mirando al lado contrario. El volteo de `scale.x` se hace al empezar. |
| 5 | `double_jump` | 6 | 20 | no | A | **`spinPose`** | **Voltereta corta hacia delante** (0° → -300°): cuerpo recogido (rodillas al pecho, `nfy` -10), daga pegada al pecho; la capa se abre en abanico (`capeAmt` 1, `capeWave` 0,6). Último fotograma = `fall`. Cuerda de vigía (E2) ondea. |
| 6 | `attack_up` | 6 | 20 | no | A | lienzo 96 | **Golpe hacia arriba.** Pose clave del tercer fotograma: `lean` 8, `bend` 4, pie adelantado; mano `fx` 14, `fy` -18; `blade` -80 con `curve` -30: la hoja barre un arco sobre la cabeza, de delante hacia atrás. `trailFrom` activo. Es el espejo de `attack` pero en vertical. |
| 7 | `attack_down` (pogo) | 6 | 20 | no | A | lienzo 96 | **Golpe hacia abajo.** Cuerpo encogido y alto (`hipy` -30 en el aire); mano `fx` 4, `fy` 17; `blade` 90, `curve` -6 (hoja casi recta hacia el suelo); piernas recogidas. Los fotogramas 4-6 repiten el 3 con brillo de rebote: el final es "pose de pinchazo". |
| 8 | `dig` (Golpe Hondo) | 11: `dig_windup` 4, `dig_fall` 2 (bucle), `dig_strike` 5 | 14 / 10 / 30 | mixto | M | **`farFist`** | **Windup:** salto, ambas manos sobre la cabeza empuñando la daga hacia abajo (la mano lejana sigue a la cercana: `gx=fx`, `gy=fy`); **caída:** como un clavo, capa en vertical; **impacto:** rodilla hincada (`nfy` -2, `ffx` -12), puño en el suelo, polvo y grietas (efecto aparte). |
| 9 | `heal` | 10 | 10 | no | A | **`prop: flask`** | Sacar el frasco ámbar del cinto (2 f), **bajar la máscara con la mano libre** y mostrar la barbilla pálida (variante de cabeza sin máscara, 1 px de piel `8`), beber con la cabeza atrás (`head` +20, 4 f), guardar (2 f), luz ámbar subiendo (efecto). Lenta a propósito: es una acción vulnerable. |
| 10 | `die` | 12 | 10 | no | A | ninguno (`lean` > 90) | **1-4:** impacto, el cuerpo se dobla hacia atrás (`hit` extremo); **5-8:** cae de rodillas (rodilla cercana al suelo, `nfx` -8), daga resbala de la mano, capucha cae; **9-12:** se desploma de lado (`lean` 85-100, `hipy` -4), capa extendida sobre el suelo y **se deshace en motas azules** por los bordes (efecto 2.7 del informe 03). Último fotograma = cuerpo en el suelo (se mantiene mientras el Eco sube). |
| 11 | `sit` / `rest` | 8 + 4 | 6 / 5 | no / sí | M | ninguno | **Sentarse:** de pie, rodilla, sentado con las piernas cruzadas **frente al Hito**; las dos manos sobre la piedra; cabeza baja. `rest` = respiración lenta con luz ámbar. Levantarse = `sit` invertida (0 fotogramas nuevos). |
| 12 | `remember` | 6 | 8 | no | M | ninguno | Mano al pecho, mirada al frente, la reliquia flota hacia el pecho; el último fotograma es la pose de ejecución de la técnica. |
| 13 | `name` (Nombrar) | 8 | 8 | no | M | **`prop: hand glow`** | Ante la Piedra de lectura: `lean` 4 (más erguido que en cualquier otra pose), mano cercana extendida y abierta a la piedra (`fx` 12, `fy` -2), **cabeza alta y capucha caída hacia atrás un instante** (la única vez que se ve la capucha caída antes del final), ojo ámbar. Los hilos de nombres son efecto. |
| 14 | `climb` | 6 | 10 | sí | M | ninguno | **Subir escaleras de mano:** `lean` 4 (casi vertical), manos alternas arriba (`fy` -14 / -6), pies alternos sobre peldaños. Una pose de reposo `climb_idle` = fotograma 1. |
| 15 | `turn` | 3 | 16 | no | M | ninguno | Frenada al cambiar de dirección: `lean` -18 un fotograma, capa que sigue hacia delante, y arranque. Aporta peso. |
| 16 | `idle_long` | 8 | 4 | no | B | ninguno | Tras 10 s: mira alrededor, se ajusta la máscara con la mano libre. De carácter. |
| 17 | `listen` | 4 | 4 | sí | M | ninguno | **Mientras un PNJ habla:** cabeza ligeramente baja hacia el interlocutor, la daga **baja** y a un lado (lo contrario de la guardia), respira. Es la forma en que un protagonista mudo escucha. |
| 18 | `interact` | 4 | 8 | no | B | ninguno | Palanca, puerta, cofre: mano al frente, giro de cuerpo. |
| 19 | `parry_ok` | 3 | 24 | no | B | ninguno | Contragolpe tras parada exitosa: rebote del puño hacia atrás (opcional si el efecto basta). |
| 20 | `crouch` | 2 | 12 | sí | B | ninguno | Solo si se añade la mecánica de agacharse (hoy no). |
| 21 | `slide` | 4 | 12 | no | B | ninguno | Ídem. |
| 22 | `respawn` | 5 | 8 | no | A | ninguno | Reaparición en el Ancla: `sit` desde el fotograma final hacia `idle` con la luz subiendo. |
| 23 | `knockback` | 2 | 16 | no | B | ninguno | Retroceso con gran daño (más fuerte que `hit`). |
| 24 | `win` (tras jefe) | 6 | 8 | no | B | ninguno | Quietud, guarda la daga, respira: cierre del combate. |

**Totales.** Prioridad A (1-7, 9, 10, 22): ≈ 53 fotogramas. Prioridad M (8, 11-15, 17): ≈ 54. Prioridad B: ≈ 27 (si se hacen todas). Hoja resultante: 58 + ~116 = ~174 fotogramas, unas **26 filas** de hoja.

**Esquemas de las poses más complejas** (cada carácter ≈ 2×2 px; la daga se dibuja con `/` y `\`).

`wall_grab` (muro a la derecha):

```
        .--.   |
       /_  ) o-|   <- mano plana sobre el muro
       |  (/  |
       | / \  |
       |/   \ |
      /|     \|__  <- pie cercano contra la piedra
     / |      |
    /  |_     |
        |_    |
```

`attack_up` (fotograma central, el arco pasa sobre la cabeza):

```
         .-''''-.
       .'  hoja  '.
      /     /\     \
     |     /  \     |
           o--+       <- puño alto
          /|
         / |        capa hacia atrás
        /  |\
```

`die`, fotogramas 4, 8 y 12 (de pie, de rodillas, en el suelo):

```
  [4]       [8]            [12]
   o         o              ____o____~~~
  /|\        |\            /___/\___   (motas
  / \        | \_          capa y cuerpo  azules
             |__\          sobre el suelo)
```

### 1.6 Cambios del esqueleto (`rig_caminante.js` / `rig_lib.js`)

Ninguno exige reescribir el rig. Son pequeños y se pueden hacer a medida que se pide cada animación.

| # | Cambio | Qué resuelve | Esfuerzo | Notas |
|---|---|---|---|---|
| R1 | **Lienzo 112×96** (`setCanvas(112, 96)`) | Golpe hacia arriba y Golpe Hondo | S | Regenerar todo; verificar que los fotogramas existentes son idénticos desplazados 32 px (diff controlado). Hay que corregir el offset en la escena. |
| R2 | **`spinPose(p, grados, centro)`** (helper de poses) | Voltereta del doble salto y muerte tumbada | M | Suma el ángulo a `lean` y **rota los desplazamientos** de pies (`nfx/nfy`, `ffx/ffy`) y manos (`fx/fy`, `gx/gy`) alrededor del centro. No rota píxeles (evita los *pixel mixels* del informe 02). La capa y la bufanda conservan la dirección de mundo. |
| R3 | **`farFist`**: dibujar un puño en la mano lejana | Empuñar la daga con las dos manos (Golpe Hondo) y gestos de PNJ | S | Hoy la mano lejana termina en el antebrazo sin puño; un círculo de 2,4 px más con el contorno. |
| R4 | **Objetos en mano** (`prop`): `flask`, `rag`, `quill`, `slate`... | Frasco al curarse, trapos, pluma de Sabela, pizarra | M | Un `drawProp(c, S, p, fist)` con unas 8 formas pequeñas (frasco con tapón que se quita, pluma, trapo con `trailChain` de 3 tramos). Comparte código con los PNJ. |
| R5 | **`mods` de estilo** | Evolución E1-E6 | M | `scarfSegs`, `scarfTip`, `strap`, `ropeLoop`, `wrapsArms`, `ear`, `bracer`, `capeDust`, `bladeVein`, `handCol`, `eye`. Cada uno es 3-10 líneas en `figure()`. `wraps` hoy se aplica a brazos y piernas: añadir una variante solo de brazos. |
| R6 | **Cabeza sin máscara** (`mask: null` con barbilla visible) | Beber el frasco, Nombrar, final Compartir | S | La capucha ya admite `mask: null` (la usa el Arrojador); falta un tono de piel (`8/6`) en el óvalo de la cara. |
| R7 | **Anclajes exportados** (`neck`, `shoulder`, `hip`) | Trapos, frasco, luz de Nombrar | S | `figure()` ya calcula todos los puntos; solo hay que devolverlos y escribirlos en el manifiesto. |
| R8 | **Contacto con suelo y pared** como parámetro | Apoyos de `die`, `sit`, `wall_*` | S | No es dibujo: una variable `ground`/`wallX` que `ik` use para limitar la posición. Se puede hacer a mano con números al principio. |

**Qué no hace falta tocar**: la cinemática inversa, la capa con inercia, el contorno automático, la estela del arma, las imágenes residuales. Todo el trabajo sigue siendo poses.

---

## 2. Los PNJ

### 2.0 Base común para humanos con rostro

El rig actual solo sabe dibujar cuerpos de cascarón (`head: 'bare'`, sin rasgos), de asesino encapuchado (`hood`) o de guardia (`helm`). Para un PNJ hace falta una **cabeza con rostro legible a 864×486**, es decir, con 4-6 píxeles que cuenten algo.

**Nueva cabeza `face`** (S-M, una vez; sirve a todos los PNJ y al final del Caminante):

- Óvalo de 5 px de radio con tres tonos de piel: **`8` (luz), `6` (medio), `5` (sombra)**. Variante pálida (Hondos y Descreídos de más edad): `8`/`3`.
- **Un píxel de brillo en el ojo** (`d` o `8`): regla de vida (2.15). Ojo cerrado = línea de 2 px `1`; ciego = 2 px lechosos `9`.
- Rasgos opcionales (cada uno una línea de código): nariz de 1 px que sobresale, boca (curva de 1 px, sonrisa con dientes `8` de 3 px), cejas, **cabello** (calvo, corto, moño, flequillo, cofia), **barba**, gafas (aro de 5 px `4`), oreja con venda, ojeras (2 px `2`), cicatriz (1 px `s`... solo si es piel, no rojo: usar `5`).
- Máscara/capucha/velo opcionales como capa encima.

**Nuevos estilos de cuerpo** (`makeStyle`) y sus números base. Las alturas salen de los huesos: un humano erguido con `legLen` 9,6 mide ~48; con 11,6 (estilo Coloso), ~55; con 7,4 (niño con cabeza grande), ~32.

| Estilo | Para | Cambios de `HERO` | Altura (px) | Dificultad |
|---|---|---|---|---|
| `erguido` | Vael, Quiteria, Hesper, Eudora, Magda | `lean` 0-4, `bend` 2, `legLen` 9,6, torso medio, sin capucha | 46-50 | S (es el rig tal cual) |
| `encorvado` | Aldara, Brunel, Sabela, anciana | `lean` 14-20, `bend` 14, `head` -18 | 40-44 | S |
| `niño` | Iria | `legLen` 7,4, `headR` 5,4, `torsoR` [3,3,3,2], `armLen` 5 | 32 | S |
| `corpulento` | Garrán, Dola, Magda | Proporciones del Coloso: `legLen` 11,6, `waistLen`/`chestLen` 8,6, `torsoR` [6,7,8,3] | 50-56 | S (existe) |
| `armadura` | Gaspar, Custodios | `shoulderPad`, cota con `waistBand`, `noise` bajo; peto liso con **hueco circular de 5 px** `1` donde iba el sello | 50 | M (pieza nueva: peto y grebas) |
| `túnica larga` | Vael, Quiteria, Eudora, Hesper, Sabela | **Falda** como polígono que baja de la cadera hasta el tobillo y se mece con el andar (variante de `trailChain` con dos cadenas, frente y espalda) | 48 | M (pieza nueva) |
| *sentado* | Aldara, Brunel, Casimar, Ilara | Postura: `hipy` -6, muslos horizontales; sin cambio de código si hay `ground` (R8) | 30-34 | S |

**Objetos en mano** (comparten código con R4): pizarra, tiza, clavo, cordel con nudos, pluma de hierro, yelmo bajo el brazo, honda, peine, paño, lámpara, martillo corto, pico, arpón, frasco. Los tres últimos reutilizan `maul`, `spear` y `knife`, con otros colores (el arpón sin trapo rojo: añadir `ragCol`).

**Lienzo.** Plantilla PNJ del informe 02: 64×64, `idle` (8), `talk` (6), `react` (4), `walk` opcional. Excepciones: Cano (carro) 96×64; Mirena (arpón) 80×64; el resto cabe en 64×64. Anclaje: pies abajo y centrados.

**Paquete de animación estándar por PNJ (18 fotogramas):**

| Animación | Fotogramas | fps | Bucle | Descripción general |
|---|---|---|---|---|
| `idle` | 8 | 6 | sí | Respiración (±0,5 px de hipy), peso que se mece, ropa que cuelga |
| `talk` | 6 | 8 | sí | Cabeza que cabecea 1 px, una mano que subrayea, boca que alterna dos formas |
| `react` | 4 | 12 | no | Sobresalto o gesto ante algo del mundo (golpe en el suelo, una frase sobre un muerto) |

Los **tres estados del arco** se hornean como `idle_2` e `idle_3` (8 fotogramas cada uno) o como poses de 1 fotograma, según el caso; el `talk` se comparte.

### 2.1 Reglas de color y facción

| Facción | Color de acento (2 px mínimo) | Rasgo que se repite |
|---|---|---|
| Orden: Selladores | Ocre quemado (`a/b`), cera partida (`c`), **lacre ocre, no rojo** | Guantes de cera, máscaras de lacre, sello partido |
| Orden: Penitentes | Gris ceniza (`2/3`), saco de arpillera `6/5` | Peto sin sello; hueco circular de 5 px |
| Orden: Negadores | Gris impoluto (`3/4`), sin acento | Uniforme sin una arruga, ojos muy abiertos (ojos de 3 px) |
| Descreídos | Lino `8`, cal `9`, círculo de cal de 6 px | Manos blancas; se cubren la cara al hablar de un muerto |
| Los que quedan | Trapo atado a la muñeca (`8`/`6`), un trapo por pérdida | Tierra (`5/6/7`), ropa remendada |
| Hondos | Vela de grasa `c` (con halo propio), trapo gris `x` sobre la boca | Ojos grandes (2×2 px con pupila), cuerpo fibroso |
| Mensajeros (extinguidos) | Hierro con pie alado | Solo objetos |

**Una sola luz por PNJ.** Cada PNJ aporta una pequeña luz ámbar propia (farol, vela, brasa, ventana) o está dentro del halo del Ancla o de una hoguera: es la forma de decir "aquí hay alguien que vive" sin añadir ningún rasgo.

### 2.2 Ficha de cada PNJ

Formato: silueta y medidas; ropa y colores; rasgo distintivo y legibilidad a 864×486; objetos; reposo, hablar y escuchar; los tres estados del arco; rig y estilo; fotogramas; dificultad; retrato. Todos los PNJ llevan el paquete estándar (18 f); los fotogramas extra se suman.

#### 2.2.1 Iria (niña de unos nueve años)

- **Silueta y medidas.** 32 px de alto y 16 de ancho, **cabeza desproporcionada** (radio 5,4 sobre un cuerpo de 3 px de radio): es la silueta más pequeña del juego. Abrigo de adulto que le llega a los tobillos y cuyas mangas cuelgan por debajo de las manos.
- **Ropa y colores.** Abrigo pardo `6/5` con parches `7`, botas ocultas. Piel `8/6`. Pelo `5` con flequillo recto.
- **Acento.** **Seis trapos de `8/6` atados a la muñeca cercana**, cada uno de 3 px de largo y distinto; es lo que dice su historia y se lee desde lejos.
- **Objetos.** Un clavo (3 px `4`) en la mano cercana, pizarra de 10×8 px (marco `2`, pizarra `1`, rayas `4`) contra el pecho con el brazo lejano.
- **Reposo.** De pie con la pizarra al pecho, se balancea sobre un pie y mueve la punta de la bota (8 f).
- **Hablar.** Barbilla alta, mira de frente (cabeza -4°), señala con el clavo hacia abajo, nunca hacia el jugador (6 f). Sin arma alzada.
- **Escuchar.** Se queda quieta con la cabeza ladeada (`react` 4 f).
- **Estados.** (1) *Directa*: cabeza alta, ojos grandes. (2) *Duda* (tras el primer objeto): hombros caídos, **mira la pizarra y la borra con la manga** (`idle_2`, 8 f). (3a) *Recuerda su nombre completo*: la pizarra con el nombre visible (3 px de rayas claras), sonríe (boca de 2 px), `idle_3` 8 f. (3b) *Se marcha con los Descreídos*: no hay sprite; queda **la pizarra en el suelo** como prop.
- **Rig.** Estilo `niño`, cabeza `face`.
- **Fotogramas.** 18 + 16 = **34**.
- **Dificultad.** S-M (el estilo niño es nuevo, pero cuenta con las mismas piezas).
- **Retrato.** Base de niña, flequillo recto, ojos grandes, labio inferior ligeramente adelantado. Tres expresiones: directa, duda, alivio.

#### 2.2.2 Aldara (anciana ciega)

- **Silueta y medidas.** Sentada en una piedra baja junto al Fogón: 34 de alto, 28 de ancho; encorvada hacia el fuego. Cuando se levanta (acto IV) mide 42.
- **Ropa y colores.** Chal gris `3` con borde `8`, vestido `2/1`. Piel `8/6`, pelo gris `4` recogido. **Ojos lechosos: 2 px `9`**, sin pupila.
- **Acento.** **El cordel de cientos de nudos**: cae desde las manos sobre el regazo y hasta el suelo; 40 px de cuerda `6` con bolitas `8` cada 3 px. Es lo que se lee primero.
- **Objetos.** Solo el cordel.
- **Reposo.** Balanceo lento de ±2 px, dedos que recorren el cordel; el rostro vuelto hacia la luz del fuego (8 f a 4 fps).
- **Hablar.** Casi cantada: el balanceo aumenta, la boca se mueve en bucle de 3 formas (6 f).
- **Escuchar.** Gira la cabeza hacia el sonido sin mirar (`react`).
- **Estados.** (1) *Lee*: dedos activos. (2) *Nudos flojos*: tramos de cuerda sin bolitas, manos quietas, cabeza ladeada. (3) *Acto IV*: se incorpora, mano tendida hacia el Caminante. **Finales:** Sellar (cabeza baja, 1 f), Soltar (sonríe y calla, 1 f), Compartir (el nudo sin nombre se deshace: 4 f en que la mano lo suelta).
- **Rig.** Estilo `encorvado` sentado, cabeza `face` con ojo ciego, cordel como `trailChain` largo (R4).
- **Fotogramas.** 18 + 16 + 6 = **40**.
- **Dificultad.** M (cordel con nudos).
- **Retrato.** La más reconocible: ojos cerrados con arrugas, cordel sobre el pecho.

#### 2.2.3 Garrán (herrero)

- **Silueta y medidas.** 50 px de alto y 30 de ancho con la espalda encorvada, hombros anchos y brazos de radio 4,4. **La silueta más "cuadrada" del Umbral.**
- **Ropa y colores.** Delantal de cuero quemado `5/a` con manchas `1`, camisa gris `3`, piel `6/5` más oscura. Una oreja que no oye: **venda gris `4` sobre la oreja izquierda** (la lejana en perfil a la derecha; en retrato se ve).
- **Acento.** Luz ámbar de la fragua sobre un costado del rostro (`c/d`).
- **Objetos.** Martillo corto (`maul` con mango de 14 px) y tenazas. **Sin pulgar izquierdo**: la mano lejana (izquierda) solo se ve cuando sostiene las tenazas; no depende de ello para leerse, y el detalle va al retrato.
- **Reposo.** De pie ante el yunque, golpea (8 f: levanta el martillo a la altura del hombro, nunca por encima de la cabeza; es trabajo, no amenaza).
- **Hablar.** Deja el martillo apoyado, se gira un tercio, apoya la mano en el yunque (6 f).
- **Escuchar.** Mira de reojo sin dejar de trabajar.
- **Estados.** (1) *Trabaja y calla*. (2) *Confiesa* (tras el Centinela): mira sus manos, hombros hundidos (`idle_2`). (3a) *Forja la mejora*: animación de forja de 8 f (+ chispas). (3b) *La fragua se hunde*: no hay sprite de PNJ; **cuerpo bajo escombros** como prop.
- **Rig.** `corpulento` encorvado, cabeza `face` (cejas gruesas, barba corta), arma `hammer` corta.
- **Fotogramas.** 18 + 8 + 8 + 8 = **42**.
- **Dificultad.** M.
- **Retrato.** Cara ancha, oreja vendada, cicatrices de quemadura en el cuello, barba corta.

#### 2.2.4 Cano (mercader)

- **Silueta y medidas.** 46 px de alto, 18 de ancho, **tres abrigos superpuestos** que forman un **dobladillo escalonado** (tres largos distintos en `7`, `6` y `3`), la mejor firma de silueta del juego. El carro es un prop de 40 px a su lado.
- **Ropa y colores.** Abrigos ocre `7`, tierra `6` y gris `3`, gorro `5`. Piel `8/6`.
- **Acento.** **Dientes desiguales**: boca abierta en sonrisa con 3 px `8` de alturas distintas (se lee de cerca).
- **Objetos.** Un carro de trastos (ollas, un clavo grande, objetos colgando) hecho aparte en tres versiones: **lleno** (Umbral), **medio vacío** (itinerante) y **cargado de objetos ajenos** (peines, una pizarra, un zapato) ante la Puerta Sin Muro.
- **Reposo.** Peso en una cadera, una mano en el bolsillo, la otra repasa algo (8 f).
- **Hablar.** El más expresivo: gesticula con las dos manos (`talk` de 8 f).
- **Escuchar.** Inclina la cabeza y entrecierra un ojo (comedia contenida).
- **Estados.** El que cambia es el carro; él mantiene la sonrisa hasta el final y en la tercera fase la deja caer en un fotograma (`idle_3`, 4 f).
- **Rig.** `erguido`, abrigos con `waistBand` y faldones como `trailChain` cortos; cabeza `face` sonriente.
- **Fotogramas.** 18 + 6 + 3 carros (3×1) = **27**.
- **Dificultad.** M (el carro).
- **Retrato.** Sonrisa de dientes desiguales, mirada de reojo.

#### 2.2.5 Vael (Acompañante)

- **Silueta y medidas.** 48 px de alto y 16 de ancho: **largo y recto**, el más "limpio" del Umbral. Túnica larga hasta la rodilla.
- **Ropa y colores.** Lino `8` con sombra `3`, cuerda en la cintura `6`. **Manos tiznadas de cal**: dos círculos blancos `9`. Piel `8/6`.
- **Acento.** **Círculo de cal de 6 px `9`** en el pecho o sobre una bolsa.
- **Objetos.** En las fases 2 y 3, un cubo de cal en la mano lejana.
- **Reposo.** De pie, brazos relajados, **la cabeza ligeramente baja y vuelta a un lado: no mira a los ojos** (8 f). Es lo que lo hace inquietante.
- **Hablar.** Manos abiertas, palmas arriba, como acogiendo (6 f). Suave.
- **Escuchar.** Asiente un píxel (2 f).
- **Estados.** (1) *Ofrece cal*: manos tendidas con el cubo. (2) *Acompañante*: ropa más blanca, círculo de cal más grande (7-8 px). (3) *Presiona a Casilda*: se inclina hacia delante (`lean` 10), mano que se tiende; **su sombra proyectada** sobre ella.
- **Rig.** `erguido` con `túnica larga`, cabeza `face`.
- **Fotogramas.** 18 + 16 = **34**.
- **Dificultad.** M.
- **Retrato.** Rasgos suaves, cabeza ladeada, ojos desviados.

#### 2.2.6 Hermano Gaspar (Penitente)

- **Silueta y medidas.** 50 px de alto, 24 de ancho; armadura completa **sin sello**: el peto liso con un **hueco circular de 5 px `1` con borde `4`**, el mismo que lleva el Centinela. **Yelmo bajo el brazo cercano**.
- **Ropa y colores.** Armadura gris oscuro `1/2` ennegrecida de ceniza (ruido `3`), **sacos de arpillera `6/5`** sobre los hombros, vaina vacía en el cinto. Rostro con **ojeras de 2 px `2`**, barba rala, piel `8/5`.
- **Acento.** El hueco del pecho (el símbolo de la Orden vaciado).
- **Objetos.** Yelmo bajo el brazo; la vaina vacía **sin espada**.
- **Reposo.** Rígido, mirada al frente, el peso en un pie (8 f).
- **Hablar.** Gira apenas la cabeza; la mano libre se cierra y se abre (6 f).
- **Escuchar.** Baja la cabeza un píxel.
- **Estados.** (1) *Guarda en silencio*. (2) *Te acompaña*: andar de 8 f con la cabeza baja. (3a) *Se arranca el último sello y se vuelve cascarón voluntario*: **la piel pasa de cálida a gris `4/3` y el ojo pierde el brillo**; es el único PNJ que cruza la regla de legibilidad (2.3) en pantalla, y por eso es potente. (3b) *Hesper lo recupera*: yelmo puesto y **sello ocre `c` restituido**; si se le ataca, es un enemigo (usa el rig del Lancero con otro peto; ya no es un PNJ).
- **Rig.** Estilo `armadura` (nuevo) + cabeza `face`.
- **Fotogramas.** 18 + 8 (andar) + 12 (transformación) = **38**.
- **Dificultad.** L (peto y grebas nuevos; la transformación).
- **Retrato.** Rostro cansado, ojeras, yelmo al borde del encuadre.

#### 2.2.7 Sabela (escriba)

- **Silueta y medidas.** 42 px de alto y 18 de ancho; encorvada (`lean` 14), con un libro abrazado al pecho.
- **Ropa y colores.** Túnica gris `3/2`, manguitos ocres `a`, **delantal de tinta con manchas `f`**. Piel `8/6`. **Dedos manchados de azul: 2 px `f` en la punta de la mano.**
- **Acento.** **Gafas de alambre**: aro de 5 px `4` en torno al ojo; y la pluma de hierro.
- **Objetos.** Pluma de hierro (14 px `4/3`, punta `f`) sostenida **hacia abajo, como una daga cuando está nerviosa**.
- **Reposo.** Mira alrededor con cabeza alterna cada 20 fotogramas, **ligeramente aterrada**; el libro en el pecho (8 f).
- **Hablar.** Pedante: dedo de la mano libre alzado (6 f).
- **Escuchar.** Se acerca el libro al pecho.
- **Estados.** (1) *Amable y tímida*. (2) *Se rebela* (tras Ilara): erguida (`lean` 4), pluma firme y mirada directa, el libro bajo el brazo. (3a) *Sigue* (Hesper cae pronto): igual y con una lámpara. (3b) *La primera sellada*: figura plana en `w/y` sin contorno ni textura, con bordes rectos (el aspecto de "lo olvidado" del informe 01).
- **Rig.** `encorvado` + `túnica larga` corta, cabeza `face` con gafas, pluma como `prop`.
- **Fotogramas.** 18 + 16 + 1 = **35**.
- **Dificultad.** M.
- **Retrato.** Gafas, mirada que se desvía, dedos azules sobre el libro.

#### 2.2.8 Dola (minera)

- **Silueta y medidas.** 46 px, 28 de ancho; **hombros muy anchos**, brazos de radio 4. Silueta de "pirámide invertida".
- **Ropa y colores.** Chaqueta de lona `3/2`, **trapo gris `x` sobre la boca**, gorro `5` con **una vela de grasa `c/d` encendida** (luz propia). Piel pálida `8/3` (Hondos), **ojos grandes de 2×2 px**.
- **Acento.** La vela del gorro: es lo que se ve a lo lejos en las Minas oscuras.
- **Objetos.** Honda en el cinturón (cuerda con bolsa de 3 px), pico **apoyado** en el hombro (no alzado).
- **Reposo.** Brazos cruzados (el brazo cercano atraviesa el pecho), peso en las piernas abiertas (8 f).
- **Hablar.** Gira la cabeza lentamente, el trapo se mueve con la voz ronca (6 f).
- **Escuchar.** La vela titila; sacude la cabeza una vez.
- **Estados.** (1) *Desconfiada*: brazos cruzados. (2) *Tras Magda*: pide el pico, baja la vista y toca la honda (`idle_2`). (3a) *Se queda guardando el pozo*: de pie junto al pozo, pico al hombro. (3b) *Se marcha con los Hondos*: sin sprite; su vela apagada en el suelo.
- **Rig.** `corpulento` con cabeza `face` cubierta por trapo; honda como `trailChain`.
- **Fotogramas.** 18 + 16 = **34**.
- **Dificultad.** M.
- **Retrato.** Ojos grandes sobre el trapo, vela sobre el borde del gorro.

#### 2.2.9 Brunel (listero)

- **Silueta y medidas.** Sentado en un cajón, 34 de alto y 20 de ancho; espalda **demasiado recta**, pizarra sobre las rodillas. Es la silueta más "de despacho".
- **Ropa y colores.** Chaqueta de listero gris `3/2` con botones `a`, visera plana `5`. Piel `8/5`. Dedos con tiza `8`.
- **Acento.** La pizarra con rayas de recuento (grupos de 5) y la tiza.
- **Objetos.** Pizarra (12×9 px, rayas `4`) y tiza.
- **Reposo = hablar.** **Siempre está hablando**: su `idle` es una lectura continua (6 f a 5 fps: la boca se mueve, la mano marca una raya). No tiene `talk` aparte.
- **Escuchar.** No escucha; lo importante es que **mira a la fila vacía y no al jugador** (se orienta hacia el lado contrario al del interlocutor).
- **Estados.** (1) *Pasa lista*. (2) *Tras Magda*: **se detiene un instante** con la tiza suspendida (2 s, 1 f de retención). (3) *Finales*: Compartir, duerme (cabeza sobre el pecho, la pizarra resbala, 4 f); Sellar, igual que (1); Soltar, la **pizarra en blanco** (prop).
- **Rig.** `encorvado` sentado, cabeza `face`.
- **Fotogramas.** 6 + 2 + 4 = **12** (el menor de todos).
- **Dificultad.** S.
- **Retrato.** Frente alta, labios entreabiertos, ojos fijos en otro sitio.

#### 2.2.10 Quiteria la Blanca

- **Silueta y medidas.** 48 px y 16 de ancho; **la más simétrica del juego**: `lean` 0, hombros horizontales, manos juntas por delante. Es lo inquietante.
- **Ropa y colores.** Lino `8` con sombra `9`, manos blancas de cal. Piel `8/6`. Sonrisa leve.
- **Acento.** El **Paño** `8` sobre el antebrazo; círculo de cal en la palma.
- **Objetos.** Paño; un cuenco de comida.
- **Reposo.** Manos unidas, respiración lenta (8 f a 4 fps, más lento que el de los demás).
- **Hablar.** Inclina ligeramente la cabeza, ofrece el Paño con las dos manos (6 f).
- **Escuchar.** Cierra los ojos un instante.
- **Estados.** (1) *Acoge*: brazos entreabiertos. (2) *Mira el mar*: **vuelta hacia el lado contrario**, la cabeza alzada. (3) *Ya no sabe quién eres*: **saturación al 40 %** por el sombreador (2.5) y **sin el píxel de brillo en el ojo**; ofrece el cuenco como a un extraño.
- **Rig.** `erguido` + `túnica larga`, cabeza `face` serena.
- **Fotogramas.** 18 + 16 = **34**.
- **Dificultad.** M (túnica larga; la dulzura se logra con inmovilidad).
- **Retrato.** Ojos entornados y serenos; el único retrato donde el ojo pierde su brillo en la fase 3.

#### 2.2.11 Mirena (barquera)

- **Silueta y medidas.** 46 px y 24 de ancho; en un lienzo de 80×64 para el arpón (44 px, **en diagonal a la espalda, guardado**).
- **Ropa y colores.** Chaqueta de hule `v/3`, botas altas `5`, pelo gris `4` recogido, piel curtida `6/5`. **Un pie que arrastra**.
- **Acento.** La pátina marina `v` de la chaqueta; el arpón.
- **Objetos.** Arpón a la espalda (`spear` con punta de hierro `4` y sin trapo rojo); en la barca, un remo.
- **Reposo.** Apoyada en una pierna, brazos en jarras (8 f).
- **Hablar.** Ladea la cabeza, mueve la mano en un gesto seco (6 f).
- **Escuchar.** Mira el horizonte.
- **Estados.** (1) *Cobra y calla*: mano extendida con la palma arriba. (2) *Reprocha o agradece*: brazos cruzados o mano alzada en saludo. (3a) *Remando*: ciclo de remo de 8 f en la barca. (3b) *Se hunde con la barca*: efecto sobre el prop de la barca, no sprite propio.
- **Rig.** `erguido`, cojera (el ciclo de andar con `ffy` más bajo y arrastre), arpón.
- **Fotogramas.** 18 + 8 (andar con cojera) + 8 (remo) = **34**.
- **Dificultad.** M-L (la cojera y el remo).
- **Retrato.** Piel curtida, mirada de lado, pelo gris recogido.

#### 2.2.12 Casilda

- **Silueta y medidas.** 36 px y 14 de ancho: **la más menuda de los adultos**; hombros hacia dentro, un brazo cruzado por delante.
- **Ropa y colores.** Vestido gris azulado apagado `3/2` con mangas `f`, delantal `8`. Piel `8/6`. Pelo gris `4`.
- **Acento.** **Una cuerda `6`** desde la mano lejana hasta un clavo en la pared (cadena tensa de 20 px), y el **peine de hueso `8`** con el nombre de Elvira.
- **Objetos.** Cuerda, peine; alrededor, props de peines, cartas y conchas.
- **Reposo.** De pie junto a la cuerda; mueve un objeto y lo oculta (8 f).
- **Hablar.** Voz apagada: casi sin gestos, ojos al suelo (6 f).
- **Escuchar.** Se encoge un píxel.
- **Estados.** (1) *Esconde sus cosas*: el peine tapado con la manga. (2) *Presionada*: `lean` -6, mirada hacia Vael. (3a) *Se queda*: más erguida, la mano en el marco de la puerta. (3b) *Olvida*: saturación al 30 %, objetos descolgados.
- **Rig.** `erguido` pequeño (altura 36), cabeza `face`, cuerda con extremo fijo.
- **Fotogramas.** 18 + 16 = **34**.
- **Dificultad.** M.
- **Retrato.** Ojos bajos, peine de hueso en la mano.

### 2.3 Los jefes con fase PNJ y otras figuras humanas

Estos personajes aparecen como personas antes (o en lugar de) luchar. Salvo indicación, **comparten rig y estilo con los PNJ**; el combate se resuelve con el rig de jefe del informe 02. Aquí solo se fija su fase de persona.

| Personaje | Fase PNJ | Silueta y rasgo legible | Estilo | Fotogramas | Dificultad |
|---|---|---|---|---|---|
| **Hesper** (Prior, 47 años) | Ofrecimiento amable: manos abiertas, palmas arriba; sonrisa. Chantaje amable: cabeza ladeada. | Túnica larga ocre `b/a` con **sello de cera partido** `c` en el pecho (dos semicírculos separados 1 px), **guantes de cera** `d`. Cabeza descubierta, canas. Alto y recto. | `erguido` + `túnica larga` + capa | 18 + 8 | M |
| **Eudora** (la Piadosa) | Acoge; se cubre la cara con la mano al hablar de Mateo; al final **sonríe sin recordarte**. | Lino `8`, círculo de cal de 8 px, manos blancas. Más mayor que Quiteria; encorvada hacia delante pero sonriente. | `erguido` + `túnica larga` | 18 + 12 | M |
| **Magda Soler** (capataz) | **Pica sin saber para qué** (8 f contra la pared), se detiene al verte. | Hombros anchos, brazos `4,2`, pico (`maul` con punta). Gorro con vela. | `corpulento` | 18 + 8 | M |
| **Casimar** (rey) | Sentado en el trono hundido, abrazado a la página. | **Corona torcida** `d`, manto raído `a/b` (no azul: reservado). Mantiene la **página `w`** contra el pecho (el píxel más claro de la sala). | `corpulento` sentado | 14 | M |
| **Sor Ilara** (copista) | Escribe sin parar con la pluma. | Sentada ante un pupitre, manguitos `a`, tinta `f` en las manos. | `encorvado` sentado | 12 | S-M |
| **Jacinto** (segador) | Siega un campo vacío. | Sombrero de paja `7`, hoz (`knife` curvo alzada **solo al segar**: es jefe). | `corpulento` | 18 | M |
| **Rufo** (farero) | Alimenta la luz. | Brazos tiznados, delantal quemado, caja de lo soltado. | `erguido` | 18 | S |
| **Maelis** (Priora Sellada) | **No es PNJ**: es jefe final. Estatua de piedra con manos tendidas. | Figura de piedra `3/2`, manos de piedra que caen. | Jefe por partes | — | L |
| **Oda** (Rastro) | Carrera, no habla. | **Silueta azul `g/h` translúcida** del Caminante en versión mensajera, con pie alado. | Estilo `mono` (azul) | 14 | M |
| **Oriol Maraver** | Solo la coraza del Centinela. | — | (ya existe) | — | — |

**Figuras de recuerdo.** Linde (niña que grita el nombre de una cabra), Tomasa (vigía alta), Jacinto (campesino joven) y Magda (última orden) aparecen en las escenas de obtención de habilidad (`guion-maestro.md`, §9) **en azul monocromo `e/f/g/h`**. Se hacen con los mismos estilos (niño, erguido, corpulento) pasados por un estilo `mono` que sustituye toda la paleta por la rampa azul. Coste mínimo (una escena de 3-5 s cada una).

### 2.4 Retratos e iconos de diálogo

**Problema.** El informe 02 dice que los retratos "se dibujan a mano" y el 03, que son opcionales y aplazables. Hacer 12+ retratos con 3 expresiones a mano en texto es costoso (36 imágenes de 48×48), pero un diálogo sin cara pierde mucho para personajes como Iria o Aldara.

**Propuesta escalonada.**

| Nivel | Qué es | Para quién | Coste |
|---|---|---|---|
| 0 | **Emblema de 16×16** junto al nombre: clavo (Iria), nudo (Aldara), martillo (Garrán), carro (Cano), círculo de cal (Vael, Quiteria, Eudora, Casilda), sello vacío (Gaspar), pluma (Sabela), vela (Dola), pizarra (Brunel), arpón (Mirena) | Todos | S (una fila de 12) |
| 1 | **Retrato de 48×48 generado por capas** con `tools/arte_retratos.js`: base de busto (5 bases: niña, anciana, adulto delgado, adulto corpulento, armadura), capas de cabello, barba, gafas, capucha, cicatriz y **tres expresiones** (boca y cejas: neutra, tensa, suave) | Los doce | M (generador) + S por personaje |
| 2 | **Retoque a mano** de ojos y boca de cuatro principales (Iria, Aldara, Quiteria, Eudora) | Principales | M |

**Formato del retrato.** 48×48, busto de tres cuartos mirando a la izquierda (hacia el texto), fondo transparente, contorno `1`, tres tonos de piel con la misma luz arriba-atrás del rig. Los PNJ que pierden memoria (Iria, Quiteria, Casilda) **se desaturan** con el mismo sombreador que sus sprites.

Mientras el generador no exista, el diálogo funciona sin retrato (informe 03, 3.3).

### 2.5 Memoria visible: saturación por fase

Es la idea más barata y más fuerte de este informe. El sombreador de desaturación del informe 01 (3.3) acepta un parámetro por material. Se aplica **por PNJ**, según la fase de su arco:

| PNJ | Fase 1 | Fase 2 | Fase 3 |
|---|---|---|---|
| Iria | 100 % | 100 % | 100 % si recuerda; **si se marcha, 0 %** (la pizarra gris en el suelo) |
| Quiteria | 100 % | 100 % | **40 %** y sin brillo en el ojo |
| Casilda | 100 % | 90 % | **30 %** si olvida |
| Aldara | 100 % | 85 % (los nudos aflojan) | 100 % si se le da el oficio |
| Gaspar | 100 % | 100 % | **5 %** si se vuelve cascarón voluntario |
| Eudora | 100 % | 100 % | **60 %** tras la derrota (olvida) |

No hay que dibujar nada nuevo. El jugador entiende sin leer que **esa persona se está yendo**.

---

## 3. Reglas de legibilidad: PNJ, enemigo, cascarón

El Caminante y los enemigos comparten esqueleto. Para que el jugador no pegue a una persona ni se acerque a un enemigo, la distinción debe funcionar en **silueta, valor, color, postura, luz y contexto**, y debe sobrevivir a la prueba de escala de grises.

### 3.1 Tabla de reglas

| # | Regla | PNJ | Enemigo | Cascarón |
|---|---|---|---|---|
| 1 | **Piel** | Cálida `8/6/5`, cara con rasgos | Piel `4/3/2` fría | Piel `4/3/2` fría, **cabeza lisa sin rostro** |
| 2 | **Ojo** | **Un píxel de brillo** (`d` o `8`) | Chispa roja `u` (los lanceros y arrojadores), o ninguna | Sin brillo |
| 3 | **Rojo** | **Nunca** (el lacre es ocre) | Siempre en trapos, vendas o penacho | Vendas rojas `s/t` |
| 4 | **Arma** | Sin arma alzada; guardada, a la espalda o apoyada | Siempre en mano | Siempre en mano |
| 5 | **Postura** | Erguida o apoyada, **hombros horizontales**, cabeza visible | Encorvada o inclinada hacia delante | Encorvada (`lean` 14, `bend` 12) |
| 6 | **Movimiento** | Respira, se mueve poco, **se vuelve hacia el jugador** al acercarse | Patrulla; **aviso de ataque** (pose alzada) | Camina por costumbre |
| 7 | **Luz** | Una luz ámbar propia o dentro de un halo | Ninguna | Ninguna |
| 8 | **Contexto** | Solo en zonas de calma (sin enemigos en la sala) | En sala de combate | En sala de combate |
| 9 | **Interacción** | Aparece el aviso de tecla a menos de 64 px | No | No |
| 10 | **Saturación** | Parámetro por fase (2.5) | La de la región (el rojo de aviso siempre al 100 %) | La de la región |

**Cómo se lee en 0,3 segundos.** El jugador clasifica en este orden: ¿hay rojo? → enemigo. ¿Hay una luz cálida y un rostro? → persona. ¿Cabeza lisa y gris? → cascarón. Las tres señales son redundantes a propósito (color, forma, luz) para que ninguna deba ser perfecta.

### 3.2 Puntos delicados

1. **Los PNJ encorvados** (Garrán, Aldara, Brunel, Sabela) comparten postura con el cascarón. Se distinguen por el **rostro** (rasgos y brillo en el ojo), la **piel cálida**, la **luz** y que no hay rojo. Si hay duda, se exagera el brillo del ojo y se baja el `lean`.
2. **Gaspar** es el caso límite: lleva armadura, y en las fases 3a y 3b pasa a ser cascarón o enemigo. Esa transformación es deliberada y se usa narrativamente (2.2.6); no se debe usar nada de su aspecto de PNJ en un enemigo normal.
3. **Los Custodios** (enemigos con armadura) y **Gaspar** comparten el hueco del pecho. El Custodio-enemigo lo lleva con **trapos rojos y yelmo cerrado**; Gaspar, con la cabeza descubierta y el peto vacío.
4. **Los Descreídos** (todo de `8/9`) pueden confundirse con **lo olvidado** (paleta `w/y`) de la Herida. Diferencia: los Descreídos tienen **piel y color de ropa cálido**; lo olvidado, no.
5. **Oda** (silueta azul) puede confundirse con el **Eco**. Es intencionado: es otro Rastro. Se separa porque el Eco violeta del jugador tiene su propio color en el mapa y Oda no daña.
6. **El enemigo ajeno a la zona** de calma (si aparece uno) debe reconocerse inmediatamente: por eso los PNJ no llevan nunca elementos de combate a la vista.

### 3.3 Prueba obligatoria

Antes de dar por bueno un PNJ: (1) captura a escala de grises junto a un cascarón y un lancero: los tres se distinguen por silueta o por rostro; (2) captura a 864×486 con el PNJ a 8 px de un enemigo: se lee la diferencia sin color; (3) el PNJ se entiende **quieto**.

---

## 4. Cuadro de producción

Esfuerzo relativo: **S** (≤ 1 sesión), **M** (2-3), **L** (4+). Las dependencias son del rig o del pipeline; **todo lo de abajo requiere, antes, el manifiesto y el lienzo nuevo (R1)**.

### 4.1 Orden recomendado

| # | Tarea | Esfuerzo | Depende de | Notas |
|---|---|---|---|---|
| 1 | **R1: lienzo del Caminante a 112×96** y regenerar | S | Nada | **Primero de todo**. Verificar diff y desplazar el `Sprite2D`. |
| 2 | **R7 + manifiesto**: anclajes exportados | S | Informe 02, hito 1 | Sirve para todo lo demás |
| 3 | Animaciones del protagonista de prioridad A sin cambio de rig: `land`, `wall_grab`, `wall_slide`, `wall_jump`, `die`, `respawn` | M | 1 | Desbloquean el salto de pared y la muerte; son lo que más se nota al jugar |
| 4 | **R2 `spinPose`** + `double_jump` | M | 1 | Aunque sea poses, hay que escribir el helper |
| 5 | `attack_up` y `attack_down` | M | 1 | Exigen el lienzo nuevo; mucho feeling de combate |
| 6 | **R4 objetos en mano (`flask`)** + **R6 cabeza sin máscara** + `heal` | M | 1, 2 | |
| 7 | **E1** (bufanda larga) y primera muda de hoja | S | 2 | El cambio tras el Dash; se prueba el sistema de mudas |
| 8 | `sit` / `rest` + `remember` + `climb` + `turn` + `listen` | M | 1 | Prioridad media |
| 9 | **Cabeza `face`** + estilos `erguido`, `encorvado`, `niño` | M | 2 | Base de todos los PNJ |
| 10 | **PNJ del Umbral**: Iria, Aldara, Cano (sin carro), Garrán (sin forja) | M (4 PNJ) | 9 | El vertical slice se beneficia: son los primeros PNJ |
| 11 | Estilo `túnica larga` + Vael, Quiteria | M | 9 | |
| 12 | **R5 `mods`** de evolución: E2, E3 | M | 7 | |
| 13 | Retratos nivel 0 (emblemas) | S | — | Barato y útil |
| 14 | **R3 `farFist`** + `dig` (Golpe Hondo) + E5 | M | 1 | Cuando se construya Excavar |
| 15 | **Estilo `armadura`** + Gaspar (con transformación) | L | 9 | Sirve también a los Custodios enemigos |
| 16 | PNJ restantes: Sabela, Dola, Brunel, Mirena, Casilda | M-L (5) | 9, 11 | Cada uno cuando entre su región |
| 17 | Generador de retratos (nivel 1) | M | 9 | Después de tener PNJ |
| 18 | `name` (Nombrar) + E6 (ojo ámbar y trapos como superposición) | M | 6, 12 | Acto IV |
| 19 | Fase PNJ de Hesper, Eudora, Magda, Casimar, Ilara, Rufo, Jacinto | M cada una | 9, 11 | Después de la región |
| 20 | Estilo `mono` (azul) + escenas de recuerdo | S | 9 | Para las grandes escenas |
| 21 | Sprites de epílogo (Compartir sin máscara; Sellar sentado) | M | 6, 9 | Al final |
| 22 | Retoque a mano de retratos principales (nivel 2) | M | 17 | Opcional |
| 23 | Animaciones de prioridad baja (`idle_long`, `interact`, `win`, etc.) | S cada una | 1 | Cuando haya tiempo |

### 4.2 Lo que se puede hacer ya, sin tocar el rig

- Animaciones de poses puras: `land`, `wall_grab`, `wall_slide`, `wall_jump`, `die`, `respawn`, `listen`, `turn`, `climb`, `sit`.
- Emblemas de 16×16 y el sombreador por fase.
- El PNJ más barato como prueba de concepto: **Brunel** (12 fotogramas, sentado, casi inmóvil). Si funciona, se avanza con el resto.

### 4.3 Presupuesto aproximado (en sesiones, orientativo)

| Bloque | Esfuerzo | Total aprox. |
|---|---|---|
| Protagonista: lienzo, animaciones A, sistema de mudas y E1-E6 | M + M + M + M + M + M | 12-18 |
| Estilos y cabeza `face` | M + M + M | 6-9 |
| 12 PNJ (paquete + estados) | 12 × (S-M a L) | 24-36 |
| Fases PNJ de jefes | 7 × M | 14-21 |
| Retratos (generador + retoque) | M + M | 5-8 |
| Epílogos y escenas de recuerdo | M + S | 4-6 |
| **Total** | | **65-98** |

Es coherente con el "D3 (PNJ, L, 8)" y "D4 (variantes del Caminante, M, 4)" del informe 01, **que se quedan cortos**: la estimación honesta para personaje principal y PNJ con estados es 3-4 veces mayor. Se puede recortar (ver preguntas).

---

## 5. Preguntas abiertas

1. **Lienzo del Caminante (R1).** ¿Se acepta 112×96 y regenerar todo (recomendado), o 112×80 con un golpe hacia arriba más corto? Afecta a la colocación en las escenas y a la memoria de todas las hojas.
2. **Hojas por etapa.** ¿Cinco hojas (una por cada cambio) o tres (opción barata)? Con cinco, cada habilidad tiene su cambio visible inmediato; con tres, se pierden el del Dash y el del Salto de pared.
3. **Ojo ámbar.** ¿Aceptamos que el ojo del Caminante pase de azul a ámbar al Nombrar? Cambia el motivo "azul = Eco" y es la mayor decisión visual de la evolución. Alternativa: dejar el ojo azul y poner el calor en los trapos.
4. **¿Se ve el rostro?** La animación de curarse propone mostrar la barbilla pálida bajando la máscara. ¿Es demasiado pronto para ver algo de Ansel? Si no, se cambia por beber **a través** de la tela (sin mostrar piel).
5. **Piel cálida contra piel gris.** ¿Se confirma que los PNJ tienen piel `8/6/5` y los cascarones `4/3/2`? Es la regla de legibilidad principal; si se cambia, hay que rehacer la tabla de la sección 3.
6. **Lacre ocre.** El lacre de la Orden no puede ser rojo (regla del informe 01). ¿Se acepta ocre quemado `a/b`, que es además el color de facción?
7. **Gaspar como jefe opcional.** Si se le ataca se vuelve enemigo: ¿rig de Lancero con otro peto (barato) o jefe propio (caro)? Sugiero lo primero y sin recompensa, como dice `personajes.md`.
8. **Carro de Cano.** ¿Tres versiones del carro (lleno, medio, cargado de lo ajeno) o dos? La tercera es la más bonita narrativamente y la más cara.
9. **Retratos.** ¿Nivel 0 (emblemas) hasta el final del slice y nivel 1 después, o saltamos directamente al generador? Hay que decidir quién retoca a mano (el usuario con Pixelorama, o nadie).
10. **Escuchar del protagonista.** ¿Aceptamos `listen` (la daga baja mientras habla el PNJ) como gesto de personaje? Es barato y evita que el protagonista parezca una estatua en cada diálogo.
11. **PNJ perdibles.** Siete PNJ pueden perderse; los sprites de pérdida (pizarra en el suelo, vela apagada, cuerpo bajo escombros) son props y no personajes. ¿Basta, o se quiere un fotograma del PNJ cayendo (más caro)?
12. **Presupuesto.** Los 65-98 puntos de la sección 4.3 son mucho. ¿Se recortan primero los estados de PNJ (solo dos fases en vez de tres) o los jefes con fase PNJ (se quedan sin fase de persona)? Sugiero lo primero.
