# Interfaz, efectos y animación: propuesta del artista

Documento de la sala de artistas (03). Es una propuesta para que el usuario decida, no una decisión tomada. Todo está pensado para una sola persona con herramientas de código: rectángulos, polígonos, `Label`, `GPUParticles2D`/`CPUParticles2D`, `Tween`, sprites como texto y generadores en JS (`tools/arte_*.js`), como ya se hace con el Ancla y las habilidades.

Lo que he mirado: `CLAUDE.md`, `docs/arte.md`, `art/palette.txt`, `docs/nucleo-jugable.md`, `docs/jefes.md`, `game/ui/*` (HUD, pausa, menú del Ancla, árbol, título), `core/ui/*` (mapa, listas de menú, barras, glifos de mando), `core/effects/*` (chispazo, número de daño, hit stop) y `game/ability_pickup/`.

Estado de partida que condiciona todo: la interfaz funciona pero usa la **fuente por defecto de Godot** (`ThemeDB.fallback_font`), recuadros translúcidos y colores sueltos en código (por ejemplo, la leyenda del mapa usa `Color(0.953, 0.769, 0.416)` a mano). Los efectos actuales son pocos: `HitSpark` (6 líneas), `DamageNumber`, `HitStop` (0,06 s), temblor de cámara, y los halos del Ancla y de las habilidades. Es una base honesta; el trabajo es darle **un lenguaje común**.

---

## 0. Principios de lenguaje visual (valen para todo)

1. **La Desmemoria se ve en la interfaz.** El juego ya dice que el color vivo es lo recordado y el gris es lo olvidado. La interfaz sigue la misma regla: lo que el jugador *ya sabe* (mapa explorado, habilidades recordadas, nombres de las Anclas) se pinta con color; lo que *no* sabe aparece en piedra apagada, con la forma apenas insinuada. Un hueco en el mapa no es negro: es una mancha gris que se "recuerda" al pasar. Esto no cuesta nada: es elegir de qué rampa se pinta cada cosa.
2. **Cuatro colores de significado, y solo cuatro.** Ámbar = tuyo / memoria / interactuable. Azul frío = recuerdo / habilidad / Eco. Rojo = peligro / daño / jefe. Verde musgo = vida de mundo, solo ambiental (nunca en la interfaz de combate). Piedra para todo el armazón. La **señal amarilla de aviso** del enemigo es un caso aparte (ver sección 3.5).
3. **Marcos de piedra, no cristal translúcido.** Un panel es una pieza de arquitectura: borde de 2 px en `3` (`#6a6670`), relleno `1` (`#1b1a1f`) casi opaco (0,92), una esquina cortada a 45°, y un filete interior de 1 px en `2`. Se dibuja con `draw_rect` y `draw_colored_polygon`, o mejor, una sola textura de 9 trozos (`NinePatchRect`) de 24×24 generada por script. Una textura, todos los paneles.
4. **Las cosas entran como se recuerdan: se enfocan.** Las animaciones de entrada de paneles no deslizan; *se condensan* (de un desenfoque de 2 px de opacidad al marco nítido) en 0,18 s. Las de salida son más rápidas (0,10 s). Nada rebota en la interfaz; el rebote se reserva para el mundo.
5. **Sin texto donde pueda haber icono, sin icono donde haga falta una frase.** Textos concisos, en infinitivo o sustantivo ("Recordar", "Mapa", "Reliquias"), nunca frases largas de manual.
6. **Todo en la rejilla de 8 px** (la del lienzo de sprites) y a escala entera. Los paneles miden múltiplos de 8; los iconos, 16×16 (o 24×24 para habilidades grandes).

### Tipografía

Hoy no hay fuente propia. Propongo **dos niveles**:

- **Texto de juego y menús: "m5x7" (Daniel Linssen)**, fuente pixel gratuita (licencia libre, uso comercial permitido; hay que comprobarlo en la página del autor antes de incluirla y apuntarlo en `docs/decisiones.md`). Altura de 7 px, tiene tildes y eñes, y se lee bien a 864×486 en tamaño 14/16/21 (múltiplos enteros de su base de 7: 7, 14, 21). Alternativas por si no convence: "Pixelify Sans" (OFL, más redondeada, Google Fonts) o "Silkscreen" (solo mayúsculas; descartada para texto largo).
- **Títulos y rótulos grandes ("SOBRE TI HAS CAÍDO", "Has recordado"): rótulo dibujado por código**, como ya se hace con `title_logo.png`. Letras de 16–24 px de alto en mayúsculas con una variante serif angulosa, que el generador JS compone a partir de un alfabeto de 26 glifos escrito como texto (igual que los sprites). Es poco trabajo (alfabeto de 5×7 ampliado ×3 con serifas añadidas a mano a los 8–10 glifos más usados) y da identidad sin depender de nadie.

Justificación: el estilo del juego es solemne y de piedra. Una fuente redondeada y simpática rompería el tono; una fuente ya hecha, gratuita y clara cubre el 95 % del texto, y el resto es rótulo. En Godot se usa como `FontFile` con `antialiasing = none`, `hinting = none`, `subpixel_positioning = disabled` y tamaño entero; si no, los bordes salen blandos. Esto sustituye al `fallback_font` en un único tema (`Theme`) aplicado a la raíz de cada pantalla, con lo que `damage_number.gd` y `input_glyphs.gd` también ganan.

Reglas de legibilidad: texto principal en `4` (`#a39fa8`), resaltado en `d` (`#f3c46a`), desactivado en `3`. Contorno de 1 px en `1` para el texto sobre el mundo (mensajes, números de daño); sin contorno dentro de paneles.

---

## 1. Dirección de cada pantalla

Pantalla de referencia: 864×486. Las maquetas usan una cuadrícula aproximada de 1 carácter ≈ 12×12 px en horizontal y vertical, solo para proporciones.

### 1.1 HUD en juego

```
+------------------------------------------------------------------------+
|  [#][#][#][#][ ]      (vida)                           +--------------+|
|  (o)(o)( )  (frascos)                                  |  minimapa    ||
|  <> 128    (Ecos)                                      |  160x96      ||
|                                                        +--------------+|
|                                                                        |
|                                                                        |
|                       "Has recordado: Dash"   (centro, arriba)         |
|                                                                        |
|                                                                        |
|  [ ] Menu            [Z] Recordar (sobre Ancla)                        |
|                                                                        |
|  ===========  BARRA DE JEFE (centrada, abajo)  =======================  |
+------------------------------------------------------------------------+
```

