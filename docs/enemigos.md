# Enemigos (documento vivo)

Estado: los cinco enemigos del primer tramo están construidos y probados; el resto del bestiario está diseñado y **sin construir**. Este documento es la versión unificada tras la reunión de diseñadores: parte de la propuesta de `docs/reunion/disenadores/04-combate-enemigos-jefes.md` (§2 y §8, que conserva el detalle largo de cada ficha) y de `docs/reunion/artistas/05-criaturas-y-jefes.md` (lectura visual y tipos de cuerpo), y la **recorta** al alcance de una sola persona. Los jefes están en `jefes.md`; las reglas de combate del jugador y la economía, en `nucleo-jugable.md`.

Leyenda: **[Impl.]** construido · **[Pend.]** pendiente. En las tablas, **P** = aviso amarillo (se puede parar) y **R** = aviso rojo (solo esquivar). Vidas dadas con el daño esperado de la región (ver `nucleo-jugable.md`); todas las cifras se ajustan jugando.

## Resumen del recorte

La propuesta original tenía 28 comunes, 5 élites, 5 minijefes y 30 combinaciones (48 entradas con los 10 jefes), unos 196 puntos de arte y 6 tipos de cuerpo nuevos. Se queda en:

| | Propuesta | Final | Qué cae |
|---|---|---|---|
| Comunes | 28 (5 existentes + 23) | **20** (5 existentes + 15 nuevos) | Mastín sin Amo, Pez de Plata, Murciélago de Cueva, Gusano de Veta, Vela Errante, Cangrejo Ermitaño, Contorno, Quimera de Rastros |
| Élites | 5 | **5** | — (son variantes baratas: escala, paleta y un rasgo) |
| Minijefes | 5 | **2** | La Yunta, Madre de Veta, el Ermitaño Mayor |
| Jefes | 10 | **10** | — (los 7 obligatorios no se tocan; los opcionales y el secreto se construyen los últimos) |
| Combinaciones de encuentro | 30 | **21** | Las que usaban enemigos descartados |
| Tipos de cuerpo | 6 nuevos | **3 + objetos animados** | Segmentado (S) y multiparte (P) como tipo reutilizable; el multiparte solo para Maelis |

Criterio: cada enemigo se queda si enseña un verbo de combate que ningún otro enseña o si es barato (humanoide con arma nueva); cae si su única aportación era un cuerpo nuevo caro (cuadrúpedo, segmentado, multiparte) o si otro enemigo ya cubre su verbo (el acechador cubre el mastín; la Armadura Vacía, el Cangrejo; la Polilla, el Murciélago). El resultado son unos 123-138 puntos de arte, en línea con el "mínimo viable" de los artistas (~140). La Herida **reconstruye fragmentos de regiones anteriores** (canon): reutiliza enemigos ya construidos en sus combinaciones, que es otro ahorro.

## Reglas de legibilidad

Contrato con el jugador. Si un ataque las rompe, se rediseña el ataque, no la regla.

1. **Todo daño tiene aviso.** Aviso visual (tinte de color y pose del arma o miembro) más sonido. Mínimos (fase 1; en fases 2 y 3 se acorta hasta un 25 %, **nunca por debajo del mínimo de su fila**):

   | Daño | Golpe único rápido | Con zona o proyectil | Remate |
   |---|---|---|---|
   | 1 | 0,28 s | 0,40 s | — |
   | 2 | 0,55 s | 0,70 s | 0,90 s |
   | 3 | no existe salvo remate | — | 1,10 s |

