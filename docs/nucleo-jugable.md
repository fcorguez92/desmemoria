# Núcleo jugable (documento vivo)

Estado: **diseño unificado tras la reunión de diseñadores** (ver `docs/reunion/disenadores/DECISIONES-EDITOR-SISTEMAS.md` para el porqué de cada decisión y la lista ordenada de cambios de código). Lo marcado **Implementado** existe y está probado por scripts; lo marcado **Pendiente** es diseño aprobado sin construir. Las cifras son de partida: si al jugarlo no se sienten bien, se ajustan aquí antes de seguir construyendo contenido encima.

Documentos hermanos: `jefes.md` (jefes y marco de jefes), `enemigos.md` (bestiario y piezas de motor), `docs/reunion/disenadores/05-progresion-y-economia.md` (tablas largas y razonamiento de la propuesta original) y el canon (`guion-maestro.md`, `personajes.md`, `textos-del-juego.md`), que manda sobre cualquier cifra de este documento.

Leyenda: **[Impl.]** implementado · **[Pend.]** pendiente · **[Recorte]** candidato a caer si falta alcance (ver orden en el último apartado).

## Principios (los que no se rompen)

1. **Más poderoso, siempre vulnerable.** El jugador crece en *margen* (más vida, más cura, más ventana de parry), no en inmunidad. Un enemigo común sigue pudiendo matarte en 5-6 golpes en cualquier momento del juego.
2. **El movimiento no se compra.** Ninguna mejora, reliquia ni consumible cambia la altura del salto, la distancia del dash ni la velocidad de carrera. Las distancias de La Chimenea y La Pasarela están validadas con maniobras exactas (`tests/puzzle_plans.json`) y todas las salas futuras se diseñan contra "salto + dash = 22 baldosas". El árbol solo toca tiempos de espera, tolerancias y combate.
3. **Una sola moneda: los Ecos.** Sin materiales ni segundas monedas. La única excepción es el hierro de Garrán, que es un objeto de misión.
4. **Nada obligatorio depende de algo perdible, opcional o equipado.** Cada jefe se calcula para el "personaje esperado" (ver curva) sin reliquias opcionales, sin Garrán y sin jefes opcionales.
5. **Los Nombres no dan poder.** Lo dice el canon (`guion-maestro.md` §10.1 y §10.5): sirven para el diario, el final Compartir y los epílogos. Nada más.
6. **Poca superficie de código.** Cada sistema nuevo se construye cuando llega el primer contenido que lo necesita y deja su prueba en `tests/smoke_test.gd`.

## Movimiento [Impl.]

Ágil y preciso, inspirado en Hollow Knight: salto con arco controlable en el aire, sin inercia pesada tipo Souls. Caminar y saltar disponibles desde el inicio; el resto de movilidad se desbloquea como habilidad de progresión. Medidas del motor (para diseñar niveles): salto simple 9 baldosas de alto y largo (máximo 11 de alto), con doble salto 16 de alto, dash en el aire hasta 16 de hueco (máximo 22 con salto + dash), salto de pared para pozos de 4 a 8 baldosas de ancho.

## Las cinco habilidades del canon

Cada habilidad es una técnica recordada de otra persona (`guion-maestro.md` §2): desbloquearla es a la vez progreso mecánico y revelación de historia. Ninguna se tiene al empezar y todas son permanentes (morir no las pierde).

| # | Habilidad (aviso del juego hoy → texto del canon) | Dueño | Dónde | Qué hace | Estado |
|---|---|---|---|---|---|
| 1 | **Dash** → "la Carrera" | Oda | Centinela Hueco (El Aljibe) | Desplazamiento horizontal rápido (135 px). **Uno por salto en el aire**: se recarga al pisar suelo. Sin invulnerabilidad de base (ver Paso fantasma en el árbol) | [Impl.] |
| 2 | **Doble salto** → "el Segundo Aliento" | Tomasa | La Torre de Riego | Un salto extra en el aire, algo más corto | [Impl.] |
| 3 | **Salto de pared** → "el Agarre" | Jacinto | La Era (jefe 2) | Agarre a cualquier pared y salto desde ella; sube pozos estrechos | [Impl.] la mecánica; **[Pend.]** colocarla en el mundo (hoy solo en el banco de pruebas) |
| 4 | **Excavar** → "el Golpe Hondo" | Magda | La Cámara de Apuntalamiento (jefe 6) | El ataque hacia abajo (y el horizontal) rompe lo "hondo": suelos y muros marcados con veta ámbar (ver más abajo) | [Pend.] |
| 5 | **Nombrar** → "Nombrar" | Linde | Hito del Umbral, acto IV | Es la única que no se recoge: se obtiene en una escena. Mantener la acción ante una Piedra de lectura que "pide un nombre". Abre también el viaje "Decir los nombres" | [Pend.] |

Los avisos del código dicen hoy "Dash", "Doble salto" y "Salto de pared"; los nombres del canon ("la Carrera"...) se aplican al implementar el texto "Has recordado: ..." definitivo (`textos-del-juego.md` §8).

### Cómo se consiguen hoy [Impl.]

Se recoge un **recuerdo** (rombo azul claro) que aparece en el mundo y el juego avisa con "Has recordado: ...".

- El **dash** lo suelta el **Centinela Hueco** (ver `jefes.md`), al fondo del camino que baja por el foso de Las Terrazas Secas y cruza La Cisterna y las Galerías Bajas. Con él se cruza ese foso y se supera el puzle de La Chimenea y La Pasarela, que acaba en un mirador con Ancla.
- El **doble salto** está en lo alto de la escalera de tablones de La Torre de Riego y abre la cornisa del Ancla.
- El **salto de pared** todavía no está colocado en el mundo; en el canon lo da Jacinto.
- En el banco de pruebas (`test_level.tscn`) cada habilidad está justo antes del obstáculo que abre.

Es el bucle metroidvania: encuentro una técnica y un camino antes cerrado se abre.

## Ataques del jugador

Un único arma cuerpo a cuerpo (el Filo) cuyo daño, ritmo y alcance mejoran en el árbol. El lienzo del sprite del Caminante pasa de 112×64 a **112×96** antes de dibujar los ataques verticales (la punta de la daga hacia arriba se sale hoy del lienzo; la colisión no cambia, 24×48).