- **Vida** (esquina superior izquierda, a 16 px del borde): segmentos, como el `SegmentedBar` actual, pero cada segmento es una **placa de piedra de 16×20** con una gema roja `t`/`u` cuando está llena y un hueco con grieta `2` cuando está vacía. Al perder vida, la gema se agrieta (1 fotograma, 0,06 s), flashea en blanco y se "apaga" fundiendo a `r` en 0,25 s. Al curar, se enciende de izquierda a derecha con 0,05 s de desfase. Con 1 sola vida llena, late (escala 1→1,12 a 1,5 Hz): señal de peligro que no depende solo del color.
- **Frascos** (debajo): iconos de 16×16 del frasco ámbar (ya existen lleno/vacío), con un tercer estado "bebiendo" de 3 fotogramas al curar.
- **Ecos**: gota azul + cifra. Al ganar Ecos, la cifra sube contando (0,4 s) y la gota hace un destello `h`. Al morir y quedar a 0, la cifra no desaparece: pasa a gris `3` y el Eco aparece en el mapa. Se evita mostrar "+5" flotante en el HUD; el feedback va en el mundo (cada enemigo suelta motas azules que vuelan hacia la gota, ver 2.9).
- **Minimapa** (superior derecha, 160×96, marco de piedra): mismo `MapView` con oscurecido radial en los bordes (se dibuja un polígono con alfa creciente), no un recorte duro.
- **Barra de jefe**: ver 1.9.
- **Mensajes** ("Has recordado: X"): un solo caso de uso grande (1.8) y los avisos pequeños (abajo). Los pequeños son una banda de 1 línea sobre el HUD, con texto `d`, en un marco mínimo.
- **Avisos de tecla**: el `InputPrompt` ya muestra el icono del dispositivo. Mantener, pero con un pequeño "balanceo" vertical de 2 px a 1 Hz para llamar la atención, y mostrarlo solo a menos de 64 px del objeto.
- **Visibilidad de contexto**: tras 4 s sin cambios ni combate, el HUD baja su opacidad a 0,55; vuelve a 1 al recibir daño, entrar en combate o abrir el mapa. Es opcional (ajuste en Opciones).

Animación de entrada: fundido de 0,3 s al empezar la sala, con los elementos entrando en cascada de 0,05 s entre ellos.

### 1.2 Menú de pausa

Ya existe con 6 opciones y subpáginas (Mapa, Personaje, Controles). Propuesta: mantener la estructura y cambiar la composición, porque hoy es un panel único con todo apilado.

```
+------------------------------------------------------------------------+
| (mundo congelado y oscurecido al 55%, desaturado)                       |
|        +------------------------+   +---------------------------+      |
|        |  PAUSA                 |   |  Personaje (resumen)      |      |
|        |                        |   |  Vida  4/4    Frascos 2/2 |      |
|        |  > Continuar           |   |  Ecos  128                |      |
|        |    Mapa                |   |  Filo  nivel 2            |      |
|        |    Reliquias           |   |  [dash] [doble salto] [ ] |      |
|        |    Personaje           |   |                           |      |
|        |    Controles           |   |  Zona: La Cisterna        |      |
|        |    Opciones            |   +---------------------------+      |
|        |    Menú principal      |                                      |
|        +------------------------+                                      |
|   [flechas] [Aceptar] [Atrás]                                          |
+------------------------------------------------------------------------+
```

- Panel izquierdo de 224×288 con la lista; panel derecho de 288×288 que muestra una **vista previa viva** del elemento seleccionado (el resumen del personaje con las habilidades recordadas como iconos grandes; al seleccionar Mapa, una miniatura). Esto sustituye al texto largo de `info_label`.
- El mundo se congela con un oscurecido y desaturado (un `ColorRect` con shader sencillo de mezcla a gris, 55 %); el fondo conserva el color vivo en los iconos de habilidades: **solo se ven con color las habilidades**, el resto cae a gris. Es una pequeña metáfora sin coste.
- Entrada: el mundo se desatura en 0,15 s y los paneles se condensan en 0,18 s. Salida: 0,10 s.
- "Opciones" se incorpora aquí (hoy solo está en el título) con: pantalla completa, volumen general, **reducir temblor**, **atenuar destellos**, **modo alto contraste**, **modo daltónico**, **tamaño de fuente de avisos**. Solo se añade cada opción cuando el efecto existe (regla del proyecto: no poner opciones que no hacen nada).

### 1.3 Mapa

Hoy: baldosa a baldosa, descubierto al pasar, con marcas de jugador, Anclas y Eco (violeta). Propuesta de lectura:

- **Descubrimiento**: lo no visitado no se dibuja. Lo visitado se pinta *por salas*, no por baldosa suelta, con relleno de la rampa de **piedra** (`2`) y borde de `4`. Una sala visitada pero con un camino no recorrido muestra una **salida en gris claro con un punto** (invita a volver). Al descubrir una baldosa nueva, hace un parpadeo de 0,3 s (de `h` a su color final): es la forma visual de "el mundo se va recordando".
- **Zonas**: cada región tiene un tinte de su rampa (Último Umbral: ámbar apagado `a`; Terrazas Secas: tierra `b`/`2`; Cisterna: azul `e`/`f`; Galerías: piedra fría `2`/`3`; Aljibe: rojo oscuro `r`). El nombre de la zona aparece como rótulo grande al cruzar su umbral por primera vez (ver 1.8) y en el mapa, en letras de 14 px a baja opacidad sobre la zona. El tinte sirve a la accesibilidad: no se apoya solo en el matiz, también en un **patrón de relleno** por zona (liso, puntos, rayas diagonales, cuadrícula, ladrillos), de 2 px de alto, para quien no distinga colores.
- **Marcadores** (todos iconos de 8×8 sobre el mapa): jugador (rombo ámbar `d` parpadeante), Ancla (cristal azul `g`), Eco (violeta, ya establecido), puerta cerrada (barra roja `s`), jefe vencido (calavera pequeña gris), recuerdo recogido (rombo `h` vacío), habilidad pendiente (rombo azul `g` relleno, solo si se conoce por pistas), **notas del jugador** (ver más abajo).
- **Leyenda**: una columna a la derecha con icono + palabra; hoy solo hay tres puntos de color en el pie. Pasarla a iconos con forma distinta por categoría (no solo color): círculo, rombo, cuadrado, triángulo. Eso resuelve el daltonismo.
- **Notas**: el jugador puede poner hasta 8 marcas (chincheta de color: ámbar, azul, rojo, blanco) con un botón; sin texto libre (evita teclado en pantalla). Es contenido para después del slice; coste medio.
- **Entrada**: se abre con un barrido de "tinta" de izquierda a derecha de 0,25 s (máscara con rectángulo que crece). Cursor libre de desplazamiento con inercia corta.

### 1.4 Menú del Ancla y árbol de habilidades

Es la pantalla más importante de progresión: el único sitio donde el jugador *decide*.

```
+------------------------------------------------------------------------+
|   HITO DE NOMBRES  -  La Cisterna                         Ecos: 128    |
|                                                                        |
|   [ Recordar (mejorar) ]   [ Descansar ]   [ Reliquias ]   [ Salir ]   |
|                                                                        |
|     CUERPO              FILO                ESPÍRITU                   |
|     (Vitalidad 2/4)     (Afilado 1/2)       (Guardia 0/3)              |
|        |                   |                   |                       |
|     (Frascos 1/2)       (Ritmo 0/3)          (Impulso 0/2)             |
|        |                   |                   |                       |
|     (Temple 0/2)        (Alcance 0/2)        (Contragolpe 0/2)         |
|                                                                        |
|   Vitalidad: +1 vida máxima.   Coste: 20 Ecos       [Aceptar] Comprar  |
+------------------------------------------------------------------------+
```

