# Pipeline de arte: qué sabe hacer hoy y cómo escalarlo

Informe del ingeniero de pipeline (artista técnico) para la sala de artistas. Alcance: un juego de 6 regiones, ~10 jefes, ~12 PNJ, ~30 tipos de enemigo y decenas de props, producido con la cadena actual (sprites como texto, esqueleto en Node, conversión en Godot).

Todo lo que sigue se ha comprobado leyendo `tools/*.js`, `tools/build_sprites.gd`, `core/components/sheet_animator.gd`, las escenas de enemigo y las hojas reales. Las cifras de peso y tiempo las he medido sobre el repositorio (regenerar los `.sprite` es determinista: tras ejecutarlo, `git status` sigue limpio).

---

## 1. Inventario honesto: qué hay y qué no

### 1.1 La cadena, en una línea

`rig_*.js` (poses a 1 px nativo) -> `art/source/*.sprite` (texto, un carácter por píxel) -> `build_sprites.gd` (PNG + vista previa x8) -> `import` de Godot -> `Sprite2D` + `SheetAnimator` (fila = animación, columna = fotograma).

Medidas reales: `art/source` pesa ~11 MB de texto (el jefe solo, 8,4 MB). Regenerar el rig del jefe tarda ~1,4 s; `build_sprites.gd` sobre todo el directorio tarda ~19 s (reconvierte todo siempre, sin caché). Es tolerable hoy; con 150 hojas dejará de serlo (ver 4.4).

### 1.2 Qué sabe hacer el rig (`rig_lib.js`, 571 líneas)

- **Un solo esqueleto: humanoide lateral bípedo.** Cadera, columna curvada en tres tramos (cintura, pecho, cabeza), brazo cercano y lejano, pierna cercana y lejana con cinemática inversa de dos huesos (`ik`), pies con ángulo.
- **Parámetros de pose** (`BASE`): ~25 números por fotograma (`hipx/hipy`, `lean`, `bend`, `head`, pies `nfx/nfy/nfa/ffx/ffy/ffa`, manos `fx/fy/gx/gy`, ángulo y curvatura del arma, viento de capa y bufanda). Las animaciones son poses clave interpoladas con `keyed()` y ciclos de pie (`footCycle`, `walk`).
- **Cabezas:** `hood` (capucha con máscara/ojos/ribete), `bare` (calva con brillo de ojo), `helm` (yelmo) y `none` (el jefe pinta la suya por encima). Tres estilos más una opción de dibujo a mano encima (`deco`).
- **Armas** (`drawWeapon`): `dagger` (hoja curva), `knife`, `spear`, `maul`, `claws` y `shard`. Seis, todas "en la mano".
- **Capa/bufanda con inercia** (`trailChain`): cadena de segmentos que mezcla gravedad y estela. Es lo que da más vida al conjunto; sirve para cualquier colgajo (faldones, banderolas, cola de trapo).
- **Adornos del cuerpo:** vendas (`wraps`), costillas (`ribs`), bandolera (`strap`), cinturón/faja (`waistBand`), hombrera (`shoulderPad`), túnica (`tunic`), bolsa.
- **Contorno y sombreado:** contorno de 1 px en tono `1` (el más oscuro de piedra) automático alrededor de toda forma (`Canvas.shape`), y sombreado de tres tonos por cadena de huesos con una luz fija arriba-atrás (`LIGHT`), más un ruido determinista (`noise`, `hash2`) para romper los planos. Siempre rampas de la paleta global.
- **Escala:** `setCanvas(w,h)` y el factor `Z`/`M`. El jefe usa `M = 2` y `K = 1,45` sobre el coloso: mismo esqueleto, longitudes multiplicadas, y encima una función `deco` que pinta armadura, grietas y la figura interior. Es decir, **escalar funciona, pero sale caro en código a mano** (636 líneas solo para el Centinela).
- **Efectos de fotograma** ya soportados: imágenes residuales (`ghost`), líneas de velocidad (`lines`), estela de arma (`trailFrom`), "glow/open" del jefe.
- **Salida:** `writeSprite` vuelca el `.sprite` con la cabecera; `render` devuelve además dónde queda la punta del arma (`tip`), útil para colocar proyectiles y hitboxes.

### 1.3 Los otros generadores (no son rig)

| Generador | Qué hace | Reutilizable para |
|---|---|---|
| `arte_ancla.js` | Monumento con piedra/musgo/runas por ruido determinista y fotogramas de brillo | Cualquier estructura de piedra animada (altares, puertas, fuentes) si se extrae el ruido |
| `arte_habilidades.js` | Reliquias con núcleo, anillo de runas y chispas | Objetos coleccionables brillantes |
| `arte_titulo.js` | Fuente 5x7 propia con relieve y deshecho | Cualquier rótulo; ya es una "fuente de píxeles" |
| `tiles_umbral.sprite` | 5 baldosas 16x16 escritas a mano en texto | Nada generado: es manual |
| `decor.sprite` | 13 piezas 48x64 escritas a mano | Manual |

La vista previa de `decor_x8.png` muestra el nivel de acabado manual actual: legible, coherente, sin variación entre instancias. Las baldosas (musgo, piedra, ladrillo, remate, tablón) son 5 en total: hoy un nivel no puede variar nada salvo recolocar esas cinco.

### 1.4 Lo que NO sabe hacer (límites reales)