2. **Código de color.** **Amarillo** [Impl.] = se puede esquivar o parar. **Rojo** [Pend.] = **no se puede parar**: agarres, suelo que se rompe, luz, áreas, golpes de cuerpo entero. **Cian** [Impl.] = estado de debilidad (aturdido). Un atributo `parryable` por ataque basta; sin esta distinción el parry sería la respuesta a todo.
3. **El rojo nunca va solo en la pose.** Todo aviso rojo pinta además una **marca en el suelo** (decal de borde recto y bandas diagonales para quien no distingue colores) y suena grave y sostenido; el amarillo suena corto y agudo.
4. **El aviso es una capa de código, no un píxel del sprite.** El amarillo y el rojo son un tinte aditivo y una marca de suelo (hoy `visual.modulate`; un shader parametrizable cuando exista el pipeline de arte): los sprites no llevan ámbar de peligro (el ámbar es memoria) ni rojo grande, y el modo de alto contraste es cambiar un parámetro.
5. **La pose acompaña (regla de la simetría), la marca decide.** Por defecto, un ataque parable se anuncia con una silueta **asimétrica** (arma echada atrás, un solo brazo) y uno no parable con una silueta **simétrica y ensanchada** (los dos brazos arriba, el cuerpo entero). Es una guía de dibujo, no una ley: las excepciones (la Vuelta amplia de Jacinto, la Mano abierta de Eudora, el Cetro de Casimar) se resuelven con la marca y la estela, y la regla se prueba con un jugador que no conozca el diseño. El `parryable` del código es lo que manda.
6. **Los enemigos no dañan por contacto** y no se dañan entre sí (golpean solo al grupo `player`). Las excepciones son explosiones y zonas declaradas (Zapador).
7. **Quien ataca se queda vulnerable:** recuperación ≥ 0,5 s (enemigos). Es la recompensa de leer bien.
8. **Cada ataque tiene al menos dos respuestas válidas** (salto o dash, parry o distancia) y la arena se lee de un vistazo.
9. **Lo que el jugador aún no sabe hacer no se le pide.** Y **cada enemigo nuevo se presenta solo, después en pareja y por fin en grupo.**
10. **Un volador no se coloca hasta que el ataque hacia arriba existe y se siente bien.**
11. El rojo en enemigos son detalles de 2-8 píxeles (vendas, lacre, pupila): un enemigo *lleva* rojo, no *es* rojo. Los no hostiles de cuerpo (Acompañante, Eudora, Oda) no llevan un píxel de rojo: su amenaza es de zona o estado y se ve en el suelo.

## El enemigo base [Impl.]

Todos los enemigos comparten `game/enemy/enemy.gd` y se diferencian por su escena (hoja de sprites, vida, alcance, tiempos) y por `attack_kind` (MELEE, PROJECTILE, LUNGE).

- `PatrolChaseAI`: estados PATROL, CHASE, WINDUP (aviso), RECOVER. Patrulla a 60 px de su origen, te detecta a 220 px (según la escena) si estás a una altura parecida (80 px), te persigue más rápido de lo que patrulla y no se cae por los bordes. Solo actúa dentro de su sala y a 4 baldosas de las puertas.
- Un golpe tuyo lo empuja y cancela su ataque; un parry lo aturde `parry_stun_time` (1,2 s, más el Contragolpe) y recibe doble daño.
- Número de daño flotante, chispa, barra de vida que se oculta sola, hit stop 0,06 s, pose de encajar el golpe, voz propia (`voice`) y sonidos de paso y golpe.
- Reaparecen al descansar o morir (`EntitySpawner`); pagan `ecos_reward`.

## El bestiario por región

Ecos de partida por banda: Cinturón 2/3/8 (común/medio/élite), Archivo 3-5/10, Minas 4-5/12, Costa 5-6/13, Herida 6/15. "Cuerpo" es el tipo de rig: **H** humanoide con estilo nuevo, **A** armadura vacía, **V** volador, **O** objeto animado (hoja pequeña dibujada a mano, sin rig). "Motor" es la pieza que necesita (ver más abajo).

### El Último Umbral y el Cinturón Yermo (0-5 h)

Región de la primera lección: lee el aviso, esquiva o para, entra en el hueco. El Umbral casi no tiene enemigos (cascarones sueltos).