- Tres columnas verticales = tres ramas, de arriba abajo en orden de desbloqueo. Cada nodo es un **hexágono de 32×32**: vacío con borde `2`, comprado con relleno de la rama (Cuerpo = rojo `s`/`t`, Filo = ámbar `c`/`d`, Espíritu = azul `g`/`h`), bloqueado (rama anterior sin comprar) con candado y gris.
- Niveles múltiples: **puntitos debajo del nodo** (4 puntos para Vitalidad), no un número.
- Las líneas de conexión son cadenas finas; al comprar un nodo, la cadena siguiente "se enciende" con un recorrido de luz de 0,3 s hacia el siguiente nodo. Es el único momento de la interfaz con ligera celebración.
- Fondo: piedra oscura con las runas grabadas del Ancla (reutiliza el sprite) pulsando de manera casi imperceptible. Los nombres de Anclas ("Hito de Nombres") salen como lista a un lado: nombres de gente borrada por la Desmemoria. Es narrativa gratis dentro del menú (a pactar con los escritores).
- Compra: mantener pulsado 0,4 s (anillo que se llena) para evitar compras accidentales; el sonido y el destello solo ocurren al completarse. Alternativa más simple: confirmar con una segunda pulsación. Mi recomendación: la segunda pulsación, que es más simple y accesible (mantener pulsado cansa a algunos jugadores).
- Estado sin Ecos suficientes: el coste se pone en rojo `t` y el nodo hace un temblor de 4 px (0,15 s) al intentar comprar, nunca solo color.
- Entrada: el Ancla pulsa (halo) y el panel emerge desde el cristal, no desde un borde.

### 1.5 Inventario: reliquias y amuletos

**Propuesta nueva, sin código todavía.** Se llama **"Reliquias"** (palabra solemne, sin acepciones vulgares) y son fragmentos de recuerdo ajeno que se llevan puestos. Referencia de lenguaje: los amuletos de Hollow Knight y las "runas" de otros souls-like; identidad propia por la idea de *memoria con peso*.

Reglas que propongo (a validar con los diseñadores):

- **Ranuras limitadas**: empiezas con 3 ranuras, el resto se amplía (un máximo de 6) con hallazgos, no con Ecos. Cada reliquia ocupa 1 o 2 ranuras (las poderosas, 2).
- **Equiparse solo en un Ancla** (descansando), nunca en pleno combate: el cambio es una decisión de preparación, no un truco de reacción.
- **Todas se ven siempre**: las no halladas aparecen como siluetas grises con "???", lo que da objetivo de colección sin texto.

```
+------------------------------------------------------------------------+
|  RELIQUIAS                                              Ranuras 3/4    |
|                                                                        |
|   Equipadas:                                                           |
|     [ #1 ][ #2 ][ #3 ][ #4 ]      (hexágonos grandes 40x40)            |
|                                                                        |
|   Halladas:                                                            |
|   +----+----+----+----+----+----+      +--------------------------+    |
|   | ic | ic | ic | ic | ic | ic |      | Vendaje de Nombres       |    |
|   +----+----+----+----+----+----+      | Ocupa 1 ranura.          |    |
|   | ic | ic | ?? | ?? | ?? | ?? |      | +1 vida tras descansar   |    |
|   +----+----+----+----+----+----+      | durante 60 s.            |    |
|   | ?? | ?? | ?? | ?? | ?? | ?? |      |                          |    |
|   +----+----+----+----+----+----+      | "Una tela con un nombre  |    |
|                                         |  que no se lee."         |    |
|                                         +--------------------------+    |
|   [Aceptar] Equipar / Quitar     [Atrás]                                |
+------------------------------------------------------------------------+
```

- Cuadrícula de 6×3 de celdas de 40×40 con icono de 24×24. Ranuras equipadas encima, hexágonos de borde ámbar `c`. Una reliquia de 2 ranuras ocupa dos hexágonos unidos (se ven como un hueso de dominó).
- Panel de descripción con 3 líneas: efecto (en `d`), coste en ranuras y una línea de texto de sabor en cursiva (en `3`). Sin números de estadística innecesarios.
- Equipar: el icono vuela del cuadro a la ranura en 0,15 s con una estela y un "clic" de piedra; al quitar, vuelve. Si no hay ranuras libres, la celda sacude y la fila de ranuras parpadea una vez.
- Reliquias maldecidas (ocupan ranuras y dan un efecto malo) quedan fuera de este slice.

Coste: al ser una pantalla de rejilla y descripción, se monta con `MenuList` + `GridContainer` y el mismo `NinePatchRect`. Es contenido nuevo de diseño más que de arte: necesita primero un sistema de datos (ver Preguntas).

### 1.6 Pantalla de muerte

Referencia de lenguaje: el rótulo de Dark Souls, pero no una copia. Mi propuesta se basa en la premisa del juego: *recordar*.

Secuencia (3,2 s hasta poder actuar, saltable a partir de 1,5 s):

1. **0,0 s**: hit stop de 0,25 s, el último golpe se congela con un tinte blanco.
2. **0,25 s**: el protagonista cae con la animación de muerte (sección 3.1); el mundo se desatura a gris en 0,6 s *menos el Eco que se está formando*, que sube como una silueta azul desde el cuerpo.
3. **0,9 s**: un rótulo grande en el centro, letras de 24 px en `4` sobre una banda horizontal de `1` con alfa 0,7 y bordes que se difuminan en 8 px: **"HAS OLVIDADO"** (alternativa: "SE APAGÓ EL RECUERDO"; a elegir con los escritores). Aparece letra a letra con 0,04 s entre letras y un temblor de 1 px. Debajo, en `3`, una línea pequeña: "Tus Ecos esperan donde caíste." (si llevaba Ecos).
4. **2,2 s**: fundido a negro en 0,4 s; reaparición en el Ancla con la luz del cristal subiendo (0,5 s).

Contraste con el "YOU DIED" original: el rótulo no es rojo (que se asocia a fallo), sino de piedra con un único trazo ámbar: la muerte es perder *memoria*, no sangre. Para reducir frustración: tras 3 muertes seguidas contra el mismo jefe, el rótulo es más corto (1,8 s).

### 1.7 Victoria sobre jefe

Secuencia (4,5 s), sin barras de "VICTORIA" tipo arcade:

1. Hit stop largo de 0,4 s y zoom de cámara a 1,15× hacia el jefe (0,3 s).
2. El jefe cae con la animación de muerte (ya existe, 12 fotogramas); la armadura vacía se desmorona en polígonos de piedra con polvo.
3. Una onda circular `h` sale del núcleo, **las rejas se levantan** (sonido ya existente) y todos los colores de la sala se **realzan** unos segundos (la sala se vuelve de color vivo y luego vuelve a su rampa), como si el recuerdo se liberara.
4. Rótulo: **"RECUERDO LIBERADO"** (alt.: "CUSTODIO DE LA ORDEN"), letra de 20 px en `d`, con el nombre del jefe debajo en 14 px. Dura 2,2 s.
5. Aparece el recuerdo de la habilidad (la gran escena, 2.8).

