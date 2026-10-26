# Jefes (documento vivo)

Estado: los dos primeros jefes (el Centinela Hueco y Jacinto, el Último Segador) están construidos y probados por scripts, **sin jugar a mano todavía**. Los otros ocho están diseñados (fichas abajo) y sin construir. Los números son de partida y se ajustan jugando. Este documento es la versión unificada tras la reunión de diseñadores; el detalle largo de cada pelea (tablas completas de ataques, pruebas clave, animaciones) está en `docs/reunion/disenadores/04-combate-enemigos-jefes.md` (§4), y el arte de cada jefe en `docs/reunion/artistas/05-criaturas-y-jefes.md` (§6). El canon (`personajes.md` §3, `guion-maestro.md`) manda sobre cualquier cifra.

Leyenda: **[Impl.]** construido · **[Pend.]** pendiente. En las tablas de ataques, **P** = aviso **amarillo** (se puede parar) y **R** = aviso **rojo** (solo esquivar). Ver `enemigos.md` para el código de colores y los mínimos de aviso, que valen igual para los jefes.

## Qué se tomó de Hollow Knight

El primer jefe de Hollow Knight, el Falso Caballero (una larva dentro de una armadura enorme, en una sala cerrada tras un banco de descanso), enseña cuatro cosas que se han copiado en su forma, no en su contenido:

- **Se llega a él por un tramo que ya ha enseñado sus reglas** (aquí: Último Umbral → Terrazas Secas → Cisterna → Galerías Bajas, con enemigos de dificultad creciente, un foso de pinchos y un Ancla justo antes de la puerta).
- **La armadura no cuenta**: golpearla no hace daño de verdad; al romperla queda expuesto un momento y solo entonces se le puede herir. Obliga a leer la pelea en lugar de golpear sin más. (Es el arquetipo del Centinela; los demás jefes **no** lo repiten, para que no se vuelva rutina.)
- **Tres fases** con ataques que se acumulan: la misma amenaza se hace más rápida y trae consecuencias nuevas.
- **Una "furia"** al empezar las fases avanzadas, que sirve de pico de tensión entre ventanas de ataque.

No hay más parecido: el jefe, su arte, su historia y las cifras son propios.

## El marco de jefes (reglas de todas las peleas)

Cada jefe es una persona con nombre y motivo; el combate es la conversación que no pudieron tener. Cada uno tiene **un verbo propio** que enseña y examina, para que diez peleas con avisos amarillos no se parezcan: arco (Jacinto), copia (Ilara), sello (Hesper), suelo (Magda), coro (Casimar), calma (Eudora), luz (Rufo), quietud (Maelis), seguir (Oda), armadura (Centinela).

### Reglas de diseño (todas obligatorias)

1. **Todo daño tiene aviso**, visual (color y pose) y sonoro. Los mínimos por daño son los de `enemigos.md`: 1 de daño → 0,28 s (golpe único rápido) o 0,40 s (zona o proyectil); 2 → 0,55 / 0,70 / 0,90 s (remate); 3 → 1,10 s. En fase 2 se puede acortar hasta un 15 % y en fase 3 hasta un 25 %, **nunca por debajo del mínimo de su fila**.
2. **Rojo = no parable.** Cada ataque declara `parryable`. El rojo lleva siempre marca en el suelo. Al menos dos respuestas válidas por ataque (salto o dash, parry o distancia).
3. **Daño por golpe:** 1 en casi todo, 2 en ataques pesados con aviso largo, 3 solo en el remate de Maelis (aviso ≥ 1,10 s, una vez por fase). **Nada mata de un golpe a vida llena.**
4. **Quien ataca se queda vulnerable:** recuperación ≥ 0,8 s tras cada secuencia (salvo furias) y **al menos una ventana segura por ciclo de ≥ 1,2 s**.
5. **Sin ataques inevitables** y sin daño por área que cubra la arena sin hueco. Ninguna dependencia del azar en el daño (la posición de las rocas puede ser aleatoria; el aviso, nunca).
6. **Aleatoriedad controlada:** los jefes eligen con `attack_picker` (bolsa barajada: no repite el último, el peor castigo no sale dos veces seguidas, pesos por distancia, y si un ataque no ha dañado tres veces se favorece otro). Patrón predecible en carácter, impredecible en orden.
7. **La arena se lee de un vistazo:** el jefe nunca ataca desde fuera de pantalla; el entorno peligroso se avisa antes que el jefe. La arena de un jefe que da una habilidad **no exige** esa habilidad (el jefe puede usarla delante del jugador como lección).
8. **Ganable sin extras:** con el personaje esperado (ver `nucleo-jugable.md`), sin reliquias ni Garrán, en ≤ 10 intentos (opcionales y secreto, ≤ 15); con el "margen" mínimo, en ≤ 15. Se baja siempre antes la vida (o la armadura) que la dificultad de los ataques.
9. **Ancla antes de cada jefe** a ≤ 60 s de camino hasta la puerta de la arena, y **nunca dos jefes sin un Ancla y un respiro** entre ellos. La arena está limpia al entrar (los ataques del jefe no se acumulan con enemigos comunes). Tras cada jefe, una sala sin enemigos con recompensa.
10. **Los jefes no miran tu equipo:** Castigo, Voz, Diente y similares **no afectan a jefes**. Así la duración depende de pocas variables (daño, ritmo, alcance, Garrán).
11. **Al morir o descansar:** la pelea se reinicia (jefe entero, rejas abiertas, invocaciones, proyectiles y restos limpiados). **Si se vence:** no vuelve y queda en `bosses` del guardado, con la recompensa esperando en la sala aunque se cargue sin haberla cogido.

### Estructura estándar de una pelea [Impl.: Centinela y Jacinto; el resto, pendiente]

| Momento | Duración | Qué ocurre |
|---|---|---|
| Entrada | 1,5-3 s | Cruzar la línea, rastrillos, temblor, nombre en la barra; el jefe despierta con un gesto característico |
| Fase 1: lectura | 55-70 s | 3 o 4 ataques, ritmo lento; el jugador aprende las reglas |
| Transición 1 | **≥ 1,5 s (2 s de referencia)** | El jefe se detiene y cambia de pose. **Invulnerable y sin atacar**: cabe un sorbo del frasco (0,70 s) |
| Fase 2: variación | 50-70 s | Ataques de la fase 1 más rápidos (aviso −15 %) y 1 o 2 nuevos |
| Transición 2 | ≥ 1,5 s | Igual; empieza una furia o una demostración del ataque nuevo |
| Fase 3: examen | 50-80 s | Combina; aparece el ataque-remate |
| Muerte | 3-4 s | Cámara lenta (30 %), la música se corta, silencio de ~1,5 s, animación de final emocional; Ancla y recompensa |