| Ataque | Control | Qué hace | Reglas | Estado |
|---|---|---|---|---|
| **Tajo horizontal** | X | Golpea por delante (hitbox ~40 px, enfriamiento 0,30 s, daño 1 a 3 con el árbol) | No se puede atacar con la guardia alzada ni durante el sorbo del frasco | [Impl.] |
| **Ataque hacia arriba** | Arriba + X (suelo o aire) | Hitbox sobre la cabeza (36×44 px), mismo daño y enfriamiento | No empuja al jugador. Es la respuesta a los voladores: **hay que tenerlo antes de colocar un solo volador** | [Pend.] |
| **Ataque hacia abajo con pogo** | Abajo + X (en el aire) | Hitbox bajo los pies (30×36). Si conecta con un **enemigo o un objeto golpeable** (grupo `pogoable`), el jugador rebota ~126 px (0,7 de salto) y puede encadenar | **No rebota en pinchos** (devuelven al suelo como hoy) y **no recarga dash ni doble salto**: así las distancias de los puzles no cambian. En el suelo, Abajo + X es el tajo normal | [Pend.] |
| **Golpe Hondo (Excavar)** | Abajo + X, o X de frente, con la habilidad | Rompe lo marcado como "hondo" (veta de rombos ámbar): suelos con el golpe hacia abajo (en suelo o aire), muros con el tajo | Es el verbo de Excavar y nada más: **no hay caída cargada con onda** (se recortó). "Golpe Hondo" es el nombre de la habilidad y de un ataque de Magda | [Pend.] |
| **Parry** | V | Ventana de 0,20 s (hasta 0,35 s con el árbol) en la que un golpe **frontal amarillo** se desvía; el atacante queda aturdido 1,2 s y recibe doble daño. Espera 0,70 s tras pulsar | **No funciona contra avisos rojos** ni por la espalda (ver "Aviso amarillo y rojo") | [Impl.] salvo la distinción amarillo/rojo, **[Pend.]** |
| **Dash** | Shift izq. / RT | Ver tabla de habilidades | — | [Impl.] |

Pendiente de animación: `attack_up`, `attack_down`, `heal` (beber) y la fila de muerte; hasta que existan, el ataque vertical usa el arco de ataque con la pose actual.

## Combate contra enemigos

Se apoya en dos ideas: **las amenazas se ven venir** y **los golpes tienen peso**. El bestiario completo, las piezas de motor y las pruebas están en `enemigos.md`; aquí las reglas que ve el jugador.

### Lo implementado [Impl.] (cifras de partida)

- **Enemigo básico** (`game/enemy/`): patrulla cerca de su punto de origen (60 px), te detecta a 220 px si estás a una altura parecida (80 px), te persigue más rápido de lo que patrulla y no se cae por los bordes.
- **Ataque con aviso:** al acercarse se queda quieto y se pone **amarillo** (aviso); después golpea (1 de daño, 2 el coloso) y descansa. Alejarte o esquivar durante el aviso evita el golpe. La recuperación es la ventana de castigo.
- **Retroceso en ambos sentidos:** un golpe tuyo empuja al enemigo y **cancela su ataque** (aturdido 0,3 s). Tras recibir un golpe tienes 0,6 s de invulnerabilidad.
- Los enemigos **no dañan por contacto**: solo con su ataque. Tampoco se dañan entre sí.
- **Parry:** ver tabla anterior. Con el aviso de 0,40 s hay que pulsar en los últimos 0,20 s. Pulsar demasiado pronto o tarde te deja vulnerable: es la apuesta entre esquivar con el dash (seguro) y parar (arriesgado, pero premia).
- **Feedback:** arma integrada en el sprite que se alza durante el aviso, destello del arco del golpe, chispazo en el impacto, temblor de cámara (fuerte al recibir, leve al dar), número de daño flotante (amarillo si estaba aturdido y recibe doble), gotas rojas, barra de vida de enemigo que se oculta sola, **hit stop** de 0,06 s y pose propia al encajar un golpe.
- **Dificultad de partida:** avisos y recuperaciones cortos, persecución algo más rápida; lancero 4 de vida, acechador 3, coloso 10.

### Aviso amarillo y rojo [Pend.]

Contrato con el jugador, válido para todo el bestiario y todos los jefes (el detalle de legibilidad y arte está en `enemigos.md`):

- **Amarillo** (ya existe) = se puede esquivar **o parar**.
- **Rojo** (nuevo) = **no se puede parar**, solo esquivar: agarres, suelo que se rompe, luz, zonas, golpes de cuerpo entero. Un atributo `parryable` por ataque basta. Todo aviso rojo va además acompañado de una **marca en el suelo** (bandas diagonales para quien no distingue colores): el rojo nunca depende solo de la pose.
- **Cian** (ya existe) = estado de debilidad (aturdido).
- **Mínimos de aviso por daño** (se aplican en fase 1; en fases 2 y 3 se puede acortar hasta un 25 %, nunca por debajo del mínimo de la fila): daño 1 → 0,28 s (golpe único rápido) o 0,40 s (con zona o proyectil); daño 2 → 0,55 s (golpe único), 0,70 s (zona o proyectil) o 0,90 s (remate); daño 3 → solo remates de la Herida, 1,10 s.
- **Ningún golpe mata a vida llena.** El daño es 1 en casi todo, 2 en pocos enemigos (coloso, cavador) y golpes de jefe, y 3 solo en el remate de Maelis (aviso ≥ 1,10 s).
- Quien ataca se queda vulnerable: toda secuencia termina con una recuperación de ≥ 0,5 s (enemigos) o ≥ 0,8 s (jefes, salvo furias).

### Estados del jugador [Pend.]

Aparecen con la Costa y el Archivo, siempre con aviso rojo, duración ≤ 4 s y sin encadenar dos a la vez. Todos caducan al morir.

| Estado | Efecto | Quién lo causa |
|---|---|---|
| **Lento** | −35 % de velocidad, 2 s | Charcos de lacre (Sellador, Hesper), tinta (Ilara) |
| **Fijado** | Sin moverse 0,6 s | Sellos de Hesper, Acompañante, abrazo de Eudora, lacre de Maelis |
| **Olvido** | El sorbo del frasco cura la mitad (redondeo hacia arriba, mínimo 1) y el contador de vida se difumina (nunca se oculta); 3-4 s | Hermano de Cal, Eudora |

El difuminado de Olvido tiene su opción de accesibilidad ("Olvido sin ocultar la vida").

## Vida, curación y frascos

### Hoy [Impl.]

Vida base 5 (hasta 9 con Vitalidad). El frasco (**H**; **B / Círculo** en el mando) cura **del todo y al instante**, 3 cargas (hasta 5 con el árbol), y no se puede usar a vida completa. Las cargas se recargan al descansar. Al morir se reaparece con vida y frascos al máximo.

### Decisión: el frasco deja de curar del todo [Pend.]

Con 13 de vida y 5 frascos, una cura total instantánea son 65 vidas de colchón y ningún jefe sería peligroso. Se adopta una cura **fija, con sorbo comprometido**, la mitad de lo que proponía la sala original (que llegaba a 6 frascos y 30 vidas de cura de campaña).

| Estadística | Base | Máximo | Cómo sube |
|---|---|---|---|
| Cura por frasco | **3 vidas** | 5 | Aliento I-II (árbol) |
| Frascos | 3 | **5** | Frascos I-II (árbol). **No hay fragmentos de frasco** (recorte) |
| Tiempo de sorbo | **0,70 s** | 0,30 s (suelo) | Aguja del Escriba (−0,25 s) |
| Con vida llena | No se bebe | — | Ya es así |