### 1.8 Mensajes: "Has recordado: X" y nombre de zona

- **Habilidad recordada** (momento más importante del juego): el HUD se retira, la cámara se acerca a 1,25×, y un rótulo a pantalla casi completa dice **"HAS RECORDADO"** (14 px, `h`) y debajo **"DASH"** (32 px, `d` con halo azul). Debajo, una frase de lore (la técnica era de alguien; a los escritores). Dura 3,5 s, cualquier botón la cierra tras 1,2 s.
- **Mensajes pequeños** de recogida: banda superior central, texto 14 px, 2,2 s, entrada por condensación y salida por fundido.
- **Nombre de zona**: al cruzar un umbral de zona nueva, letras de 24 px en `4`, bajo el HUD a un tercio de la altura, con una raya fina `3` encima. Se escriben con una máscara de izquierda a derecha en 0,6 s, 2 s visibles, 0,6 s de salida. Se usa también para zonas ya vistas pero solo la primera vez por sesión.

### 1.9 Barra de jefe

```
              CENTINELA HUECO
  [==========================|=====|==================]
   ^armadura (gris-ámbar)       ^marcas de fase (3 muescas)
  [########################----------]
   ^núcleo (rojo)
```

- Centrada, abajo, ancho 480×16 (dos barras apiladas: **armadura** arriba en `3`→`c` y **núcleo** abajo en `s`→`t`), con marco de piedra y esquinas de calavera hueca. Las **muescas de fase** (a 10 y 5 de 15 de núcleo) se ven en la barra de núcleo, porque la pelea las usa como suelo de vida.
- La armadura es un recurso a romper, así que su barra se gasta de forma visible; al llegar a 0, se **agrieta y estalla** en polígonos de `3` que caen, y la barra del núcleo se enciende en `u` (ventana de daño de 3 s, con un anillo que decrece).
- Entrada: el nombre aparece letra a letra y la barra se "llena" de 0 a 100 % en 0,8 s (el jugador sabe el tamaño de la pelea). Salida al morir: se vacía hacia el centro y desaparece.

### 1.10 Pantalla de título

Ya hay un fondo (`title_backdrop.gd`, mapa en `title.map`) y un logo. Propuesta:

- Composición: logo grande arriba-centro (el nombre provisional "Desmemoria" con un estilo de letras que se desvanecen por abajo en gris, como el Eco), menú de cuatro entradas abajo-centro, y fondo en parallax lento de la silueta de una gran ruina bajo un cielo ceniza.
- **La Herida en el cielo**: un círculo gris sin textura en lo alto, con un halo, que respira (escala ±3 % en 6 s). Presentarlo ya como motivo prepara el final.
- Entrada del menú: tras 1,2 s sin tocar nada, las opciones se condensan. "Continuar" resaltada en ámbar, con un pequeño cristal que flota junto a la opción.
- Música/sonido: silencio con viento y un único tono. Fuera del alcance de este documento.

### 1.11 Créditos y final

- Créditos: texto en columna centrada, rótulos en 14 px, que sube lento (24 px/s) sobre una secuencia de las zonas del mapa **con su color pleno**: el mundo "recordado" al revés de como empezó. Sin saltos: fundidos de 1 s entre imágenes. Saltables con botón mantenido.
- Final: aún no existe el guion. Lo que sí propongo es la **regla visual**: la última pantalla de juego es el mapa completo con sus zonas pintadas en color, la silueta del Eco del protagonista a un lado, y un texto de una sola línea. Que sea corto: 20 s.

---

## 2. Efectos visuales (VFX)

Convenciones: todos con `CPUParticles2D` o `GPUParticles2D` pequeños, o con polígonos dibujados en `_draw` y animados con `Tween` (como `HitSpark`). Tope global propuesto: **200 partículas vivas** en pantalla y **6 emisores de ambiente**. Coste: bajo / medio / alto es relativo al presupuesto de un juego 2D a 60 fps sobre una GPU integrada.

### 2.1 Golpes (el Filo y de enemigos)
- **Qué**: arco de tajo (ya existe, sutil) + chispazo + salpicadura. Ampliar el chispazo a **rayas más cortas con dispersión** y una **mancha de impacto**: un óvalo plano de 3 fotogramas que se estira en la dirección del golpe.
- **Cómo**: `HitSpark` con 6 rayas cortas (8–14 px) + 6 gotas de 2×2 px con gravedad (`CPUParticles2D`, explosiva, `one_shot`). Colores: tuyo, `h`→blanco; de enemigo, `u`→`t`; en armadura de jefe, chispas `d` naranjas.
- **Duración**: 0,18–0,30 s. **Coste**: bajo. **Variante por material**: carne = gotas rojas; hierro = chispas; piedra = esquirlas grises. Se elige por la capa del objetivo, no por código aparte.

### 2.2 Parry
- **Qué**: un anillo azul que se expande y un destello vertical, con chispazo azul mayor y **parada en seco**. Es el momento de mayor recompensa en combate, así que merece un efecto distinto.
- **Cómo**: anillo (`draw_arc`, 3 px, de radio 6 a 36 en 0,2 s, `h`→`g`, alfa a 0), destello de rayas `h` ampliado (×1,6 de `HitSpark`), hit stop de 0,12 s (el doble de normal) y una **onda de distorsión** opcional (shader de desplazamiento radial sencillo; si no hay tiempo, omitirla).
- **Duración**: 0,25 s. **Coste**: bajo (anillo) / medio (shader).

### 2.3 Dash (estela)
- **Qué**: imágenes residuales azules y líneas de velocidad (ya hay "imágenes residuales" en el sprite; sumar la estela del mundo).
- **Cómo**: cada 0,03 s se crea una copia del `Sprite2D` con `modulate` `g` a alfa 0,5 que se desvanece en 0,18 s (el patrón clásico de *ghost trail*); tres líneas `h` de 12–20 px detrás. Polvo `2`/`3` al despegar y al frenar en el suelo.
- **Duración**: la del dash + 0,2 s. **Coste**: bajo (máximo 6 copias vivas).

### 2.4 Doble salto
- **Qué**: un anillo aplastado de plumas de luz bajo los pies (se parece al objeto de habilidad: coherencia).
- **Cómo**: elipse plana (24×6 px) que crece a 40×10 y se desvanece, más 5 motas `h` que suben 16 px.
- **Duración**: 0,25 s. **Coste**: bajo.

### 2.5 Salto de pared y deslizamiento
- **Qué**: al agarrarse, tres chispas de polvo a la altura de la mano; al deslizar, un fino hilo de polvo caído continuo; al saltar, una mancha de impulso apartándose de la pared.
- **Cómo**: emisor continuo (4 partículas/s) activo solo en deslizamiento; ráfaga de 4 partículas al saltar. Color `3`/`4`, o `h` si ya se recordó la habilidad (la mano espectral).
- **Duración**: 0,3 s por ráfaga. **Coste**: bajo.