Duración objetivo para un jefe obligatorio sin fallos: 2,5-4 minutos (6-12 con las muertes de aprendizaje); Maelis, 5-6. El Centinela conserva sus transiciones propias (ver más abajo).

### Feedback común [Pend.]

| Evento | Hit stop | Cámara | Sonido |
|---|---|---|---|
| Golpe del jugador al jefe | 0,06 s (como hoy) | Temblor leve | Impacto seco, según el material |
| Golpe a armadura o escudo | 0,03 s | — | Metal (`armor_hit`) |
| Parry exitoso | 0,10 s | Temblor medio, zoom 3 % | Chispazo azul y campana corta |
| Ruptura de armadura / fin de fase | 0,15 s | Temblor fuerte | Rotura grave |
| Daño recibido | 0,06 s | Temblor fuerte | Golpe + latido |
| Muerte del jefe | 0,30 s + cámara lenta | Zoom 8 % | La música se corta; silencio; el tono de la persona |

**Música**: sin músicos, por síntesis de código como los efectos (`docs/sonido.md`). Una base de bajo, una capa de pulso que entra en la fase 2 y una de tensión en la 3; un timbre propio por jefe (hoz y viento, órgano y plumas, campana y lacre, pico y roca, arpa y mar, fuelle y llama, coro callado, una sola nota larga). Todos terminan en silencio, no en fanfarria. **[Recorte]**: si falta alcance, un tema común con la capa de furia.

### Marco técnico

`game/boss/boss_room.gd` ya resuelve todo lo que no es "la pelea" y **se reutiliza tal cual** para los nueve restantes: disparador al cruzar la línea, dos rastrillos (`Gate` de `core/objects/gate.gd`, escena `game/environment/reja.tscn`), barra (`boss_bar`), reinicio al morir o descansar, recompensa en el centro y registro en `bosses`. El único cambio: que la recompensa deje de ser solo `reward_ability` y admita **recuerdo de habilidad, Sello, llave o reliquia** (un `reward_scene` genérico). El Sello además abre una ranura de reliquia (lo decide el estado del jugador, no la sala).

**Cómo se monta un jefe:**

1. Una escena del jefe con `take_hit` y `on_parried`, las señales `defeated` y `status_changed`, y `display_name`, `armor_hp`, `armor_max()`, `core_hp`, `core_health`, `wake()` y `arena_left/right/ceiling` (ver `centinela.gd`). Los jefes sin armadura exponen su vida por fases con el mismo contrato (la barra sabe pintar "armadura + núcleo", "Calma + vida" o "partes").
2. Una sala con `script = boss_room.gd`, `boss_scene` y `reward_ability` (o la recompensa genérica), y en el mapa los marcadores `b` `t` `[` `]` `r` (ver `vertical-slice.md`).
3. Cada ataque declara su aviso, duración, daño, `parryable` y su exposición; un método `debug_force_attack(id)` permite probarlos uno a uno.

**Se extrajo al construir Jacinto [Impl.]** (a partir de `centinela.gd`, que mezcla tres cosas que se repetirán), y solo lo que los dos jefes usan:

| Pieza | Qué hace | Dónde |
|---|---|---|
| `PhaseTracker` | Vida en tramos con "suelos" para que el daño no salte de fase (equivale a `CORE_FLOORS`); señales `floor_reached` y `phase_changed`. Lo usa Jacinto; el Centinela conserva su vida con armadura | `core/components/phase_tracker.gd` |
| `AttackPicker` | Bolsa barajada sin repetir el último, con sesgo por distancia, equidad y límites. Lo usa Jacinto; el Centinela conserva su decisión propia | `core/components/attack_picker.gd` |
| `Spawner` | Invocaciones con tope de vivas (la Llamada de Jacinto) | `core/objects/spawner.gd` |
| `boss_base` | **Mínimo**: buscar al jugador, temblor de cámara, mirar si hay suelo, `_floor_below` y traspasar al jugador cuando el jefe cae encima. Los estados (dormido, despertar, recuperarse...) siguen siendo de cada jefe: aún no se repiten lo bastante para extraerlos | `game/boss/boss_base.gd` |

Los jefes sin armadura (todos menos el Centinela) usan **vida simple repartida en fases por umbrales**, con exposición condicionada a un estado (aturdido por parry, recuperación larga, parte rota). Eudora usa una "Calma" regenerable en lugar de armadura.

## El Centinela Hueco [Impl.]

Armadura vacía de un Custodio de la Orden del Archivo (Oriol Maraver) que sigue guardando el Aljibe "porque nadie vino a relevarle". Dentro, en el hueco del pecho, lo que la Desmemoria dejó: una figura pálida y encorvada, Oda Bellver. Es el primer recuerdo que el jugador **no puede olvidar**: el del mensajero que cruzaba los pasos rotos. Al vencerlo suelta el recuerdo del **dash**.

- Sala: **El Aljibe** (`game/levels/aljibe.map`, 64×33 baldosas: una arena propia, del tamaño de una pantalla y media, con dos tablones para esquivar). Entrada por el oeste desde las Galerías Bajas, salida por el este hacia La Chimenea. Al cruzar la línea de la sala caen **dos rastrillos de hierro** de 2×6 baldosas (temblor de cámara y sonido) que no se abren hasta vencerlo (o morir).
- Código: `game/boss/centinela.gd` (la pelea), `boss_room.gd` (la sala), `falling_rock.gd`, `shockwave.tscn` (un `Projectile` de `core/`), `core/objects/gate.gd` y `game/environment/reja.tscn` (cada celda de reja), `boss_bar.gd`.
- Arte: `art/source/centinela.sprite` (lo genera `tools/rig_centinela.js`), 384×256 por fotograma. Es **enorme**: el cuerpo mide 112×160 (el jugador, 24×48), casi cuatro veces su altura.
- Recompensa: dash y **40 Ecos**.

### Reglas de la pelea

| | Fase 1 | Fase 2 | Fase 3 |
|---|---|---|---|
| Armadura (daño a romper) | 8 | 9 | 10 |
| Núcleo, al terminar la fase | 10 | 5 | 0 (muere) |
| Aviso del mazazo | 0,85 s | 0,70 s | 0,58 s |
| Rocas por mazazo / por aterrizaje | 0 / 0 | 2 / 2 | 3 / 2 |
| Ondas | hacia delante | hacia delante | a los dos lados |
| Furia al empezar | — | 4 mazazos | 6 mazazos |

Vida total: 27 de armadura + 15 de núcleo = 42.