Reglas del sorbo:

- Pulsar H empieza el sorbo; la carga **se gasta y la vida se recupera al terminar** (0,70 s). Mientras dura no se puede atacar, parar ni moverse.
- **Un golpe recibido lo interrumpe y el frasco no se gasta.** Saltar o hacer dash lo cancela a voluntad, sin coste (permite abortarlo al ver venir un ataque).
- **Los jefes no atacan durante las transiciones de fase (≥ 1,5 s)**: caben dos sorbos justos. Con 3 a 5 frascos, un jefe permite una o dos curaciones planificadas.
- Descansar en un Ancla o morir recarga todo, como hoy.
- Técnica: `HealthComponent` gana `heal_amount` (0 = cura del todo, compatible con el uso genérico y con las pruebas actuales), `heal_time`, `begin_heal()` y cancelación por daño; `use_heal_charge()` sigue siendo la aplicación instantánea (la llama el final del sorbo). Estos exports son genéricos y caben en `core/`.

### Vida máxima [Pend.]

```
vida_max = 5 + nivel(Vitalidad) + floor(fragmentos_de_vida / 4) + (Trapo de Iria equipado ? 1 : 0)      # tope absoluto 13
```

Hay **12 fragmentos de vida** (cada 4 dan +1, es decir +3 en total) repartidos por exploración: 4 visibles, 4 de plataformas, 3 secretos (pared falsa o Excavar) y 1 tras un reto de combate opcional. Reparto por región orientativo: Umbral 1 (tras La Puerta Tapiada, se cierra la cuenta a las ~11:30), Cinturón 3, Archivo 3, Minas 3, Costa 2, Herida 0 (la última región no regala margen). Cadencia: 4.º a ~6:15, 8.º a ~9:00, 12.º a ~11:30, siempre antes de un hito emocional y nunca en las dos primeras horas. Se anuncian "Fragmento de vida 2/4" y el contador vive en el diario.

## Árbol de habilidades [Impl. el esqueleto; Pend. la ampliación]

Se abre desde el menú del Ancla (**Z** para descansar, primera opción). Se gastan Ecos, el juego se pausa y las mejoras son permanentes (morir no las pierde, los Ecos en la mano sí). Comprar vida o frascos los rellena. El componente genérico es `SkillTree` (`core/components/skill_tree.gd`); lo propio del juego vive en `game/player/skills.gd`.

**Se conservan los 9 ids actuales y sus niveles** (las partidas guardadas guardan niveles, no costes, y siguen siendo válidas) y se añaden **5 mejoras nuevas**. Quedan **14 mejoras, 29 niveles y 1.800 Ecos** (hoy 9, 22 y 310). La sala original proponía 21 mejoras, 43 niveles y 2.180 Ecos; se recortaron Sorbo, Fortaleza, Rompecorazas, Peso, Desvío, Latido y Asidero (motivos en el documento de decisiones): o eran de poco efecto, o los cubría una reliquia, o exigían una pieza de motor para una sola mejora.

Un nodo pide, además de Ecos, su **mejora previa** (a un nivel mínimo) y a veces una **puerta de historia** (un jefe vencido o una habilidad), que se explica en el menú sin revelar recorrido ("Lo aprendes del Segador cuando lo venzas").

### Rama Cuerpo (5 mejoras, 11 niveles, 670 Ecos)

| Mejora | Niveles | Efecto por nivel | Coste por nivel (hoy → final) | Requiere | Puerta | Estado |
|---|---|---|---|---|---|---|
| Vitalidad | 4 | +1 vida máxima (5 → 9) | 5/8/12/18 → **10/25/50/85** (170) | — | — | [Impl.] efecto; costes [Pend.] |
| Frascos | 2 | +1 frasco (3 → 5) | 10/18 → **30/65** (95) | Vitalidad | — | [Impl.]; costes [Pend.] |
| Temple | 2 | Invulnerable tras un golpe 0,6 → 0,8 → 1,0 s | 14/24 → **35/60** (95) | Frascos | — | [Impl.]; costes [Pend.] |
| Aliento | 2 | Cura por frasco +1 (3 → 4 → 5) | **50/100** (150) | Frascos | — | [Pend.] nuevo |
| Brasa | 1 | Una vez por descanso: si un golpe te mataría y tenías ≥ 3 de vida, quedas a 1 con 1,2 s de invulnerabilidad. No vale contra caídas ni pinchos | **160** | Vitalidad nivel 4 | Hesper vencido | [Pend.] nuevo |

### Rama Filo (4 mejoras, 8 niveles, 510 Ecos)

| Mejora | Niveles | Efecto por nivel | Coste (hoy → final) | Requiere | Puerta | Estado |
|---|---|---|---|---|---|---|
| Filo afilado | 2 | +1 daño por golpe (1 → 3) | 14/30 → **35/110** (145) | — | — | [Impl.]; costes [Pend.] |
| Ritmo | 3 | Espera entre golpes 0,30 → 0,26 → 0,22 → 0,18 s | 8/14/22 → **20/50/90** (160) | Filo afilado | — | [Impl.]; costes [Pend.] |
| Alcance | 2 | +6 px por nivel (20 → 32) | 10/18 → **30/55** (85) | Ritmo | — | [Impl.]; costes [Pend.] |
| Castigo | 1 | +1 daño al golpear a un enemigo **común** en su recuperación (tras fallar su ataque). **No afecta a jefes** | **120** | Ritmo nivel 2 | Jacinto vencido | [Pend.] nuevo |

El daño del árbol tiene tope 3. Las mejoras nuevas de Filo cambian *cómo* se pelea (castigar a destiempo), no *cuánto*.

### Rama Espíritu (5 mejoras, 10 niveles, 620 Ecos)

| Mejora | Niveles | Efecto por nivel | Coste (hoy → final) | Requiere | Puerta | Estado |
|---|---|---|---|---|---|---|
| Guardia | 3 | Ventana del parry 0,20 → 0,25 → 0,30 → 0,35 s | 6/10/15 → **15/35/65** (115) | — | — | [Impl.]; costes [Pend.] |
| Impulso | 2 | Espera del dash 0,40 → 0,32 → 0,24 s | 8/14 → **25/50** (75) | Guardia | — | [Impl.]; costes [Pend.] |
| Contragolpe | 2 | Enemigo desviado aturdido +0,5 / +1,0 s (1,2 → 2,2 s) | 12/20 → **40/80** (120) | Impulso | — | [Impl.]; costes [Pend.] |
| Paso fantasma | 2 | El dash te hace invulnerable el 35 % / 60 % de su duración (0,05 / 0,09 s). No cruza paredes ni pinchos | **60/110** (170) | Impulso | Tener el Dash | [Pend.] nuevo |
| Voz | 1 | Con Nombrar, en combate: aturde 2 s a un vaciado (cascarón, lancero...) cercano; espera de 25 s. **No afecta a jefes** | **140** | Contragolpe | Tener Nombrar | [Pend.] nuevo **[Recorte]** (el canon marca los usos de combate de Nombrar como lo primero que cae) |