| Enemigo | Vida | Daño | Ataque: aviso / recuperación | Tipo | Cómo se contrapone | Cuerpo · IA y motor | Ecos | Estado |
|---|---|---|---|---|---|---|---|---|
| **Cascarón** | 3 | 1 | Tajo corto: 0,30 / 0,5 s | P | Parry, dash por detrás, retroceso | H · `PatrolChaseAI` | 2 | [Impl.] |
| **Lancero** | 4 | 1 | Estocada larga (alcance 84): 0,42 / 0,6 s | P | Entrar tras la estocada; el parry exige timing por el alcance | H · MELEE | 3 | [Impl.] |
| **Arrojador** | 2 | 1 | Proyectil recto (a 240 px): 0,50 / 0,8 s; mantiene distancia | P | Saltar el proyectil, dash a través, parry | H · PROJECTILE | 3 | [Impl.] |
| **Acechador** | 3 | 1 | Embestida desde 150 px (215 px/s): 0,28 / 0,65 s | P | Saltar por encima, parry (ventana corta) | H · LUNGE | 3 | [Impl.] |
| **Coloso** | 10 | 2 | Mazazo: 0,72 / 1,0 s; 78 px/s | P | Parry (premia: 1,2 s de doble daño), dash por detrás | H · MELEE | 8 | [Impl.] |
| **Cuervo de Rastrojo** | 2 | 1 | Vuela a ~90 px de altura; picado a 260 px/s: 0,45 s, pausa de 1,2 s entre picados | P | Ataque hacia arriba, parry en el picado, dash lateral | V · `fly_ai` | 2 | [Pend.] |
| **Espantapájaros** | 4 | 1 | Inmóvil hasta que pasas a 100 px; se levanta (1,0 s, sin daño) y avanza lento; golpe de brazo: 0,65 s | P | Rodearlo mientras se levanta; es la **emboscada** (tres falsos entre los verdaderos en La Era) | H · estado DORMANT | 3 | [Pend.] |

**Élite: Segador Vaciado** (variante del cascarón; vida 7, hoz larga, solo en los bancales altos, examen de entrada a La Era). Barrido en arco alto-bajo (alcance 90): 0,60 s, daño 1, **P**; cada 12 s un paso de segador con 0,40 s. Entrar por dentro, pegado a él, evita el arco (anticipa la lección de Jacinto). Ecos 12. Cuerpo H, MELEE con hitbox de arco (ya existe). [Pend.]

**Combinaciones del Cinturón** (5):

| # | Encuentro | Dónde | Lección |
|---|---|---|---|
| C1 | Cascarón + cascarón escalonados 12 baldosas | Camino de las Terrazas | Primer 1 contra 1, luego 1 contra 2 con espacio |
| C2 | Lancero en el suelo + arrojador en el tablón | La Cisterna | Dos alturas: el lancero cierra el suelo, el arrojador cobra por ir al tablón |
| C3 | Acechador + cascarón en un pasillo con un foso | Bancales | Gestionar la presión; el foso fuerza el salto |
| C4 | Cuervo + arrojador + espantapájaros durmiente | Bancal con andamios | Mirar arriba, abajo y alrededor |
| C5 | Coloso + acechador detrás; el Segador como examen previo a La Era | Galería larga | El coloso se para (hueco de 1,2 s) pero el acechador te saca de posición |

### El Archivo (5-7,5 h)

Selladores, Penitentes y vaciados del oficio. Clave de sala: pasillos en blanco junto a salas intactas. Verbos nuevos: parry y prioridades.