1. **Cuadrúpedos.** El Acechador (ver `acechador_x8.png`) es un humanoide inclinado 50-88 grados que *parece* ir a cuatro patas. Funciona para un bicho pequeño, pero no hay columna horizontal, ni dos pares de patas con sus propios ciclos de marcha, ni cola. Un lobo, un jabalí o un perro de caza no salen del rig.
2. **Alas y voladores.** No hay huesos de ala, ni batido, ni cuerpo sin patas. Un enemigo volador sería un humanoide colgado.
3. **Tentáculos, serpientes, gusanos, segmentados.** `trailChain` es la base correcta (cadena con inercia), pero solo se usa para la capa, con 3-5 segmentos y sin contorno propio por segmento ni cabeza al final.
4. **Cuerpos sin cabeza o sin torso** (armaduras vacías, espectros): el jefe lo hace con `head:'none'` + dibujo manual encima; no es una opción del rig.
5. **Multi-parte móvil independiente.** Un jefe con cabeza, dos manos flotantes y un cuerpo que se mueven cada uno por su lado (el patrón Hollow Knight) exige partes con su propia pose. El rig dibuja una figura por fotograma, no una escena de varias.
6. **Líquidos, humo, fuego, partículas.** Nada de eso se anima con el rig; la luz del Ancla ya se hace con nodos de Godot (halo aditivo, motas), no con sprites. Es el camino correcto, pero no hay un componente reutilizable.
7. **Variación por instancia.** Dos Cascarones son idénticos píxel a píxel. Sin paleta alternativa ni tinte, 30 enemigos con un cuerpo de 5 estilos serán "los mismos cinco".
8. **Proporciones no humanas.** Cabezas gigantes, torsos anchos de bestia, brazos de longitud extrema: posibles tocando números, pero sin garantías (la IK se rompe si el objetivo queda fuera de alcance; está sujeta con `clamp`, así que se estira en vez de fallar visiblemente).
9. **Vista frontal/trasera, 3/4, y rotaciones.** Solo perfil lateral; el volteo es `scale.x = -1`. Bien para el juego; mal para ilustraciones, retratos o PNJ de diálogo.
10. **Dirección de luz fija** (arriba-atrás). Cualquier sprite generado queda iluminado igual: coherente, pero un jefe de región con otra luz (lava) no lo refleja sin un segundo juego de rampas.

### 1.5 Estado de las convenciones hoy (lo que hay y lo que no está escrito)

Hay convenciones implícitas bien resueltas: los enemigos comparten las filas `idle, walk, windup, strike, hit` y la misma escena base (`enemy.tscn`), y cada variante solo define la textura, las dimensiones de colisión y la tabla `animations` en la escena heredada (`{"hit":[4,4,14.0,false], ...}`: fila, fotogramas, fps, bucle). Esa tabla se duplica a mano en cada `.tscn`: si el rig cambia el número de fotogramas, la escena se queda desfasada y nadie lo detecta. Ese es el primer punto débil a automatizar (sección 4).

Las hojas son rejillas rectangulares: columnas = la animación más larga, y por tanto muchas celdas vacías: 24 de 60 celdas en los enemigos, 54 de 112 en el jugador y **47 de 132 en el jefe**.

---

## 2. Plan de extensión del rig y las herramientas

Principio de la casa: nada "por si acaso". Cada pieza se construye cuando el primer enemigo/jefe/región que la necesita está en el calendario. Aun así hay un orden que evita rehacer trabajo.

### 2.0 Preparación previa (barata y rentable): extraer el núcleo común

**Problema:** `rig_lib.js` mezcla primitivas de dibujo (Canvas, contorno, sombreado por cadena, ruido) con el esqueleto humanoide. Todo cuerpo nuevo necesitará las primitivas, no el humanoide.

**Propuesta:** dividir en `tools/lib/raster.js` (Canvas, `shape`, contorno, `chainTest/chainColor`, `polyTest`, ruido, `trailChain`, `writeSprite`) y dejar `rig_lib.js` como "cuerpo humanoide" que lo importa. No cambia ninguna salida: se verifica regenerando y comprobando que los `.sprite` quedan idénticos byte a byte (`git diff --stat` vacío).

**Coste:** 0,5 día. **Riesgo:** bajo, la regresión es trivial de medir. **Alternativa:** copiar y pegar la parte necesaria en cada rig nuevo (más rápido hoy, peor en cuanto haya tres rigs). **Recomendación:** hacerlo antes del primer rig nuevo.

### 2.1 Cuerpos nuevos (por orden de necesidad)

Cada tipo de cuerpo es un "rig" con su propio juego de huesos, poses y ciclos, pero comparte primitivas, estilos de color, ruido y salida.