Las tolerancias de Paso fantasma son de ejecución, no de alcance: no crean atajos en las salas diseñadas con las cifras base.

### Vista del árbol

Pasa de 3×3 a 3 columnas × hasta 5 filas (cabe sin desplazamiento en 864×486): Cuerpo 5 filas, Filo 4, Espíritu 5 (Paso fantasma cuelga de Impulso y Voz de Contragolpe). Cada nodo muestra "antes → después" (ya lo hace `Skills.describe`) y, si falta algo, qué (Ecos, mejora previa o puerta). Comprar pide una segunda pulsación de confirmar. Técnica: `SkillTree.define()` admite el nivel mínimo del requisito y una puerta resuelta por el dueño.

### Topes absolutos [Pend.]

`Skills.stat(id, nivel)` sigue siendo la única fuente del árbol; las reliquias y los fragmentos aplican modificaciones **después** y el resultado pasa por `clamp()` al tope de esta tabla (la prueba de humo verifica cada tope con todo comprado y todas las reliquias simuladas).

| Estadística | Base | Máximo del árbol | Qué más suma | Tope absoluto |
|---|---|---|---|---|
| Vida máxima | 5 | 9 | +3 fragmentos, +1 Trapo | **13** |
| Frascos | 3 | 5 | — | **5** |
| Cura por frasco | 3 | 5 | — | **5** |
| Tiempo de sorbo | 0,70 s | 0,70 s | Aguja −0,25 s | suelo **0,30 s** |
| Daño por golpe | 1 | 3 | Garrán +1, Pesa +1 | **5** (Castigo y Diente suman solo contra comunes) |
| Espera entre golpes | 0,30 s | 0,18 s | Pesa +0,12 s | suelo **0,16 s** |
| Alcance | 20 px | 32 px | — | **32 px** |
| Invulnerabilidad tras golpe | 0,6 s | 1,0 s | — | **1,0 s** |
| Ventana de parry | 0,20 s | 0,35 s | — | **0,35 s** (el aviso mínimo es 0,28 s) |
| Aturdimiento del parry | 1,2 s | 2,2 s | Corona +0,4 s | **2,6 s** |
| Espera del dash | 0,40 s | 0,24 s | Insignia −0,10 s | suelo **0,15 s** |
| Ranuras de reliquia | 3 | — | +1 por Sello (3) | **6** |

## Forja de Garrán [Pend.]

Canon: una sola mejora, a cambio del hierro de la Veta Tapiada (se pica con Excavar). **Filo Hondo**: el tope de daño del árbol sube de 3 a **4**. Cuesta **150 Ecos** y se hace entre las 9:30 y las 10:30 (antes de que "se hunda la fragua"). Si falta (o Garrán muere, que es perdible), se pierde 1 de daño frente al "ideal", nunca frente a lo exigido: **todos los jefes se pueden vencer sin Garrán**. Con él, la pelea baja un 20-25 %. Texto del menú: "Garrán te devuelve el Filo con un temple nuevo."

## Reliquias y ranuras [Pend.]

Amuletos que se llevan puestos. Nada de maldiciones ni de más de una cifra por reliquia.

- **Ranuras**: 3 desde la primera reliquia (~1:00); **+1 por cada Sello** conseguido (Cera con Hesper, Piedra con Magda, Cal con Eudora): 6 como máximo. Cada reliquia ocupa **1 o 2 ranuras**. No hay Nombres que den ranuras (el canon lo prohíbe).
- **Solo se cambian descansando** en un Ancla (opción "Reliquias", tras el árbol); en la pausa se ven pero no se editan. Las no halladas se muestran como siluetas grises con "???".
- Hay **16 reliquias**: las 15 del canon (`textos-del-juego.md` §7) con efecto asignado, más la **Hebra de Cal** (Casilda promete "una reliquia" y el canon no la tenía). Se descartaron las 6 reliquias nuevas que proponía la sala (Hoz mellada, Clavo de Cano, Piedra menor de Linde, Brújula de Mirena, Pizarra de Brunel, Moneda sin cara).

| # | Reliquia | Ranuras | Efecto | Dónde | Estado |
|---|---|---|---|---|---|
| 1 | Aguja del Escriba | 1 | Sorbo −0,25 s (0,70 → 0,45 s) | Archivo, Scriptorium (~5:30) | [Pend.] |
| 2 | Dedal de la Torre | 1 | Cada 25 s, un golpe de **1** de daño no te hiere. Se queda corto en cuanto el enemigo pega 2: amuleto de principio de viaje | Torre de Riego (~3:30) | [Pend.] |
| 3 | Medalla del Umbral | 1 | Al morir **conservas el 25 %** de tus Ecos | Cano, 50 Ecos (o Umbral oculto) | [Pend.] |
| 4 | Trapo de Iria | 2 | **+1 vida máxima** (tope 13) | Iria, tras el trompo y el zapato (~10:50) | [Pend.] |
| 5 | Lacre de silencio | 1 | Los enemigos te detectan desde −30 % de distancia | Gaspar, tras retirar tres sellos (~6:30) | [Pend.] |
| 6 | Diente de la Mina | 2 | +1 de daño contra criaturas "duras" (Colosos, Geodas, Chinches, armaduras) | Minas (~8:00) | [Pend.] |
| 7 | Cuenta del Rosario | 1 | Una vez por descanso, si caes a un foso o pinchos que te matarían, quedas a 1 de vida en el último suelo firme | Foso de las Terrazas, escondida (~1:00) | [Pend.] |
| 8 | Campanilla de la Costa | 1 | Flecha en el borde de la pantalla hacia enemigos a menos de 18 baldosas **[Recorte]** | Costa (~10:00) | [Pend.] |
| 9 | Pesa del Archivo | 2 | **+1 de daño y +0,12 s de espera** entre golpes (golpe lento, golpe fuerte) | Archivo (~6:15) | [Pend.] |
| 10 | Pluma sin tinta | 1 | Recoges tu Eco y las Bolsas de Rastro sin pulsar Z, a menos de 3 baldosas | Sabela, tras las 6 Páginas (post-juego) | [Pend.] |
| 11 | Llave sin puerta | 1 | Los muros falsos y suelos frágiles brillan a menos de 6 baldosas | Cano, 60 Ecos (o Umbral) | [Pend.] |
| 12 | Corona sin Reina | 2 | Enemigo desviado aturdido +0,4 s (tope 2,6 s) | Casimar (opcional, ~8:30) | [Pend.] |
| 13 | Piedra blanca de la Costa | 2 | Un parry exitoso cura **1 vida** (máx. 2 por descanso, 8 s entre curaciones) | Muro Blanco (~10:00) | [Pend.] |
| 14 | Vela del Faro | 1 | Las Anclas de salas ya visitadas aparecen en el minimapa aunque no estén cerca | Rufo (opcional, ~10:00) | [Pend.] |
| 15 | Insignia de Mensajera | 1 | Espera del dash −0,10 s. Es la **llave del epílogo del Relevo** (se puede desequipar) | Oda (secreto, ~14:00) | [Pend.] |
| 16 | Hebra de Cal | 1 | Recuperar tu Eco te cura **2 vidas** | Casilda (~10:30) | [Pend.] |