| Enemigo | Vida | Daño | Ataque: aviso / recuperación | Tipo | Cómo se contrapone | Cuerpo · IA y motor | Ecos | Estado |
|---|---|---|---|---|---|---|---|---|
| **Novicio Borrado** | 4 | 1 | Estocada de pluma (alcance 100): 0,50 / 0,7 s | P | Parry (aviso largo: regala la técnica), dash | H · MELEE | 3 | [Pend.] |
| **Sellador** | 5 | 1 | Lanza una bola de lacre a 5 baldosas del jugador: 0,50 s; el charco ocupa 3 baldosas 4 s y deja **Lento** 2 s (sin daño). Después, cuchillo de cera: 0,45 s | Charco **R**, cuchillo P | Saltar el charco; limpiarlo a golpes (3); parry el cuchillo | H · `telegraph_zone` + estado Lento | 4 | [Pend.] |
| **Penitente** | 5 | 1 | Látigo de cadena en giro (alcance 130): 0,60 s, dura 0,4 | P | Entrar por dentro de la cadena, ataque aéreo, parry | H (cadena) · MELEE con hitbox circular | 4 | [Pend.] |
| **Armadura Vacía** | 8 + escudo | 1 | Golpe de escudo (empuja 60 px): 0,70 / 0,9 s; baja el escudo 0,4 s cada cuatro golpes | P | **El escudo bloquea todo golpe frontal.** Se rompe con parry (aturde 1,5 s), con el golpe desde arriba o por la espalda, o rodeándola con salto | A · `directional_guard` | 5 | [Pend.] |
| **Polilla de Archivo** | 2 | 1 | Vuela en ochos lentos (70 px/s) y se lanza en picado: 0,55 s; no ataca cerca de un Ancla | P | Ataque hacia arriba, parry | V · `fly_ai` | 3 | [Pend.] |

**Élite: Relator Hueco** (vida 9; capa de Relator y un libro en blanco). No ataca: invoca dos Novicios Borrados (aviso 1,0 s) desde las páginas, cada 8 s si se le ignora, hasta 4 vivos. Si se le mata antes de que acaben de invocar, los novicios se esfuman. Ecos 10. Cuerpo H · `Spawner` con tope. [Pend.]

**Minijefe: Custodio Mayor del Pasillo en Blanco.** Armadura Vacía a escala 1,45 con alabarda y escudo grande; guarda el cruce entre dos alas. Vida 40 y escudo con 6 puntos (como la armadura del Centinela). *Estocada larga* (0,70 s, 1, alcance 140, **P**), *Embestida de escudo* (0,90 s, 2, 5 baldosas, **R**), *Giro* (0,60 s, 1, **P**). El escudo bloquea de frente; se abre con parry o pasando por su espalda tras la embestida (queda 1,2 s de cara a la pared). Barra propia sobre el enemigo. Ecos 35. Recompensa: abre el pasillo hacia la Sala de los Relatores. Cuerpo A (recolor y escala de la Armadura, sin cuerpo propio). [Pend.]

**Combinaciones del Archivo** (5):

| # | Encuentro | Lección |
|---|---|---|
| A1 | Novicio solo en un pasillo estrecho | Parry cómodo: el aviso largo regala la técnica |
| A2 | Armadura Vacía + novicio detrás | El escudo hace que pelees contra el novicio por encima |
| A3 | Sellador + Penitente a lados opuestos de una sala | El charco Lento te obliga a pelear dentro de él contra la cadena |
| A4 | Tres polillas + un novicio en estantes | Mirar arriba y abajo; usar el pogo |
| A5 | Relator Hueco + dos Armaduras | Prioridad de objetivos: el relator primero |

### Las Minas del Origen (7,5-11 h)

Subterráneas, estrechas, oscuras. Cavadores vaciados, Hondos y criaturas **saturadas** (exceso de recuerdos apilados como roca). Verbos nuevos: verticalidad y entorno.