- **Armadura**: cada golpe la gasta (el daño del arma cuenta), sin aturdirlo ni apartarlo. Al llegar a 0 queda **expuesto** 3 s, arrodillado y con el cascarón asomando: solo entonces se le baja el núcleo.
- **Núcleo**: 15 en total. En cada fase no baja de su marca (10, 5, 0): al alcanzarla se levanta y pasa a la siguiente, con armadura nueva y su furia. Si el tiempo de exposición acaba antes, repone la armadura y sigue en la misma fase.
- **Parry**: desviar el mazazo (o el aterrizaje) lo deja expuesto 1,5 s sin gastar armadura. Una onda de polvo desviada vuelve contra él y le quita el doble.
- **Ataques** (todos con aviso en amarillo, esquivables y, salvo las rocas, parables):
  - *Mazazo* (alcance ~240 px) **P**: golpe de área delante (2 de daño) y una onda baja de polvo (1 de daño) que se salta. Desde la fase 2 caen rocas del techo **R**, cada una con un aviso de polvo en el suelo.
  - *Salto* **P**: se agazapa, salta y cae junto al jugador (no encima). El golpe es rasante (2 de daño): saltar lo evita. No salta dos veces seguidas.
  - La **onda** de polvo corre pegada al suelo: si sale de un tablón, al acabarse **cae al suelo de abajo y sigue avanzando**; sube escalones pequeños y se deshace contra una pared (`shockwave.gd`). Un parry la devuelve igual.
  - El **polvo** del aterrizaje se genera por código y solo sale **sobre suelo** (`impact_dust.gd`). Por eso el mazazo solo se da si hay suelo bajo toda la huella del mazo (si no, se recoloca con un salto).
  - Si cae **encima del jugador** no se queda subido: mientras salta y justo después no choca con él y se aparta a un lado hasta separarse.
  - Baja de los tablones como el jugador si este está claramente más abajo, y el salto apunta también a su altura. Las rocas caen hasta lo primero sólido que haya debajo de su sitio.
  - *Furia*: mazazos seguidos en el sitio, con ondas a los dos lados y rocas por toda la sala.
- **Ecos**: suelta 40 al morir.
- **Si el jugador muere o descansa en un Ancla**: la pelea se reinicia (jefe entero y dormido, rejas abiertas). **Si se vence**: no vuelve y queda guardado (`bosses`). El recuerdo del dash aparece en el centro de la sala y, si se carga una partida sin haberlo cogido, sigue esperando.

### Animaciones y sincronía

La hoja del jefe tiene 11 animaciones (idle, walk, windup, strike, crouch, jump, fall, land, stagger, getup, death). El daño, la onda y las rocas del mazazo no salen al empezar el tajo sino en el **fotograma de impacto** (`STRIKE_IMPACT_FRAME` = 5 de `strike`; `LAND_IMPACT_FRAME` = 1 de `land`), que avisa `SheetAnimator.frame_changed`: lo que se ve y lo que pega coinciden, y un parry o un aturdimiento a mitad del tajo cancelan el golpe. Si se redibuja la animación hay que mover esas dos constantes.

### Pendiente del Centinela (por prioridad)

1. **Jugarlo a mano.** Todo lo demás depende de esto. Medir intentos, tiempo real y dónde se muere antes de construir el siguiente jefe.
2. **La furia de la fase 3** (6 mazazos con ondas dobles y rocas) es el pico de dificultad y con el arma sin mejorar puede ser injusta (el jugador aún no tiene el dash). Si el tiempo de la fase 3 supera 90 s o la tasa de muerte en la furia pasa del 50 %, bajar a 5 mazazos y dar 0,6 s de aviso a las rocas. La sala debe tener siempre un tablón seguro.
3. **La exposición (3 s) y la armadura:** con armadura 10 y daño 1 la tercera fase se alarga. Primero bajar la armadura (9 en la fase 3), luego la exposición.
4. **La onda baja necesita aviso propio** (0,4 s) distinto del mazazo; hoy se confunden. **Barra legible:** armadura (gris) y núcleo (rojo) con el nombre; comprobar que se entiende que el núcleo no baja hasta romper.
5. **Secuencia final del canon** (el cascarón sale del hueco del pecho, corre hacia el este y se apaga; la coraza queda arrodillada): animación nueva `release` de 6 fotogramas.
6. Si el salto queda bloqueado por el jugador pegado a una pared, ya se resuelve (cae a su lado), pero conviene mirarlo en juego.

## Jacinto, el Último Segador [Impl.]

Campesino de los bancales (Jacinto Ferrán) que sigue segando un campo vacío porque su mujer, Eulalia, y su hijo, Eloy, iban a venir a comer. Segundo jefe del juego: **verbo propio, leer un arco y entrar por dentro**. Al vencerlo suelta el recuerdo del **salto de pared** (el Agarre), su Nombre y 60 Ecos. Es el jefe más triste: al caer baja la hoz, camina al muro de bancal y apoya la mano; la era vuelve a tener trigo un instante. **Construido y probado por scripts; sin jugar a mano todavía.**

- **Dónde:** **La Era** (`game/levels/la_era.map`, 60×30 baldosas, posición (419,-65)), en el Cinturón alto. Se llega por **El Cercado Vacío** (`cercado_vacio.map`, 56×34, (363,-70), con el **Ancla A12**), que se sube desde el **Cruce del Pan** por un pozo abierto en su techo (ver `mundo.md`). Sin enemigos entre el Ancla y la puerta: unas 35 baldosas de camino (menos de 10 s).
- **La arena:** suelo plano de 48 baldosas entre dos **muros de bancal de 14 baldosas** (columnas 6 y 54; el jugador aún no puede subirlos, Jacinto sí), un disco de piedra en el centro (a ras de suelo), **dos peldaños** de un solo sentido a 3 y 5 baldosas en el lado de la entrada, seis postes de adorno (los espantapájaros), cielo abierto. La entrada es un túnel por el muro izquierdo con **una reja** (2×6 celdas, `core/objects/gate.gd`) que cae al cruzar la línea del disparador y no se abre hasta vencerlo (o morir). **No hay reja de salida**: de momento la arena es un callejón (la salida este, hacia La Cuesta del Segador, se abrirá con esa sala). Una tablilla con el Nombre de **Eloy Ferrán** está en el centro antes de la pelea; al vencer, junto al recuerdo, aparece **la hoz clavada** (Nombre de **Jacinto Ferrán**).
- **Código:** `game/boss/jacinto.gd` (la pelea; hereda de `game/boss/boss_base.gd`, lo que ahora comparten él y el Centinela), `hoz.tscn` (la hoz lanzada, un `Projectile` de `core/` en modo retorno), `core/components/attack_picker.gd`, `core/components/phase_tracker.gd`, `core/objects/spawner.gd`, `TelegraphZone` con anillo, `boss_room.gd` (sala, ahora con `arena_margin_cells`, `after_note` y tamaño propio del jefe) y `boss_bar.gd` (sin armadura enseña solo la barra de vida).
- **Arte:** `art/source/jacinto.sprite` y `hoz.sprite` (los genera `tools/rig_jacinto.js` con el esqueleto de `rig_lib.js`): lienzo de 224×128, **17 filas** (idle, walk, windup_swing, swing_low, windup_spin, spin, step_slash, windup_throw, throw, catch, climb, wall_hold, dive, summon, stagger, death, release) y como mucho 8 columnas: **unos 15 MB de textura** (14,9 MiB; tope 16). Cuerpo de 32×80 (el jugador, 24×48). Paleta de tierra y lino: sombrero de paja, camisa de lino, pañuelo verde y una hoz de mango largo con el filo claro; el rojo no se usa en el cuerpo (el rojo es peligro). Las vueltas dejan una estela de trigo; la Llamada levanta paja del suelo; `release` llena el campo de espigas.
- **Sonido:** voz propia (`jacinto_alert/attack/hurt/die`, grave, ronca y con aire) y cinco sonidos nuevos en `tools/sonidos.js`: `hoz_swing`, `hoz_spin`, `hoz_ground`, `straw_rise`, `wheat_bloom`. Sin música de jefe todavía.