### 2.6 Curación
- **Qué**: el protagonista bebe del frasco; luz ámbar sube en volutas desde el pecho; tras la curación, un destello cálido.
- **Cómo**: 12 partículas `c`/`d` que suben con deriva sinusoidal (una función en `_process` para el desplazamiento X), un halo aditivo alrededor del cuerpo (`BLEND_MODE_ADD`) que sube a 0,35 de alfa, y el icono de vida del HUD que se enciende. Mantener la acción **lenta** (el aviso de que bebiendo eres vulnerable es parte del diseño).
- **Duración**: la de la acción + 0,4 s. **Coste**: bajo.

### 2.7 Muerte del jugador
- **Qué**: no una explosión, sino una **disolución**: el cuerpo se separa en motas azules que suben y forman el Eco.
- **Cómo**: al terminar la animación de caída, el sprite se sustituye por ~40 partículas `g`/`h` con la forma de la silueta (el emisor usa una máscara rectangular de 20×44) que suben hacia la posición del Eco. Un fogonazo blanco de 1 fotograma al comienzo.
- **Duración**: 1,2 s. **Coste**: medio (40 partículas, una vez).

### 2.8 Eco
- **Qué**: silueta azul que flota (ya existe), con un halo y motas que se desprenden por abajo (se deshace en jirones).
- **Cómo**: halo aditivo, 3 motas por segundo con gravedad negativa. Al recogerlo, la silueta **se vuelca hacia ti** (tween de posición en 0,4 s) y los Ecos se vuelcan en la gota del HUD como un chorro de motas que vuelan hacia la esquina (cada una con curva en arco). Sonido mantenido.
- **Duración**: continuo / 0,6 s al recoger. **Coste**: bajo.

### 2.9 Ecos al derrotar enemigos
- Cada enemigo vencido suelta 5–8 motas azules `g` que flotan 0,3 s alrededor y luego **vuelan hacia el jugador** y al HUD. Es el feedback de "ganar Ecos" sin texto. **Coste**: bajo.

### 2.10 Descanso en el Ancla
- **Qué**: ya hay halo, charco, motas y onda. Sumar: los **nombres grabados** brillan uno a uno (las runas del sprite se encienden en cascada), un anillo de luz ámbar sube por el monumento y el mundo se oscurece levemente alrededor (viñeta) mientras el menú está abierto.
- **Cómo**: Se anima por encima del sprite con tweens de `modulate` por zonas (el sprite ya tiene 8 fotogramas; reutilizar). Ráfaga de 20 partículas `d`.
- **Duración**: 1,2 s. **Coste**: bajo.

### 2.11 Habilidad recordada ("la gran escena")
Secuencia de 3,5 s, hecha con elementos ya existentes más pocos nuevos:

1. Al tocar el objeto: hit stop de 0,2 s, el halo del objeto se expande a pantalla completa en blanco (alfa 0→0,8→0 en 0,5 s).
2. La música baja; el mundo se **desatura** menos el objeto, que flota hasta el pecho del protagonista.
3. **Un recuerdo ajeno**: durante 1,2 s, sobre un viñeteado, se muestran 6–8 siluetas en azul claro de una escena (la persona que dominaba esta técnica, haciéndola) en estilo de *flash* de píxeles muy grandes (tres o cuatro fotogramas de pocos polígonos). Costoso de dibujar: la versión barata es una **silueta del Caminante repitiendo la técnica** (reutilizando la animación) desvanecida en azul.
4. El protagonista **ejecuta** la técnica una vez (dash, doble salto, salto de pared) con su VFX completo, y el rótulo "HAS RECORDADO" (1.8).
5. Retorno del color al mundo con un barrido horizontal en 0,5 s.

- **Cómo**: capa `CanvasLayer` con `ColorRect` para el flash y la desaturación (un shader de 5 líneas: `mix(color, vec3(luma), amount)`), `Tween` de `Engine.time_scale` a 0,3 durante 0,4 s para cámara lenta y vuelta a 1. Partículas: anillo de runas girando (ya hecho en el objeto) y 30 motas ascendentes.
- **Coste**: medio, pero se ve una vez por habilidad. Es **el efecto que más merece pulirse**.

### 2.12 Impacto de jefes
- **Mazazo del Centinela**: polvo (ya existe, `impact_dust.gd`), grietas en el suelo (dos líneas poligonales `2` que se abren 0,3 s), onda de choque (ya existe), temblor 9 px / 0,45 s, hit stop de 0,08 s al impactar sobre ti.
- **Rocas del techo**: antes de caer, un polvillo fino en el punto de impacto (la **señal de aviso**, 0,4 s). Al caer: esquirlas (8 partículas `3`/`4`) y polvo.
- **Rotura de armadura**: polígonos de hierro que salen disparados (12 piezas con rotación), chispas `d`, parada de 0,2 s y un sonido sordo.
- **Muerte del jefe**: ver 1.7.
- **Coste**: medio, pero localizado en la sala del jefe.

### 2.13 Ambientales por región
Se aplican en `Room` según el atributo de región. Todos son un único emisor por pantalla, con las partículas **alineadas al rango de cámara** (emisión de 864×486 más 100 px de margen) para que el coste no crezca con el tamaño de la sala.

| Región | Efecto | Construcción | Colores | Partículas | Coste |
|---|---|---|---|---|---|
| El Último Umbral | Polvo en luz y motas de polen | emisor en caja, deriva lenta, 2×2 px | `d` alfa 0,35, `4` | 25 | bajo |
| Terrazas Secas | Ceniza y brizna de paja | caída lenta con viento lateral, rotación | `3`, `4`, `b` | 40 | bajo |
| La Cisterna | Goteo y ondas en el agua | gota 1×3 px que cae, anillo plano al tocar agua | `g`, `h` | 15 + ondas | bajo |
| Galerías Bajas | Polvo de roca, humo frío | 20 partículas grandes con alfa muy baja, escala creciente | `2`, `3` | 20 | bajo |
| El Aljibe (jefe) | Brasas de la armadura | motas rojas que ascienden, parpadeo | `t`, `u`, `c` | 12 | bajo |
| Zonas de musgo/vivas | Esporas | luminosas, ascienden y oscilan | `p`, `o` | 25 | bajo |
| Cerca de la Herida | Niebla gris, "ceniza al revés" que sube | tira de niebla (sprite grande a baja opacidad moviéndose, 2 capas en parallax), ceniza `3` ascendente | `3`, `4` | 30 + 2 capas | medio |

La **niebla** se hace con un solo sprite de 256×64 de ruido (generado con JS) repetido horizontalmente con desplazamiento lento y opacidad 0,12–0,25. Barato, vale para todas las regiones.