| Enemigo | Vida | Daño | Ataque: aviso / recuperación | Tipo | Cómo se contrapone | Cuerpo · IA y motor | Ecos | Estado |
|---|---|---|---|---|---|---|---|---|
| **Cavador Vaciado** | 6 | **2** | Pico sobre la cabeza (golpea a 60 px delante): 0,55 / 0,9 s | P | Parry, retroceder | H · MELEE | 5 | [Pend.] |
| **Hondo** | 7 | 1 | Lanza su lámpara en arco: 0,60 s; deja una llama en el suelo 3 s (daño 1) | Lámpara P, llama **R** | Parry el golpe, evitar la llama | H · proyectil en arco + zona | 5 | [Pend.] |
| **Chinche de Roca** | 4 | 1 | Se enrolla (0,45 s) y rueda a 330 px/s con 2 rebotes; al acabar queda aturdida 1,3 s | **R** (cuerpo entero) | Saltar (rueda por debajo), pogo sobre la bola, dash a través | O (bola) · `attack_kind` ROLL | 4 | [Pend.] |
| **Geoda Saturada** | 6 | 1 | Estática; a 80 px se **abre** (1,0 s) y lanza cuatro esquirlas en abanico (0,50 s); se cierra con coraza (inmune) | Esquirlas P | Atacar mientras está abierta; pogo sobre el cristal | O (objeto) · `directional_guard` (cerrada = guardia total) | 5 | [Pend.] |

**Élite: Zapador Eterno** (Cavador con un barril de pólvora a la espalda; vida 10). Arroja el barril (0,70 s, fusible de 1,0 s, daño 2 en 100 px, **R**); si se le mata con el barril cargado, explota dañando a todo lo cercano, **incluidos los demás enemigos** (excepción declarada a la regla de no dañarse). Ecos 12. Cuerpo H · `telegraph_zone` con objetivos de ambos bandos. [Pend.]

**Combinaciones de las Minas** (4):

| # | Encuentro | Lección |
|---|---|---|
| M1 | Dos chinches en una sala con vigas | Calcular rebotes y usar las plataformas |
| M2 | Cavador + Hondo con lámpara | La zona de fuego cambia dónde se pelea |
| M3 | Geodas + Zapador | Hacer explotar al zapador junto a las geodas |
| M4 | Cavador + chinche en un pozo | Verticalidad con presión |

### La Costa Retenida (9,75-11 h)

La región más luminosa. Los Descreídos pelean porque les han pedido que protejan el olvido; el combate es más lento y más bonito. Verbos nuevos: estados y racha. Pocas salas de combate (2).

| Enemigo | Vida | Daño | Ataque: aviso / recuperación | Tipo | Cómo se contrapone | Cuerpo · IA y motor | Ecos | Estado |
|---|---|---|---|---|---|---|---|---|
| **Hermano de Cal** | 6 | 0 / 1 | Pinta un **círculo de cal** de 2 baldosas: 0,80 s, **Olvido** 3 s al pisarlo (se borra en 6 s). Empujón: 0,55 s, daño 1 | Círculo **R**, empujón P | No pisar el círculo; parry el empujón | H · `telegraph_zone` + Olvido | 6 | [Pend.] |
| **Acompañante** | 4 | 0 | **No ataca.** Da *Calma* (escudo de 3 puntos) a sus aliados. Si estás a < 3 baldosas, intenta abrazarte: 0,80 s, **Fijado** 0,6 s | Abrazo **R** | Matarlo primero (prioridad); el parry no sirve; dash | H · soporte (escudo de aliados) + Fijado | 5 | [Pend.] |
| **Gaviota Rapaz** | 2 | 1 | Vuela en círculos y pica: 0,40 s | P | Ataque hacia arriba, parry | V · `fly_ai` | 5 | [Pend.] |

**Élite: Hermano de Cal Antiguo** (vida 12). Ataca despacio (1,0 s, golpe amplio de 1), pero sus círculos se suman (hasta 3 a la vez) y están ligados: pisar uno activa los otros 1,0 s después. Se resuelve estando quieto fuera de los círculos y entrando en sus recuperaciones. Anuncia a Eudora. Ecos 13. Cuerpo H (escala y paleta). [Pend.]

**Combinaciones de la Costa** (3):