### Reglas de la pelea

Vida simple de 36 con `PhaseTracker` (marcas 24 / 12 / 0), sin armadura. Elige con `AttackPicker`: bolsa barajada sin repetir el último, pesos por **distancia** (cerca: siega y vuelta; lejos: paso y hoz), como mucho **dos vueltas en cinco ataques**, y si una vuelta daña, la siguiente no sale en dos turnos. Entre fases, una **transición de 2 s** (invulnerable y sin atacar: cabe un sorbo del frasco) que abre con una demostración del ataque nuevo (la hoz en la fase 2, la Llamada en la 3). Daño de **1 o 2**; nada mata de un golpe.

| Ataque | Aviso (F1) | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| **Siega baja** (barrido a ras, 124 px delante) | 0,75 s (F2 0,64; F3 0,56; mín. 0,40) | 1 | **P** | Saltar, parry, dash. Marca amarilla en el suelo |
| **Vuelta amplia** (360°, radio 130, hueco seguro de 45 px pegado a él) | 0,90 s (mín. 0,70) | 2 | **P** | **Entrar por dentro** (marca en anillo con el centro libre) o retroceder más de 130 px. Parry: aturdido 1,6 s |
| **Paso de segador** (avanza 48 px y siega) | 0,55 s (mín. 0,40) | 1 | **P** | Saltar o dash por detrás |
| **Hoz lanzada** (F2; boomerang a ras de suelo, hasta 260 px) | 0,60 s (mín. 0,40) | 1 | **P** | Saltar; parry la devuelve contra él. **Manos vacías mientras la hoz anda fuera (~1,4 s): recibe el doble** |
| **Trepa y picado** (F2) | 0,5 s agarrado (amarillo) + sombra roja ≥ 0,5 s | 2 | **R** | Salir de la sombra (círculo de 60 px, con bandas). Solo sale si llevas más de 6 s a más de 4 baldosas. Sube por el muro derecho: demuestra el salto de pared |
| **Llamada** (F2 y F3) | 0,90-1,00 s | espantapájaros: 1 (aviso 0,65) | — | Levanta espantapájaros (vida 3, sin Ecos, **tope 2 vivos**); matarlos o ignorarlos |
| **Tres vueltas** (F3, remate) | 0,90 s solo al principio | 2 / 2 / 2 | **P, P, R** | Dentro en las dos primeras; la tercera es una **marca roja de 320×24 a ras de suelo** (0,6 s): saltarla o retroceder. Recuperación 1,4 s |

**Sincronía:** el daño de la siega y del paso llega en el **fotograma de impacto** de su animación (`SWING_IMPACT_FRAME` = 2 de `swing_low`, `STEP_IMPACT_FRAME` = 3 de `step_slash`; la marca amarilla dura el aviso más lo que tarda ese fotograma). Si se redibuja la animación hay que mover esas constantes. Las vueltas hacen daño mientras giran (0,5 s), una vez por vuelta.

**Exposición y parry:** parry en siega, paso o vuelta → aturdido 1,6 s (daño ×2). La hoz devuelta le hace el doble (y el doble por tener las manos vacías). Los avisos rojos (picado y la tercera vuelta) atraviesan la guardia. Recuperación tras cada ataque 1,0 / 0,95 / 0,9 s (la vuelta, 1,1 s) más una pausa de 0,60 / 0,45 / 0,35 s: siempre hay al menos 1,25 s sin ataque.

**Reinicio y victoria:** si el jugador muere o descansa, Jacinto vuelve a dormir con la vida y la fase de partida, la reja se abre y se borran la hoz, los avisos y los espantapájaros. Vencido: no vuelve, queda en `bosses` (`LaEra`) y la recompensa y la hoz clavada siguen en la sala aunque se cargue sin haber cogido el recuerdo.

### Lo que se decidió al construirlo (y se aparta del diseño largo)

- La arena mide 60×30 de sala (48 de suelo entre los muros), no 48×22: hace falta la altura de los muros de 14 baldosas y el margen del cielo. Una sola reja (la del túnel de entrada); la segunda llegará con La Cuesta.
- La Trepa usa siempre el muro **derecho** (el izquierdo tiene el túnel de entrada a ras de suelo). La Llamada pide 2 espantapájaros en la fase 2 y 3 en la 3, pero con tope 2: en la práctica rellena hasta 2.
- La hoz va y vuelve en ~1,4 s (el diseño decía 1,2): la ida son 0,7 s y la distancia se ajusta a donde está el jugador (100-260 px).
- Recompensa y progresión: el salto de pared ya existe como habilidad del jugador, pero el mundo no lo daba en ningún sitio; Jacinto suelta su recuerdo (`reward_ability = wall_jump`). Quien ya lo tenga (partida antigua o banco de pruebas) no ve el recuerdo (`world.gd` lo retira al cargar) y conserva el Nombre en la hoz clavada y los 60 Ecos. La puerta del Castigo del canon queda para cuando exista esa sala.
- Ecos: el diseño largo (`04-combate-enemigos-jefes.md`) dice 80 y el unificado de `jefes.md` 60; se usa **60**.

### Pendiente de Jacinto (por prioridad)

1. **Jugarlo a mano.** Medir intentos (diseño: 4-6), tiempo de pelea limpia (2:30-3:30) y dónde se muere. Con el Filo base el daño es 1: 36 golpes; si sale largo, bajar antes la vida que los ataques.
2. Que la **marca amarilla del anillo** (radio 130) se entienda de un vistazo, y si el hueco de 45 px es fácil de encontrar en movimiento; que la **sombra roja** del picado deje tiempo de leer (0,5 s mínimo; sube con la distancia).
3. La **tercera vuelta** (franja roja de 24 px): si saltarla es cómodo con el doble salto y con el dash y si se lee que es el remate.
4. Música de jefe (hoz y viento, sin percusión hasta la fase 2), cámara lenta en la muerte, y la salida este de la arena cuando exista La Cuesta del Segador.
5. El arte es provisional pero legible: cara sin rasgos, sin retoques de lienzo; `release` es una animación simple (mano levantada hacia el muro y trigo).