| # | Cuerpo | Problema que resuelve | Enfoque | Coste | Riesgo |
|---|---|---|---|---|---|
| 1 | **Bestia de cuatro patas** (lobo, jabalí, sabueso, rata gigante) | Mitad de la fauna de una región; hoy imposible | Columna horizontal de dos tramos (pecho, grupa), cuatro patas con IK de dos huesos y fases de marcha desfasadas (trote: diagonales; galope: pares), cabeza con mandíbula, cola con `trailChain`. Mismos `shape`, contorno y sombreado | 3-4 días el rig + 1 día por especie | Medio: las poses de ataque (embestida, mordisco) hay que afinarlas jugando |
| 2 | **Volador** (murciélago, espectro, polilla gigante) | Enemigos aéreos y de vuelo estacionario para las regiones verticales | Cuerpo corto, dos o cuatro alas como cadena de 3 huesos con batido sinusoidal y deformación de membrana (polígono entre huesos), sin patas | 3 días | Medio: el batido en 1 px se ve tosco a menos de 6 fotogramas; mitigar con anticipación y estela |
| 3 | **Serpiente/segmentado** (gusano, ciempiés, anguila, tentáculo de jefe) | Enemigos de cavernas/cisternas y partes de jefe | Una cadena larga de N segmentos con radio variable que sigue a una "cabeza" por una trayectoria (`trailChain` generalizada: la cabeza dibuja una onda y el resto la hereda con retraso). Contorno por unión, no por segmento | 2-3 días | Bajo: es el caso más cercano a lo que ya existe |
| 4 | **Armadura vacía / sin cabeza** | Centinelas, caballeros huecos, espectros de armadura: son el motivo central del juego | Formalizar lo que ya hace el jefe: `head:'none'` como opción de primera clase, piezas rígidas (yelmo, peto, hombreras, falda) adheridas a huesos con desplazamiento propio y **vacío visible** (hueco con sombra/brillo ámbar). Extraer de `rig_centinela.js` el `deco` genérico | 2 días | Bajo: el prototipo funciona |
| 5 | **Jefe multi-parte** | Jefes tipo Hollow Knight con manos, cabeza o cola independientes | Ver 2.1.1 | 4-5 días el soporte + 3-5 días por jefe | Alto: es la pieza que más tiempo puede comerse |
| 6 | **Humanoide con variantes** (PNJ, cultistas) | 12 PNJ y 10-15 enemigos humanoides | No hace falta rig nuevo: más cabezas (`hood/bare/helm`, añadir `crown`, `veil`, `horned`), más armas (`staff`, `bow`, `torch`, `scythe`, `shield`), ropa larga (`robe`: falda como `trailChain` + eje) | 3 días + 0,5 por estilo | Bajo |

#### 2.1.1 Jefes grandes con varias partes móviles

Hoy el Centinela es **una figura de 11 animaciones x hasta 12 fotogramas en una hoja de 49,5 MB** (4608x2816). Escalar eso a 10 jefes es insostenible en VRAM y en tiempo de generación: cada fotograma lleva el cuerpo entero aunque solo cambie un brazo.

Alternativa recomendada: **jefes por partes**, no por hoja completa.

- Cada parte móvil (cabeza, torso, brazo izquierdo/derecho, arma, cola) es una pequeña hoja propia y un `Sprite2D` hijo en la escena del jefe, con su pivote.
- Un `AnimationPlayer` mueve y rota los sprites (cinemática 2D por escena, no por píxel); las poses de dibujo (boca abierta, ojos que se encienden) se mantienen como fotogramas de la hoja de la parte.
- Los rigs generan *partes*, no figuras completas: la función `render` ya devuelve el `tip` del arma; hay que añadirle "dibuja solo estos huesos y pivota aquí".
- Ventaja: una hoja de 10 jefes pasa de ~500 MB a 30-60 MB y se pueden reutilizar partes (la misma garra en dos jefes con otro tinte).
- Contra: se pierde el aspecto "dibujado fotograma a fotograma" con contorno único, y la rotación de un sprite de pixel art a ángulos arbitrarios introduce **píxeles de distinta escala (pixel mixels)** y bordes dentados. Mitigar con rotación en múltiplos de 15-22,5 grados o rotación "por pasos" (el `AnimationPlayer` salta de pose en vez de interpolar), que además es el estilo del género.

**Decisión recomendada:** mantener el método por hoja completa para el *humanoide mediano* (jugador, PNJ, enemigos normales) y usar partes para jefes que no sean humanoides o cuyo tamaño pase de ~160x160 px. El Centinela, al ser humanoide, se queda como está (con recorte, 4.3).

### 2.2 Tilesets por región

**Problema:** 6 regiones con identidad visual propia; hoy hay 5 baldosas de una región. Dibujar 6 tilesets desde cero a mano en texto es mucho trabajo y arriesga incoherencia.

Tres alternativas:

| Opción | Idea | Pros | Contras |
|---|---|---|---|
| A. **Rampa de paleta por región** | Las mismas baldosas con los cuatro tonos de cada rampa sustituidos por los de la región (piedra gris -> piedra rojiza, musgo -> ceniza) | Barato, coherente, ya alineado con "la Desmemoria se expresa con la paleta" | Las regiones se parecen en forma; sin ruido propio parece un cambio de filtro |
| B. **Variantes con ruido determinista** | Un generador que parte de la forma base (ladrillo, losa, suelo) y añade grietas, musgo, humedad, óxido según parámetros de región y semilla fija | Variación real (cada región tiene su textura), 3-4 variantes por baldosa para romper el patrón repetido | Más código; ajustar a ojo |
| C. **Dibujo manual por región** | Pixelorama/LibreSprite | Máxima calidad | 6x el trabajo y no escala con los cambios de paleta |

**Recomendación: A + B, y C solo para los remates singulares.** Concretamente:

1. Un generador `tools/arte_tiles.js` con una **definición de baldosa por forma** (`brick`, `slab`, `rubble`, `floor_top`, `cap`...) y una **definición de región** (rampa de piedra, color de vegetación/óxido, densidad de grietas, semilla). Salida: `tiles_<region>.sprite` y `tiles_<region>.png`.
2. **Variantes**: 4 por forma, con ruido determinista `hash2(x, y, semilla)` (mismo mecanismo que el rig, no hay que inventar nada). Solo cambia el interior; **los bordes superior e inferior se conservan** para que encajen con las vecinas. Se prueba con un tablero de test que repita cada baldosa 8x8 para detectar costuras.
3. **Autotiling**: la hoja de 5 baldosas no basta para esquinas, bordes interiores ni escaleras; pasar a un bloque de 47 (o 16 variantes mínimas) con el terreno de Godot. Esto es **trabajo de `TileSet`, no de arte**, y condiciona cómo se pinta el mapa de texto (`.map`): hay que decidirlo con el equipo de diseño de niveles antes de generar nada.
4. Cada región es **un `TileSet` propio** (misma rejilla, mismo orden de índices), de modo que cambiar de región en un mapa no obliga a repintarlo.