| # | Encuentro | Lección |
|---|---|---|
| T1 | Hermano de Cal solo en una playa | Aprender el círculo y el Olvido sin presión |
| T2 | Hermano + Acompañante | Prioridad: el Acompañante cubre al Hermano |
| T3 | Tres gaviotas + Hermano en un acantilado | Combate vertical con los círculos en el suelo |

### La Herida (11,75-13 h)

Inestable y apenas reconocible; examen final sin ser injusto, **mezcla de habilidades ya vistas**. Reutiliza enemigos de las regiones anteriores "reconstruidos".

| Enemigo | Vida | Daño | Ataque: aviso / recuperación | Tipo | Cómo se contrapone | Cuerpo · IA y motor | Ecos | Estado |
|---|---|---|---|---|---|---|---|---|
| **Eco Borrado** | 8 | 1 | Se teletransporta 4 baldosas (parpadea 0,40 s) y reaparece a 3 baldosas a la espalda del jugador; golpe de brazo: 0,40 s | P | Predecir el parpadeo (siempre reaparece detrás), parry | H (plano) · `teleport` en la IA | 6 | [Pend.] |

**Élite: Relevo Vacío** (máscara azul, vida 14). Usa el dash contra el jugador (se encorva 0,30 s) y ataca en la llegada; aprende: si se le esquiva, la siguiente vez hace una finta. Es el "examen de dash". Ecos 15. Cuerpo H con el rig del jugador. [Pend.]

**Minijefe: El Doble Vacío.** Silueta del Caminante, vida 36. Repertorio **fijo** de 4 ataques con avisos de 0,50 a 0,80 s (no copia lo que ha hecho el jugador, para no ser injusto). El único enemigo que habla (una línea). Ecos 40. Recompensa material: ninguna; abre la puerta al jefe. Cuerpo H con el rig del jugador (acopla su arte al del protagonista: si se rehace el Caminante hay que regenerarlo). [Pend.]

**Combinaciones de la Herida** (4):

| # | Encuentro | Lección |
|---|---|---|
| H1 | Un Eco Borrado solo | Nuevo patrón: no se huye, se predice |
| H2 | Tres Ecos en una sala circular | Moverse sin encerrarse |
| H3 | Relevo Vacío + dos Ecos | Control de multitud con dash |
| H4 | Fragmentos reconstruidos: cascarón, lancero y armadura vacía con tinte de Herida | Combinar patrones ya vistos con terreno inestable |

Total: 5 + 5 + 4 + 3 + 4 = **21 combinaciones**.

## Tipos de cuerpo y arte (qué se construye)

Fuente: `docs/reunion/artistas/05-criaturas-y-jefes.md` §2. La decisión de sistemas es **qué tipos de cuerpo se aceptan** (cada uno cuesta días de ingeniería de rig):

| Tipo | Decisión | Por qué |
|---|---|---|
| **H** humanoide con estilo nuevo | Sí (4 días: cabezas, armas, ropas, escala) | Cubre más de la mitad del bestiario y 8 jefes |
| **A** armadura vacía | Sí (2-3 días: extraer del Centinela) | Armadura Vacía, Custodio Mayor, y refactor del Centinela |
| **V** volador | Sí (3 días) | Cuervo (banco de pruebas), Polilla, Gaviota: un cuerpo, tres criaturas por tamaño y paleta |
| **Q** cuadrúpedo y artrópodo | **No** (5-6 días para dos criaturas) | La Chinche es una bola y la Geoda un objeto: se dibujan como **objetos animados** (O) sin rig |
| **S** segmentado y de línea | **No** | Gusano de Veta, Pez de Plata y Contorno caen |
| **P** multiparte | Solo para Maelis, como escena de `Sprite2D` por parte, **sin soporte genérico de rig** | Es el único jefe que lo pide |