## Los otros ocho jefes [Pend.]

Vida del jefe en puntos y en golpes eficaces (N) con el daño esperado en ese punto. Ecos de la economía (`nucleo-jugable.md`). Todos reutilizan `boss_room.gd`. Las arenas son tamaños en baldosas (ancho × alto).

### 2 · Jacinto, el Último Segador (La Era, ~4:30) [Impl.: ver su sección más arriba; esta es la ficha de diseño]

- **Arena:** 48×22; suelo plano con un disco de piedra central, dos muros de bancal de 14 baldosas (el jugador aún no puede subirlos; Jacinto sí, y lo exhibe), dos peldaños y seis espantapájaros de adorno. Aire abierto.
- **Vida:** 36 (N = 18 con daño 2), umbrales 24/12, sin armadura. **Ecos 60.** Intentos 4-6.
- **Verbo: leer un arco y entrar por dentro.** La zona pegada a él (< 45 px) no recibe el arco de la Vuelta amplia.

| Ataque | Aviso | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| Siega baja (barrido a ras) | 0,75 s | 1 | P | Saltar, parry, dash |
| Vuelta amplia (360°, radio 130 px) | 0,90 s | 2 | P | **Entrar por dentro**; retroceder > 140 px; parry lo deja expuesto 1,6 s |
| Paso de segador (avanza 3 baldosas y siega) | 0,55 s | 1 | P | Saltar o dash por detrás |
| Hoz lanzada (fase 2, boomerang a 6 baldosas) | 0,60 s | 1 | P | Saltar; parry la devuelve. Mientras la hoz está fuera, manos vacías 1,4 s: doble daño |
| Trepa y picado (fase 2) | 0,5 s agarrado + 0,5 s de sombra | 2 | **R** | Salir de la sombra. Demuestra el salto de pared |
| Llamada (fases 2-3) | 1,0 s | — | — | Levanta 2 espantapájaros (vida 3, tope 2 vivos; 1 de daño, aviso 0,65 s; sin Ecos) |
| Tres vueltas (fase 3, remate) | 0,9 s | 2/2/2 | P, P, **R** (la tercera, radio 160) | Dentro las dos primeras; saltar o retroceder la tercera. Recuperación 1,4 s |

- **Decisión:** máximo dos Vueltas amplias en cinco ataques; la Trepa solo sale si el jugador lleva > 6 s sin acercarse a menos de 4 baldosas (castiga huir).
- **Recompensa:** recuerdo del **Salto de pared**, el Nombre Jacinto Ferrán y la puerta del Castigo. Final: apoya la mano en el muro y la era vuelve a tener trigo un instante.
- **Animación (17 filas):** idle, walk, windup_swing, swing_low, windup_spin, spin, step_slash, throw, catch, climb, wall_hold, dive, summon, hit, stagger, death, release. Tipo H, lienzo 224×128.
- **Motor nuevo [Impl.]:** `boss_base` (mínimo), `PhaseTracker`, `AttackPicker`, `TelegraphZone` (la sombra, y ahora anillo), `Spawner` con tope, modo retorno del `Projectile`.

### 3 · Sor Ilara, la Copista (El Scriptorium Callado, ~6:15)

- **Arena:** 56×26, techo con vigas, 8 pupitres como plataformas que **se borran y reaparecen** cada ~6 s con aviso de 1,0 s, y una mesa central de 10 baldosas. Tinta que gotea en puntos marcados.
- **Vida:** 40 (N = 20 con daño 2), umbrales 28/14. **Ecos 80.** Intentos 4-6.
- **Verbo: la Copia.** Cada ataque se repite como copia de tinta pasado un retardo, en el sitio y con la orientación del original. F1: una copia (2,0 s); F2: dos (1,5 y 3,0 s); F3: tres (1,2/2,4/3,6 s). Máximo 3 copias vivas; golpear una en su aviso la disipa. Ilara no elige un ataque cuyo hueco ya cubra una copia pendiente.

| Ataque | Aviso | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| Pluma (estocada, alcance 200 px) | 0,60 s | 1 | P | Parry, dash, salir del carril |
| Tachón (3 gotas del techo; deja charco Lento 3 s) | 0,80 s | 1 | **R** | Salir del círculo |
| Página (hoja que gira y vuelve) | 0,50 s | 1 | P | Saltar; parry la devuelve (1 de daño a ella) |
| Borrón (se desvanece y reaparece al otro lado) | 0,45 s | 1 | P | Alejarse; el golpe llega al aparecer |
| Pupitre (lo arroja) | 0,70 s | 2 | **R** | Saltar; destruirlo antes (3 golpes) |
| Lista (fase 3, remate: lluvia de tachones en 3 oleadas) | 1,10 s | 1 por impacto | **R** | Moverse al hueco entre oleadas |

- **Exposición:** tras 3 ataques seguidos queda 1,4 s con la pluma baja; parry en la Pluma, 1,5 s. **Enseña la planificación** y el uso de plataformas.
- **Recompensa:** la **Llave de Tinta**, el Nombre Ilara y el recuerdo de la página con las iniciales "A. V.". Final: la última página que copia está en blanco.
- **Animación (13 filas):** idle, walk, windup_pluma, pluma, throw_page, cast_drops, vanish, appear, lift_desk, raise_book, hit, stagger, death. Las copias reutilizan fotogramas con tinte.
- **Motor nuevo:** `attack_echo` (cola de acciones con retardo, ~40 líneas, dentro de `game/boss`), plataformas con temporizador de aparición, `telegraph_zone`, estado Lento.

### 4 · Hesper, el Prior (El Salón de Sellado, ~7:30)

- **Arena:** 60×30, estanterías-torre en los extremos, un sello de cera gigante decorativo, cuatro pilares de lacre rompibles y dos escalones. Antes de la pelea, la fase de diálogo (ofrecimiento amable → chantaje amable, `textos-del-juego.md`).
- **Vida:** 54 (N = 18 con daño 3), umbrales 36/18. **Ecos 110.** Intentos 4-7.
- **Verbo: atacar las barreras.** Cada bloque de lacre (2×3 baldosas, 3 golpes) sella el suelo y, **al romperse, devuelve el golpe a Hesper**: 4 de daño y 1,2 s de aturdimiento. Si no se rompe, desaparece a los 6 s. Máximo 2 bloques vivos; si el jugador queda encajado, el siguiente Sello no aparece en 3 baldosas.