Equilibrio: ninguna reliquia es estrictamente mejor que otra (las más fuertes ocupan 2 de las 6 ranuras); ninguna abre ni cierra caminos del camino principal; cada combo tiene un hueco (Pesa + Piedra blanca pegan y curan pero no dejan sitio a nada más). Las tres "de maestría" (Piedra blanca, Insignia, Corona) premian dominar el parry y el dash. Las reliquias de las que dependen sistemas aún inexistentes (Campanilla, Llave sin puerta) se implementan las últimas; si no, se sustituyen por "+0,1 s de invulnerabilidad" a igual coste.

Orden de implementación sugerido para la primera versión (10 reliquias, las que no exigen sistemas nuevos): Cuenta, Dedal, Medalla, Aguja, Pesa, Lacre, Diente, Piedra blanca, Hebra, Trapo.

## Los Nombres y el Paño, en lo mecánico [Pend.]

El canon fija el sistema en `guion-maestro.md` §10; aquí solo lo que toca a los números.

**Pronunciarlos (leerlos).** Hay 30 (5 por región; 28 alcanzables sin jefes opcionales). Se leen en inscripciones, objetos y PNJ, pasan al **diario de la pausa** ("Umbral 3/5") y son progreso permanente. **Al descansar en un Ancla se pronuncian** ("Pronuncias los nombres. Nuevos: {lista}."): no hay menú ni efecto de curación extra. **No dan Ecos, ni vida, ni daño, ni ranuras**: sirven para el diario, para el final **Compartir** (20 de 30 *sostenidos* y la habilidad Nombrar) y para los epílogos. Es una decisión consciente: el Nombre no es un mejorable, es una persona.

**Callarlos (el Paño).** Se recibe tras el sueño con Quiteria (o tras Eudora si se rechazó), desde unas 10:15-10:50. En el menú del Ancla aparece **"Callar un nombre"**:

| Aspecto | Valor |
|---|---|
| Qué da | **50 Ecos** por Nombre silenciado (un nivel medio del árbol, que cuesta 35-110) |
| Qué cuesta | Deja de contar como sostenido, su fuente se lee "en blanco" para siempre y Aldara lo nota (un nudo menos). **Nunca vuelve** |
| Qué no hace | No cambia combate ni mapa; el protagonista sigue sabiéndolo |
| Confirmación | "Es para siempre." Botón por defecto: "No". Muestra el contador: "Sostenidos: 24 → 23 (hacen falta 20)" y avisa si ya no se podría llegar a 20 |
| Límite natural | Con 28 alcanzables y 20 necesarios se pueden callar hasta 8 sin perder el final (hasta 10 con 30): 400-500 Ecos como máximo. No hace falta ningún tope artificial |
| Ajuste | Si en las pruebas nadie calla, sube el pago; si todos callan, baja. Es el único número del sistema |

Se descartó que los Nombres leídos den ranuras ("Hilos"): contradecía el canon y creaba una segunda forma de poder ligada a un coleccionable narrativo.

## Ecos, muerte y economía

### Ecos y muerte [Impl.]

Los enemigos derrotados sueltan **Ecos** (fragmentos de memoria ajena). Al morir, el jugador reaparece con vida y curaciones al máximo y pierde todos sus Ecos, que quedan marcados como **un Eco de sí mismo** en la última posición en que pisó suelo firme (no en el punto de muerte, para que una caída no deje el Eco inalcanzable). El Eco no es hostil: se recupera acercándose y pulsando interactuar (**Z**, o **Y / Triángulo**). Si el jugador muere otra vez antes de llegar a él, ese Eco anterior (y sus Ecos) se pierde para siempre. El Eco aparece siempre al morir, aunque no se llevaran Ecos (sirve de señal de "aquí moriste"; el mapa lo marca en violeta). Se probó un Eco hostil y se descartó.

Ajustes de muerte [Pend.]: la reliquia Medalla (conserva el 25 %), la Hebra de Cal (recuperarlo cura 2) y la Pluma sin tinta (recogida automática). **No hay límite de Ecos llevables** (el riesgo de acumular es parte del diseño) **ni fatiga del Rastro** (anti-farmeo): se añade la regla "100 % la primera vez y 50 % en reapariciones, en memoria, sin guardado" solo si el playtest demuestra farmeo.

### Fuentes [Pend. salvo los enemigos]

| Fuente | Cantidad | Regla |
|---|---|---|
| Enemigos [Impl.] | `ecos_reward` por escena: Cinturón 2/3/8 (común/medio/élite), Archivo 3-5/10, Minas 4-5/12, Costa 5-6/13, Herida 6/15 | Reaparecen con cada descanso o muerte, sin fatiga |
| Jefes | Fijo, una vez: Centinela 40 [Impl.], Jacinto 60, Ilara 80, Hesper 110, Magda 140, Eudora 160, Maelis 200 (**790** obligatorios); Casimar 90, Rufo 90, Oda 150 (330 opcionales) | Quedan guardados (`bosses`) |
| **Bolsas de Rastro** | ~24 repartidas, 12 a 30 Ecos | Montón de polvo gris que se pulsa; se guarda cuál se recogió; no reaparecen. Comparten sistema con los fragmentos |
| El Paño | 50 por Nombre callado, hasta 400-500 | Una vez por Nombre |
| Venta de objetos | No existe | Evita la hoja de cálculo |

### Sumideros

| Sumidero | Ecos |
|---|---|
| Árbol de habilidades | **1.800** (Cuerpo 670, Filo 510, Espíritu 620) |
| Garrán (Filo Hondo) | 150, opcional |
| Cano (Medalla 50, Llave sin puerta 60) | 110, opcional |
| Barca de Mirena | gratis (Mirena "cobra y calla" solo en el diálogo) |
| **Total** | **2.060** |

Regla de precio: una compra cuesta entre 4 y 12 enemigos de la región actual; nunca más de 160 de una vez (Garrán, 150). Los precios no suben con las compras de otro tipo. El jugador completo no tiene dónde gastar al final, a propósito.

### Presupuesto y su invariante