**Coste:** generador y primera región 3-4 días (incluye autotiling); cada región nueva, medio día de calibrado y revisión. **Riesgo:** que el ruido genere "sopa de píxeles" (las baldosas de relleno actuales ya lo rozan); mitigar con la regla de que el ruido solo mueve entre tonos adyacentes de la rampa.

### 2.3 Sistema de paletas alternativas (desaturación por zona)

**Problema:** `arte.md` fija niveles 0-3 de desaturación, a implementar "con un sombreador o paletas alternativas cuando existan las primeras zonas reales".

Alternativas:

| Opción | Mecánica | Pros | Contras |
|---|---|---|---|
| 1. **Sombreador de intercambio de paleta** (palette swap) | El sprite sigue en la paleta base; un shader por `CanvasItem` o por `CanvasLayer` mapea cada color a otro (textura de rampa 32x N) | Un solo PNG, cambia en tiempo real (transición a la Herida, flash de daño, Eco), sin regenerar nada | Hay que mantener la textura de paleta; los 32 colores deben ser exactos (ya lo son) |
| 2. **Hojas pre-generadas por región** | `build_sprites.gd` emite una hoja por (sprite x región) | Sin shader; control total | Multiplica los PNG y la VRAM x N regiones |
| 3. **Filtro de pantalla** (saturación global) | Un shader de postproceso | Trivial | Desatura también la interfaz y las cosas "recordadas" que deben seguir vivas; no distingue objetos |

**Recomendación: opción 1.** La paleta ya es un conjunto cerrado de ~28 colores con un carácter por color, perfecto para un `palette lookup`: el shader recibe un píxel, lo busca por índice y lo sustituye. Para que sea fiable los PNG deben usar **exactamente** los colores de `palette.txt` (garantizado por `build_sprites.gd`, y comprobable en la validación, 4.1), y el contorno `1` y las rampas deben seguir siendo reconocibles tras el intercambio.

Cómo organizarlo:

- `art/palettes/<region>.txt`: mismas claves, otros colores. Una **tabla de paletas** (`base`, `umbral`, `cisterna`, ..., `herida_1..3`).
- Un `ShaderMaterial` compartido con parámetros `palette_from` / `palette_to` y un `mix` (0-1) para transiciones suaves.
- Cada región (`room.gd` o `world.gd`) aplica el material a una capa de nivel y a un grupo de entidades; el jugador, el HUD y los objetos "recordados" quedan **fuera** para que conserven el color (esto es regla de diseño, no técnica).
- Los fondos y el decorado reciben la paleta de región; los enemigos, una **variante por tinte** (paleta de enemigo) para convertir 5 cuerpos en 15 sin dibujar nada.

**Coste:** shader + textura de paleta + herramienta de generar paleta por región 2 días; tiene retorno inmediato (variación de enemigos). **Riesgo:** el intercambio puede generar contraste pobre si la paleta de destino no mantiene el orden de luminosidad: se comprueba con un script que verifique que cada rampa está ordenada de oscuro a claro.

### 2.4 Fondos parallax por región

**Problema:** cada región necesita 3-5 capas (cielo, lejanía, medio, cerca, niebla) que no existen; el menú ya lo hace **por código** (`title_backdrop.gd`).

Alternativas: (a) dibujar capas como PNG de pantalla ancha, (b) generarlas por código en tiempo de ejecución (como el menú), (c) generarlas por script offline a PNG.

**Recomendación: (c) con un generador `tools/arte_fondo.js`.** Parámetros por región: silueta (colinas, ruinas, bosque muerto, bóveda de cisterna, chimeneas), densidad, paleta, altura de horizonte. Cada capa se escribe como una tira que **se repite horizontalmente sin costura** (el ruido se hace periódico con módulo del ancho) de 864 px de alto máximo. Ventajas frente a (b): se revisa en una vista previa estática y no cuesta CPU; frente a (a): la paleta y las siluetas cambian por región con un parámetro.

Tamaño: tira de 1728x486 (dos pantallas) x 4 capas = 13 MB sin comprimir por región. Cuidado: es **casi tanto como todo el resto de arte junto**; reducir con capas de 1/2 de alto (las lejanas tienen poco detalle) y `Parallax2D` con repetición.

**Coste:** 3 días el generador + 1 por región. **Riesgo:** que el fondo compita con el primer plano; regla: todas las capas de fondo en rampas desaturadas y sin contorno oscuro.

### 2.5 Props

**Problema:** decenas de objetos (cajas, barriles, urnas, estatuas, pasamanos, faroles, vigas, cadenas, ataúdes, puertas) y hoy `decor.sprite` es una hoja manual de 13 piezas.

**Propuesta:** `tools/arte_props.js` con **formas paramétricas + ruido + paleta** (reutiliza la rasterización con contorno y sombreado del rig: un prop es una "cadena de huesos" fija). Familias: contenedores (caja/barril/urna), piedra (columna, mojón, estatua, arco), madera (poste, viga, tablón, puerta), colgantes (cadena, estandarte, enredadera, farol), restos (huesos, escombros). Cada familia genera N variantes con semilla. Lo singular (estatuas con rostro, un trono, el árbol del Ancla) se dibuja a mano.

**Coste:** 4 días para las familias principales; cada prop adicional, 15-30 minutos. **Riesgo:** que los props generados se vean "iguales y limpios": mitigar con grietas, musgo y desgaste por región (misma maquinaria que las baldosas).