| Ataque | Aviso | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| Sello (marca una zona; si estás dentro, **Fijado** 0,6 s) | 1,00 s | 1 | **R** | Salir; si se forma sin ti, golpearlo |
| Mano de cera (estocada, alcance 150) | 0,50 s | 1 | P | Parry (rinde mucho), dash |
| Estampa (sello gigante del techo) | 1,00 s | 2 | **R** | Salir de la sombra |
| Llamada (F2: dos Selladores, tope 2) | 1,20 s | charcos Lentos | — | Matarlos |
| Lluvia de cera (F3, 3 oleadas de 4 gotas) | 0,70 s | 1 | **R** | Leer el hueco entre carriles |
| Pilares (F3, derriba un pilar que queda como plataforma) | 0,80 s | 1 | **R** | Esquivar |
| Cierre (remate: cuatro Sellos, uno sin bloque) | 1,40 s | 1 / Fijado | **R** | Encontrar el hueco |

- **Exposición:** aturdido 1,2 s al romper un bloque; parry en la Mano de cera, 1,5 s.
- **Recompensa:** el **Sello de Cera** (primera llave de la Herida, que abre además una ranura de reliquia), el juramento "Nadie más se perderá" y la puerta de **Brasa**. Final: su sello se resquebraja y el ala se vacía.
- **Animación (8 filas):** idle (levita), cast_seal, dagger, call, drops, drop_pillar, stagger, death (+ hit). Los bloques, sellos y gotas son sprites sueltos.
- **Motor nuevo:** `telegraph_zone` que además instancia un **nodo sólido destructible**, `status_effects` (Fijado, Lento), `Spawner`. Prueba clave: el jugador nunca queda atrapado entre bloques; un bloque que aparece sobre él lo expulsa a un lado en lugar de enterrarlo.

### 5 · Casimar, el Rey sin Reina (El Trono Hundido, ~8:30, opcional)

- **Arena:** 52×28, trono al fondo sobre tres escalones, gradas laterales con cortesanos y bóveda con pasarela.
- **Vida:** 70 (N = 24), umbrales 46/24. **Ecos 90.** Intentos 4-6. Pesado y lento.
- **Verbo: el Coro.** Cada 10 puntos que pierde llama a un cortesano (vida 4, abanico: aviso 0,60 s, 1 de daño, tope 3). Con 3 vivos, Casimar **abraza la página** (inmune y curándose 1 por segundo) hasta que se mata a uno. Cada cortesano que aplaude acelera el siguiente ataque un 15 % (hasta 3 veces; nunca por debajo de 0,55 s para daño 2).

| Ataque | Aviso | Daño | Tipo |
|---|---|---|---|
| Cetro (golpe vertical) | 1,00 s | 2 | P |
| Decreto (onda de 600 px por el suelo) | 0,90 s | 1 | **R** (saltar) |
| Embestida de trono (F2) | 0,80 s | 2 | **R** (esquivar por detrás) |
| Llamamiento (invoca cortesano) | 1,00 s | — | — |
| Corona (F3, remate: seis proyectiles dorados en abanico) | 1,10 s | 1 cada uno | **R** |

- **Recompensa:** el Nombre **Áurea** y la reliquia **Corona sin Reina**. Final: la página se deshace y se oye reír a una mujer.
- **Animación:** 9 filas el rey + 4 el cortesano. **Motor nuevo:** `Spawner` con tope e invulnerabilidad por estado.

### 6 · Magda Soler, la Capataz (La Cámara de Apuntalamiento, ~9:15)

- **Arena:** 56×34, dos niveles (suelo principal y galería inferior de 6 baldosas con pinchos solo en los extremos), un pozo central de 8 baldosas, seis vigas y tres plataformas.
- **Vida:** 66 (N = 22 con daño 3), umbrales 44/22. **Ecos 140.** Intentos 5-7.
- **Verbo: vigilar el suelo, no solo al enemigo.** **Recorte esencial:** no se editan baldosas; se usan **losas frágiles** preubicadas (la "grieta honda" de `03-puzles` M2: aparece, avisa, se hunde y se regenera tras la pelea) y vigas que son objetos. En la fase 3 el suelo principal está casi perforado y la lucha pasa al nivel inferior; siempre hay una ruta de vuelta (paredes agarrables).

| Ataque | Aviso | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| Pico (golpe vertical, alcance 120) | 0,70 s | 2 | P | Parry (1,6 s expuesta), dash por detrás |
| Barrido de pico | 0,55 s | 1 | P | Saltar, parry |
| Golpe Hondo (onda por el suelo y rompe losas) | 0,90 s | 1 + caída | **R** | Saltar la onda, salir de las losas marcadas; queda con el pico clavado 1,6 s (**exposición**) |
| Apuntalar (golpea una viga: caen rocas) | 0,80 s | 1 por roca | **R** | Leer las sombras |
| Carga del capataz (F2) | 0,60 s | 2 | **R** | Saltar; si choca con la pared, aturdida 1,2 s |
| Latido (F3, cada 9 s, independiente) | 1,0 s | 1 | **R** | Saltar la onda circular |
| Última orden (remate: tres Golpes Hondos) | 1,20 s | 1/1/1 + caída | **R** | Moverse entre golpes |

- **Recompensa:** **Excavar** (el Golpe Hondo), el **Sello de Piedra** (otra ranura), el Nombre Magda Soler. Final: deja el pico y camina hacia el jugador sin hablar.
- **Animación (12 filas):** idle, walk, windup_pico, pico, sweep, plant, pull, charge, hit, stagger, death, drop_pico.
- **Motor nuevo:** losas frágiles (`breakable_slab`), pico clavado como zona golpeable, onda por el suelo (reutiliza `Shockwave`). Prueba clave: con el suelo roto siempre hay ruta de vuelta; el techo no cae sobre una zona sin aviso.

### 7 · Rufo, el Farero (El Faro de las Velas, ~10:00, opcional)

- **Arena:** 44×34, plataforma circular con cuatro **espejos** móviles y una gran lente central.
- **Vida:** 58 (N = 20), umbrales 40/20. **Ecos 90.** Intentos 4-6.
- **Verbo: usar el entorno.** Cada espejo proyecta un haz (aviso amarillo fino 0,8 s, luego haz rojo 0,5 s). Golpear un espejo lo gira 45°. Un haz que alcanza a Rufo le hace 6 de daño y lo deslumbra 1,5 s. Siempre hay una sombra alcanzable.

| Ataque | Aviso | Daño | Tipo |
|---|---|---|---|
| Haz (línea de luz, ticks de 0,25 s) | 0,80 s | 1 por tick | **R** |
| Barra de tizón | 0,60 s | 1 | P |
| Brasas (3 cartas ardiendo en arco; dejan fuego 2 s) | 0,60 s | 1 cada una | **R** |
| Barrido de lámpara (F2, 180°) | 1,20 s | 1 por tick | **R** (cobertura tras la lente) |
| Todos los haces (F3, remate) | 1,30 s | 1 por tick | **R** |