El total comprable está **cerrado y es público** (el diario del árbol muestra "Llevas 1.340 de 1.800"). El invariante que se vigila con una prueba (T20) es que la suma de Ecos del camino principal bruto (enemigos de la primera pasada con un 10 % por rondas, jefes obligatorios, Bolsas del camino) caiga entre el **90 % y el 110 %** del coste de los sumideros del camino principal (~2.000-2.300 brutos), con ~10 % perdido por Ecos no recuperados. Los números reales dependen de cuántos enemigos tengan los mapas definitivos (la sala original supuso 216 apariciones; el mapa macro sugiere más bien 100-130): **el ajuste se hace en los Ecos por enemigo y en las Bolsas, no en los precios**, y se recalcula al terminar cada región. A las 13 h el jugador medio ha comprado ~90 % del árbol; quien calla Nombres lo cierra del todo.

## Anclas de Memoria [Impl.]

Un objeto curativo de usos limitados (el frasco) que se recarga solo en los puntos de descanso. Las Anclas:

- Sirven de punto de guardado: al cargar se aparece en la última en la que se descansó.
- Se activan **a propósito** con el botón Z (no al pasar por encima) y muestran "Z: Recordar" al estar al alcance. Descansar es una parada, no un accidente.
- Al usarlas, reinician (respawnean) a los enemigos normales y los jefes no derrotados. Los enemigos también reaparecen al morir. Hoy se reinician **todos** los enemigos del mundo; limitarlo a la región del Ancla queda para cuando el mundo crezca.
- Su menú muestra solo entradas que existen (regla del proyecto: sin entradas vacías): hoy el árbol; con el tiempo, **Reliquias**, **Callar un nombre** (tras el Paño) y **Decir los nombres** (tras Nombrar).

### Aspecto: el Hito de Nombres

El Ancla es un **hito de piedras apiladas**, cada una con grabado el nombre de alguien que la Desmemoria borró. Los supervivientes lo levantan para que al menos ese nombre siga existiendo. Como el protagonista no puede olvidar, descansar ahí es pronunciar esos nombres en voz alta. No es un banco ni una hoguera, y expresa la premisa en un objeto cotidiano.

## Mapa y viaje

### Mapa [Impl. lo básico]

Descubrimiento baldosa a baldosa alrededor del jugador (12 baldosas), minimapa en el HUD y mapa completo en la pausa, con marcadores de Ancla y de Eco (violeta). No hay cartógrafa ni mapas de pago (el canon los eliminó) **ni planos pintados** (se descartaron: el mapa se rellena solo y no hace falta nada que lo sustituya). **[Pend., prioridad baja]**: icono de **candado** automático al ver una puerta, pared o foso que pide una habilidad que aún no se tiene, y hasta 8 alfileres del jugador de 4 tipos. Las cifras de "Hallazgos" por región, la Brújula y la Pizarra se descartaron.

### Viaje [Pend.]

Sin viaje rápido libre. Rápido, pero por pasos y con sentido:

| Etapa | Qué existe | Cómo se desbloquea | Coste |
|---|---|---|---|
| Actos I-III | **Atajos físicos**: puertas que se abren por un solo lado, ascensores de cuerda, escaleras, rastrillos, y los de Excavar (el Metro, el Pozo de los Cantores...). Cada Ancla debe tener un retorno de ≤ 90 s a pie | Diseño de sala (`01-mapa-macro.md` §5.3) | Nivel (rejas y grietas de `03-puzles`) |
| Acto III | **Barca de Mirena** (Costa ↔ Cauce/pie del Cinturón): plataforma sobre carril con Mirena, **gratis** | Hablarle tras Eudora o tras Rufo, lo que llegue antes | S-M |
| **Acto IV en adelante** | **"Decir los nombres"**: desde cualquier Ancla ya visitada se puede ir al **Hito del Umbral** y, desde él, volver a cualquier Ancla visitada **fuera de la Herida** (sus Anclas "sin nombre" se conquistan a pie) | Se enciende al obtener **Nombrar**. Sin coste, con una animación de 3 s | M |
| Siempre | **"Volver al Ancla"** en el menú de la pausa: igual que morir (los Ecos quedan en un Eco), sin contar como muerte. Válvula contra atascos imprevistos | Siempre; con confirmación | S |

Por qué no antes del acto IV: el diseño de 13 h pide explorar a pie y el atajo físico es la recompensa de abrir una puerta. Por qué sí después: el 100 % (Puerta Tapiada, Pasarela de Oda, fragmentos) exige volver al Cinturón y al Umbral sin repetir 15 minutos de camino. Es un viaje *a través del Hito*: encaja con la premisa (la memoria que conecta lugares) y con el acto IV. "Decir los nombres" nace del menú del Ancla, así que nunca hay enemigos persiguiendo; no existe durante un jefe porque no se descansa en su arena.

## La curva de poder, de 0 a 15 horas

"Personaje razonable": quien explora lo que se cruza, compra primero lo barato y útil y no hace rutas de farmeo. Vida sin Trapo salvo donde se indica. Ranuras = ranuras de reliquia. Dificultad percibida de 1 a 10 (no es daño, es lo que siente el jugador medio). Ecos brutos acumulados, aproximados.

| Hora | Hito | Vida | Frascos / cura | Daño | Ranuras | Movimiento | Ecos brutos | Dif. |
|---|---|---|---|---|---|---|---|---|
| 0:00 | Despertar en el Hito del Umbral | 5 | 3 / 3 | 1 | — | Mover, saltar, Filo, parry | 0 | 2 |
| 0:30 | Primer Ancla; se entiende la premisa | 5 | 3 / 3 | 1 | — | — | 15 | 3 |
| 1:00 | Foso de las Terrazas (se cae a La Cisterna) | 5 | 3 / 3 | 2 | 3 (Cuenta; Cano) | — | 40 | 4 |
| 2:00 | Antes del Aljibe (Ancla) | 7 | 3 / 3 | 2 | 3 | — | 110 | 5 |
| 2:15 | **Centinela Hueco** (jefe 1) | 7 | 3 / 3 | 2 | 3 | **Dash** | 150 | **7** |
| 2:45 | El Mirador: se ve la Herida | 7 | 3 / 3 | 2 | 3 | Dash | 175 | 3 |
| 3:30 | La Torre de Riego (Tomasa) | 7 | 3 / 3 | 2 | 3 (Dedal) | **Doble salto** | 240 | 4 |
| 4:30 | **Jacinto** (jefe 2), La Era | 8 | 4 / 3 | 2 | 3 | **Salto de pared** | 395 | **7** |
| 5:30 | Entrada del Archivo | 8 | 4 / 3 | 2 | 3 (Aguja) | — | 480 | 5 |
| 6:15 | **Sor Ilara** (jefe 3) | 10 | 4 / 4 | 3 | 3 (Pesa) | — | 650 | **7** |
| 7:30 | **Hesper** (jefe 4); Sello de Cera | 10 | 4 / 4 | 3 | 4 | — | 915 | **8** |
| 8:30 | Minas; Casimar (opcional) | 10 | 4 / 4 | 3 | 4 | — | 1.100 | 7 |
| 9:15 | **Magda** (jefe 6); Sello de Piedra | 11 | 5 / 4 | 3 | 5 | **Excavar** | 1.330 | **8** |
| 10:00 | Garrán forja el Filo Hondo (opcional) | 11 | 5 / 5 | 3-4 | 5 | Excavar | 1.500 | 6 |
| 10:50 | **Eudora** (jefe 8); Sello de Cal; el Paño; Trapo | 11 (+1) | 5 / 5 | 3-4 | 6 | Excavar | 2.020 | **8** |
| 11:30 | Vuelta al Umbral; **Nombrar**; Puerta Tapiada (12.º fragmento) | 12 (+1) | 5 / 5 | 3-4 | 6 | **Nombrar** (5) | 2.200 | 3 |
| 12:15 | La Herida: Puerta Sin Muro, Cano | 12 (+1) | 5 / 5 | 3-4 | 6 | Todas | 2.350 | 8 |
| 12:55 | **Maelis** (jefe 9) | 12 (+1) | 5 / 5 | 3-4 | 6 | Todas | 2.550 | **9** |
| 13:00 | Sala de Aún: elección de final | 12 (+1) | 5 / 5 | 3-4 | 6 | Todas | — | 4 |
| 14:00 | Oda, la Última Mensajera (jefe 10, secreto): una carrera | 12 (+1) | 5 / 5 | 4 | 6 | Todas | 3.050 | 7 |
| 15:00 | 100 %: Páginas, Pluma, Insignia | 12 (+1) | 5 / 5 | 4-5 | 6 | Todas | 3.310 | 2 |