### 2.6 Partículas y efectos

**Problema:** polvo, brasas, chispas, sangre, escombros, humo, niebla, onda de choque (ya hay `impact_dust.gd`, `shockwave.gd`, `pickup_burst.gd` por código).

**Recomendación:** **no generar sprites de partículas**. Usar `GPUParticles2D`/`CPUParticles2D` con **3-4 texturas diminutas** (punto 1x1, punto 2x2, chispa 3x3, escombro 4x4, humo 8x8) y rampas de la paleta de la región. Un `core/components/burst_fx.gd` genérico (color, cantidad, gravedad, vida) sustituye a los tres scripts sueltos. Las trayectorias en píxeles enteros dan el aspecto correcto sin dibujar un solo fotograma.

**Coste:** 1-2 días. **Riesgo:** bajo, pero evitar que cada efecto sea un script distinto (hoy ya lo es).

### 2.7 Orden recomendado de construcción

1. Extraer `lib/raster.js` (0,5 d).
2. Validador de arte + recorte de hojas + tabla de animaciones generada (sección 4; 2-3 d): **antes de producir más contenido**, para que el contenido ya nazca verificado.
3. Sistema de paletas con shader (2 d): desbloquea variación de enemigos y las regiones.
4. Generador de baldosas + autotiling de la primera región nueva (3-4 d).
5. Cuerpo cuadrúpedo (3-4 d) y volador (3 d), según qué enemigos pida la primera región.
6. Props paramétricos (4 d), fondos (3 d), partículas (1-2 d).
7. Serpiente/segmentado y soporte de jefes por partes cuando el primer jefe no humanoide esté en el calendario.

---

## 3. Formato y convenciones para TODOS los sprites nuevos

Objetivo: que **una sola escena base** anime cualquier criatura (hoy lo hace `enemy.tscn`) y que añadir una nueva sea "elegir plantilla + dar textura + marcar diferencias".

### 3.1 Reglas generales

- **Rejilla de lienzo en múltiplos de 8** (hoy hay 96, 112, 144 y 384x256: sí, pero también 112x64 en el jugador). Fijar lienzos de plantilla (tabla 3.3) y no inventar tamaños.
- **Anclaje:** pies/base centrados horizontalmente en la última fila del lienzo (como hoy). Para voladores: **centro de masa** en el centro del lienzo; para colgantes (arañas, estandartes): **techo** en la primera fila. El tipo de anclaje se declara en la plantilla, no se deduce.
- **Simetría:** sprite simétrico respecto al centro del cuerpo, volteo con `scale.x = -1` (ya así). El arma sobresale hacia delante dentro del lienzo.
- **Paleta:** solo `art/palette.txt` (y, a futuro, sus índices para el shader). Contorno `1` en todas las formas, nunca negro puro.
- **Orientación:** mirando a la derecha.
- **Luz:** arriba-atrás (como el rig), para que el conjunto sea coherente.

### 3.2 Nombres de animación estándar y orden de filas

Un solo vocabulario, siempre en este orden de fila para las criaturas (el valor es fila fija; las que no existan se omiten del final, nunca del medio):

| Fila | Nombre | Descripción | fps | Bucle |
|---|---|---|---|---|
| 0 | `idle` | reposo | 6-8 | sí |
| 1 | `walk` | andar/correr/volar | 12-24 | sí |
| 2 | `windup` | aviso del ataque | 10-12 | no |
| 3 | `strike` | golpe (el fotograma de impacto marcado en el manifiesto) | 24-30 | no |
| 4 | `hit` | golpe recibido | 14-16 | no |
| 5 | `death` | muerte | 10 | no |
| 6+ | extras por plantilla | `jump`, `fall`, `land`, `stagger`, `getup`, `crouch`, `windup2`, `strike2`, `cast`, `block`, `spawn` | - | - |

Hoy los enemigos **no tienen `death`** (se hace por desvanecimiento en código): la plantilla lo incluye como opcional, y los jefes lo tienen ya (12 fotogramas).

Reglas: nombres en inglés (igual que el código), minúsculas, sin espacios; un animación = una fila; fotogramas contiguos desde la columna 0; fps entre 6 y 40 (el jugador está a 40 fps; el resto, ≤ 30).

### 3.3 Manifiesto: una sola fuente de verdad para la hoja y la escena

**Problema:** hoy la tabla `animations = {"hit":[4,4,14.0,false], ...}` se copia a mano en cada `.tscn` y puede desfasarse del rig.

**Propuesta:** cada generador emite, junto al PNG, un **`<nombre>.anim.json`** (o una línea de cabecera en el `.sprite`) con:

```json
{
  "sheet": "coloso_sheet.png",
  "cell": [144, 96],
  "anchor": "feet",
  "palette": "base",
  "animations": {
    "idle":   {"row": 0, "frames": 8,  "fps": 6,  "loop": true},
    "strike": {"row": 3, "frames": 6,  "fps": 24, "loop": false, "impact": 4}
  },
  "points": {"weapon_tip_strike": [58, -2]}
}
```

`build_sprites.gd` lo lee para validar y para **recortar la hoja** (4.3); `SheetAnimator` puede cargar la tabla del manifiesto en lugar de duplicarla en la escena. Con eso se elimina la clase más frecuente de error de integración (fila equivocada, fotogramas de más) y los puntos de anclaje (punta del arma, boca para escupir, origen del proyectil) dejan de ser "números que hay que adivinar".

### 3.4 Plantillas