### 2.14 Presupuesto y reglas de seguridad
- **Máximo de efectos por impacto**: un golpe no puede generar más de 20 partículas.
- **No ver efectos fuera de cámara**: `VisibleOnScreenNotifier2D` para pausar emisores de ambiente.
- **Destellos**: nada con más de 3 destellos por segundo a pantalla completa (accesibilidad, 3.7); los flashes blancos de pantalla completa se limitan a 0,15 s y alfa 0,6 salvo la gran escena.
- **Distinguir lo importante**: el color del efecto indica de quién viene. Los efectos del jugador siempre usan azul frío/blanco, los de enemigos rojo/naranja y los de jefes añaden ámbar: así, en un caos de partículas se sabe qué es amenaza.

---

## 3. Animación y "game feel"

### 3.1 Poses que faltan al protagonista
Hoy tiene: reposo (10), correr (14), salto (4), caída (4), ataque (12), guardia (4), golpe recibido (4), dash (6). **Faltan** (con fotogramas orientativos y prioridad):

| Animación | Fotogramas | fps | Nota | Prioridad |
|---|---|---|---|---|
| Agarre de pared | 2 (agarre + deslizamiento) | 6 | brazo extendido sobre la pared, pies alzados; necesaria para el salto de pared | Alta |
| Salto de pared (impulso) | 3 | 14 | giro rápido, vuelta del cuerpo | Alta |
| Doble salto | 4 | 14 | giro en el aire, capa que se abre | Alta |
| Aterrizaje | 3 | 18 | agacharse y recuperar; con más fuerza si la caída es larga | Alta |
| Golpe hacia arriba | 6 | 20 | el Filo describe un arco por encima de la cabeza | Alta (existe en el diseño) |
| Golpe hacia abajo (pogo) | 6 | 20 | punta hacia el suelo, cuerpo encogido | Alta |
| Curarse (beber) | 8 | 10 | sacar el frasco, beber, guardarlo | Alta |
| Muerte | 10 | 10 | caída de rodillas, caída de lado, la capa se deshace | Alta |
| Sentarse/descansar en el Ancla | 8 | 6 | manos sobre el hito, cabeza baja; entrada y salida | Media |
| Recoger objeto / recordar habilidad | 6 | 8 | mano al pecho, mirada al frente, ejecución de la técnica | Media |
| Deslizarse (agacharse) | 4 | 12 | solo si se añade la mecánica | Baja |
| Giro (cambiar de dirección al correr) | 3 | 16 | frenada ligera: aporta mucho al "peso" | Media |
| Empuje/ interactuar (puertas, palancas) | 4 | 8 | si hay mecánica de palancas | Baja |
| Reposo largo (tras 10 s) | 8 | 4 | el protagonista mira alrededor, se ajusta la máscara | Baja, de carácter |

Todas con el mismo lienzo (112×64), reutilizando piezas como indica `arte.md`. Para el golpe hacia arriba y abajo hay que dibujar el arma en dos poses nuevas: ya hay generador de piezas; es dibujo sobre todo de un brazo y una daga.

### 3.2 Enemigos genéricos
Todos tienen reposo, andar, aviso, golpe, golpe recibido. **Faltan**:
- **Muerte** (6 fotogramas): hoy desaparecen. Propuesta: cada enemigo cae y se deshace en su color (cenizas rojas), 0,5 s. Sin esto, matar no tiene cierre visual.
- **Aturdimiento** (2–3 fotogramas en bucle): tras un parry, se tambalea con la cabeza gacha y estrellas **no**; en su lugar, una espiral de motas azules. Hoy se señala con tinte azul, suficiente para el slice.
- **Detección / alerta** (3 fotogramas): un sobresalto y un gesto antes de perseguirte (anticipación gratis para el jugador).
- **Aparición** (opcional): al reaparecer tras descansar, salir de las sombras.
- Mejor conservar las **siluetas distintas** (Cascarón, Lancero, Arrojador, Coloso, Acechador) como ya están: se identifican por forma antes que por color, lo que ayuda a la accesibilidad.

### 3.3 PNJ (cuando existan)
Un PNJ pequeño necesita solo: **reposo** (4–6 fotogramas con respiración), **hablar** (2 fotogramas alternando para mover la cabeza), y una **acción propia de su oficio** (por ejemplo, el cuidador del Hito que apila piedras). Hasta que haya un PNJ concreto, **no dibujar nada**. Sus diálogos usan el mismo panel de 1.8 con retrato opcional de 48×48 (aplazable: un diálogo sin retrato sí funciona).

### 3.4 Principios de anticipación y peso
1. **Anticipación proporcional a la amenaza**: mazazo del Coloso 0,6–0,85 s con pose alzada, tajo del Cascarón 0,4 s (hoy ya es así). La pose de aviso es *dibujada*, no solo tintada: el tinte amarillo refuerza, no sustituye.
2. **Tres tiempos**: aviso → golpe (1–2 fotogramas muy rápidos) → recuperación. El golpe es lo más veloz que existe en pantalla, y la recuperación es lo que concede la ventana al jugador.
3. **Squash y stretch mínimos** (±8 %): al saltar (estirar), al aterrizar (aplastar, 3 fotogramas), y solo a escala de píxel entero. Se hace con `scale` en fotogramas concretos, nunca continuo (para no deformar píxeles).
4. **Cuerpo, luego capa**: la capa tiene inercia propia y se retrasa 2–3 fotogramas respecto al cuerpo: da la mayor parte del "peso" y ya está dibujada en parte.
5. **Acciones del jugador responden en 1–2 fotogramas** de entrada (ataque instantáneo): la anticipación del jugador es mínima; la del enemigo, larga. Es una asimetría deliberada.

### 3.5 Hit stop, temblor y feedback de combate
- **Hit stop** (ya implementado): estandarizar en tres niveles: golpe normal 0,06 s; parry 0,12 s; golpe contra armadura de jefe 0,05 s; romper la armadura 0,2 s; recibir daño 0,08 s (se *siente* más fuerte detener al jugador cuando es golpeado). Implementar con `Engine.time_scale` o pausando solo a los dos implicados (mejor: solo los implicados, para que las partículas sigan vivas y el golpe no se vea como un fallo).
- **Temblor de cámara**: tres perfiles (leve 2 px / 0,1 s; medio 5 px / 0,2 s; fuerte 9 px / 0,45 s) con caída suave y **eje preferente** (el temblor de un mazazo es vertical; el de un tajo es horizontal). Siempre multiplicado por el ajuste de accesibilidad "Intensidad del temblor" (0–100 %).
- **Retroceso del golpe** con un fotograma de estiramiento. El número de daño ya existe: unificarlo con la nueva fuente y limitarlo a 3 dígitos.
- **Luz de golpe**: un destello puntual aditivo de 0,06 s en el punto de impacto.
- **Señal amarilla de aviso**: es la única función del amarillo en todo el juego. Reservar ese tono (`d`/`#f3c46a` más saturado) *solo* para avisos de ataque, y que el ámbar de interfaz sea más naranja (`c`) para que no se confunda. Ver 3.7 para su versión accesible.

