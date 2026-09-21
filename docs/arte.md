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
| Jugador | 24×48 | 32×56 | Los pies, centrados |
| Enemigo básico | 32×48 | 40×56 | Los pies, centrados |
| Ancla, objetos, Eco | según objeto | múltiplos de 8 | Base, centrada |

El lienzo es algo mayor que la colisión para dejar sitio a armas, capas o
extremidades que sobresalgan. Así el arte se puede cambiar sin recolocar nada.

## Animaciones previstas (fotogramas por segundo orientativos)

- Reposo: 4 fotogramas, 6 fps.
- Caminar/correr: 6 fotogramas, 12 fps.
- Salto: subida, apogeo y caída (3 poses).
- Ataque: pose de preparación, golpe y recuperación. El brazo provisional que
  hay ahora se sustituirá por estas poses; los tiempos los siguen fijando los
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

1. Herramienta de dibujo: **Pixelorama** o **LibreSprite** (gratuitas). El arte
   fuente se guarda en `art/source/` (proyectos de la herramienta) y lo exportado
   en `game/.../` junto a la escena que lo usa (ver `arquitectura.md`).
2. Exportar hojas de sprites en PNG con fondo transparente, un archivo por
   personaje y animación.
3. En Godot se usa `AnimatedSprite2D` o `Sprite2D` con la hoja de sprites; el
   componente de animación se hará en cuanto exista el primer sprite real.
4. Importación de las imágenes con el preajuste "Pixel art" (filtro Nearest, sin
   mipmaps). Ya es el filtro por defecto del proyecto.

## Reglas sobre IA en el arte

- De momento el arte lo hace el usuario con herramientas gratuitas, y Claude
  ayuda con integración, animación y paletas. Claude no genera imágenes.
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