| Plantilla | Lienzo | Cuerpo (dibujo) | Colisión orientativa | Animaciones | Notas |
|---|---|---|---|---|---|
| **Enemigo pequeño** | 64x48 (96x64 si lleva arma larga) | hasta 20x28 | 20-28 x 24-32 | idle, walk, windup, strike, hit, death | Ratas, murciélagos, arañas, sabuesos pequeños |
| **Enemigo mediano** | 96x64 (144x64 con lanza) | 24x44 (humanoide) | 32x48 | idem | Es el estándar actual: Cascarón, Lancero, Arrojador |
| **Enemigo grande** | 144x96 | hasta 44x64 | 44x64 | idem + `stagger` | Coloso; brutos, bestias grandes |
| **Élite/miniboss** | 192x128 | hasta 56x88 | 56x88 | idem + `windup2`, `strike2`, `stagger`, `death` | Capitanes de región |
| **Jefe** | 256x192 a 384x256 (**solo celdas recortadas**, o por partes) | 112x160 | según fases | `idle, walk, windup, strike, ...` más fases propias | Centinela; ver 2.1.1 y 4.3 |
| **PNJ** | 64x64 | 20x44 | sin colisión de combate | `idle` (8), `talk` (6), `react` (4), `walk` (opcional) | Sin `strike`/`hit`; los PNJ viven del `idle` con micro-movimiento (respiración, capa) y de un retrato aparte |
| **Objeto/pickup** | 32x32 o 48x48 | - | - | 1 fila `idle` (8 fps, bucle) | Como las reliquias |
| **Proyectil** | 16x16 (o 32x16) | - | pequeña | `fly` (2-4), `hit` (3-4, opcional) | Esquirla: ya así |
| **Prop estático** | múltiplos de 16, ancho x alto (16-64) | - | según prop | 1 fotograma, o `idle` de 4-8 | Anclaje base centrada (apoyado) o techo (colgante) |
| **Prop rompible** | 16-48 | - | pequeña | `idle`, `break` (4-6) | Ya existen caja/barril/urna |

Recomendación sobre los PNJ: **retratos fuera del rig** (ver 5). Los 12 PNJ en perfil lateral se hacen con el humanoide con `idle` suave, y los retratos de diálogo a mano.

---

## 4. Verificación automática del arte

Hoy `smoke_test.gd` comprueba que la hoja del jugador y la del enemigo cuadran con su rejilla (`texture.get_size() == hframes*112 x vframes*64`) y poco más. Tampoco hay ninguna comprobación sobre arte en `build_sprites.gd` salvo "pieza desconocida", "carácter sin color" y "no cabe en el lienzo".

### 4.1 Comprobaciones a añadir en `build_sprites.gd` (se ejecutan al generar)

Salida con código 1 si falla alguna, con mensaje en español y fichero/animación/fotograma:

1. **Paleta:** todos los píxeles opacos están en `palette.txt` (ya implícito, pero a validar también PNG pintados a mano, que no pasan por este script).
2. **Hoja vacía o fotograma vacío:** cada celda declarada en una animación debe tener al menos N píxeles opacos (N=12). Detecta poses que se salen del lienzo.
3. **Fotogramas idénticos:** en animaciones con más de 2 fotogramas, ningún par consecutivo debe ser idéntico (salvo whitelist `hold` en el manifiesto): detecta ciclos que "no se mueven".
4. **Fotograma recortado por el borde:** ningún píxel opaco en la fila/columna del borde del lienzo (salvo suelo): detecta armas que se salen.
5. **Anclaje:** en animaciones con anclaje `feet`, los pies (el píxel opaco más bajo) deben estar en la misma fila en `idle` y `walk` ± 1 px; evita enemigos que "flotan" o se hunden al cambiar de animación.
6. **Tamaño de cuerpo:** el recuadro mínimo del `idle` debe caber en el cuerpo de plantilla y en la colisión de la escena (se lee de la `.tscn`): el arte "debe caber en las colisiones actuales", como dice `arte.md`.
7. **Contorno:** porcentaje de píxeles de borde que son tono `1`; avisa si baja de un umbral (detecta formas sin contorno).
8. **Presupuesto de VRAM por hoja y global** (4.2).
9. **Manifiesto coherente:** filas y fotogramas del `.anim.json` iguales a los del `.sprite`.

### 4.2 Límites de VRAM

Godot carga las hojas descomprimidas en 2D (RGBA8, 4 bytes por píxel). Medido:

| Hoja | Tamaño | MB | Celdas | Vacías |
|---|---|---|---|---|
| Centinela (jefe) | 4608x2816 | **49,5** | 132 | 47 (36 %) |
| Coloso | 1728x480 | 3,2 | 60 | 24 |
| Lancero | 1728x320 | 2,1 | 60 | 24 |
| Jugador | 1568x512 | 3,1 | 112 | 54 |
| Cascarón | 1152x320 | 1,4 | 60 | 24 |

Presupuesto propuesto (ajustable tras medir en hardware modesto): **0,5-4 MB por hoja de criatura, 16 MB como máximo para un jefe, 150 MB para todo lo residente en una sala**. Con estas cifras, 30 enemigos x 3 MB ya son 90 MB, así que los enemigos de una sala deben ser ~6-8 tipos y el resto, descargados al cambiar de región (Godot libera las texturas sin referencias).

El validador cuenta MB de las hojas referenciadas por una escena y falla por encima del tope.

### 4.3 Recorte de hojas (el caso del Centinela)

Medido: de las 132 celdas, 47 están vacías (se rellena la rejilla hasta la animación más larga), y el dibujo ocupa solo **280x236** de cada celda de 384x256 (x entre 100 y 379, y entre 21 y 256). Es decir, hay un 36 % de celdas inútiles *y* un 45 % de margen en las que se usan.