Los Ecos de esta tabla son los de la propuesta original (calibrada con 216 apariciones de enemigos): se reescalan con el invariante de presupuesto. La forma de la curva no cambia: dientes de sierra de unas 2,5 h por región (subida, pico en el jefe, respiro con recompensa); el momento más bajo es la vuelta al Umbral (calma y duelo).

### El personaje esperado al llegar a cada jefe

Es el que asume el diseño de ese jefe: árbol comprado en orden razonable, **sin reliquias opcionales, sin Garrán**. "Margen" es lo mínimo con lo que se puede ganar con paciencia (≤ 15 intentos).

| Jefe | Hora | Vida | Frascos / cura | Daño | Espera golpe | Parry | Reliquias típicas | Margen mínimo ganable |
|---|---|---|---|---|---|---|---|---|
| 1 Centinela | 2:15 | 7 | 3 / 3 | 2 | 0,26 | 0,25 s | Cuenta, Medalla | Vida 5, daño 1 (dura más) |
| 2 Jacinto | 4:30 | 8 | 4 / 3 | 2 | 0,26 | 0,25 s | Dedal | Vida 6, daño 2 |
| 3 Ilara | 6:15 | 10 | 4 / 4 | 3 | 0,22 | 0,30 s | Aguja, Pesa | Vida 8, daño 2 |
| 4 Hesper | 7:30 | 10 | 4 / 4 | 3 | 0,22 | 0,30 s | Aguja, Lacre | Vida 8, daño 3 |
| 5 Casimar (opc.) | 8:30 | 10 | 4 / 4 | 3 | 0,22 | 0,30 s | Diente | Vida 9 |
| 6 Magda | 9:15 | 11 | 5 / 4 | 3 | 0,18 | 0,35 s | Diente | Vida 9, daño 3 |
| 7 Rufo (opc.) | 10:00 | 11 | 5 / 5 | 3 | 0,18 | 0,35 s | Campanilla | Vida 10 |
| 8 Eudora | 10:50 | 11 (+1) | 5 / 5 | 3 | 0,18 | 0,35 s | Piedra blanca | Vida 10 |
| 9 Maelis | 12:55 | 12 (+1) | 5 / 5 | 3 | 0,18 | 0,35 s | Cualquiera | Vida 11 |
| 10 Oda (secreto) | 14:00 | — | — | — | — | — | Ninguna: es una carrera de movimiento | Dash + doble salto dominados |

Tiempos objetivo de pelea limpia y número de golpes, vida de cada jefe e intentos esperados: ver la tabla de `jefes.md`. Si el jugador llega con menos, el jefe dura más pero no es imposible; con todo comprado, los jefes duran un 25-40 % menos, que es la recompensa de completar.

## Dificultad por región (objetivo)

| Magnitud | Cinturón | Archivo | Minas | Costa | Herida |
|---|---|---|---|---|---|
| Vida del jugador | 5-8 | 8-10 | 10-11 | 11-12 | 12-13 |
| Daño del jugador | 1-2 | 2-3 | 3 | 3 | 3-4 |
| Vida del enemigo común | 3 | 4-6 | 6-9 | 6-9 | 8-12 |
| Daño del enemigo común | 1 | 1-2 | 1-2 | 1 | 1-2 |
| Golpes para matar (común) | 2 | 2-3 | 2-3 | 2-3 | 3-4 |
| Golpes para morir | 5-8 | 5-7 | 5-6 | 5-6 | 5-6 |
| Aviso (rápido / lento) | 0,30-0,40 s | 0,40-0,60 s | 0,35-0,55 s | 0,35-0,55 s | 0,30-0,50 s |

Un común muere en 2-4 golpes y un élite en 6-10; si algo aguanta más, es minijefe (aviso largo y Ancla cerca). La amenaza crece en **cantidad y combinación**, no en cifras de daño. El aviso baja poco a poco y la ventana máxima de parry (0,35 s) deja el aviso más corto de la Herida a un parry exacto: es el único lugar donde la curva exige maestría.

## Modo asistido y accesibilidad [Pend.]

Un submenú "Ayuda" en Opciones con **interruptores independientes** (no una barra fácil/difícil), cambiables en cualquier momento y sin reiniciar. Sin aviso de culpa, sin cambio de final, sin bloquear logros ni Nombres. Tras 6 muertes seguidas al mismo jefe, el menú de pausa muestra una línea "¿Quieres ajustar la ayuda?" (nunca un cuadro emergente ni activación automática).

| Opción | Valores | Efecto |
|---|---|---|
| Daño recibido | Normal / Reducido | Los golpes de 2 o más hacen 1 menos (los de 1 no bajan: nunca desaparece el daño) |
| Eco seguro | No / Sí | Morir no pierde los Ecos |
| Margen del parry | +0 / +0,05 / +0,10 s | Se suma a la ventana |
| Avisos más largos | ×1 / ×1,25 / ×1,5 | Multiplica el aviso de enemigos y jefes |
| Vida de los jefes | 100 / 80 / 65 % | Mínimo 65 % para que existan las fases |
| Velocidad del juego | 100 / 90 / 80 % | Todo menos el hit stop |
| Marca de aviso | Sí / No | Dibuja la zona con borde grueso: continuo = parable, rayas = no parable |
| Alto contraste de avisos | Sí / No | Cambia amarillo y rojo por una pareja más separada y añade un icono |
| Temblor de cámara | 100 / 50 / 0 % | Mareos |
| Parpadeos | Normal / Atenuados | Fotosensibilidad |
| Olvido sin ocultar la vida | Sí / No | Mantiene el efecto sobre la curación |

