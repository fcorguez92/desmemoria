# Jefes (documento vivo)

Estado: primer jefe construido y probado por scripts; **sin jugar a mano todavía**.
Los números son de partida y se ajustan jugando.

## Qué se tomó de Hollow Knight

El primer jefe de Hollow Knight, el Falso Caballero (una larva dentro de una
armadura enorme, en una sala cerrada tras un banco de descanso), enseña cuatro
cosas que se han copiado en su forma, no en su contenido:

- **Se llega a él por un tramo que ya ha enseñado sus reglas** (aquí: Último
  Umbral → Terrazas Secas → Cisterna → Galerías Bajas, con enemigos de dificultad
  creciente, un foso de pinchos y un Ancla justo antes de la puerta).
- **La armadura no cuenta**: golpearla no hace daño de verdad; al romperla queda
  expuesto un momento y solo entonces se le puede herir. Eso obliga a leer la pelea
  en lugar de golpear sin más.
- **Tres fases** con ataques que se acumulan: la misma amenaza (mazazo, salto) se
  hace más rápida y trae consecuencias nuevas (rocas del techo, ondas a dos lados).
- **Una "furia"** al empezar las fases avanzadas: golpes seguidos con escombros
  cayendo, que sirve de pico de tensión entre ventanas de ataque.

No hay más parecido: el jefe, su arte, su historia y las cifras son propios.

## El Centinela Hueco

Armadura vacía de un Custodio de la Orden del Archivo que sigue guardando el
Aljibe "porque nadie vino a relevarle". Dentro, lo que la Desmemoria dejó: una
figura pálida y encorvada. Es el primer recuerdo que el jugador **no puede
olvidar**: el del mensajero que cruzaba los pasos rotos. Al vencerlo suelta el
recuerdo del **dash**.

- Sala: **El Aljibe** (`game/levels/aljibe.map`, 64×33 baldosas: una arena propia,
  del tamaño de una pantalla y media, con dos tablones para esquivar). Entrada por
  el oeste desde las Galerías Bajas, salida por el este hacia La Chimenea. Al cruzar
  la línea de la sala caen **dos rastrillos de hierro** de 2×6 baldosas (temblor de
  cámara y sonido) que se ven claramente; no se abren hasta vencerlo (o morir).
- Código: `game/boss/centinela.gd` (la pelea), `boss_room.gd` (la sala: disparador,
  rejas, recompensa, reinicio, barra), `falling_rock.gd`, `shockwave.tscn`
  (un `Projectile` de `core/`), `arena_gate.*` (cada celda de reja), `boss_bar.gd`.
- Arte: `art/source/centinela.sprite` (lo genera `tools/rig_centinela.js`), 384×256
  por fotograma, 8 animaciones. Es **enorme**: el cuerpo mide 112×176 (el jugador,
  24×48), casi cuatro veces su altura.

### Reglas de la pelea

| | Fase 1 | Fase 2 | Fase 3 |
|---|---|---|---|
| Armadura (daño a romper) | 8 | 9 | 10 |
| Núcleo, al terminar la fase | 10 | 5 | 0 (muere) |
| Aviso del mazazo | 0,85 s | 0,70 s | 0,58 s |
| Rocas por mazazo / por aterrizaje | 0 / 0 | 2 / 2 | 3 / 2 |
| Ondas | hacia delante | hacia delante | a los dos lados |
| Furia al empezar | — | 4 mazazos | 6 mazazos |

- **Armadura**: cada golpe la gasta (el daño del arma cuenta), sin aturdirlo ni
  apartarlo. Al llegar a 0 queda **expuesto** 3 s, arrodillado y con el cascarón
  asomando: solo entonces se le baja el núcleo.
- **Núcleo**: 15 en total. En cada fase no baja de su marca (10, 5, 0): al
  alcanzarla se levanta y pasa a la siguiente fase, con armadura nueva y su furia.
  Si el tiempo de exposición acaba antes, repone la armadura y sigue en la misma fase.
- **Parry**: desviar el mazazo (o el aterrizaje) lo deja expuesto 1,5 s sin gastar
  armadura. Una onda de polvo desviada vuelve contra él y le quita el doble.
- **Ataques** (todos con aviso en amarillo, esquivables):
  - *Mazazo* (alcance de ~240 px): golpe de área delante (2 de daño) y una onda baja de polvo (1 de daño)
    que se salta. Desde la fase 2 caen rocas del techo, cada una con un aviso de
    polvo en el suelo.
  - *Salto*: se agazapa, salta y cae junto al jugador (no encima). El golpe es
    rasante (2 de daño): saltar lo evita. No salta dos veces seguidas.
  - *Furia*: mazazos seguidos en el sitio, con ondas a los dos lados y rocas por
    toda la sala.
- **Ecos**: suelta 40 al morir.
- **Si el jugador muere o descansa en un Ancla**: la pelea se reinicia (jefe
  entero y dormido, rejas abiertas). **Si se vence**: no vuelve, y queda guardado
  (`bosses` en la partida). El recuerdo del dash aparece en el centro de la sala
  y, si se carga una partida sin haberlo cogido, sigue esperando.

### Cómo se monta otro jefe

1. Una escena del jefe con `take_hit` y `on_parried`, las señales `defeated` y
   `status_changed`, y `display_name`, `armor_hp`, `armor_max()`, `core_hp`,
   `core_health`, `wake()` y `arena_left/right/ceiling` (ver `centinela.gd`).
2. Una sala con `script = boss_room.gd`, `boss_scene` y `reward_ability`, y en el
   mapa los marcadores `b` `t` `[` `]` `r` (ver `vertical-slice.md`).

## Cómo se comprueba

La prueba de humo (`tests/smoke_test.gd`) fuerza cada ataque, recorre las tres
fases golpeando, comprueba el parry y la onda devuelta, que morir reinicia la
pelea y que vencerlo queda guardado. El puzle de después se repite con
maniobras de referencia (ver `docs/arquitectura.md#verificación`). Nada de eso
sustituye a jugarlo.

## Cosas a vigilar al jugarlo

- El tamaño de la ventana de exposición (3 s) y de la armadura: si la pelea se
  hace larga, bajar primero la armadura.
- La furia de la fase 3 (6 mazazos con ondas a los dos lados y rocas): es el pico
  de dificultad; con el arma sin mejorar puede ser demasiado.
- El salto del jefe puede quedar bloqueado por el propio jugador pegado a una
  pared; se resuelve (cae a su lado), pero conviene mirarlo en juego.