Dos pasos, de menos a más invasivo:

1. **Recorte por celda y atlas compacto (recomendado).** `build_sprites.gd` calcula el recuadro mínimo de cada fotograma, lo recorta, y **empaqueta solo los fotogramas existentes** en una hoja compacta, guardando en el manifiesto `{row, frame, rect, offset}`. Estimación para el jefe: 85 celdas x 280x236 x 4 B ≈ **22 MB** (de 49,5; -55 %), y si se recorta por fotograma ajustado, probablemente menos de 15 MB. El `SheetAnimator` debe pasar a usar `AtlasTexture`/`region_rect` con `offset` en lugar de `hframes/vframes`; es un cambio acotado en un solo componente de `core/` más el manifiesto (hoy el animador calcula `row * hframes + frame`).
2. **Alternativa mínima sin tocar el animador:** conservar la rejilla pero reducir el lienzo de la celda al recuadro máximo real (280x240 en vez de 384x256) y añadir `offset` al `Sprite2D`. Ahorra ~35 % (hasta ~32 MB para el jefe), sin recortar las celdas vacías.

Además: comprobar que la importación no use compresión con pérdida (`compress/mode = Lossless`, no VRAM Compressed: arruina el pixel art), y que **no se generen mipmaps** en las hojas.

### 4.4 Comprobaciones y tiempos

- **Prueba de humo (`tests/smoke_test.gd`):** añadir una prueba "El arte cumple las reglas" que, **sin regenerar**, recorra los manifiestos y verifique: la hoja existe, el tamaño de la textura coincide con el manifiesto, cada animación que declara una escena existe en su `SheetAnimator`, cada hoja pasa el presupuesto de VRAM y los PNJ/enemigos tienen `idle`. Coste: segundos. Esto sustituye las dos comprobaciones sueltas de ahora (96x64 del enemigo, 112x64 del jugador).
- **Generación incremental:** `build_sprites.gd` reconvierte todo (19 s hoy). Guardar un hash del `.sprite` y regenerar solo lo cambiado (`art/.cache/hashes.json`, fuera de Git). A más de 100 hojas y con el texto del jefe en 8 MB, esto pasa de cómodo a necesario.
- **El `.sprite` del jefe pesa 8,4 MB de texto** (y el total, 11 MB) dentro de Git. Mejor **no versionar el `.sprite` generado** de los rigs (se regenera con `node`, es determinista) y versionar solo los generadores y el PNG resultante, o versionar el `.sprite` comprimido. Decisión a tomar con el usuario porque cambia "una sola fuente de verdad": la fuente sería el rig, no el texto.
- **Vista previa de revisión:** ya existe (`art/preview/*_x8.png`). Añadir una **hoja de contactos** por región (todos sus enemigos, props y baldosas juntos, a escala) para revisar la coherencia, no solo cada pieza.

---

## 5. Riesgos y qué conviene dibujar a mano

### 5.1 Riesgos

1. **Calidad percibida.** El rig produce figuras competentes, coherentes y bien animadas (el movimiento es su gran fuerte), pero **poco expresivas**: no hay "gesto de autor" en un rostro, una mirada o una silueta icónica. Para 30 enemigos de relleno es suficiente; para jefes, PNJ importantes y el protagonista, el público ve la diferencia. La repetición (mismo cuerpo, distinto tinte) se nota tras la tercera aparición.
2. **Silueta.** El mayor riesgo de diseño: si todos los enemigos salen del mismo esqueleto, tienen siluetas parecidas, y en un juego de combate la lectura de silueta es jugabilidad. Cada enemigo debe diferenciarse por **silueta** (arma larga, joroba, tamaño, cuernos), no solo por color.
3. **Tiempo de generación y repositorio.** 19 s hoy y subiendo; 11 MB de texto. Mitigación: incremental y no versionar lo derivado.
4. **Mantenimiento del rig.** Cada cuerpo nuevo son ~300-600 líneas de código con muchos números mágicos (el Centinela son 636). Si solo hay una persona (o IA) que lo entiende, es un riesgo de proyecto. Mitigación: extraer primitivas (2.0), documentar parámetros y usar el manifiesto como contrato.
5. **VRAM y rendimiento.** Ver 4.2; sin recorte, 10 jefes como el actual son ~500 MB.
6. **Paletas.** Si el shader de intercambio se aplica a todo, se pierde la lectura de "esto está recordado, aquello no". Regla de diseño: lo recordado y la interfaz nunca se desaturan.
7. **Rotación de pixel art** en jefes por partes (2.1.1): evitar interpolación y rotar solo por pasos.
8. **Mano de obra única.** Hay que contar con que el usuario no dibuja: lo "a mano" lo haría un artista externo o el usuario con Pixelorama, y eso es una decisión de proyecto (presupuesto, licencia), no técnica.

### 5.2 Qué generar por código y qué dibujar a mano

**Por código (rentable y coherente):**
- Ciclos de movimiento de cuerpos repetidos: andar, correr, golpes, golpe recibido, muerte, de humanoides, bestias, voladores y segmentados.
- Variantes por tinte y por paleta de región; props en familia (cajas, barriles, vigas, cadenas).
- Baldosas y sus variantes por región; fondos parallax de siluetas; texturas de relleno (piedra, madera, óxido).
- Fuentes de píxeles, logotipos animados, iconos de interfaz sencillos, partículas.
- Efectos de objetos brillantes con ruido y anillos (reliquias, Ancla).