Reglas de reutilización: los élites son escala y paleta más un rasgo de silueta (nunca solo recolor); el Custodio Mayor es la Armadura Vacía a escala 1,45; las variantes de paleta salen de una tabla de paletas por ranura (piel, tela, metal, acento), no de PNG nuevos. Orden de producción por región: primero los comunes que establecen la lectura, luego el élite, luego el minijefe y al final el jefe (así el jefe se prueba contra enemigos ya vistos).

## Piezas de motor nuevas y su orden

Cada pieza se construye **cuando llega el primer enemigo o jefe que la necesita**, no antes. Las genéricas viven en `core/components/` (una responsabilidad y exports configurables, sin referencias a `game/`); lo específico del juego, en `game/`. Costes: S = ≤ 1 día, M = 2-4 días, L = 5 o más.

| # | Pieza | Qué hace | La necesita primero | Coste | Cuándo |
|---|---|---|---|---|---|
| 1 | **`parryable` + aviso rojo + marca de suelo** | Atributo por ataque; `ParryComponent` lo respeta (un golpe no parable atraviesa la guardia); tinte rojo y decal | Todos los rojos (Sellador, Chinche...); Jacinto | S | Antes de cualquier enemigo o jefe nuevo |
| 2 | **Ataque hacia arriba y hacia abajo (pogo) del jugador** | Ver `nucleo-jugable.md` | Cuervo, Polilla, Gaviota, Geoda | M + M | Antes de colocar el primer volador |
| 3 | **`fly_ai`** (vuelo) | Equivalente a `PatrolChaseAI` sin gravedad: merodea, se coloca a altura de ataque, picado con aviso, retirada. Detecta por distancia en 2D (no por la tolerancia vertical de 80 px). Mismo contrato (`step`, señales); necesita colisión con techo y suelo | Cuervo | M | Cinturón alto; el cuervo es el banco de pruebas de V |
| 4 | **Estado DORMANT** en `PatrolChaseAI` | Inmóvil hasta que el jugador pasa a N px; se "levanta" y pasa a CHASE | Espantapájaros | S | Cinturón alto |
| 5 | **`attack_picker`, `phase_tracker`, `boss_base`** | Ver `jefes.md` | Jacinto | M | Con Jacinto |
| 6 | **`telegraph_zone`** | Rectángulo, círculo o sector en el suelo o el aire que se pinta en amarillo o rojo durante N s y después aplica daño o efecto a lo que haya dentro (reutiliza `MeleeAttackComponent`). Puede ser persistente (charco) y de objetivos configurables | Jacinto (sombra del picado), Sellador, Hondo, Zapador, Hermano de Cal | M | Con Jacinto, en versión mínima; crece con el Archivo |
| 7 | **`Spawner` con tope** | Crea N entidades con un máximo vivo; se libera al morir el invocador. Sin pooling | Jacinto, Relator, Hesper | S | Con Jacinto |
| 8 | **`status_effects` (Lento, Fijado)** | Aplica y retira estados con duración; señal `status_changed` para el HUD; morir los limpia | Sellador, Hesper, Acompañante | M | Antes del Archivo |
| 9 | **`directional_guard`** (escudo) | Bloquea golpes que llegan por el lado indicado (rebote con chispa y metal); se rompe con parry, golpe desde arriba, por la espalda o tras la recuperación propia. `take_hit` ya recibe `from_direction`. Un parámetro `closed` permite la Geoda | Armadura Vacía | S-M | Con el Archivo |
| 10 | **`attack_kind` ROLL** | LUNGE con rebote en paredes y aturdimiento final | Chinche | S | Minas |
| 11 | **Estado Olvido** | La cura del sorbo a la mitad y contador de vida difuminado, con su opción de accesibilidad | Hermano de Cal | S | Costa |
| 12 | **`teleport` y dash en la IA** | Salto instantáneo con parpadeo de aviso; embestida con finta | Eco Borrado, Relevo Vacío | S + S | Herida |
| 13 | **Partes golpeables** (local de Maelis) | Zonas con multiplicador y dueño | Maelis | L | Final del proyecto |

