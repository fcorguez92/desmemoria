# Sonido

Efectos de sonido, no banda sonora (esa queda para más adelante). El tono buscado es el de Hollow Knight: sutil, grave, húmedo, con eco de caverna; que se note lo que pasa sin que nunca tape el juego.

## De dónde salen

Igual que el arte, los sonidos **se sintetizan por código** (ruido filtrado, tonos, campanas, voces graves con formantes) en `tools/sonidos.js`, que escribe los `.wav` en `game/audio/sfx/`. No hay descargas ni licencias de terceros, y para cambiar un sonido se edita el script y se regenera:

```
node tools/sonidos.js            # todos
node tools/sonidos.js step ui    # solo los que empiecen por esos nombres
godot --headless --path . --import
```

Cada sonido sale en varias variantes (`step_1.wav` … `step_4.wav`) y el juego elige una al azar, con un poco de variación de tono, para que no suene a máquina. Mono, 32 kHz, 16 bits (unos 3 MB en total). Los sonidos se normalizan todos al mismo pico: el volumen relativo de cada uno se decide al reproducirlo (`volume_db`), en el sitio del código que lo pide.

## Cómo suena en el juego

- `core/audio/sfx.gd` (`Sfx`): biblioteca por nombre y un reproductor con varias voces. `Sfx.play(&"nombre")` sin posición (interfaz y sonidos del jugador) o `Sfx.play(&"nombre", posición)` en el mundo, donde el sonido baja con la distancia al centro de la cámara y se desplaza hacia un lado. Un sonido que no existe se ignora. El mismo sonido no se repite en menos de 45 ms.
- Todo pasa por el bus `SFX`, que crea el propio `Sfx`: filtro que corta los agudos (7 kHz) y una reverberación corta de cueva. Sigue sonando con el juego en pausa.
- `game/audio/game_audio.gd` apunta el reproductor a la carpeta del juego; lo llaman el menú principal y el jugador.

## Qué suena

| Origen | Sonidos |
|---|---|
| Caminante | pasos (sincronizados con los pies de la animación de correr, fotogramas 6 y 13) y aterrizaje (más fuerte cuanto más cae), ambos distintos según el suelo: piedra, musgo o madera (dato `material` de las baldosas, leído con `GroundMaterial`), salto, doble salto, salto de pared, dash, tajo, guardia, parry, golpe recibido, curarse, morir |
| Enemigos | pasos (el coloso, más pesados), aviso al empezar a perseguir, grito al preparar el ataque, golpe (tajo, estocada, mazazo, embestida, lanzamiento), queja al ser herido, muerte. Cada tipo tiene su voz: cascarón (ronca y jadeante), lancero (de soldado), arrojador (fina y sibilante), coloso (muy grave), acechador (bestia) |
| Mundo | romper objetos, impacto de la esquirla, recoger un Eco, recordar una habilidad, descansar en un Ancla, comprar una mejora (o no poder) |
| Interfaz | mover, aceptar, volver, negado, abrir y cerrar la pausa, empezar partida |

## Cómo añadir uno

1. Definirlo en `tools/sonidos.js` con `def('nombre', variantes, (i, r) => …)` y regenerar.
2. Pedirlo donde ocurra: `Sfx.play(&"nombre", …)`. La prueba de humo comprueba que todo `Sfx.play(&"…")` del código tiene su archivo.
3. Un enemigo nuevo: basta `voice` (prefijo de sus cuatro voces: `_alert`, `_attack`, `_hurt`, `_die`), `strike_sound` y `step_sound` en su escena.

## Lo que falta (a propósito)

- Un control de volumen en Opciones (hoy solo hay pantalla completa): se añadirá cuando haya dónde ponerlo útilmente.
- Ambiente (viento, goteo, zumbido del Ancla) y música: son otra fase.
- Estos sonidos están sintetizados y **no se han podido escuchar durante el desarrollo**: los niveles y los timbres hay que ajustarlos jugando.
