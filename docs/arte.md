# Arte: dirección y reglas (documento vivo)

Estado: dirección elegida; sin arte final todavía. Todo lo que se ve hoy son formas
de colores planos provisionales. Este documento fija las reglas para que el arte
que se vaya haciendo sea coherente y encaje sin tocar la jugabilidad.

## Dirección

**Pixel art oscuro con paletas limitadas**, en la línea de *Blasphemous* o
*Death's Gambit*, pero con identidad propia. Decisión tomada por el usuario entre
tres opciones (ver `decisiones.md`).

Idea central: **la Desmemoria se expresa con la paleta.** Las zonas y cosas
"recordadas" tienen color vivo; cuanto más cerca de la Herida (ver `mundo.md`),
más se desaturan hasta el gris casi sin forma. No hace falta dibujar nada extra
para que el mundo cuente su historia: basta con aplicar la rampa de color de la
zona.

## Resolución y escala

- **Resolución interna: 864×486 píxeles**, escalada por números enteros: ×2 da
  1728×972, que cabe en una ventana sobre una pantalla de 1920×1080 con barra de
  tareas. Cada píxel del arte es un cuadrado nítido en pantalla, sin mezclas ni
  medios píxeles. (Se probó 640×360, que se vio demasiado cerrado para un juego
  de exploración; 960×540 solo cabría a pantalla completa.) A pantalla completa
  en 1080p se ve con bordes negros; si algún día se prefiere llenar la pantalla,
  se puede pasar a 960×540.
- Ya configurado en `project.godot`: filtro de texturas "Nearest", escalado
  entero, modo de estirado "viewport" y ajuste de transformaciones al píxel.
- **Rejilla de nivel: 16×16 px** (los tiles). Las medidas del nivel de prueba
  actual son provisionales y se reharán sobre esta rejilla al construir el
  *vertical slice*.

## Tamaños de sprite (el arte debe caber en las colisiones actuales)

| Elemento | Colisión actual | Lienzo del sprite | Punto de anclaje |
|---|---|---|---|
| Jugador | 24×48 | 64×56 (cuerpo de 20×44) | Los pies, centrados |
| Enemigo básico | 32×48 | 64×56 (cuerpo de 24×44) | Los pies, centrados |
| Ancla, objetos, Eco | según objeto | múltiplos de 8 | Base, centrada |

El lienzo es mucho mayor que la colisión para dejar sitio a las armas, que se
dibujan en el sprite y sobresalen al extenderse. Es siempre simétrico respecto al
centro del cuerpo, para poder voltear el sprite (`scale.x = -1`) sin recolocarlo.
Así el arte se puede cambiar sin tocar colisiones.

## Animaciones previstas (fotogramas por segundo orientativos)

- Reposo: 4 fotogramas, 6 fps.
- Caminar/correr: 6 fotogramas, 12 fps.
- Salto: subida, apogeo y caída (3 poses).
- Ataque: aviso (arma alzada), golpe y recuperación, con el arma dibujada en el
  propio sprite (hecho: ver "Sprites actuales"). Los tiempos los fijan los
  componentes de `core/` (aviso de 0,4 s en el enemigo, etc.).
- Recibir golpe, morir, dash, agarre de pared.

## Paleta (provisional, a ajustar por el usuario)

Rampas de 4 tonos, de oscuro a claro. La paleta total se mantiene por debajo de
unos 32 colores.

| Rampa | Uso | Tonos |
|---|---|---|
| Piedra | Suelos, muros, arquitectura | `#1b1a1f` `#3a3840` `#6a6670` `#a39fa8` |
| Memoria (ámbar) | Objetos recordados, Ancla, acentos cálidos | `#4a2b12` `#8a5320` `#d18a2e` `#f3c46a` |
| Recuerdo (azul frío) | Habilidades, Ecos, luz de la Desmemoria | `#12283a` `#1f5573` `#4aa3c7` `#a9e3f2` |
| Sangre (rojo) | Enemigos, daño, aviso de ataque | `#3a1218` `#7a2430` `#c2453f` `#f08a6a` |
| Musgo (verde apagado) | Vegetación, zonas vivas | `#15241a` `#2c4a30` `#587a4a` `#9cb57a` |

**Desaturación por zona:** cada región aplica un nivel a toda su paleta: 0 (color
completo, zonas recordadas como El Último Umbral) hasta 3 (casi gris, cerca de la
Herida). Se implementará con un sombreador o con paletas alternativas cuando
existan las primeras zonas reales; no antes.

## Cómo se produce (pipeline)

El usuario no dibuja y Claude no genera imágenes, así que los sprites se escriben
**como texto**: una cuadrícula de caracteres, uno por píxel, con los colores de
`art/palette.txt` (el punto es transparente). Un programa los convierte en PNG.
El texto se puede leer, corregir y versionar en Git como cualquier otro archivo.