Se descartaron como piezas genéricas: `hurt_zone` (solo la usa Maelis; se queda dentro del jefe), el `attack_kind` LEAP (cae el mastín) y los terrenos editables (se usan objetos preubicados: losas frágiles, bloques destructibles, espejos).

## Qué declara cada escena de enemigo

Para que ningún enemigo nuevo rompa el contrato, cada escena declara: `ecos_reward`, vida, `parryable` por ataque, aviso y recuperación, `voice`, sonidos, y su grupo (`enemy`, y `duro` si es Coloso, Armadura, Geoda, Chinche o Custodio, para el Diente de la Mina). Los enemigos que admiten **Castigo** son los que pasan por RECOVER tras fallar; los jefes no.

## Cómo se comprueba

Todas las pruebas se añaden a `tests/smoke_test.gd` (o a ficheros hermanos que la prueba de humo ejecute) y sustituyen a "mirar si va", pero no a **jugarlo**.

| Prueba | Qué se comprueba |
|---|---|
| Aviso mínimo | El aviso es ≥ el mínimo de la tabla para su daño, también en fases acortadas |
| `parryable` | Un ataque rojo con el parry activo hace daño y no aturde; uno amarillo no hace daño y aturde `parry_stun_time` |
| Sin daño por contacto | Con el jugador pegado a un enemigo en PATROL, la vida no baja |
| Sala y puertas | Con el jugador fuera de la sala (o a < 4 baldosas de la puerta) no ataca ni persigue |
| Parry y retroceso | Frontal con parry: sin daño, aturde y el aturdido recibe el doble; un golpe suyo y uno del jugador producen retroceso y el del jugador cancela su ataque |
| Muerte y Ecos | Al morir suelta `ecos_reward` exactos y no deja nodos huérfanos (proyectiles, charcos, bloques) |
| Reaparición | Tras descansar, todos los enemigos de la sala están en su estado inicial |
| Voladores y embestidas | No atraviesan suelo ni techo; la embestida se corta en bordes y paredes |
| Estados | Lento, Fijado y Olvido caducan; morir los limpia |
| Ataque arriba y abajo | Cada volador recibe daño del golpe hacia arriba; el pogo rebota en enemigo y objeto `pogoable`, no en pinchos, y no recarga dash ni doble salto |
| Escudo | Un golpe frontal rebota; por la espalda o desde arriba entra; el parry lo rompe |
| Encuentros (las 21) | Se cruzan sin daño con las habilidades disponibles en ese punto; un bot cauto sale con ≥ 60 % de la vida; uno que solo corre sale dañado; nadie se atasca en tablones o paredes |
| Presupuesto de Ecos | La suma de `ecos_reward` de los enemigos colocados más jefes y Bolsas se mantiene en el rango del invariante (ver `nucleo-jugable.md`) |

## Cosas a vigilar al jugarlo

- **Los voladores** fastidian si el ataque hacia arriba no se siente bien: implementarlo primero y, si no, mantenerlos cortos de vida (2).
- **Sobredimensión**: aun recortado son 20 comunes, 5 élites y 2 minijefes. Orden de sacrificio si falta alcance: opcionales → élites (se quedan como comunes con más vida) → minijefes (se quedan como élites) → comunes de relleno. **Nunca** los jefes obligatorios.
- **Estados del jugador** (Olvido, Fijado, Lento): duraciones ≤ 4 s, aviso rojo, sin encadenar dos; si frustran, se acortan antes de quitar la opción de accesibilidad.
- **Fatiga de silueta**: con ~16 humanoides, el riesgo de repetición es alto; tope de tres enemigos con la misma cabeza en una región.
- **Orden libre Minas / Costa**: los enemigos de ambas regiones deben cargarse sin depender del orden en que se construyeron los tipos de cuerpo (V y H ya estarán en ambas).