### 3.6 Cámara, transiciones y fundidos
- **Límites**: la cámara se ata a la sala (límites `limit_*`) y **no sale** de los bordes del mapa, para no enseñar el vacío. En salas pequeñas se centra. Suavizado (`position_smoothing`) a 6–8, con **adelantamiento** en la dirección de movimiento (look-ahead de 48 px) y mirar arriba/abajo manteniendo el stick (ya existe `camera_look_component`).
- **Zoom en jefes**: al cerrar las rejas, la cámara se aleja suavemente de 1,0× a 0,85× (en 1,2 s) para encuadrar toda la arena y vuelve al abrirse. Como el juego escala por enteros, **el zoom se hace cambiando el límite visible**, no con escalado fraccionario (que ensucia los píxeles). Si hace falta, una cámara con zoom 1× y salas de jefe diseñadas del tamaño de la pantalla. Aviso: es un riesgo técnico; ver preguntas.
- **Transición de sala**: fundido a negro de 0,15 s de salida y 0,25 s de entrada (no más: la exploración no debe sentirse lenta), con el protagonista caminando 1–2 pasos automáticos al aparecer en la puerta para que se note el cruce. Si la sala siguiente es contigua (sin pantalla de carga), preferible un **corte limpio con scroll**.
- **Fundidos por emoción**: negro para muerte y transición, blanco para recuerdo/habilidad, gris para olvido.
- **Viñeta**: oscurecimiento de 20 % en los bordes, fijo; sube a 40 % con vida de 1.
- **Cámara en la muerte**: se detiene (sin temblor) y se acerca 5 % hacia el cuerpo.

### 3.7 Accesibilidad
Una opción de interfaz se añade solo cuando existe su efecto; esta es la lista propuesta, ordenada por coste:

1. **Intensidad del temblor** (0 %, 50 %, 100 %): multiplica los perfiles de 3.5. Coste mínimo; un solo número en `ScreenShakeComponent`.
2. **Reducir destellos**: sustituye los flashes de pantalla completa por una subida de 25 % de alfa, y limita la repetición. Importante para fotosensibilidad.
3. **Contraste alto**: oscurece el fondo bajo el texto, engrosa el contorno de los mensajes a 2 px y añade un borde blanco fino a los **enemigos y proyectiles** (shader de contorno de 1 px) para que sobresalgan del escenario.
4. **Daltonismo** (protanopia/deuteranopia/tritanopia):
   - La paleta del juego usa **rojo y verde apagado**, una combinación problemática. Pero **el verde nunca lleva información de juego**, solo ambiente. La información crítica se apoya en rojo vs azul, que se separa bien.
   - La **señal amarilla de aviso** del enemigo debe funcionar sin color: el aviso se dibuja *también* con una **forma**: un destello blanco de 2 fotogramas en la mano del arma y una **exclamación de 8×8 píxeles** sobre la cabeza del enemigo (opcional, activable). Además del tinte, el sprite hace pulsar su brillo a 8 Hz. En modo daltónico, el tinte se cambia de amarillo a **blanco-azulado** (que se distingue del fondo de cualquier forma de daltonismo) y se sube la frecuencia del pulso.
   - La leyenda del mapa y los marcadores usan forma, no solo color (1.3).
5. **Tamaño de texto**: opción de 100 % o 150 % para avisos y diálogos (la fuente solo escala por múltiplos enteros: 14 → 21).
6. **Subtítulos de sonido** de los eventos clave (golpe, aviso fuera de pantalla). Aplazable.
7. **Ayudas de ventana**: opción de ampliar el parry de 0,2 s a 0,3 s. Es un tema de diseño, lo menciono porque está en el cruce con accesibilidad.
8. **Mando y teclado**: los glifos de mando ya están. Permitir *remapear* controles es lo que más gente necesita; fuera de este documento pero no debe olvidarse.

---

## 4. Iconografía

Estilo: silueta clara, 1 px de contorno en `1` (negro piedra), 3 tonos de la rampa del significado, un punto de luz de 1 px en el tono más claro. Todos legibles a 16×16 sobre fondo `1`. Los de 24×24 son los de habilidades, amuletos y mapa grande. Donde sea útil, abajo va una descripción de píxeles; tres de ellos llevan además la rejilla de carácter (`.` transparente, letras de `palette.txt`).

### Habilidades (24×24, rampa azul `e f g h`)
1. **Dash**: tres cheurones `>>>` apuntando a la derecha, escalonados 2 px en vertical, con la punta `h` y el cuerpo `g`; detrás, dos rayas horizontales `f`. Contorno en `e`.
2. **Doble salto**: ala de tres plumas hacia arriba (la del objeto) con dos puntos `h` encima, separados 4 px. Plumas en `g`, punta `h`.
3. **Salto de pared**: línea vertical de piedra `3` a la izquierda de 4 px de ancho y una mano de tres dedos `g` aferrada, con una pequeña chispa `h` en el nudillo.
4. **Excavar/romper suelo**: un pico de 8 px de ancho sobre dos trapecios de suelo agrietado `3`, con grieta en zigzag `e`.
5. **Parry**: escudo pequeño en forma de rombo `f` con una raya diagonal `h` (reflejo).
6. **Golpe hacia abajo (pogo)**: punta de daga `h` hacia abajo con un arco de rebote `g` debajo.

### Árbol de habilidades (16×16, rama por color)
7. **Vitalidad**: gota/gema de corazón `t` con filete `u` arriba a la izquierda, sobre una placa `2`.
8. **Frascos**: frasco de cuello corto, base panzuda `c`, tapón `a`, líquido `d` a medio llenar.
9. **Temple**: pequeña coraza/pechera `3` con una grieta `1` reparada con una línea `c`.
10. **Filo afilado**: hoja curva en diagonal `4` con filo `h` y mango `b`.
11. **Ritmo**: dos flechas circulares de 3 píxeles de ancho, `c`, formando un reloj abierto.
12. **Alcance**: hoja con tres líneas de movimiento delante, la más alejada en `b`.
13. **Guardia**: arco semicircular `g` con un pico en la mitad (la ventana del parry).
14. **Impulso**: huella de pie `4` con tres rayas `g` atrás.
15. **Contragolpe**: dos flechas cruzadas `t` y `h` que se enfrentan con un pequeño asterisco entre ellas.

### Objetos y HUD (16×16)
16. **Eco**: gota `g` con filete `h`, base rota en dos jirones (ya existe).
17. **Frasco de curación** (lleno y vacío): ya existen; añadir el estado "bebiendo" con tapón fuera.
18. **Llave / sello**: una llave corta `c` con anilla romboidal `d`, sin barba (para puertas de la Orden).
19. **Recuerdo (colectable)**: rombo `h` con núcleo `g`, esquinas con chispa.

### Reliquias (24×24; rampa según su sentido)
20. **Vendaje de Nombres**: tira de tela `4` enrollada con una línea de trazos `c` (letras ilegibles).
21. **Sello de la Orden**: disco `3` con un símbolo de torre hueca `1` y anillo `c`.
22. **Colmillo del Cascarón**: colmillo curvo `4` manchado de rojo `s` en la base.
23. **Cristal de Anclaje**: esquirla del Ancla, diamante alargado `g` con una llama `d` dentro.
24. **Cuerda del Mensajero**: ovillo de cuerda `b` con un nudo `a` y un cabo suelto.
25. **Moneda sin rostro**: círculo `d`/`c` con la cara lisa y borde mellado.
26. **Máscara hueca**: media máscara `4` con el hueco de un ojo `1` y una grieta `e`.