Se guardan en `opciones.cfg`. Cada opción se añade cuando el efecto existe (regla del proyecto: no poner opciones que no hacen nada). El remapeo de botones se trata aparte. Se descartaron el "frasco extra" (lo cubre el árbol) y el aviso sonoro adicional. El buffer de pulsación (0,12 s) es corrección para todos, no ayuda.

## Post-juego

Canon (`guion-maestro.md` §13): una sola partida debe poder verlo todo; no hay segundos mapas ni finales ocultos.

| Elemento | Qué es | Coste | Estado |
|---|---|---|---|
| Continuar tras la Sala de Aún | Tras el final, "Continuar" carga la última Ancla (antes de la Sala) para completar Nombres, Páginas, opcionales y el secreto de Oda | S (ya es el comportamiento) | [Impl.] de hecho |
| Estadísticas | Tiempo de juego, muertes, Ecos totales y % de "Completado" (un solo porcentaje: salas, jefes, Nombres, habilidades, reliquias, árbol, fragmentos, Páginas) | S | [Pend.] |
| Logros narrativos | Los del canon ("Pronunciaste todos los nombres", "Llegaste al Mirador sin morir", "Relevo") y pocos más. Sin recompensa mecánica | S | [Pend.] |
| Modo sin Ecos | Los Ecos no se recuperan al morir. Marca "Camino del Olvido" en el título | S | [Pend.] |
| Nuevo Ciclo | Conserva habilidades, árbol, reliquias, Nombres y mapa; jefes y fragmentos reaparecen; enemigos y jefes con +50 % de vida y +1 de daño; los PNJ no te reconocen. Sin tienda del ciclo | M | [Pend.] **[Recorte]** |

Se descartaron las Memorias de jefe, las Pruebas de la Pasarela y los dos porcentajes de progreso ("Camino" y "Completado": basta uno).

## Guardado [Impl.]

Automático, como en Hollow Knight: no hay botón de guardar. La partida se guarda al **cambiar de sala**, al **descansar en un Ancla** (y al comprar una mejora en ella), al **reaparecer tras morir** y al **salir del juego**.

Al elegir **Continuar** en el menú principal se carga y se aparece en la **última Ancla en la que se descansó** (o al principio, si aún no se ha descansado en ninguna), con la vida y las curaciones completas, no en el sitio exacto donde se dejó: así cada sesión empieza en un lugar seguro y conocido, y descansar sigue importando.

Se guarda hoy: habilidades, Ecos, niveles del árbol, lo explorado del mapa (baldosa a baldosa), las salas visitadas, jefes vencidos, la última Ancla y el Eco de la última muerte (dónde está y cuántos Ecos guarda). No se guarda: los enemigos (reaparecen) ni las urnas rotas (son decoración). Los recuerdos de habilidades ya conseguidas no vuelven a aparecer.

Técnica: un JSON (`user://partida.json`; en Windows, `%APPDATA%\Godot\app_userdata\Proyecto Souls2D\`). Una partida ilegible o de una versión incompatible se ignora y se empieza de cero; si el Ancla guardada ya no existe se aparece al principio conservando el resto. Las pruebas usan otro archivo.

### Claves nuevas [Pend.]

**No se sube `FORMAT_VERSION`** (subirla descartaría las partidas existentes): todas las claves nuevas son opcionales y una partida sin ellas carga con los valores iniciales. Los ids desconocidos se ignoran, como ya hace el árbol.

| Clave | Contenido | Si falta |
|---|---|---|
| `skills` | Niveles (ya existe); ids nuevos incluidos; se recortan al máximo | niveles 0 |
| `fragments` | Ids de fragmentos de vida recogidos | `[]` |
| `bags` | Ids de Bolsas de Rastro recogidas | `[]` |
| `relics` | `{ owned: [...], equipped: [...] }` | vacío |
| `names` | `{ read: [...], silenced: [...] }` | vacío |
| `forge` | `{ iron: bool, filo_hondo: bool }` | `false` |
| `flags` | Marcas permanentes de mundo (ids `prefijo:sala.objeto`, de `03-puzles` M1) | vacío |
| `stats` | `{ time, deaths }` | 0 |
| `cycle` | Número de ciclo | 1 |

Las ranuras no se guardan: se calculan (3 + Sellos conseguidos). La fatiga, los alfileres y los planos no existen.

## Menú principal [Impl.]

El juego arranca en un menú principal (`game/ui/title_screen.tscn`):

- **Continuar** — carga la partida; desactivado si no hay ninguna.
- **Nuevo juego** — empieza de cero; si ya hay partida, pide confirmación con el "no" por defecto.
- **Opciones** — por ahora solo pantalla completa (`user://opciones.cfg`). Lo demás se añade cuando existe.
- **Salir**.

Desde la pausa, **Menú principal** guarda y vuelve. La pausa tendrá además las pestañas Estado, Recuerdos, Reliquias, Nombres que sostienes y Estadísticas [Pend.], y la entrada "Volver al Ancla".

## HUD [Impl. lo básico]

Vida en segmentos (una sola fila, hasta 13 placas de 16 px caben de sobra en 864 px), frascos debajo (hasta 5), Ecos y minimapa. [Pend.]: icono de "bebiendo" del frasco, indicador de estado (Lento, Fijado, Olvido), barra de jefe con armadura y núcleo (ya existe para el Centinela) y con Calma (Eudora) o partes (Maelis).

## Qué falta y en qué orden se construye

El orden detallado por dependencias, con costes S/M/L, está en `docs/reunion/disenadores/DECISIONES-EDITOR-SISTEMAS.md`. Resumen:

1. **Combate legible y frasco** (aviso rojo, sorbo, topes de estadísticas, lienzo 112×96, ataque arriba y abajo). Bloquea la calibración de todo lo demás.
2. **Economía legible** (fragmentos y Bolsas con id guardado, fórmula de vida máxima, precios nuevos).
3. **Árbol ampliado** y sus efectos.
4. **Reliquias y ranuras**, con Cano y Garrán.
5. **Nombres, diario y Paño.**
6. **Viaje** (barca, "Decir los nombres", "Volver al Ancla") y estadísticas.
7. **Ayuda y post-juego.**

Orden de recorte si falta alcance (primero lo primero): Nuevo Ciclo, Voz, Campanilla y Llave sin puerta, alfileres y candados del mapa, la barra de armadura/Calma/partes (que se simplifica a una barra), Garrán, Cano, Brasa. **Nunca**: el frasco rediseñado, los ataques arriba y abajo, el aviso rojo, Aliento, las cinco habilidades del canon.

Sigue vigente, además: reinicio de enemigos por región, jugar a mano el jefe y el puzle del dash para ajustar, y capas de colisión cuando crezca el número de entidades.