**A mano (en Pixelorama o LibreSprite, o por un artista):**
- **El protagonista y los jefes principales, al menos su silueta y rostro.** Pueden mantenerse en el rig como *animación base* y recibir un repaso manual por encima (retocar fotogramas clave); aviso: eso rompe la regla de "una sola fuente de verdad", así que o se borra el `.sprite` o se guarda el retoque como capa aparte.
- **Retratos de PNJ y de diálogo** (las caras son lo que más cuesta y menos sale de un esqueleto).
- **Pantallas ilustradas:** pantalla de título (arte clave), logotipo final, cartas de región, imágenes de historia.
- **Iconos de objetos del inventario** de importancia narrativa (reliquias únicas, armas singulares).
- **Elementos icónicos del escenario:** el Ancla, el árbol de cada región, las puertas, los monumentos "firma", los remates singulares de los tilesets.
- **Cualquier cosa con rostro o expresión** (estatuas, máscaras, cadáveres identificables).

**Criterio para decidir:** generar por código lo que se **repite** o se **mueve** mucho, y dibujar a mano lo que se **ve quieto y de cerca** o **lleva identidad**. Si un sprite aparece 100 veces, código; si aparece una vez y el jugador se queda mirándolo, mano. Una vía mixta útil es dejar al artista dibujar **plantillas de cabeza/arma/pieza** que el rig coloca (las "piezas" del formato `.sprite` ya lo permiten, con `@x,y`).

---

## 6. Hoja de ruta en 6 hitos

Esfuerzos orientativos para una persona dedicada; el trabajo de revisión y de "jugarlo" (obligatorio, regla de `CLAUDE.md`) no está incluido.

### Hito 1 — Base verificable (3-4 días)
Extraer `lib/raster.js`; manifiesto `.anim.json` por hoja; validador en `build_sprites.gd` (4.1) y la prueba de humo de arte (4.4); generación incremental; recorte/atlas de hojas y reducción de la del jefe (4.3).
**Criterio de salida:** `git diff` de los `.sprite` vacío tras la refactorización; el jefe pasa de 49,5 MB a menos de 25 MB; falla una hoja con una celda vacía o fuera de paleta.

### Hito 2 — Paletas y variación (3 días)
Shader de intercambio de paleta y tabla de paletas (`base`, 2 regiones de prueba y 3 niveles de desaturación); tinte de enemigo como variante de paleta; regla "lo recordado y la interfaz no se desaturan".
**Criterio de salida:** el Cascarón en tres paletas distintas en el juego, sin PNG nuevos.

### Hito 3 — Primera región completa nueva (7-9 días)
Generador de baldosas con variantes, autotiling y un `TileSet` por región; generador de props en familias; generador de fondos parallax; `burst_fx` genérico para partículas.
**Criterio de salida:** una segunda región jugable con su propio tileset, 3 capas de fondo, 10 props y su paleta, creada solo con parámetros y con el mismo mapa de texto.

### Hito 4 — Cuerpos nuevos (10-12 días)
Cuadrúpedo (2 especies), volador (2 especies), armadura vacía formalizada (2 variantes), cabezas/armas nuevas para humanoides. Plantillas de la sección 3 aplicadas a todos.
**Criterio de salida:** ~12 enemigos nuevos en total (con tinte, hasta 20+) que comparten la escena base y pasan el validador.

### Hito 5 — Jefes y PNJ (12-15 días)
Soporte de jefes por partes (solo si algún jefe es no humanoide); segmentado/serpiente; 3 jefes más; 12 PNJ en perfil con `idle`/`talk`; **retratos a mano** (encargo externo o a mano en Pixelorama).
**Criterio de salida:** 4 jefes y 12 PNJ conviviendo con el presupuesto de VRAM, y retratos integrados en la escena de diálogo.

### Hito 6 — Producción en serie y pulido (continuo, 3-4 semanas)
Resto de regiones (2-3 días cada una con generador y paleta), enemigos hasta ~30 tipos con tintes, props hasta decenas, fondos y partículas por región, repaso manual de lo icónico (jugador, jefes, Ancla, pantallas ilustradas), hoja de contactos por región y revisión de silueta y legibilidad. Jugar cada región completa antes de cerrarla.
**Criterio de salida:** las 6 regiones con su paleta, tileset, fondo y reparto de enemigos; todas las hojas dentro del presupuesto; la prueba de humo de arte en verde.

### Total estimado
~7-9 semanas de trabajo técnico concentrado para llegar a "todo el arte del juego" en calidad sólida de proyecto personal, con los retratos, pantallas ilustradas y el repaso manual de lo icónico como línea paralela.

---

## Resumen de recomendaciones (para decidir en la reunión)

1. **Primero la base verificable y el recorte de hojas** (hito 1): evita que el problema de los 49,5 MB se multiplique por diez jefes.
2. **Paletas por shader en lugar de PNG por región:** una sola hoja, N regiones y N variantes de enemigo, con la regla de diseño de que lo recordado no se desatura.
3. **Tilesets por región = misma forma + rampa + variantes con ruido determinista + autotiling**; lo singular, a mano.
4. **No generar sprites de partículas:** texturas diminutas y nodos de partículas de Godot.
5. **Jefes humanoides por hoja recortada; jefes no humanoides por partes.**
6. **Generar por código lo que se repite o se mueve; dibujar a mano lo icónico, los rostros y los retratos.** Decidir quién dibuja ese 15-20 %: es la decisión de proyecto más importante que queda abierta.
7. **Decisión pendiente del usuario:** si los `.sprite` generados (11 MB) siguen versionándose en Git o solo los generadores y los PNG.