### Mapa (8×8 o 16×16)
27. **Ancla**: pila de tres piedras `3` con un punto `g` encima (cristal).
28. **Eco**: rombo violeta (ya establecido), con jirón.
29. **Jefe vencido**: calavera hueca de 8×8 `3`.
30. **Puerta cerrada**: barra gruesa `s` con tres puntos.
31. **Jugador**: rombo `d` con parpadeo.
32. **Chincheta de nota**: círculo de 5 px con un punto, en ámbar/azul/rojo/blanco, con forma diferente por color (círculo, cuadrado, triángulo, rombo).

### Rejilla de ejemplo: Frasco (16×16)

```
................
.......aa.......
......a11a......
......1bb1......
.......11.......
......1cc1......
.....1cddc1.....
....1cddddc1....
....1cdddd c1...
....1cdddddc1...
....1ccddddc1...
....1cccdccc1...
.....1cccccc1...
......111111....
................
................
```
(Bien leído como orientación: cuello `1`/`a`, panza `c`/`d`; corregir espacios al pasar a `.sprite`.)

### Rejilla de ejemplo: Dash (24×24, esquema)

```
........................
........................
..................h.....
...................hh...
.....h.......h.......hh.
......hh.......hh......h
.......ghh.....ghh....hg
........gghh....gghh.hg.
.........gg.hh...ggghg..
..ff.....ffggg...gggg...
...fff...ffgg....ggg....
(...simétrico en la mitad inferior)
```
(Esquema de masa: tres cheurones desplazándose, con la punta `h` y el resto `g`. En la implementación se dibuja con tres polígonos de 4 vértices en el generador JS, que da el resultado exacto.)

### Rejilla de ejemplo: Eco (16×16)

```
................
.......hh.......
......hggh......
.....hgggfh.....
.....ggggff.....
....hgggfff.....
....ggggfff.....
....gggffff.....
....gggffff.....
.....gffffe.....
.....fffee......
......ffe.e.....
.......e...e....
..............e.
................
................
```

Producción de los iconos: los de 16×16 se escriben a mano como texto en `art/source/iconos.sprite` (una fila por categoría) y los de 24×24 se pueden generar con un script JS que dibuja polígonos y los rasteriza, como el Ancla.

---

## 5. Prioridades y esfuerzo

Escala de esfuerzo para una sola persona con herramientas de código: S (≤ 1 sesión), M (2–3 sesiones), L (4+).

**Prioridad 1: necesario para que el slice se sienta terminado (y lo que mejora más por menos)**
| Elemento | Esfuerzo |
|---|---|
| Tema unificado: fuente, `NinePatch` de panel, colores en un recurso | S |
| Animación de muerte del jugador + disolución en Eco + pantalla de muerte | M |
| Poses: agarre de pared, doble salto, aterrizaje, golpe arriba/abajo, curarse | L |
| Muerte de enemigos con ceniza | S |
| Estandarización de hit stop y temblor con opción de intensidad | S |
| Barra de jefe con dos barras + muescas + entrada | S |
| Victoria sobre jefe (secuencia 4,5 s) | M |
| VFX básicos: dash, doble salto, salto de pared, parry, curación | M |
| Mensaje grande "Has recordado" + nombre de zona | S |

**Prioridad 2: calidad**
| Elemento | Esfuerzo |
|---|---|
| La gran escena de habilidad recordada completa | M–L |
| Ambientales por región (7 efectos) | M |
| Mapa: zonas con patrón, leyenda con formas, parpadeo al descubrir | M |
| Árbol de habilidades con nodos hexagonales y cadenas luminosas | M |
| Opciones de accesibilidad (temblor, destellos, alto contraste, daltonismo) | M |
| Pantalla de título rehecha con La Herida | S |
| Sentarse/descansar y recoger objeto | M |

**Prioridad 3: contenido que depende de decisiones de diseño**
| Elemento | Esfuerzo |
|---|---|
| Panel de Reliquias + sistema de datos | L |
| Notas del mapa | M |
| Créditos y final | M |
| PNJ y diálogo con retrato | L |
| Zoom de cámara en jefes | M (riesgo técnico) |

Mi recomendación de orden: **tema y fuente → muerte → poses que faltan → VFX básicos → victoria sobre jefe → gran escena**. La razón es que cada una cambia cómo se *siente* el juego en el primer minuto y se ve mejor cuanto antes se pruebe. El panel de Reliquias y los créditos son tentadores pero no mejoran el núcleo jugable, y el proyecto prefiere "pequeño y terminado".

---

## 6. Preguntas abiertas

1. **Fuente**: ¿te vale "m5x7" (o "Pixelify Sans") para el texto y un rótulo propio para los títulos? Hay que confirmar la licencia antes de incluirla y apuntarlo en `docs/decisiones.md`.
2. **Texto de muerte y de victoria**: ¿"HAS OLVIDADO" y "RECUERDO LIBERADO" encajan con la voz del juego? Lo ideal es que lo cierren los escritores.
3. **Reliquias**: ¿queremos el sistema en este proyecto? Es la mayor pieza de contenido nueva de esta lista y cambia el diseño (números, descripciones, dónde se encuentran). Si no está claro, se puede **aplazar sin coste** y dejar el botón "Reliquias" fuera.
4. **La gran escena**: ¿recuerdos ajenos con silueta de otra persona (más caro, narrativamente potente) o repetir el Caminante (barato)? Depende de cuánto pese cada habilidad en la historia.
5. **Zoom en jefes**: ¿admitimos zoom fraccionario con pérdida de nitidez, o diseñamos las arenas del tamaño de pantalla? Mi preferencia es lo segundo.
6. **Señal amarilla**: ¿aceptamos reservar el amarillo exclusivamente para avisos (cambiando el ámbar de interfaz a más naranja) y sumar la exclamación opcional? Afecta a todo el arte.
7. **Hit stop**: ¿pausar solo a los implicados (más técnico, mejor sensación) o `Engine.time_scale` global (más simple)? Conviene probar los dos jugando.
8. **Compra en el árbol**: ¿doble pulsación o mantener pulsado? Prefiero la primera por accesibilidad.
9. **Notas del mapa**: ¿merece la pena en un mundo de este tamaño? Quizá solo con un mapa mayor.
10. **Idioma de los textos del jugador**: ¿todo en español de España, también los botones del mando? Los glifos ya son iconos, pero las opciones y avisos habrá que revisarlas con el mismo criterio.
11. **Música y sonido**: este documento no la cubre, pero la gran escena, la muerte y el título dependen de ella; ¿quién coordina con `docs/sonido.md`?
12. **Presupuesto de rendimiento**: ¿cuál es el equipo mínimo objetivo? Los 200 partículas y 6 emisores son una estimación que debe medirse con el slice real.