- **Recompensa:** la reliquia **Vela del Faro** y el Nombre Rufo. Dilema: vencerlo no resuelve nada. **Animación:** 7 filas + espejos y lente. **Motor nuevo:** `telegraph_zone` lineal (haz) y espejo con ángulo (objeto golpeable).

### 8 · Eudora, la Piadosa (El Rellano de Cal, ~10:50)

- **Arena:** 60×28, abierta al mar, plataformas de cal y **círculos de cal** que aparecen y desaparecen. Luz clara y música suave.
- **Vida:** Calma 100 por fase + vida 60 (umbrales 40/20; ~25 golpes), **Ecos 160.** Intentos 4-6.
- **Verbo: encadenar sin ser tocado.** La Calma se comporta como la armadura del Centinela pero **se regenera** (+6/s si no recibe daño durante 2 s). Con Calma > 0, cada golpe hace 1 a la vida y el resto a la Calma; con Calma 0 queda "inquieta" 3 s y recibe daño completo. El parry en la Mano abierta le quita 40 de Calma. Nunca es inmune.

| Ataque | Aviso | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| Círculo de cal (bajo el jugador, 3 s activo) | 1,20 s | 1 + **Olvido** 4 s | **R** | Salir |
| Mano abierta (barrido lento, empuja) | 1,10 s | 1 | P | Parry (rinde mucho), dash |
| Nana (partículas desde arriba; no se puede usar frasco mientras dura) | 0,90 s | 1 por oleada | **R** | Moverse bajo el hueco |
| Abrazo (F2, agarra si estás cerca) | 0,80 s | 0 + **Fijado** 0,8 s | **R** | Alejarse |
| Acompañantes (F3: dos Hermanos de Cal que le dan Calma) | 1,20 s | — | — | Matarlos primero |
| Olvido (remate: anula 2 s la curación) | 1,30 s | 2 | **R** | Aguantar |

- **Decisión:** picker lento, pausas largas (parece una conversación); un respiro de 1,0 s cada tres ataques. Al encadenar golpes sube un tono; si cae la Calma, la música baja.
- **Recompensa:** el **Sello de Cal** (tercera ranura) y el Nombre **Mateo**. Al morir, olvida al jugador y sonríe.
- **Animación (11 filas):** idle, walk, draw_circle, hand, sing, embrace, call, hit, stagger, death, smile. **Motor nuevo:** `status_effects` (Olvido, Fijado) y un contador de racha del jugador.

### 9 · Maelis, la Priora Sellada (La Sala del Asiento, ~12:55)

- **Arena:** 64×36, circular, cinco sillas con máscara azul y la sexta (del Caminante) al fondo. Maelis emerge de la pared del fondo: un **busto con rostro de piedra y dos manos enormes**.
- **Partes:** dos manos de 24 y rostro de 32 (80 en total, N ≈ 27 con daño 3). **Ecos 200.** Intentos 6-9. F1 rompes una mano, F2 la otra, F3 el rostro.
- **Verbo: no quedarse quieto.** Si el jugador se mueve a < 30 px/s más de 1,4 s, el lacre lo **Fija** 0,6 s y lo empuja hacia el asiento. **Ningún ataque de Maelis es parable:** la pelea examina el movimiento (dash, doble salto, salto de pared). No hay interacción con Nombrar en combate.

| Ataque | Aviso | Daño | Tipo | Respuesta |
|---|---|---|---|---|
| Barrido de mano | 0,85 s | 2 | **R** | Saltar, dash por debajo |
| Palma (aplasta una zona; la mano queda hundida 2,0 s: daño ×1,5) | 1,00 s | 2 | **R** | Salir |
| Corriente de lacre (arrastra hacia el asiento) | 0,70 s | 0 (si llegas: Fijado 1,5 s y 1) | **R** | Dash y doble salto contra corriente |
| Gotas de lacre | 0,60 s | 1 | **R** | Moverse |
| Mano cerrada (puño contra la pared) | 0,90 s | 1 + piedras | **R** | Esquivar |
| Cierre (remate F3: las dos manos se cierran) | 1,20 s | **3** | **R** | Quedar bajo un hueco entre los dedos (marcado) o fuera del círculo |

- **Exposición:** mano hundida 2,0 s; mano rota, 3 s con el rostro desprotegido. La corriente no puede empujar a una zona de muerte.
- **Recompensa:** abre la **Sala de Aún**. Sala en silencio, sin cámara lenta al caer las manos: es culpa, no triunfo.
- **Animación (10 filas):** rostro (idle, hit, death), mano (idle, sweep, palm, close, fist, hurt, break) ×2 espejadas. **Motor nuevo:** partes golpeables propias de este jefe (`hurt_zone` local, no genérica), `status_effects` (Fijado), `telegraph_zone` grande, fuerza de arrastre al jugador. Es el jefe más caro de arte (multiparte); **[Recorte]**: rostro estático.

### 10 · Oda, la Última Mensajera (La Pasarela, secreto, ~14:00)

- **Es una carrera, no un combate.** Sin vida del jefe, sin daño y sin parry. Usa los tres huecos de 17 baldosas de La Pasarela; para la prueba el abismo se cubre con un velo: los pinchos se retraen y caer devuelve a la plataforma anterior sin daño. Se invoca desde el Ancla del Mirador (distancia 0) con Nombrar.
- **Mecánica:** Oda corre por la Pasarela con carreras, saltos y dashes; el jugador debe mantenerse a **menos de 6 baldosas** (1,0 s de gracia). Tres vueltas a 280, 330 y 380 px/s; la tercera exige salto + doble salto + dash en un mismo hueco, y ella lo muestra primero con un gesto. Si te quedas atrás, vuelve a un punto de control a esperarte: nunca castiga. Barra de **Distancia** (verde cuando la sigues bien).
- **Recompensa:** la **Insignia de Mensajera** (llave del epílogo del Relevo) y 150 Ecos. Música: una sola nota larga y pasos.
- **Animación (6 filas):** idle, run, dash, jump, wait, hand. **Motor nuevo:** un controlador de ruta con puntos y señales de espera (no es IA de combate). Prueba clave: un bot de referencia con dash + doble salto completa las tres vueltas; un jugador parado no se bloquea.

## La curva de dificultad de los jefes

Golpes eficaces (N) con el daño esperado en ese punto; la pelea limpia es el tiempo de un intento que acaba en victoria. Los números de los jefes 2-10 son un presupuesto, no una medición: se corrigen al construir y jugar cada uno.