- `art/palette.txt` — la paleta: un carácter por color.
- `art/source/*.sprite` — los sprites en texto. Se definen **piezas** (cabeza y
  torso, capa, piernas...) y las animaciones se componen apilando piezas, así los
  fotogramas reutilizan el mismo dibujo. El formato está explicado al principio de
  `tools/build_sprites.gd`.
- `tools/build_sprites.gd` — genera las hojas de sprites PNG y unas vistas previas
  ampliadas ×8 en `art/preview/` (no se guarda en Git). Se ejecuta con:

  ```
  godot --headless --path . --script res://tools/build_sprites.gd
  ```

- **Hoja de sprites:** una fila por animación y una columna por fotograma, con el
  personaje centrado y apoyado en los pies dentro de su lienzo. Los PNG resultantes
  viven junto a su escena (`game/player/player_sheet.png`, `game/enemy/enemy_sheet.png`).
- **En Godot:** el nodo `Sprite2D` usa la hoja (con `hframes` y `vframes`) y el
  componente `SheetAnimator` (core) elige la fila y el fotograma según la
  animación que pida el dueño.

- **Baldosas de nivel:** `art/source/tiles_umbral.sprite` es una hoja de una fila (una baldosa de 16×16 por fotograma) que genera `game/levels/tiles_umbral.png`; el `TileSet` `tiles_umbral.tres` las usa por su posición en la fila. El terreno se dibuja en `.map` (ver `vertical-slice.md`).
- **Fotogramas intermedios sin dibujar piezas nuevas:** para suavizar un ciclo (p. ej. correr/andar) sin partir de cero, se puede recortar progresivamente la pierna que va a "desaparecer" en el fotograma siguiente (quitarle el pie primero, luego más) reutilizando las mismas piezas ya dibujadas. Como el lienzo ancla el cuerpo por los pies (ver más arriba), una pieza de pierna con menos filas también agacha un poco el cuerpo entero: por eso conviene recortar por filas completas (el pie, luego la pantorrilla) y no caracteres sueltos dentro de una fila, o la silueta queda rota.

**Regla importante: una sola fuente de verdad por sprite.** Mientras exista su
`.sprite`, ese texto manda y volver a generar sobrescribe el PNG. Si alguien
retoca el PNG a mano en Pixelorama o LibreSprite, hay que borrar su `.sprite` (o
guardar el retoque como nuevo fuente) para no perderlo. Así se pueden combinar las
dos maneras: empezar con el texto y pasar a retocar a mano cuando compense.

## Sprites actuales (primera pasada)

| Sprite | Dibujo | Lienzo | Animaciones |
|---|---|---|---|
| Caminante (jugador) | 20×44, figura con capucha, ojo y bufanda de luz azul; espada ("el Filo") de acero con canto azul | 64×56 | reposo (2), correr (6), salto (1), caída (1), ataque (3), guardia (2), golpe recibido (2) |
| Cascarón (enemigo) | 24×44, figura pálida sin rostro con trapos rojos; cuchillo pesado oxidado | 64×56 | reposo (2), andar (6), aviso (2), golpe (2), golpe recibido (2) |
| Iconos del HUD | 16×16: frasco de curación (lleno y vacío, ámbar) y Eco (gota azul) | 16×16 | una fila de 3 fotogramas (`game/ui/hud_icons.png`) |

Son un primer dibujo funcional, no arte final. **Las armas van integradas en el
sprite**: se dibujan como piezas superpuestas al cuerpo (brazo y arma) en cada pose,
y el lienzo es ancho (64 px) para que quepa el arma extendida. La animación de
golpe recibido reutiliza piezas ya existentes (piernas de salto/caída, capa
alterna, arma con el offset cambiado) en vez de dibujo nuevo. Todavía no hay
animación de muerte, dash ni agarre de pared.

## Reglas sobre IA en el arte

- El usuario no dibuja. Claude no genera imágenes, pero sí escribe los sprites como
  texto con la paleta (ver "Cómo se produce") y revisa el resultado viendo las
  vistas previas. El usuario decide qué le gusta y qué cambiar, y puede retocar
  los PNG en Pixelorama o LibreSprite cuando quiera.
- Si más adelante se usa una herramienta de IA para sprites: revisar cada
  resultado, mantener la paleta de este documento y registrar qué parte es
  aportación humana. Steam solo pide declarar la IA cuyo contenido llega al
  jugador, y lo generado únicamente por IA no es registrable como obra en EE. UU.
  (ver `decisiones.md`). Ninguna de las dos cosas afecta a un proyecto personal.

## Pendiente de decidir

- Fuente tipográfica del juego y HUD real.
- Fondos con paralaje (capas) y su nivel de detalle.
- Efectos de luz e iluminación de la Desmemoria.
- Si el brillo de los "recuerdos" (objetos, Ecos) se hace con sprites o con luz.