| Jefe | Hora | Vida del jefe | N | Pelea limpia | Intentos (típico / rango) | Ecos |
|---|---|---|---|---|---|---|
| 1 Centinela [Impl.] | 2:15 | 42 (27 armadura + 15 núcleo) | ~21 | 2:30-4:00 | 3 / 1-6 | 40 |
| 2 Jacinto | 4:30 | 36 | 18 | 2:30-3:30 | 5 / 4-6 | 60 |
| 3 Ilara | 6:15 | 40 | 20 | 2:30-3:30 | 5 / 4-6 | 80 |
| 4 Hesper | 7:30 | 54 | ~18 (con bloques) | 3:00-4:00 | 5 / 4-7 | 110 |
| 5 Casimar (opc.) | 8:30 | 70 | 24 | 3:30-5:00 | 5 / 4-6 | 90 |
| 6 Magda | 9:15 | 66 | 22 | 3:00-4:30 | 6 / 5-7 | 140 |
| 7 Rufo (opc.) | 10:00 | 58 | 20 | 3:00-4:00 | 5 / 4-6 | 90 |
| 8 Eudora | 10:50 | Calma 100 + vida 60 | ~25 | 3:30-5:00 | 5 / 4-6 | 160 |
| 9 Maelis | 12:55 | 80 (24 + 24 + 32) | ~27 | 5:00-6:00 | 7 / 6-9 | 200 |
| 10 Oda (secreto) | 14:00 | sin vida | — | ~3:00 (tres vueltas) | 3 / 2-5 | 150 |

Total de combate de jefe obligatorio: 7 jefes × 5 intentos × ~4 min ≈ 2,3 h, el 18 % del camino principal. Tras cada jefe la dificultad percibida baja (respiro). Vencerlos con todo el árbol dura un 25-40 % menos: es la recompensa de completar. Para el personaje esperado en cada uno, ver `nucleo-jugable.md`.

Reglas para que ningún jefe sea imposible, en forma de lista de control al construirlo: ganable sin extras en ≤ 10 intentos; todo ataque con aviso ≥ su mínimo y con color; ningún golpe supera su límite de daño; ventana segura de ≥ 1,2 s por ciclo; sin ataques inevitables; Ancla a ≤ 60 s; con Garrán o reliquias se hace más fácil, nunca necesario.

## Piezas de motor nuevas que piden los jefes

| Pieza | La usan | Orden |
|---|---|---|
| `parryable` por ataque + aviso rojo | todos | Antes de Jacinto (ver `enemigos.md`) |
| `PhaseTracker`, `AttackPicker`, `boss_base` (mínimo) | Jacinto en adelante **[Impl.]** | Con Jacinto |
| `TelegraphZone` (con anillo) | Jacinto (sombra, vueltas) **[Impl.]**, Ilara, Hesper, Magda, Rufo, Eudora, Maelis | Con Jacinto (versión mínima) |
| `Spawner` con tope; modo retorno del `Projectile` | Jacinto **[Impl.]**, Hesper, Casimar, Eudora | Con Jacinto |
| `attack_echo` y plataformas con temporizador | Ilara | Con Ilara |
| `status_effects` (Lento, Fijado) | Ilara, Hesper, Maelis | Antes de Hesper |
| Bloque sólido destructible | Hesper | Con Hesper |
| Losas frágiles (`breakable_slab`) | Magda | Con Magda |
| `status_effects` Olvido y contador de racha | Eudora | Con Eudora |
| Espejos y haz | Rufo | Con Rufo (opcional) |
| Partes golpeables, arrastre | Maelis | Al final del proyecto |
| Controlador de ruta | Oda | Con Oda |

Cada pieza se construye cuando llega el primer jefe que la necesita, no antes.

## Cómo se comprueba

La prueba de humo (`tests/smoke_test.gd`) fuerza cada ataque del Centinela, recorre las tres fases golpeando, comprueba el parry y la onda devuelta, que morir reinicia la pelea y que vencerlo queda guardado. El puzle de después se repite con maniobras de referencia (ver `docs/arquitectura.md#verificación`). Nada de eso sustituye a jugarlo. Jacinto tiene el suyo: sala y puertas alineadas, jefe dormido, fases por marcas (24 / 12 / 0) sin saltarse ninguna, transición invulnerable, cada ataque forzado con `debug_force_attack(id)` (aviso, color y parable o no, daño, sincronía con el fotograma de impacto, parry y exposición), la hoz que vuelve, el picado que no sale de la arena, el tope de 2 espantapájaros, la tercera vuelta roja, la muerte con su recompensa guardada, el reinicio sin restos, 60 s de pelea al azar sin atascos y la tirada del `AttackPicker` (1.000 elecciones sin repetir).

Para los jefes nuevos se propone un banco reutilizable `tests/boss_harness.gd` que cada jefe invoque con su escena. Invariantes por jefe:

1. **Fases:** forzar la vida a cada umbral; `phase_changed` salta una vez y no se saltan dos fases de un golpe.
2. **Ataques forzados:** `debug_force_attack(id)`; se comprueban aviso (≥ mínimo), duración, daño y `parryable`.
3. **Parry:** en los parables produce la exposición declarada; en los rojos no los desvía.
4. **Exposición:** golpeable solo en los estados declarados; después vuelve a defenderse.
5. **Reinicio:** morir o descansar reinicia vida, fase, rejas e invocaciones, proyectiles, copias, charcos, bloques y losas.
6. **Victoria persistente:** queda en `bosses` y la recompensa existe aunque se cargue sin cogerla.
7. **Sin atascos:** siempre hay camino a suelo; los rastrillos se abren al vencer o al morir; ningún estado dura más que su máximo + 1 s (un vigilante en la prueba); el jefe no sale de la arena en 60 s de simulación aleatoria.
8. **Bot de referencia:** uno sencillo (esquiva con salto ante el aviso, golpea en la exposición) lo vence en < 8 min sin parry; otro que solo ataca y salta al azar pierde o tarda > 15 min (si lo vence sin leer el patrón, es demasiado fácil).
9. **Fuzz:** 60 s de entradas aleatorias sin excepciones ni nodos que crezcan sin tope.
10. **Picker:** con 1.000 elecciones, nunca se repite consecutivamente y todos aparecen en un rango esperado.
11. **Ayuda:** con los avisos más largos activados, se alargan según el factor y nunca bajan del mínimo.

## Cosas a vigilar al jugarlo

- El tamaño de la ventana de exposición del Centinela (3 s) y de la armadura: si la pelea se hace larga, bajar primero la armadura.
- La furia de la fase 3 del Centinela: es el pico de dificultad; con el arma sin mejorar puede ser demasiado.
- **Fatiga de jefe**: diez jefes con avisos amarillos acaban pareciéndose; por eso cada uno tiene un verbo propio y los rojos reparten el peso entre parry y esquiva.
- **Estados del jugador** (Olvido, Fijado): duraciones cortas, siempre con aviso rojo, sin encadenar dos, con opción de accesibilidad.
- **Terreno cambiante** (Magda, Hesper): se resuelve con objetos preubicados, no editando baldosas; la prueba de atascos es obligatoria.
- Si el Centinela, como plantilla, resulta demasiado duro y marca un listón que luego no se mantiene, recortarlo (> 5 min de pelea) antes de construir a Jacinto.
