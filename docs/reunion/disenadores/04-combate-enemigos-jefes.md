# Sala de diseño 04: Combate, enemigos y jefes

Autor: diseñador de enemigos y jefes. Documento de propuesta para la reunión; no modifica ningún otro archivo del proyecto. Todas las cifras son hipótesis de partida, calibradas contra lo que ya existe (`enemy.gd`, `patrol_chase_ai.gd`, `centinela.gd`, `docs/jefes.md`, `docs/nucleo-jugable.md`) y contra el canon (`personajes.md`, `guion-maestro.md`). Se ajustarán jugando.

## 0. Resumen ejecutivo

- **Bestiario:** 28 tipos comunes repartidos en las 6 regiones (los 5 que ya existen más 23 nuevos), 5 enemigos de élite que son variantes con mecánica añadida, 5 minijefes (uno por región, más uno de la Herida) y 30 combinaciones de encuentro (5 por región).
- **Jefes:** los 10 del canon, cada uno con arena, tres fases, tabla de ataques con aviso, números y animaciones. Siete obligatorios, dos opcionales, uno secreto que no hace daño.
- **Ley central del diseño:** *el combate es la conversación que no pudieron tener* (frase del canon). Cada jefe tiene que enseñar una cosa, examinar esa misma cosa y, al caer, cambiar cómo se siente la persona que era. La mecánica es el carácter.
- **Lo que hay que construir en el motor** se concentra en seis piezas pequeñas y genéricas (sección 1.4): vuelo, escudo direccional, zonas con aviso en el suelo, estados alterados del jugador, selector de ataques con aleatoriedad controlada y partes golpeables. Con ellas se cubren los 28 enemigos y los 9 jefes pendientes. Nada de arquitectura "por si acaso": cada pieza se construye cuando llega el primer enemigo o jefe que la necesita y se anota en qué hito.
- **Ataques del jugador pendientes:** ataque hacia arriba, ataque hacia abajo con pogo y el Golpe Hondo (Excavar) como golpe pesado. Sin ellos, los voladores, los espíritus y varios jefes no tienen respuesta. Son la prioridad número uno de combate antes de construir el Archivo.
- **Riesgo mayor:** la cantidad de contenido. Se propone una **versión mínima** de cada pieza (marcada como "recorte") para no pasar de lo viable con esqueletos vectoriales.

---

## 1. Marco de partida

### 1.1 Qué hay hoy (hechos verificados en el código)

| Elemento | Valor actual |
|---|---|
| Jugador | 24×48 px, 300 px/s, salto 180 px, dash 135 px (uno por salto, sin invulnerabilidad documentada) |
| Ataque | Tajo horizontal ~40 px, enfriamiento 0,3 s, daño 1 a 3 con el árbol; **arriba/abajo no implementado** |
| Parry (V) | Ventana 0,2 s, solo golpes frontales; enemigo aturdido 1,2 s y recibe doble daño; enfriamiento 0,7 s; no se ataca con la guardia alzada |
| Vida / curación | 5 de base (hasta 9 con Vitalidad), frascos que se recargan en el Ancla |
| Invulnerabilidad tras golpe | 0,6 s |
| Hit-stop | 0,06 s al conectar |
| Cascarón | Vida 3, aviso 0,3 s, recuperación 0,5 s, persigue a 150 px/s, daño 1 |
| Lancero | Vida 4, alcance 84, aviso 0,42 s, rec. 0,6 s, 125 px/s |
| Arrojador | Vida 2, proyectil a 240 px, aviso 0,5 s, rec. 0,8 s, 100 px/s |
| Acechador | Vida 3, embestida desde 150 px, aviso 0,28 s, rec. 0,65 s, 215 px/s |
| Coloso | Vida 10, daño 2, alcance 78, aviso 0,72 s, rec. 1,0 s, 78 px/s |
| Ecos | Cascarón 2, lancero 3, arrojador 3, acechador 3, coloso 8; Centinela 40 |
| IA | `PatrolChaseAI`: PATROL, CHASE, WINDUP, RECOVER. Solo ve a alturas parecidas (80 px), solo actúa dentro de su sala a 4 baldosas de las puertas |
| `attack_kind` | MELEE, PROJECTILE, LUNGE |
| Jefe | `centinela.gd` (máquina de estados propia), `boss_room.gd` (disparador, rastrillos, barra, recompensa, reinicio) |

Lectura: el sistema actual ya cumple la regla de oro (aviso visible, sin daño por contacto, todo esquivable). Los números de los enemigos básicos están en un rango sano: avisos de 0,28 a 0,72 s, daño 1 (2 el coloso), recuperaciones de 0,5 a 1,0 s que son la **ventana de castigo**.

### 1.2 Reglas de lectura (contrato con el jugador)

Estas reglas valen para todo el bestiario y todos los jefes; si un ataque las rompe, se rediseña el ataque, no la regla.

1. **Todo daño tiene aviso.** Aviso visual (color) y de postura (el arma se alza) más sonido. Mínimos de aviso:

   | Daño | Ataque rápido (un solo golpe) | Ataque con zona o proyectil | Ataque de remate |
   |---|---|---|---|
   | 1 | 0,28 s | 0,40 s | — |
   | 2 | 0,55 s | 0,70 s | 0,90 s |
   | 3 | no existe salvo remate | — | 1,10 s |

   Se aplica a partir de la fase 1; en fases 2 y 3 se puede acortar hasta un 25 % sobre el valor de la fase 1, nunca por debajo de 0,28 s.
2. **Código de colores del aviso.** Amarillo (ya existe) = se puede esquivar **o parar**. **Rojo** (nuevo) = **no se puede parar**, solo esquivar: agarres, suelo que se rompe, luz, áreas. Cian (ya es el tinte de aturdido) = estado de debilidad. Un atributo `parryable` por ataque basta. Sin esta distinción, el parry se vuelve la respuesta a todo y los jefes pierden variedad.
3. **Ningún daño supera 2** salvo el remate del jefe final (3, una vez por fase, con aviso ≥ 1,1 s). La vida mínima es 5, así que **nada mata de un golpe**.
4. **Quien ataca se queda vulnerable.** Toda secuencia de ataque termina con una recuperación de 0,5 s o más (enemigos) o 0,8 s o más (jefes, salvo furias). La recuperación es la recompensa de leer bien.
5. **La arena se lee de un vistazo.** Un jefe nunca ataca desde fuera de pantalla ni desde una zona sin suelo visible. Los elementos peligrosos del entorno se avisan antes que los del jefe.
6. **Aleatoriedad controlada.** Los jefes eligen el siguiente ataque con una **bolsa barajada** (cada ataque entra una vez, no se repite el último, el peor castigo no sale dos veces seguidas). Nunca una tirada pura. Detalle en 1.4.
7. **Sin ataques que atraviesen la sala sin solución.** Cada ataque tiene al menos dos respuestas válidas (por ejemplo, salto o dash; parry o distancia).
8. **Lo que el jugador aún no sabe hacer no se le pide.** La arena de un jefe que da una habilidad no exige esa habilidad; el jefe, en cambio, puede *usarla* delante del jugador como lección (Jacinto trepa por las paredes).
9. **Cada enemigo nuevo se presenta solo, después en pareja y por fin en grupo** (patrón del guion maestro, 7.1).


### 1.4 Las seis piezas que faltan en el motor

Las ordeno por orden de aparición. Todas son componentes de `core/components/` con exports y una sola responsabilidad (regla de `arquitectura.md`); `game/` solo decide cuándo se usan.

| # | Pieza | Qué hace | Quién la necesita primero | Coste |
|---|---|---|---|---|
| E1 | **`attack_picker`** (selector de ataques) | Bolsa barajada con "no repetir el último", pesos por fase y "memoria" corta (si el jugador esquivó tres veces el mismo, favorece otro). Devuelve un identificador | Jacinto, y de paso refactor opcional del Centinela | Pequeño (~60 líneas). Es tablero de decisiones, no IA |
| E2 | **`telegraph_zone`** | Rectángulo, círculo o sector en el suelo/aire que se pinta en amarillo o rojo durante N s y después aplica daño/efecto a lo que haya dentro. Reutiliza `MeleeAttackComponent` para el daño | Sellador (primer enemigo con zona), Hesper, Eudora, Magda, Rufo, Maelis | Medio. Es la pieza más rentable: cubre media docena de ataques de jefe |
| E3 | **`fly_ai`** (vuelo) | Equivalente a `PatrolChaseAI` pero sin gravedad: merodea, se coloca a una altura de ataque, picado con aviso, retirada. Mismo contrato (`step`, señales) | Cuervo de Rastrojo, polilla, murciélago, gaviota, vela errante | Medio. Necesita colisión con techo y suelo |
| E4 | **`directional_guard`** (escudo) | Bloquea golpes que llegan por el lado indicado; el golpe rebota con chispa y sonido de metal. Se rompe con parry, ataque aéreo desde arriba (pogo), ataque por la espalda o tras la recuperación de su propio ataque | Armadura vacía, Cangrejo, Centinela (ya tiene armadura propia, no lo necesita) | Pequeño. El `take_hit` del enemigo recibe `from_direction`, ya lo tiene |
| E5 | **`status_effects`** (estados del jugador) | Aplica y retira estados con duración: *Fijado* (no se mueve, 0,6 s), *Lento* (-35 % de velocidad), *Olvido* (la curación tarda el doble y la barra del frasco parpadea), *Cegado* (reduce la luz alrededor, solo cosmético). Señal `status_changed` para el HUD | Sellador (lacre = Lento), Hesper (Fijado), Eudora (Olvido), Maelis (Fijado) | Medio. Toca al jugador, así que cuidado con el orden de entradas |
| E6 | **`hurt_zone`** (partes golpeables) | Zona golpeable con multiplicador de daño y a qué cuerpo pertenece. Permite jefes con partes (corazón, brazo, lámpara) y enemigos con punto débil por la espalda | Madre de Veta, Casimar, Rufo, Quimera de Rastros | Pequeño-medio |

Además hay **cuatro cosas de escala de jefe** que no son componentes sino capacidades de la sala:

- **Invocaciones:** un `Spawner` simple con tope (máximo N vivos), usado por Jacinto, Casimar, Hesper, Eudora y los élites. Sin pooling: se crea y se libera.
- **Terreno cambiante:** baldosas que se rompen, se bloquean o aparecen durante la pelea. Hoy los mapas son de texto y estáticos; el jefe lo modifica como el Centinela modifica las rocas. Lo necesitan Magda (suelo roto) y Hesper (lacre). *Alto coste, ver Magda.*
- **Tiempo de combate por fases con "respiro":** un hueco de 1,5 a 2,5 s de transición entre fases en el que el jefe no ataca y el jugador puede curarse (frasco: 0,9 s de lanzamiento, ver 3.3).
- **Música de jefe:** hoy el sonido es sintetizado por código (`tools/sonidos.js`). Se propone tema de 2 capas (base + capa de furia) mezclables, ver 3.4.

Recomendación de orden: **E2 y E5** antes del Archivo, **E3** con las Minas (o antes con el cuervo del Cinturón alto, que sirve de banco de pruebas), **E4** con el Archivo, **E6** con las Minas.

---

## 2. Bestiario

### 2.1 Cómo leer las fichas

Tabla por región. Columnas: **Enemigo** (nombre y lugar en el canon), **Vida**, **Aspecto** (una línea), **Comportamiento y ataques** (aviso / duración / daño), **Cómo se contrapone**, **Grupo** (con quién se combina), **Ecos**, **Motor** (qué necesita). Las vidas están dadas con el Filo base (daño 1); a partir del Filo 2 y 3 los golpes necesarios bajan, y se vigila con la curva de la sección 5. "Aviso" es el tiempo de amarillo/rojo; "dur." es la duración activa del golpe; "rec." es la recuperación (el hueco de castigo).

Los enemigos de cada región heredan el ambiente y el canon: Selladores (capas ocre, lacre), Penitentes (sacos de ceniza), Hondos (grasa y refranes), Descreídos (cal), cascarones vaciados (gesto repetido) y fauna.

### 2.2 El Último Umbral y el Cinturón Yermo (periferia, 0 a 5 h)

Región de la primera lección: lee el aviso, esquiva o para, entra en el hueco. Fauna y vaciados del campo. Hay 5 existentes y 3 nuevos.

| Enemigo | Vida | Aspecto | Comportamiento y ataques | Contrapone | Grupo | Ecos | Motor |
|---|---|---|---|---|---|---|---|
| **Cascarón** (existe) | 3 | Persona vaciada con cuchillo oxidado, repite su gesto | Tajo corto: aviso 0,30, dur. 0,10, daño 1, rec. 0,5 | Parry, dash por detrás, retroceso | Base de todo grupo; anzuelo para el arrojador | 2 | Hecho |
| **Lancero** (existe) | 4 | Guardia de la Orden vaciado, lanza | Estocada larga (alcance 84): aviso 0,42, daño 1, rec. 0,6 | Entrar tras la estocada; parry exige timing por el alcance | Detrás de un cascarón; en pareja cubre toda la altura | 3 | Hecho |
| **Arrojador** (existe) | 2 | Vigía o cantero vaciado, lanza piedras | Proyectil recto: aviso 0,5, daño 1, rec. 0,8; mantiene distancia | Saltar el proyectil, dash a través, parry lo devuelve | Sobre un tablón con un lancero abajo | 3 | Hecho |
| **Acechador** (existe) | 3 | Vaciado a rastras, rápido y bajo | Embestida desde 150 px: aviso 0,28, 215 px/s, daño 1, rec. 0,65 | Saltar por encima, parry (la ventana es corta: aviso 0,28 < ventana de reacción) | Detrás de una pared de lanceros; en pozo | 3 | Hecho |
| **Coloso** (existe) | 10 | Vaciado de Custodio mayor, mazo de hierro | Mazazo: aviso 0,72, daño 2, rec. 1,0, 78 px/s | Parry (premia mucho: 1,2 s de doble daño), dash por detrás | Solo; o al final de una galería | 8 | Hecho |
| **Cuervo de Rastrojo** | 2 | Corneja con restos de tela, vuela en círculos sobre los bancales | Vuela a 90 px de altura; picado con aviso 0,45 (se detiene y se pone amarillo), 260 px/s, daño 1; vuelve arriba. Pausa de 1,2 s entre picados | Ataque hacia arriba (cuando exista), parry en el picado, dash lateral | Con un arrojador bajo: hay que mirar a dos alturas | 2 | `fly_ai` (E3); necesita ataque arriba |
| **Espantapájaros** | 4 | Muñeco de paja con harapos clavado en un palo; "se levanta" al pasar | Inmóvil hasta que pasas a 100 px; se levanta (1,0 s, sin daño), luego avanza lento (60 px/s) y da un golpe de brazo, aviso 0,65, daño 1. Arde: recibe +1 de daño si lo alcanza fuego (no hay fuego aún; reservado a Rufo) | Rodearlo mientras se levanta; ataque aéreo | **Emboscada**: en la Era hay tres falsos entre los verdaderos | 3 | Estado "durmiente" en la IA; reutiliza `PatrolChaseAI` |
| **Mastín sin Amo** | 3 | Perro flaco de pastor, ladra al detectar | Carrera + salto: aviso 0,35, salta 120 px horizontales con arco (puede saltarse pasando por debajo del salto con dash), daño 1, rec. 0,8 | Esperar el salto y pasar por debajo; parry en el aterrizaje; salto mutuo | Manada de dos: uno a la vez, el otro rodea | 3 | LUNGE con arco: `attack_kind` **LEAP** (nuevo, derivado de LUNGE con gravedad) |

**Enemigo de élite del Cinturón: Segador Vaciado (variante del cascarón).** Vida 7, hoz larga. Barrido en arco alto-bajo con aviso 0,6 s, daño 1, alcance 90 px; entrar por dentro, pegado a él, evita el arco (anticipa la lección de Jacinto). Cada 12 s da un paso de segador con 0,4 s de aviso. Ecos 12. Motor: MELEE con hitbox de arco (ya existe en `MeleeAttackComponent`). Aparece **solo** en los bancales altos; es el examen de entrada a La Era.

**Minijefe del Cinturón: La Yunta.** Dos bueyes vaciados uncidos a un arado con cuchillas. Mide el doble de largo que el jugador, 4 patas. Vida 24 (barra propia sobre el enemigo, no la grande). Ataques: *Arrancada* (aviso rojo 0,9, embiste todo el pasillo a 340 px/s, daño 2, se detiene al chocar contra la pared y queda aturdido 1,6 s), *Coz doble* (aviso 0,5, daño 1, 70 px atrás), *Surco* (levanta una piedra del arado que se desliza por el suelo, salto o dash). Contra: dejar que embista contra la pared. Ecos 30. Dónde: sala larga de bancales (Cinturón alto), antes de La Era. Recompensa: un atajo (abre una puerta desde dentro). Motor: LUNGE largo con aturdimiento por choque (parámetro `stun_on_wall`).

**Cinco combinaciones de encuentro (Cinturón):**

| # | Encuentro | Lugar | Lección |
|---|---|---|---|
| C1 | Cascarón + cascarón escalonados 12 baldosas | Camino de las Terrazas | Primer 1 contra 1, luego 1 contra 2 con espacio |
| C2 | Lancero sobre el suelo + arrojador en el tablón | La Cisterna | Dos alturas: el lancero cierra el suelo, el arrojador cobra por ir al tablón |
| C3 | Dos mastines + un cascarón en un pasillo con un foso | Bancales | Gestionar la presión; el foso fuerza el salto |
| C4 | Cuervo + arrojador + espantapájaros durmiente | Bancal con andamios | Mirar arriba, abajo y alrededor: no te fíes del campo vacío |
| C5 | Coloso + acechador detrás | Galería larga | El coloso se parry-ea (hueco de 1,2 s) pero el acechador te saca de posición |

### 2.3 El Archivo (acto II, 5 a 7,5 h)

Selladores (capas ocre, lacre), Penitentes (sacos de ceniza), los Negadores (barren pasillos) y vaciados del oficio. La clave de sala: **pasillos en blanco junto a salas intactas**; el blanco puede ser una zona donde el enemigo "no está" (aparece al entrar) y el suelo del pasillo es un tablón de papel que se rompe, pero eso es de entorno.

| Enemigo | Vida | Aspecto | Comportamiento y ataques | Contrapone | Grupo | Ecos | Motor |
|---|---|---|---|---|---|---|---|
| **Novicio Borrado** | 4 | Cascarón de túnica gris con una pluma de hierro en la mano | Estocada de pluma a media distancia (alcance 100): aviso 0,5, daño 1, rec. 0,7. Deja una línea de tinta en el aire que dura 0,3 s (solo cosmética) | Parry (aviso largo: fácil), dash | Detrás de un armadura vacía | 4 | MELEE, ya |
| **Sellador** | 5 | Capa ocre, guantes de cera, máscara de lacre; es el "soldado" de Hesper | Lanza una bola de lacre al suelo a 5 baldosas del jugador: aviso 0,5 (la bola se ve), el charco ocupa 3 baldosas y dura 4 s; quien lo pisa queda **Lento** (-35 %) 2 s. No hace daño directo. Después se acerca con un cuchillo de cera: aviso 0,45, daño 1 | Saltar el charco, no pisarlo; parry el cuchillo; el charco se limpia golpeándolo (3 golpes) | Con un lancero/armadura: te obliga a pelear dentro del charco | 5 | `telegraph_zone` (E2) + `status_effects` (E5) |
| **Penitente** | 5 | Sacos de ceniza sobre una armadura sin sello en el pecho; cadena con un peso | Látigo de cadena: giro de cadena sobre la cabeza (alcance 130, aviso 0,6, daño 1, dur. 0,4), se hace daño a sí mismo (pierde 1 de vida cada tres ataques, hasta 1; no se mata). Al morir, el saco se rompe y suelta **ceniza** (nube que tapa 2 s la visión, solo cosmética) | Entrar por dentro de la cadena; parry en el aviso; ataque aéreo | Contra Sellador (se odian: no se ayudan; si están juntos y el jugador esquiva, el Penitente golpea al Sellador: 2 de daño) | 5 | MELEE con hitbox circular; evento de enemigo-enemigo (el sistema de daño ya acepta `take_hit` de otros) |
| **Armadura Vacía** | 8 + escudo | Coraza de Custodio, escudo alto, sin nadie dentro (un cascarón mínimo) | Camina con el escudo por delante. El escudo bloquea todo golpe **frontal**. Ataque: golpe de escudo (aviso 0,7, daño 1, empuja 60 px), rec. 0,9. Cada cuatro golpes baja el escudo 0,4 s | Parry (rompe el escudo y deja 1,5 s aturdido), pogo/ataque desde arriba, dash para pasar por detrás (cuesta el dash), salto y golpe por la espalda | Guardián de un Sellador; bloquea el pasillo | 8 | `directional_guard` (E4) |
| **Polilla de Archivo** | 2 | Polilla grande de alas grises, polvo de papel | Vuela en ochos (lento, 70 px/s), suelta polvo (cosmético, tapa 1 s la vista) y se lanza en picado con aviso 0,55, daño 1; se pega a una estantería y vuelve | Ataque arriba, parry en el picado; se espanta con la luz del Ancla (no atacan cerca de un Ancla) | Muchas, de una en una; cebo para Pez de Plata | 3 | `fly_ai` |
| **Pez de Plata** | 3 | Insecto plateado segmentado, del tamaño de un brazo, en estantes y suelo | Se arrastra pegado a paredes y suelo; sale de debajo de las páginas con aviso rojo en el suelo de 0,4 s (polvo), salta 90 px, daño 1. Si se le golpea, se parte en dos segmentos de vida 1 | Pisar fuera del polvo; ataque abajo (pogo) | En pasillos estrechos, de tres en tres | 3 | Segmentado con 2 hitbox; `telegraph_zone` en el suelo |

**Élite del Archivo: Relator Hueco.** Vida 9. Cascarón con capa de Relator y un libro en blanco. Invoca (aviso 1,0 s) dos Novicios Borrados desde las páginas; no ataca él mismo. Si se le mata antes de que acaben de invocar, los novicios se esfuman. Si se le ignora, la invocación se repite cada 8 s hasta un máximo de 4 vivos. Ecos 18. Motor: `Spawner` con tope.

**Minijefe del Archivo: El Custodio Mayor del Pasillo en Blanco.** Armadura vacía doble de tamaño con escudo grande y alabarda; guarda el cruce entre dos alas. Vida 40, escudo con puntos (como la armadura del Centinela: 6). Ataques: *Estocada larga* (aviso 0,7, daño 1, alcance 140), *Embestida de escudo* (rojo, aviso 0,9, daño 2, 5 baldosas), *Giro* (aviso 0,6, daño 1, alrededor). Reglas: el escudo bloquea de frente; se abre con parry o pasando por su espalda tras la embestida (se queda 1,2 s de cara a la pared). Ecos 35. Recompensa: abre el pasillo hacia la Sala de los Relatores. Motor: `directional_guard` más estados.

**Cinco combinaciones (Archivo):**

| # | Encuentro | Lección |
|---|---|---|
| A1 | Novicio solo en un pasillo estrecho | Parry cómodo: el aviso largo regala la técnica |
| A2 | Armadura vacía + novicio detrás | El escudo hace que pelees contra el novicio por encima |
| A3 | Sellador + Penitente a lados opuestos de una sala | Se odian: si los enfrentas, uno hiere al otro |
| A4 | Tres polillas + un pez de plata en estantes | Mirar arriba y abajo, usar el pogo |
| A5 | Relator Hueco + dos armaduras | Prioridad de objetivos: relator primero |

### 2.4 Las Minas del Origen (acto III, 7,5 a 11 h)

Subterráneas, estrechas, oscuras. Cavadores vaciados, Hondos (que no son enemigos por defecto: son del bando que "oye el Latido"), y criaturas **saturadas** (no vaciadas: tienen exceso de recuerdos apilados como roca). La verticalidad llega aquí: pozos, vetas, arenas de varias alturas.

| Enemigo | Vida | Aspecto | Comportamiento y ataques | Contrapone | Grupo | Ecos | Motor |
|---|---|---|---|---|---|---|---|
| **Cavador Vaciado** | 6 | Obrero con casco y pico | Pico sobre la cabeza: aviso 0,55, daño 2 (apuñala hacia abajo, golpea en 60 px delante); también pica la pared y hace caer una piedra (rojo, 0,6 s) | Parry; esquivar hacia atrás; la piedra es predecible | Con un Chinche; en pasillo | 8 | MELEE + `telegraph_zone` |
| **Chinche de Roca** | 4 | Cuadrúpedo del tamaño de un perro, coraza de roca | Se enrolla en bola (aviso 0,45) y rueda a 330 px/s rebotando en paredes, 2 rebotes, daño 1; queda aturdido 1,3 s al terminar | Salto (rueda por debajo), pogo sobre la bola (le hace daño 1 y rebota), dash a través | Varios en una sala con vigas; la sala se vuelve una mesa de billar | 6 | `attack_kind` **ROLL** (LUNGE con rebote) |
| **Gusano de Veta** | 5 | Serpiente segmentada de roca, 5 segmentos | Asoma de una veta en el suelo/pared: aviso rojo en el suelo 0,55, golpe con la cabeza hacia arriba, daño 1; vuelve a esconderse 2 s (invulnerable escondido) | Saber dónde está la veta; ataque al asomar | En vetas, tres puntos de salida | 6 | Entidad que cambia de posición; `telegraph_zone` |
| **Murciélago de Cueva** | 2 | Murciélago ciego, ojos cosidos | Cuelga del techo; cuando el jugador se acerca a 120 px y hace ruido (correr, atacar), se suelta y picado con aviso 0,4, daño 1; luego se cuelga de nuevo | Moverse sin correr (caminar silencioso no lo despierta), ataque arriba | Cuando llueve de ellos en una cámara larga | 3 | `fly_ai` con "oído" (detección por actividad del jugador) |
| **Hondo** | 7 | Fibroso, ojos enormes, trapo gris en la boca, lámpara de grasa | Lanza la lámpara en arco (aviso 0,6, daño 1 + deja una llama en el suelo 3 s: rojo, daño 1); si el jugador lo mira de cerca, **se retira** (los Hondos solo defienden su territorio) | Parry el golpe de pico; evitar la llama | Con Cavadores (aliados); desplazan llamas por la sala | 8 | Proyectil en arco con efecto de zona |
| **Geoda Saturada** | 6 | Roca con cristales de recuerdo, ojos que son rendijas, de cuatro patas cortas | Estática; si te acercas a 80 px se **abre** (1,0 s), lanza esquirlas (cuatro, en abanico: aviso 0,5, daño 1) y se cierra con coraza (inmune). Al morir explota en esquirlas (aviso 0,6 s antes de la explosión, daño 1 en 100 px) | Atacar mientras está abierta; pogo sobre el cristal de arriba | En grupos, bloquea un pasillo | 8 | `directional_guard` (cerrado = guardia total), `hurt_zone` |

**Élite de las Minas: Zapador Eterno.** Cavador con un barril de pólvora a la espalda. Vida 10. Arroja un barril (aviso 0,7, 1,0 s de fusible, daño 2 en 100 px, destruye baldosas "frágiles" del entorno). Si se le mata con el barril cargado, explota dañando a lo que tenga alrededor, incluidos los enemigos. Ecos 22. Se combina con Hondos: se llama la atención del Hondo y la explosión daña a los demás.

**Minijefe de las Minas: Madre de Veta.** Gran gusano de roca de 8 segmentos que ocupa una sala vertical. Vida 50, tres puntos débiles (las "bolsas de recuerdo" en el cuerpo, `hurt_zone` con x2). Ataques: *Ataque desde las paredes* (rojo, 0,7, daño 2), *Aplastamiento* (cabeza cae desde el techo, aviso 0,9, daño 2), *Escupitajo de grava* (cinco piedras que caen, aviso 0,5, daño 1). Se expone al romper una bolsa (1,8 s). Ecos 45. Recompensa: abre un atajo entre regiones (antes de obtener Excavar). Motor: partes golpeables (E6).

**Cinco combinaciones (Minas):**

| # | Encuentro | Lección |
|---|---|---|
| M1 | Dos chinches en una sala con vigas | Calcular rebotes, usar plataformas |
| M2 | Cavador + Hondo con lámpara | Zona de fuego que cambia dónde se pelea |
| M3 | Murciélagos colgados en un túnel largo | Moverse con cuidado; sigilo |
| M4 | Geodas + Zapador | Hacer explotar al zapador junto a las geodas |
| M5 | Gusano de veta + dos cavadores en un pozo | Tres vetas: orientar el espacio |

### 2.5 La Costa Retenida (acto III, 9,75 a 11 h)

La región más luminosa, la menos afectada. Los Descreídos son amables; el horror es que dan alivio. Los enemigos no son agresivos por naturaleza: pelean porque *les han pedido que protejan el olvido*. Aquí el combate es **más lento y más bonito**, con efectos que "borran".

| Enemigo | Vida | Aspecto | Comportamiento y ataques | Contrapone | Grupo | Ecos | Motor |
|---|---|---|---|---|---|---|---|
| **Hermano de Cal** | 6 | Lino blanco manchado, manos tiznadas de cal, rostro cubierto | Camina despacio, extiende una mano y pinta un **círculo de cal** de 2 baldosas en el suelo (aviso rojo 0,8); quien lo pisa queda en **Olvido** 3 s (la curación dura el doble). Ataque físico débil: empujón, aviso 0,55, daño 1 | No pisar el círculo; el círculo se borra en 6 s | Con Acompañante | 7 | `telegraph_zone` + `status_effects` |
| **Acompañante** | 4 | Lino blanco limpio, manos abiertas, cálido | **No ataca.** Se acerca a aliados y les da **Calma** (escudo de 3 puntos que se gasta). Si el jugador está a menos de 3 baldosas, intenta abrazarlo: agarrón (rojo, aviso 0,8, empuja y no daña, pero deja al jugador en Fijado 0,6 s) | Matarlo primero (prioridad), parry no sirve (rojo), dash | Siempre detrás de Hermanos; el puzle del encuentro es la prioridad | 8 | Soporte: escudo de aliados; `status_effects` |
| **Gaviota Rapaz** | 2 | Gaviota flaca, ojos hundidos | Vuela en círculos, picado con aviso 0,4, daño 1 sobre el jugador; roba un Eco (cuando es golpeada suelta 1 Eco) | Ataque arriba, parry | De cuatro en cuatro en los acantilados | 2 | `fly_ai`; viento (cosmético) |
| **Cangrejo Ermitaño** | 7 | Cangrejo con una concha hecha de una campana rota | Concha como escudo frontal (guardia hacia delante); tenazas: aviso 0,5, daño 1, rec. 0,8. Cuando es golpeado por la espalda o desde arriba, pierde la concha y queda indefenso 2 s. Se esconde dentro (cerrado) si el jugador está lejos | Pogo (ataque abajo), salto por encima y golpe, parry | En playas, con gaviotas | 8 | `directional_guard` |
| **Vela Errante** | 3 | Llama azulada flotante, sostenida por un hilo de humo | Flota hacia el jugador despacio (45 px/s); sin atacar, genera una zona de **luz** de 140 px de radio cuya luz quema: daño 1 por segundo al estar dentro, tras 0,8 s de aviso (la zona se pinta amarilla). Se apaga si le da el aire de una puerta (zona de viento) | Quedarse fuera del radio, matarla de un tajo desde fuera (alcance), pogo | Crea zonas que se superponen en grupos | 5 | `fly_ai` + `telegraph_zone` en movimiento |

**Élite de la Costa: Hermano de Cal Antiguo.** Hermano que ya lo olvidó casi todo. Vida 12. Ataca despacio (aviso 1,0) con un golpe amplio daño 1, pero sus círculos se suman (hasta 3 a la vez) y están ligados: pisar uno activa los otros 1,0 s después. Ecos 24. Se resuelve estando quieto fuera de los círculos y entrando en sus recuperaciones. Anuncia a Eudora.

**Minijefe de la Costa: El Ermitaño Mayor.** Cangrejo enorme con una barca como concha; vida 44, la concha es un escudo con puntos (6) que se recarga. Ataques: *Tenaza* (aviso 0,7, daño 2, barrido), *Marea* (rojo 1,0, ola de agua que cubre media sala; se evita subiendo a la barca/plataformas), *Concha giratoria* (aviso 0,8, rueda y rebota). Ecos 40. Recompensa: una Llave de Playa que abre el atajo al Faro.

**Cinco combinaciones (Costa):**

| # | Encuentro | Lección |
|---|---|---|
| T1 | Hermano de Cal solo en una playa | Aprender el círculo y el Olvido sin presión |
| T2 | Hermano + Acompañante | Prioridad: el Acompañante cubre al Hermano |
| T3 | Cuatro gaviotas en un acantilado | Combate vertical con viento |
| T4 | Cangrejo + gaviotas | Pelear en el suelo mientras te cae algo del cielo |
| T5 | Dos velas errantes + Hermano | Las zonas de luz y de cal se suman: casi no queda suelo seguro |

### 2.6 La Herida (acto V, 11,75 a 13 h)

Inestable, apenas reconocible. Los enemigos son **ecos de los de antes** reconstruidos mal, o la propia ausencia (el Margen). Debe sentirse como un examen final sin ser injusto: **mezcla de habilidades ya vistas**.

| Enemigo | Vida | Aspecto | Comportamiento y ataques | Contrapone | Grupo | Ecos | Motor |
|---|---|---|---|---|---|---|---|
| **Eco Borrado** | 5 | Silueta sin contorno, un cascarón al que le falta el borde | Se **teletransporta** 4 baldosas (aviso: parpadea 0,4), golpe de brazo (aviso 0,4, daño 1) | Predecir el parpadeo (siempre reaparece a la espalda del jugador, a 3 baldosas), parry en el golpe | Tres a la vez, sala circular | 14 | Salto instantáneo (`teleport` en la IA) |
| **Contorno** | 8 | Un trazo negro que dibuja la silueta de lo que fue: serpiente, mano, pájaro. Se mueve como una línea | Segmentos que borran el suelo: zona (rojo 0,7) en la que el suelo desaparece 2 s (se cae a una plataforma inferior o a pinchos) | Moverse; el suelo vuelve | Con Eco Borrado | 16 | `telegraph_zone` que modifica baldosas |
| **Quimera de Rastros** | 14 | Un torso de coloso con las manos de un lancero y la cabeza de un cuervo; ensamblado con partes de otros enemigos | Combina tres ataques (mazazo 0,72/2, estocada 0,42/1, picado 0,45/1) en una secuencia fija que sorprende por encadenar; cada parte es `hurt_zone` con un punto débil en la cabeza | Memorizar el patrón (el orden cambia cada vez, pero cada ataque es de los ya vistos) | Solo, o con un Eco Borrado | 22 | `hurt_zone` + selector |

**Élite de la Herida: Relevo Vacío.** Máscara azul, vida 14. Usa el dash contra el jugador (aviso: se encorva 0,3 s) y ataca en la llegada; aprende: si se le esquiva, la siguiente vez hace una finta. Ecos 28. Es el "examen de dash".

**Minijefe de la Herida: El Doble Vacío.** Silueta del Caminante. Vida 36; imita el Filo, el parry y el dash del jugador (cuidado: sin copiar lo que ha hecho el jugador, para no hacerlo injusto: usa un repertorio fijo de 4 ataques con avisos de 0,5 a 0,8 s). Ecos 50. Narrativamente es el único enemigo que habla (una línea). Recompensa: nada material; abre la puerta al jefe.

**Cinco combinaciones (Herida):**

| # | Encuentro | Lección |
|---|---|---|
| H1 | Un Eco Borrado solo | Nuevo patrón: no se huye, se predice |
| H2 | Tres Ecos en una sala circular | Moverse sin encerrarse |
| H3 | Contorno + Eco | La sala se borra mientras peleas |
| H4 | Quimera + Contorno | Combinar patrones con terreno |
| H5 | Relevo Vacío + dos Ecos | Control de multitud con dash |

---

---

## 3. Marco común de los jefes

### 3.1 Qué se reutiliza del Centinela y qué se saca de él

`boss_room.gd` ya resuelve todo lo que no es "la pelea": disparador al cruzar la línea, dos rastrillos (`arena_gate`), barra (`boss_bar`), reinicio al morir o descansar, recompensa en el centro y registro en `bosses` del guardado. **Se reutiliza tal cual para los nueve jefes restantes** (el único cambio: que `reward_ability` admita también reliquia, sello o llave, mediante un `reward_scene` genérico). Lo que cambia es el script del jefe, que debe cumplir el contrato existente: `take_hit`, `on_parried`, señales `defeated` y `status_changed`, `display_name`, `wake()`, límites de arena.

`centinela.gd` mezcla tres cosas que se repetirán en cada jefe. Se propone extraerlas **cuando se construya el segundo jefe (Jacinto), no antes**:

| Pieza | Qué hace | Estado |
|---|---|---|
| `phase_tracker` (core) | Vida en tramos: dado un total y unos umbrales, dice la fase actual, emite `phase_changed` y fija "suelos" para que el daño no salte de fase (equivale a `CORE_FLOORS`) | Nuevo, generalizando lo del Centinela |
| `attack_picker` (core, E1) | Bolsa barajada con pesos por fase | Nuevo |
| `boss_base` (game/boss) | Estados comunes (dormido, despertar, recuperarse, aturdido, morir), parpadeo de daño, números de daño, chispas, `shake`, tinte de aviso, suelo/tablón/ralentizar | Se extrae del Centinela |

Los jefes sin "armadura" (todos menos el Centinela y, en versión de Calma, Eudora) usan **vida simple repartida en fases por umbrales** con exposición condicionada a un estado (aturdido por parry, recuperación larga, parte rota). Así no se multiplica el arquetipo "armadura + núcleo", que a la tercera vez se vuelve rutina.

### 3.2 Estructura estándar de una pelea

| Momento | Duración | Qué ocurre |
|---|---|---|
| Entrada | 1,5 a 3 s | Cruzar la línea, rastrillos, temblor, nombre en la barra. El jefe despierta (`wake`) con un gesto característico |
| Fase 1: lectura | 55 a 70 s | 3 o 4 ataques, ritmo lento; el jugador aprende las reglas del jefe |
| Transición 1 | 2 s | El jefe se detiene, cambia de pose, el entorno responde (sonido, polvo). **Invulnerable y sin atacar**; el jugador puede curarse con el frasco |
| Fase 2: variación | 50 a 70 s | Ataques de la fase 1 más rápidos (aviso -15 %) más 1 o 2 ataques nuevos |
| Transición 2 | 2 s | Igual; el jefe empieza con una **furia** (serie corta, solo en Centinela y Maelis) o con una **demostración** del ataque nuevo |
| Fase 3: examen | 50 a 80 s | Combina; aparece el ataque-remate |
| Muerte | 3 a 4 s | Cámara lenta (0,3), música se corta, animación de final emocional, Ancla de recompensa |

Duración objetivo: **2,5 a 4 minutos** para un jefe obligatorio sin fallos (6 a 12 minutos con las muertes de aprendizaje); 5 a 6 minutos Maelis. Intentos medios hasta vencerlo: 3 a 6 (Centinela 3, final 8).

### 3.3 Transiciones, frascos y castigo del error

- **Frasco en pelea:** curar tarda 0,9 s de lanzamiento durante los cuales el jugador es vulnerable. Se propone que el frasco cure 1 de vida (lo es hoy) y que el jefe **no tenga ataque automático durante la transición**. Con 3 a 5 frascos, un jefe típico permite 1 o 2 curaciones planificadas.
- **Sin castigo adicional por morir:** reiniciar la pelea, ya definido. Sí se pierde la tanda de Ecos (regla general).
- **El Ancla antes de cada jefe** (regla del canon). Hasta cada jefe hay entre 25 y 60 segundos de camino desde el Ancla con enemigos ya despejados (el carro de la muerte no debe ser un castigo: es un respiro).

### 3.4 Feedback común (hit-stop, cámara, sonido, música)

| Evento | Hit-stop | Cámara | Sonido |
|---|---|---|---|
| Golpe del jugador al jefe | 0,06 s (como hoy) | Temblor leve (2 px, 0,1 s) | Impacto seco; distinto según material |
| Golpe al escudo/armadura | 0,03 s | Ninguno | Metal (`armor_hit`) |
| Parry exitoso | 0,10 s | Temblor medio, zoom 3 % 0,2 s | Chispazo azul y campana corta |
| Ruptura de armadura / fin de fase | 0,15 s | Temblor fuerte (8 px, 0,3 s) | Rotura grave |
| Daño recibido por el jugador | 0,06 s | Temblor fuerte (6 px) | Golpe + latido |
| Muerte del jefe | 0,30 s + cámara lenta 1,0 s al 30 % | Zoom 8 % en el jefe | La música se corta, silencio de 1,5 s, tono de la persona |

**Música de jefe:** sin músicos, con síntesis por código como los efectos (`docs/sonido.md`). Esquema: una **base** de bajo/drone en la tonalidad del jefe, una **capa de pulso** que entra en la fase 2 y una **capa de tensión** que entra en la 3. Cada jefe tiene un **timbre** distinto ligado a su oficio: hoz y viento (Jacinto), plumas rasgando y órgano en seco (Ilara), campana y lacre (Hesper), pico y roca (Magda), cuerda de sala vacía (Casimar), arpa y mar (Eudora), fuelle y llama (Rufo), coro callado (Maelis), pasos y una sola nota larga (Oda). Todos terminan en silencio, no en fanfarria.

**Barra de vida:** nombre en la barra como en el canon (ya definido en `personajes.md`). La barra de Eudora muestra Calma y vida; la de Maelis muestra manos y rostro.

### 3.5 Aleatoriedad controlada (norma)

Todos los jefes usan `attack_picker` con las mismas tres reglas:

1. **No repetir:** el último ataque queda fuera de la bolsa.
2. **Distancia manda:** si el jugador está lejos, se priorizan los ataques de aproximación; si está pegado, los de área. Los pesos cambian de forma gradual (no por umbrales rígidos que se puedan explotar).
3. **Equidad:** si el jugador no ha recibido daño del último ataque tres veces, el picker favorece otro (evita que un jugador atascado vea siempre lo mismo y que uno diestro lo vea siempre estático); si el jugador ha recibido daño del mismo ataque dos veces, no sale el siguiente turno.

Con ello el patrón es **predecible en el carácter e impredecible en el orden**, como en los buenos jefes de acción.

---

## 4. Los diez jefes

Convención de cada ficha: **Arena**, **Vida y fases**, **Ataques** (tabla con aviso / duración / daño / respuesta), **Decisión**, **Exposición**, **Parry**, **Enseña y examina**, **Matices de feedback**, **Recompensa**, **Animación mínima**, **Motor nuevo** y **Prueba clave**. Los números de aviso son de fase 1; en fase 2 se reducen un 15 % y en fase 3 un 25 % (con el suelo de 1.2). Daño en "puntos de vida" del jugador (el jugador tiene entre 5 y 9). La vida del jefe se da en puntos y en **golpes equivalentes** con el Filo que se supone en ese punto del juego.

### 4.1 El Centinela Hueco (construido; qué queda por pulir)

**Estado:** construido, probado por scripts (509 comprobaciones), sin jugar a mano. Arena 64×33, armadura 8/9/10, núcleo 15 (floors 10/5/0), exposición 3 s, parry 1,5 s, 11 animaciones, 40 Ecos, dash como recompensa.

**Qué queda por pulir (en orden de prioridad):**

| # | Asunto | Propuesta |
|---|---|---|
| 1 | **Jugarlo a mano.** Todo lo demás depende de esto | Hito antes de construir el siguiente jefe. Medir intentos, TTK real y dónde se muere |
| 2 | **Furia de la fase 3** (6 mazazos con ondas dobles y rocas) | Riesgo de pico injusto con Filo 1. Si el TTK de la fase 3 supera 90 s o la tasa de muerte en la furia pasa del 50 %, bajar a 5 mazazos y dar 0,6 s de aviso a las rocas. El jugador aún no tiene el dash (lo gana al vencerlo). Las ondas dobles se esquivan con salto, pero la sala debe tener al menos un tablón seguro |
| 3 | **Equidad de la exposición** (3 s) | Con armadura 10 y Filo 1 la tercera fase puede alargarse. Primero bajar la armadura (9 en F3), luego la exposición |
| 4 | **Doble aviso de ataque con onda** | La onda baja (1 daño) debe tener un aviso propio (0,4 s) distinto del mazazo. Hoy se confunden |
| 5 | **Barra de armadura legible** | Dos barras (armadura gris, núcleo rojo) con el nombre; hoy `boss_bar` muestra ambas pero hay que ver que el jugador entiende que el núcleo no baja hasta romper |
| 7 | **Música y secuencia final** | Falta la secuencia del canon: el cascarón sale del hueco del pecho, corre hacia el este y se apaga; la coraza queda arrodillada. Es animación nueva (la hoja actual solo tiene `death`). Pedir 6 fotogramas más para `release` |

### 4.2 Jacinto, el Último Segador (Cinturón alto, hora 4,5)

- **Arena: La Era.** 48×22 baldosas. Suelo plano con un disco central de piedra (12 baldosas). Dos muros de bancal de piedra seca de 14 baldosas, uno a cada lado (el jugador no puede subirlos todavía; Jacinto sí, y lo exhibe). Dos peldaños de piedra a 3 y 5 baldosas en un lado para un respiro vertical. Seis espantapájaros inertes de adorno. Rastrillos en las dos entradas. Aire abierto: cielo y viento.
- **Vida y fases.** 36 puntos (18 golpes con Filo 2). Fase 1 hasta 24, fase 2 hasta 12, fase 3 hasta 0. Sin armadura. Ecos 80.
- **Número de intentos esperado:** 4 a 6.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Siega baja** (barrido a ras, delante) | 0,75 s (hoz atrás) | 0,2 s, alcance 120 px | 1 | Saltar; parry; dash |
| **Vuelta amplia** (giro de 360° con la hoz, radio 130 px) | 0,90 s (se agacha y la hoz arrastra) | 0,5 s | 2 | **Entrar por dentro**: la zona pegada a él (menos de 45 px) no recibe el arco. También se puede retroceder más de 140 px. Parry desvía y lo deja expuesto 1,6 s |
| **Paso de segador** (avanza 3 baldosas y siega) | 0,55 s | 0,3 s | 1 | Saltar o dash por detrás; mal contra el muro |
| **Hoz lanzada** (fase 2; boomerang a 6 baldosas) | 0,60 s (hoz sobre la cabeza) | Va y vuelve en 1,2 s | 1 | Saltar; parry la devuelve. Mientras la hoz está fuera, Jacinto se queda con las manos vacías 1,4 s: **hueco de ataque con doble daño** |
| **Trepa y picado** (fase 2) | 0,5 s agarrado al muro (amarillo) + 0,5 s de sombra roja en el suelo | Cae en 0,3 s, daño en 60 px al aterrizar | 2 | Alejarse de la sombra (no se puede parar). Demuestra el salto de pared: se impulsa desde el muro |
| **Llamada** (fase 2 y 3) | 1,0 s, alza la hoz | Levanta 2 espantapájaros (3 en F3, tope 2 vivos) | Espantapájaro: 1 (aviso 0,65) | Matarlos (vida 3) o ignorarlos; no dan Ecos |
| **Tres vueltas** (fase 3; remate) | 0,9 s solo al principio | Tres vueltas encadenadas, la tercera de radio 160 px | 2 / 2 / 2 | Entrar por dentro de las dos primeras; sobre la tercera, saltar o retroceder. Recuperación larga 1,4 s |

- **Decisión.** `attack_picker` con peso por distancia: lejos favorece Paso de segador y Hoz; cerca, Siega baja y Vuelta amplia. Un máximo de **dos Vueltas amplias en cinco ataques** (la segunda solo si no ha dañado). La Trepa solo sale si el jugador lleva más de 6 s sin acercarse a menos de 4 baldosas (castiga huir).
- **Exposición.** Tras Vuelta amplia o Tres vueltas fallidas queda recuperándose 1,0 a 1,4 s. Parry: 1,6 s. Tras lanzar la hoz: 1,4 s de manos vacías.
- **Parry.** Funciona en Siega, Paso y Vuelta; **no** en el picado ni en las vueltas rojas del remate (la tercera).
- **Enseña / examina.** Enseña **leer un arco y entrar por dentro** (contra el instinto de huir) y **hacer plataformas con el campo de batalla** (el muro del que él cae). Examina el timing del parry y el uso del espacio.
- **Feedback.** Cada vuelta deja una estela de trigo en la hoz; el viento mueve los espantapájaros con el aviso. La música: hoz y viento, sin percusión hasta la fase 2.
- **Recompensa.** El recuerdo de **Salto de pared** y el Nombre. Final emocional: apoya la mano en el muro (la postura del agarre) y la era vuelve a tener trigo por un instante.
- **Animación mínima (filas de hoja):** idle, walk, windup_swing, swing_low, windup_spin, spin, step_slash, throw, catch (sin hoz), climb, wall_hold, dive, summon, hit, stagger, death, release (el trigo). 17 filas, esqueleto humanoide con arma larga.
- **Motor nuevo.** `boss_base`, `attack_picker`, `telegraph_zone` simple (la sombra del picado), `Spawner` con tope, proyectil boomerang (extender `Projectile` con modo retorno).
- **Prueba clave.** La Vuelta amplia no golpea a un objetivo a menos de 45 px; la Trepa no deja al jefe fuera de la arena; los espantapájaros no superan 2 vivos; la hoz vuelve aunque el jugador muera.

### 4.3 Sor Ilara, la Copista (Archivo, hora 6,25)

- **Arena: El Scriptorium Callado.** 56×26 baldosas, techo alto con vigas, 8 pupitres distribuidos en dos filas que sirven de plataformas (altura 2 baldosas), una gran mesa central de 10 baldosas. Los pupitres **se levantan y se borran** (aparecen y desaparecen cada ~6 s con aviso de 1,0 s: se pintan de tinta antes de desvanecerse). Tinta que gotea del techo en puntos marcados. Rastrillos en las dos puertas.
- **Vida.** 40 puntos (20 golpes con Filo 2). Umbrales 28 / 14. Ecos 120. Sin armadura.
- **Mecánica propia: la Copia.** Cada ataque de Ilara se **repite** como copia de tinta pasado un retardo, en el sitio y con la orientación en que se hizo. Fase 1: una copia con retardo de 2,0 s. Fase 2: dos copias (1,5 s y 3,0 s). Fase 3: tres copias (1,2 / 2,4 / 3,6 s), y las copias duran el mismo tiempo que el ataque. Máximo 3 copias vivas. Si se golpea una copia en la fase de aviso se disipa y no ataca.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Pluma** (estocada con la pluma de hierro, alcance 200 px) | 0,60 s | 0,15 s | 1 | Parry; dash; salir del carril. La copia repite desde donde estaba |
| **Tachón** (tres gotas de tinta caen del techo en tres puntos) | 0,80 s (círculos oscuros en el suelo, rojo) | Caen en 0,3 s | 1 | Salir del círculo. Deja charco de tinta 3 s (Lento) |
| **Página** (lanza una hoja que gira y vuelve) | 0,50 s | Va y vuelve 1,6 s | 1 | Saltar; parry la devuelve a Ilara (1 de daño a ella) |
| **Borrón** (se desvanece y aparece al otro lado de la sala) | 0,45 s (la silueta parpadea) | Reaparece con un golpe | 1 | Alejarse; el golpe llega al aparecer. Se puede anticipar |
| **Pupitre** (levanta un pupitre y lo arroja) | 0,70 s | Vuela 400 px | 2 | Saltar; destruir antes de que salga (3 golpes) |
| **Lista** (fase 3; remate) | 1,10 s, alza el libro | Cae una lluvia de tachones en toda la sala en 3 oleadas | 1 por impacto | Moverse al hueco que queda entre oleadas |

- **Decisión.** Picker con peso por posición de las copias: Ilara **no elige un ataque cuyo hueco ya esté cubierto por una copia pendiente** (evita imposibilidad). Máximo dos copias se solapan en la misma mitad de la sala.
- **Exposición.** Tras 3 ataques seguidos queda 1,4 s con la pluma baja. Parry en la Pluma: 1,5 s. Golpear la página devuelta: 1 de daño y 0,8 s de confusión.
- **Enseña / examina.** Enseña **memoria a corto plazo**: lo que ves ahora llegará dos tiempos después. Examina la **planificación** y el uso de plataformas (los pupitres que desaparecen). Premia al jugador que se mueve por el espacio y no por reflejo.
- **Feedback.** Las copias son siluetas azul tinta, translúcidas, con un trazo; cuando atacan, hay una **línea de tinta** que se une con Ilara (para leer de dónde vienen). Música: órgano seco y plumas rasgando; el tempo marca el retardo de la copia (negra = 1,0 s).
- **Recompensa.** La **Llave de Tinta**, el Nombre y el recuerdo de la página con las iniciales "A. V.". Final: la última página que copia está en blanco; la cámara se queda sobre ella dos segundos.
- **Animación mínima:** idle, walk, windup_pluma, pluma, throw_page, cast_drops, vanish, appear, lift_desk, raise_book, hit, stagger, death. 13 filas, esqueleto humanoide con capa. Las copias reutilizan los fotogramas con un tinte.
- **Motor nuevo.** `attack_echo` (cola de acciones con retardo, posición y orientación: unas 40 líneas, vive en `boss_base` o como componente de `game/boss`), plataformas que aparecen y desaparecen (ya hay *tablones*, falta temporizador), `telegraph_zone`.
- **Prueba clave.** Dos copias nunca dejan una zona sin salida durante más de 0,5 s; el pupitre que desaparece con el jugador encima no mata (cae al suelo); matar a Ilara disipa todas las copias y gotas; el contador de copias no supera 3.

### 4.4 Hesper, el Prior (Archivo, hora 7,5)

- **Arena: El Salón de Sellado.** 60×30 baldosas, estanterías-torre en los extremos, un sello de cera gigante en el centro del techo (decorado), cuatro pilares de lacre (rompibles) y dos escalones laterales a 3 baldosas. Hesper levita ligeramente. Antes de la pelea hay una **fase PNJ** de ofrecimiento amable → chantaje amable (texto en `textos-del-juego.md`). Rastrillos habituales.
- **Vida.** 54 puntos (18 golpes con Filo 3 o 27 con Filo 2). Umbrales 36 / 18. Ecos 160. Sin armadura.
- **Mecánica propia: el Sello.** Hesper sella zonas; cada bloque de lacre sella el suelo (bloque de 2×3 baldosas, 3 golpes para romperlo) y, **al romperse, devuelve el golpe a Hesper**: 4 de daño y 1,2 s de aturdimiento. Si el jugador no lo rompe, el bloque desaparece a los 6 s sin efecto. Es un peligro y una herramienta.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Sello** (marca una zona en el suelo) | 1,00 s (círculo rojo con símbolo) | El lacre emerge en 0,3 s | 1 si pisas; si estás dentro, quedas **Fijado** 0,6 s | Salir. Si el bloque se forma sin ti, golpéalo |
| **Mano de cera** (estocada con un cuchillo de lacre) | 0,50 s | 0,15 s, alcance 150 px | 1 | Parry (rinde mucho); dash |
| **Estampa** (sello gigante que cae del techo sobre una zona) | 1,00 s (rojo, sombra) | Cae en 0,2 s | 2 | Salir de la sombra. No se puede parar |
| **Llamada** (fase 2; invoca dos Selladores) | 1,20 s | 2 Selladores (vida 5), tope 2 | Charcos Lentos | Matarlos; los charcos se limpian |
| **Lluvia de cera** (fase 3; gotas en tres carriles) | 0,70 s | 3 oleadas de 4 gotas | 1 | Leer el hueco entre carriles |
| **Pilares** (fase 3; derriba un pilar de lacre) | 0,80 s | Cae, se rompe en plataformas | 1 en el impacto | El pilar roto queda como plataforma |
| **Cierre** (remate; cuatro Sellos a la vez, uno de ellos sin bloque: el camino de salida) | 1,40 s | Todos a la vez | 1 / Fijado | Leer cuál es el hueco |

- **Decisión.** Picker normal; **no puede haber más de 2 bloques de lacre vivos**; si el jugador queda encajado por bloques, el siguiente Sello no aparece en un radio de 3 baldosas.
- **Exposición.** Aturdido 1,2 s al romper un bloque (4 de daño); parry en Mano de cera: 1,5 s.
- **Enseña / examina.** Enseña a **atacar las barreras**, no solo al enemigo. Examina la lectura del campo y el valor de arriesgar (dejar que se forme un bloque cerca para romperlo).
- **Feedback.** Cada bloque roto: hit-stop 0,12 s, campana, trozo de cera en cámara lenta. Música: campana y órgano; el bajo de la fase 3 late al ritmo de los Sellos.
- **Recompensa.** **Sello de Cera**, su juramento ("Nadie más se perderá"). Final: su sello se resquebraja y el ala se vacía (desaparecen pasillos).
- **Animación mínima:** idle (levita), cast_seal, dagger, call, drops, drop_pillar, stagger, death. 8 filas, humanoide con capa ocre. Los efectos (bloque, sello, gotas) son partículas y sprites sueltos.
- **Motor nuevo.** `telegraph_zone` que además **instancia un nodo sólido destructible** (el bloque), `status_effects` (Fijado, Lento), `Spawner`.
- **Prueba clave.** El jugador nunca queda atrapado entre dos bloques sin poder romper alguno; un bloque que aparece sobre el jugador lo expulsa a un lado en lugar de enterrarlo; con la sala llena de bloques, se vence en tiempo finito.

### 4.5 Magda Soler, la Capataz (Minas, hora 9,25)

- **Arena: La Cámara de Apuntalamiento.** 56×34 baldosas, dos niveles: un suelo principal y debajo una galería de 6 baldosas de profundidad con pinchos solo a los extremos; en el centro, el **pozo** (8 baldosas de ancho). Vigas de madera (6) que sostienen el techo, tres plataformas de apuntalamiento. Al fondo, un reflejo rojo: el Latido.
- **Vida.** 66 puntos (22 golpes con Filo 3). Umbrales 44 / 22. Ecos 220. Sin armadura.
- **Mecánica propia: terreno que cambia.** Magda golpea el suelo con el pico y **rompe baldosas** (con aviso), dejando huecos al nivel inferior; golpea una viga y **cae un tramo de techo**. En la fase 3 el suelo principal está casi perforado y la lucha pasa al nivel inferior.
- **Recorte esencial:** no se editan baldosas del mapa. Se usan **losas frágiles** preubicadas (escena `breakable_slab`: aparece, avisa, se hunde y se regenera tras la pelea) y vigas que son *objetos* (no baldosas). Cuesta lo que costó la reja del Centinela.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Pico** (golpe vertical delante, alcance 120 px) | 0,70 s | 0,2 s | 2 | Parry (premia: 1,6 s); dash por detrás |
| **Barrido de pico** (golpe lateral) | 0,55 s | 0,25 s | 1 | Saltar; parry |
| **Golpe Hondo** (hunde el pico en el suelo, onda por el suelo y rompe las losas cercanas) | 0,90 s (rojo, losas parpadean) | Onda 0,4 s | 1 y caída | Saltar la onda, **salir de las losas marcadas**. Magda queda con el pico clavado 1,6 s (**exposición**) |
| **Apuntalar** (golpea una viga) | 0,80 s | Cae un tramo de techo en 3 puntos | 1 por roca | Leer las sombras |
| **Carga del capataz** (fase 2; embiste con el hombro) | 0,60 s (rojo) | 0,5 s a 320 px/s | 2 | Saltar; la carga contra la pared la deja 1,2 s aturdida |
| **Latido** (fase 3; cada 9 s el pozo pulsa) | 1,0 s (el suelo vibra) | Onda circular desde el pozo | 1 | Saltar; ocurre aunque no esté Magda atacando |
| **Última orden** (remate fase 3) | 1,20 s | Tres Golpes Hondos seguidos | 1 / 1 / 1 + caída | Moverse entre golpes |

- **Decisión.** Picker. El Latido es una cuenta atrás independiente (no se elige).
- **Exposición.** Pico clavado: 1,6 s. Carga contra la pared: 1,2 s. Parry en Pico: 1,6 s.
- **Enseña / examina.** Enseña **vigilar el suelo, no solo al enemigo**: cada ataque cambia el campo. Examina lo aprendido de verticalidad (doble salto, salto de pared) para volver arriba desde el nivel inferior (hay paredes agarrables).
- **Feedback.** El suelo marca antes de romperse con grietas amarillas. Música: pico en cadencia de trabajo; en la fase 3 el bajo late como un corazón.
- **Recompensa.** **Excavar (Golpe Hondo)**, **Sello de Piedra**, Nombre. Final: deja el pico y camina hacia el jugador.
- **Animación mínima:** idle, walk, windup_pico, pico, sweep, plant (hunde el pico), pull (saca el pico), charge, hit, stagger, death, drop_pico. 12 filas, humanoide robusto.
- **Motor nuevo.** `breakable_slab`, `hurt_zone` para el pico clavado, proyección de onda por el suelo (hay `Shockwave` del Centinela), `Spawner` no.
- **Prueba clave.** Con el suelo parcialmente roto, siempre hay una ruta de vuelta arriba; el jugador no cae a los pinchos por una losa que no estaba marcada; el techo no cae sobre una zona sin aviso.

### 4.6 Casimar, el Rey sin Reina (Minas, opcional, hora 9)

- **Arena: El Trono Hundido.** 52×28 baldosas, un trono al fondo sobre tres escalones, dos filas de gradas laterales donde se sientan cascarones cortesanos. Alfombra raída. Bóveda alta con pasarela.
- **Vida.** 70 puntos. Umbrales 46 / 24. Ecos 180. Sin armadura. Pesado y lento.
- **Mecánica propia: el Coro.** Cada vez que Casimar pierde **10 puntos** llama a un cortesano (cascarón aplaudidor, vida 4, golpea con un abanico: aviso 0,6, daño 1) que sale de las gradas. Tope 3. Con 3 cortesanos vivos, Casimar **abraza la página** (inmune y curándose 1 punto por segundo) hasta que se mata a uno. Hay que mantenerse en movimiento y matar al coro con criterio.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Cetro** (golpe vertical con el cetro) | 1,00 s | 0,3 s | 2 | Parry (rinde mucho); salir hacia atrás |
| **Decreto** (se levanta y golpea el suelo, una fila de losas) | 0,90 s (rojo) | Onda de 600 px | 1 | Saltar |
| **Aplauso** (cada cortesano que aplaude acelera el aviso del siguiente ataque de Casimar un 15 %, hasta 3 veces) | Ninguno | Pasivo | — | Matar cortesanos |
| **Embestida de trono** (fase 2; se levanta con el trono a la espalda) | 0,80 s | Avanza 4 baldosas | 2 | Esquivar por detrás |
| **Llamamiento** | 1,00 s | Invoca cortesano | — | Matar |
| **Corona** (fase 3; remate) | 1,10 s | Seis proyectiles dorados en abanico | 1 cada uno | Moverse entre ellos |

- **Exposición.** Tras Cetro fallido: 1,2 s. Parry: 1,6 s. Mientras abraza la página, inmune.
- **Enseña / examina.** Enseña a **priorizar objetivos** y a **no quedarse a trading**. Examina el control de multitudes.
- **Recompensa.** Nombre **Áurea** y reliquia **Corona sin Reina**. Final: la página se deshace y se oye reír a una mujer.
- **Animación mínima:** idle (sentado), stand, walk, cetro, decreto, embrace, hit, stagger, death. 9 filas para Casimar y 4 para el cortesano (idle, clap, fan, hit/death).
- **Motor nuevo.** `Spawner` con tope e invulnerabilidad por estado. Todo lo demás existe.
- **Prueba clave.** Con 3 cortesanos Casimar es inmune y el sistema no se atasca: matar cualquiera lo desbloquea; el aplauso nunca baja el aviso por debajo de 0,55 s para daño 2.

### 4.7 Eudora, la Piadosa (Costa, hora 10,9)

- **Arena: El Rellano de Cal.** 60×28 baldosas, abierto al mar por un lado, plataformas de cal blanca; **círculos de cal** que aparecen y desaparecen en el suelo. Gaviotas decorativas. Luz clara y música suave.
- **Vida.** Calma 100 (por fase) y vida 60. Umbrales de vida 40 / 20. Ecos 260.
- **Mecánica propia: la Calma.** Se comporta como la armadura del Centinela, pero **se regenera**: la Calma baja con golpes y sube +6 por segundo si no recibe daño durante 2 s; con Calma > 0, cada golpe hace 1 de daño a la vida y la mayor parte a la Calma; con Calma = 0 queda "inquieta" 3 s y recibe daño completo. Se gana encadenando golpes seguidos, **sin dejar que respire**. El parry en la Mano abierta le quita 40 de Calma de un golpe.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Círculo de cal** (pinta un círculo de 3 baldosas bajo el jugador) | 1,20 s (rojo) | 3 s activo | 1 + **Olvido** 4 s | Salir; el círculo se borra |
| **Mano abierta** (barrido lento hacia delante) | 1,10 s | 0,4 s | 1, empuja | Parry (rinde mucho); dash |
| **Nana** (ola de partículas blancas desde arriba) | 0,90 s | 1,5 s | 1 por oleada | Moverse bajo el hueco; mientras dura no se puede usar frasco |
| **Abrazo** (fase 2; agarra si está cerca) | 0,80 s (rojo) | 0,5 s | 0 pero Fijado 0,8 s | Alejarse |
| **Acompañantes** (fase 3; dos Hermanos de Cal que le dan Calma) | 1,20 s | Dos hermanos | — | Matarlos primero |
| **Olvido** (remate) | 1,30 s | Anula 2 s la curación y los avisos de la vida | 2 | Aguantar |

- **Estado Olvido (HUD).** Reduce el efecto de la curación a la mitad y **difumina** el contador de vida durante su duración (nunca lo oculta: se ve un número aproximado). Tiene su opción de accesibilidad (7.2).
- **Decisión.** Picker lento: pausas largas, para que la pelea se parezca a una conversación. Cada tres ataques da un respiro de 1,0 s.
- **Exposición.** Calma 0: 3 s. Parry en Mano abierta: 1,5 s.
- **Enseña / examina.** Enseña **encadenar sin ser tocado** (ritmo ofensivo) frente a todo lo anterior. Examina la agresividad y la gestión de la curación.
- **Feedback.** Cada golpe encadenado sube un tono; si deja caer la Calma, la música baja. Al morir, olvida al jugador: cambia la animación a una sonrisa y se queda mirándolo. Música: arpa y mar.
- **Recompensa.** **Sello de Cal**, Nombre **Mateo**.
- **Animación mínima:** idle, walk, draw_circle, hand, sing, embrace, call, hit, stagger (inquieta), death, smile. 11 filas.
- **Motor nuevo.** `status_effects` (Olvido, Fijado), `telegraph_zone`, un contador de racha del jugador.
- **Prueba clave.** La Calma no regenera mientras el jugador la esté golpeando; el Olvido caduca; la curación se restablece al terminar; Eudora no es inmune en ningún estado.

### 4.8 Rufo, el Farero (Costa, opcional, hora 10,4)

- **Arena: El Faro de las Velas.** 44×34 baldosas en la sala de la lámpara, con una plataforma circular y **cuatro espejos** móviles en los bordes. Gran lente central. Noche y mar.
- **Vida.** 58 puntos. Umbrales 40 / 20. Ecos 200. Sin armadura.
- **Mecánica propia: luz y sombra.** Cada espejo proyecta un **haz** (línea fina amarilla 0,8 s de aviso, luego haz rojo 0,5 s con daño). Los espejos giran 45° cuando el jugador los **golpea**. Un haz que alcanza a Rufo le hace 6 de daño y lo deslumbra 1,5 s.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Haz** (un espejo dispara una línea) | 0,80 s | 0,5 s | 1 por tick de 0,25 s | Salir de la línea; golpear el espejo para redirigirlo |
| **Barra de tizón** (golpe con una barra al rojo) | 0,60 s | 0,2 s | 1 | Parry |
| **Brasas** (lanza cartas ardiendo en arco, 3) | 0,60 s | Caen en 0,8 s | 1 cada una | Esquivar; dejan fuego 2 s |
| **Barrido de lámpara** (fase 2; la lente gira y hace un barrido de 180°) | 1,20 s (rojo) | 1,0 s | 1 por tick | Ponerse bajo cobertura (sombra tras la lente) |
| **Todos los haces** (fase 3; remate) | 1,30 s | Cuatro haces cruzados | 1 por tick | Ponerse en la sombra que dejan |

- **Decisión.** Picker; Rufo siempre se sitúa en una sombra y ataca poco; el peligro es el entorno.
- **Exposición.** Deslumbrado 1,5 s. Parry en la Barra: 1,5 s.
- **Enseña / examina.** Enseña a **usar el entorno** contra el enemigo. Examina el movimiento y la geometría.
- **Recompensa.** **Vela del Faro** y Nombre. **Dilema:** vencerlo no resuelve nada (canon).
- **Animación mínima:** idle, walk, tizón, throw, dazzled, hit, death. 7 filas más animaciones de espejo (rotar) y lente.
- **Motor nuevo.** `telegraph_zone` lineal (haz), espejo con ángulo (objeto golpeable), recibe ya `take_hit`.
- **Prueba clave.** En cualquier configuración de espejos hay siempre una sombra alcanzable; el haz nunca se solapa con otro haz sin hueco; golpear un espejo no da un ángulo muerto.

### 4.9 Maelis, la Priora Sellada (Herida, hora 12,5)

- **Arena: La Sala del Asiento.** 64×36 baldosas, circular, cinco sillas en círculo (con máscaras azules) y una sexta, la del Caminante, al fondo. Suelo de baldosas con lacre incrustado. Sobre ellas, Maelis emerge de la pared del fondo: **busto con rostro de piedra y dos manos enormes**. Rastrillos que cierran la sala.
- **Vida.** Dos manos de 24 puntos cada una + rostro 32. Ecos 400. Sin armadura convencional: **partes** (`hurt_zone`).
- **Mecánica propia: no quedarse quieto.** Si el jugador permanece con velocidad < 30 px/s más de 1,4 s, el lacre del suelo lo **Fija** 0,6 s y le empuja hacia el asiento. Es lo contrario del dash.
- **Estructura de fases:** F1 manos (rompes una mano, fin de fase 1), F2 segunda mano, F3 el rostro.

| Ataque | Aviso | Duración | Daño | Respuesta |
|---|---|---|---|---|
| **Barrido de mano** | 0,85 s | 0,3 s | 2 | Saltar; dash por debajo |
| **Palma** (aplasta una zona) | 1,00 s (rojo) | 0,25 s | 2 | Salir; la mano queda **hundida 2,0 s**: exposición para golpear (daño x1,5) |
| **Corriente de lacre** (arrastra hacia el asiento) | 0,70 s | 1,5 s | 0 (si llegas al asiento: Fijado 1,5 s y 1) | Dash y doble salto contra corriente |
| **Gotas de lacre** (punto en el suelo) | 0,60 s | Puntos de 2 baldosas | 1 | Moverse |
| **Mano cerrada** (puño que golpea la pared) | 0,90 s | 0,4 s | 1 y piedras | Esquivar |
| **Cierre** (remate de F3: las dos manos se cierran sobre la arena) | 1,20 s, sombra roja en el suelo | 0,3 s | 3 | Quedar bajo un hueco entre los dedos (marcado en el suelo) o fuera del círculo |

- **Decisión.** Picker; la fase 3 añade la corriente de lacre de manera continua.
- **Exposición.** Mano hundida 2,0 s; mano rota: 3 s con el rostro desprotegido.
- **Enseña / examina.** Examina **todo**: movimiento continuo, dash, doble salto, salto de pared, parry; Nombrar tiene un uso opcional (pronunciar un nombre aturde 2 s un brazo).
- **Feedback.** Sala en silencio; sin música hasta la F2; entonces un coro callado. Al caer las manos: sonido de piedra que se afloja, sin cámara lenta: es culpa, no triunfo.
- **Recompensa.** Abre la **Sala de Aún**. Sus manos caen.
- **Animación mínima:** rostro (idle, hit, death), mano (idle, sweep, palm, close, fist, hurt, break) ×2 espejadas. 10 filas.
- **Motor nuevo.** `hurt_zone` (manos), `status_effects` (Fijado), `telegraph_zone` grande, fuerza de arrastre al jugador.
- **Prueba clave.** El hueco entre dedos existe siempre; la corriente de lacre no puede empujar al jugador a una zona de muerte; se vence con el Filo 2 sin Nombrar.

### 4.10 Oda, la Última Mensajera (Pasarela, secreto, hora 13+)

- **Arena: La Pasarela de los Mensajeros.** Los tres huecos de 17 baldosas existentes. Para esta prueba el abismo se cubre con un velo: **los pinchos se retraen** y caer devuelve a la plataforma anterior sin daño.
- **Vida.** No tiene. Hay una barra de **Distancia** (verde cuando la sigues bien).
- **Mecánica: seguir a Oda.** Ella corre por la Pasarela con una secuencia de carreras, saltos y dashes. El jugador debe mantenerse a **menos de 6 baldosas** de ella (1,0 s de gracia) y pasar por los huecos con la misma secuencia. Tres vueltas, de más lenta a más rápida (velocidad 280, 330, 380 px/s). Si te quedas atrás, regresa a un punto de control a esperarte (nunca te castiga). No hace daño.
- **Progresión.** La tercera vuelta exige combinar salto, doble salto y dash en un mismo hueco; ella lo muestra primero con un gesto (se detiene a mitad del hueco y vuelve a hacerlo).
- **Parry.** No hay parry.
- **Enseña / examina.** Enseña (por reflejo) lo que el juego ha enseñado de movimiento; examina el dominio del movimiento. Es un jefe sin combate, que premia a quien ha llegado hasta aquí.
- **Feedback.** Música: una sola nota larga y pasos. Al final se queda quieta, la mira y entrega la insignia.
- **Recompensa.** **Insignia de Mensajera** (reliquia), que habilita el epílogo del Relevo.
- **Animación mínima:** idle, run, dash, jump, wait (de pie), hand (entrega). 6 filas.
- **Motor nuevo.** Un controlador de ruta con puntos y señales de "espera" (no es IA de combate). El velo del abismo es un cambio de tiles.
- **Prueba clave.** Un bot de referencia con dash+doble salto completa las tres vueltas; un jugador parado no queda bloqueado (Oda regresa); nunca daña.

---

## 5. Curva de dificultad de 0 a 15 horas

### 5.1 Principios

1. **El poder del jugador sube más despacio que la amenaza, y sube en dos ejes:** *daño* (golpes para matar) y *resistencia* (vida, frascos). Nunca solo uno.
2. **Los golpes necesarios para un enemigo común se mantienen en 3 a 5**, aunque suba su vida. Si un cascarón de la Herida costase 12 golpes, el combate sería un trámite. La vida de los enemigos sube a la par que el Filo del jugador: el jugador *siente* que el Filo mejora porque los enemigos viejos caen en 1 o 2 golpes (ahí está el "poder"), mientras los nuevos siguen pidiendo 3 a 5.
3. **El daño recibido casi no sube** (1 hasta el Archivo; 2 en pocos enemigos: coloso, cavador, élites; 3 solo en el remate de Maelis). La amenaza crece en **cantidad y combinación**, no en cifras de daño. Con vida máxima 5 a 9, subir el daño medio lo volvería injusto.
4. **Aprendizaje por capas:** cada región enseña un verbo nuevo de combate (Cinturón: aviso y esquiva; Archivo: parry y prioridades; Minas: verticalidad y entorno; Costa: estados y racha; Herida: todo junto).
5. **Los primeros 40 minutos son un tutorial sin texto:** cascarón solo, luego lancero, luego arrojador. El Centinela es el primer examen y debe poder ganarse con el Filo base, un parry decente y 3 frascos.

### 5.2 Tabla maestra

Supone el recorrido de `guion-maestro.md`. Los valores de jugador son los **esperados** con el gasto medio de Ecos; un jugador con más Ecos va por delante, uno que muere mucho por detrás.

| Hora | Hito | Vida del jugador | Daño del Filo | Frascos | Guardia (parry) | Enemigo típico (vida / daño) | Golpes para matar un común | Jefe (vida total) | Golpes al jefe | Intentos esperados |
|---|---|---|---|---|---|---|---|---|---|---|
| 0:00 a 0:45 | Umbral y Terrazas | 5 | 1 | 0 a 1 | 0,2 s | 2 a 4 / 1 | 2 a 4 | — | — | — |
| 0:45 a 1:45 | Cisterna y Galerías | 5 | 1 | 3 | 0,2 s | 3 a 10 / 1 (coloso 2) | 3 a 4 | — | — | — |
| 2:00 | **Centinela Hueco** | 5 a 6 | 1 a 2 | 3 | 0,2 s | — | — | 27 de armadura + 15 | ~42 con Filo 1; ~22 con Filo 2 | 3 a 5 |
| 3:30 | Torre de Riego | 6 | 2 | 3 | 0,2 a 0,26 | 3 a 6 / 1 | 2 a 3 | Mastines, espantapájaros | — | — |
| 4:30 | **Jacinto** | 6 a 7 | 2 | 4 | 0,26 | 4 a 7 / 1 | 3 a 4 | 36 | 18 | 4 a 6 |
| 5:00 a 6:15 | Archivo (primera parte) | 7 | 2 | 4 | 0,26 | 4 a 9 / 1 (escudo) | 3 a 5 | — | — | — |
| 6:15 | **Ilara** | 7 | 2 | 4 | 0,26 | — | — | 40 | 20 | 4 a 6 |
| 7:30 | **Hesper** | 7 a 8 | 2 a 3 | 4 | 0,32 | — | — | 54 | ~22 (con bloques) | 4 a 7 |
| 7:30 a 9:00 | Minas (primera parte) | 8 | 3 | 4 a 5 | 0,32 | 4 a 10 / 1 a 2 | 2 a 4 | Madre de Veta (50) | 17 | 2 a 4 |
| 9:00 | **Casimar** (opc.) | 8 | 3 | 5 | 0,32 | — | — | 70 | 24 | 4 a 6 |
| 9:15 | **Magda** | 8 | 3 | 5 | 0,32 | — | — | 66 | 22 | 5 a 7 |
| 9:45 a 10:50 | Costa | 8 a 9 | 3 | 5 | 0,38 | 4 a 8 / 1 | 2 a 3 | Ermitaño Mayor (44) | 15 | 2 a 4 |
| 10:50 | **Eudora** | 9 | 3 | 5 | 0,38 | — | — | Calma 100 + 60 | ~25 | 4 a 6 |
| 10:20 | **Rufo** (opc.) | 8 a 9 | 3 | 5 | 0,38 | — | — | 58 | 20 | 4 a 6 |
| 11:45 | La Herida | 9 | 3 | 5 | 0,38 | 5 a 14 / 1 | 2 a 5 | Doble Vacío (36) | 12 | 3 a 5 |
| 12:30 | **Maelis** | 9 | 3 | 5 | 0,38 | — | — | 24 + 24 + 32 | ~27 | 6 a 9 |
| 13:00 a 15:00 | Secretos | 9 | 3 | 5 | 0,38 | — | — | Oda (sin vida) | — | 2 a 5 |

Nota sobre el valor de "Guardia": son los tres niveles del árbol (0,2 → 0,26 → 0,32 → 0,38). Hoy no hay números oficiales de cada nivel; es una propuesta de +0,06 por nivel.

### 5.4 Lo que pido a la economía

Este documento da necesidades, no cifras de precios:

1. **Ecos por hora:** unos 10 a 20 Ecos por minuto de exploración activa en el Cinturón, 25 a 40 en el Archivo y las Minas, y 40 a 70 en la Herida. Con los Ecos por enemigo de la sección 2 salen unos 2.200 acumulables en el camino principal. El árbol actual suma 310; **sobra**. Propongo que la economía tenga un segundo sumidero (reliquias y mejoras de Nombres) y que los niveles del árbol cuesten más a partir del nivel 2 (ver pregunta 9 de la sección 9.1).
2. **Las reliquias** deben ofrecer opciones de combate **laterales** (no más daño) (reliquias que cambien el estilo: parry que cura medio punto, ataque arriba más fuerte contra voladores, estados más cortos).
3. **Pérdida por muerte:** al morir se pierden todos los Ecos; con 200 Ecos en la mano el castigo duele, con 20 no. Pido que se estudie un **límite de pérdida por muerte** (por ejemplo, un máximo del 50 % en una zona de jefes) para que los jefes no sean una apuesta de 200 Ecos.
4. **El precio del frasco extra** y de la Vitalidad deben ser accesibles antes del jefe 4 (Hesper) para el jugador medio.
5. **No dar Ecos al repetir enemigos** más de dos veces en una misma sesión de zona (anti-farm): propuesta, Ecos que se reducen al 50 % a la tercera reaparición. Es una decisión de economía, no de combate.

---

## 6. Ataques del jugador pendientes

### 6.1 Diagnóstico

Hoy solo existe el tajo horizontal, el parry y el dash. En el diseño de este documento hay **veinte** enemigos y tres jefes que necesitan responder en vertical o conectar con pogo: cuervo, polilla, murciélago, gaviota, vela errante, pez de plata, geoda, cangrejo, Madre de Veta, Hesper (levita), Ilara (borrón), manos de Maelis. El documento `nucleo-jugable.md` ya prometía ataque arriba y abajo. Se pide implementarlos **antes del Archivo**.

### 6.2 Propuesta

| # | Ataque | Control | Qué hace | Coste (motor y diseño) | Reglas |
|---|---|---|---|---|---|
| P1 | **Ataque hacia arriba** | Arriba + atacar (en suelo o aire) | Tajo con la hitbox sobre la cabeza (36×44 px, alcance vertical 44), mismo daño y enfriamiento que el horizontal | Pequeño: un `AttackHitbox` más y una animación (1 fila). Control: la dirección "arriba" ya existe para mirar | No cancela el parry; da daño completo; no empuja al jugador |
| P2 | **Ataque hacia abajo con pogo** | Abajo + atacar en el aire | Hitbox bajo los pies (30×36). Si conecta con **enemigo, objeto golpeable o pinchos**, el jugador rebota hacia arriba una altura de 0,7 de salto (~126 px) | Medio: rebote, interacción con `SpikeHazard` (hoy hace daño y devuelve al suelo firme; el pogo anula ese daño), animación | Mientras se rebota se puede encadenar otro golpe abajo. **No recarga el dash ni el doble salto** (protege los puzles existentes de La Chimenea y La Pasarela, que se calcularon sin pogo; la recarga se podría activar como mejora en el futuro) |
| P3 | **Golpe Hondo (Excavar)** | Abajo + atacar en el aire, con la habilidad | Caída rápida (700 px/s) y onda al aterrizar (radio 80 px, daño 2). Rompe suelo frágil y losas. Sustituye al pogo mientras se mantiene pulsado | Medio: ya figura como habilidad 4 de progresión. Aplicar a enemigos con `hurt_zone` | Recuperación 0,4 s al aterrizar; enfriamiento 1,2 s; no usable sobre pinchos |
| P4 | **Nombrar en combate** | Mantener la acción ante un enemigo cascarón | Aturde 2 s al cascarón vaciado ("un nombre dicho devuelve un instante de sí mismo"); contra jefes solo funciona en las manos de Maelis | Pequeño: ya es mecánica de Nombrar; 6 s de enfriamiento. Se limita a cascarones | Gasta un Nombre ya sostenido; no se gasta, se "presta" |
| P5 | **Curación con riesgo** (existe) | H | Curar 1 vida en 0,9 s con la guardia baja | Ya existe; asegurar que la cura **se cancela al recibir daño** | Es el eje del "cuándo curarse" de los jefes |

---

## 7. Accesibilidad de combate: modo asistido sin trivializar

### 7.1 Principios

1. **Voluntario y por capas:** cada ayuda se activa por separado y se pueden combinar. No hay "modo fácil" cerrado.
2. **Sin marca ni castigo:** no cambia el final, no bloquea logros o Nombres, no se anuncia en pantalla.
3. **Nunca se elimina el aprendizaje:** las ayudas **ensanchan el margen**, no quitan el reto. Un aviso de 0,28 s sigue necesitando respuesta.
4. **Se puede activar a media partida** y desactivar. Tras 5 muertes seguidas ante el mismo jefe, un mensaje discreto en el menú de pausa sugiere abrir las opciones (nunca activa nada solo).

### 7.2 Tabla de opciones

| Opción | Qué hace | Valores | Por qué no trivializa |
|---|---|---|---|
| **Avisos más largos** | Multiplica el tiempo de aviso de enemigos y jefes | x1 / x1,25 / x1,5 | El patrón y la lectura siguen siendo los mismos; solo se gana tiempo de reacción |
| **Ventana de parry ampliada** | Suma a la ventana del parry | +0 / +0,05 / +0,10 s | Sigue habiendo que decidir cuándo; no es automático |
| **Memoria de pulsación (buffer)** | El parry y el ataque se guardan si se pulsan hasta 0,12 s antes de poder ejecutarse | Siempre activo (para todos) | Estándar; no es ayuda, es corrección |
| **Daño reducido** | Los golpes de 2 o más hacen un punto menos (los de 1 no bajan) | Desactivado / Reducido | Nunca desaparece; un golpe de 1 sigue quitando vida |
| **Frasco extra** | +1 carga de curación | Sí / No | Un recurso más, no inmunidad |
| **Vida de los jefes** | Multiplica la vida de los jefes | 100 % / 80 % / 65 % | Los patrones y ataques son idénticos; el mínimo es 65 % para que las fases existan |
| **Velocidad de juego en combate** | Reduce la velocidad de todo (jugador, enemigos) mientras hay un jefe vivo | 100 % / 90 % / 80 % | No cambia el diseño; ayuda a quien reacciona despacio |
| **Marca de aviso** | Dibuja la zona de peligro con borde grueso y símbolo: línea continua = parable, rayas = no parable | Sí / No | Solo hace legible lo que ya estaba |
| **Alto contraste de avisos** | Cambia el amarillo y el rojo por una pareja con más separación y añade un **icono** (flecha vs. rombo) | Sí / No | Daltonismo y baja visión |
| **Temblor de cámara** | Reduce el temblor de cámara | 100 % / 50 % / 0 % | Mareos |
| **Parpadeos** | Sustituye destellos por un cambio de color sostenido | Sí / No | Fotosensibilidad |
| **Aviso sonoro** | Cada ataque con aviso emite un tono corto característico (más agudo si es rojo) | Sí / No | Jugadores con visión reducida; sin sonido no pasa nada porque sigue el visual |
| **Eudora sin ocultar la vida** | El estado Olvido no difumina el contador de vida | Sí / No | Mantiene el efecto sobre la curación |
| **Remapeo** | Todos los botones reasignables, incluidos los del mando | Siempre | Estándar |

---

## 8. Pruebas automáticas

La prueba de humo (`tests/smoke_test.gd`, 509 comprobaciones) ya cubre el Centinela. Se propone generalizarla con un **banco de pruebas de jefe** reutilizable, `tests/boss_harness.gd`, que cada jefe nuevo invoque con su escena y sus parámetros, y un banco análogo para enemigos.

### 8.1 Invariantes para cualquier enemigo común

| Prueba | Qué se comprueba |
|---|---|
| Aviso mínimo | El tiempo de aviso es ≥ 0,28 s y no es menor que el mínimo de la tabla 1.2 para su daño |
| Sin daño por contacto | Con el jugador pegado a un enemigo en `PATROL`, la vida no baja |
| Sala y puertas | Con el jugador fuera de la sala (o a < 4 baldosas de la puerta) no ataca ni persigue |
| Parry | Un golpe frontal con el parry activo no daña, aturde al enemigo `parry_stun_time`, y el daño recibido es el doble |
| Retroceso | Un golpe suyo y uno del jugador producen retroceso; el golpe del jugador cancela su ataque |
| Muerte y Ecos | Al morir suelta `ecos_reward` exactos; no queda ningún nodo huérfano (proyectil, charco) |
| Reaparición | Tras descansar en un Ancla, todos los enemigos de la sala están a su estado inicial |
| Vuelo/embestida | Los voladores no atraviesan suelo ni techo; la embestida se corta en bordes y paredes |
| Estados | Un estado aplicado (Lento, Olvido, Fijado) caduca; morir lo limpia |
| Ataque arriba/abajo | Cada volador recibe daño del ataque hacia arriba; el pogo rebota sobre geoda y pez de plata |

### 8.2 Invariantes para cualquier jefe

| # | Prueba | Cómo |
|---|---|---|
| J1 | **Fases** | Forzar la vida del jefe a cada umbral y comprobar que `phase_changed` salta exactamente una vez y que el jefe no salta dos fases por un golpe grande |
| J2 | **Ataques forzados** | Un método `debug_force_attack(id)` lanza cada ataque; se comprueba el aviso (≥ mínimo), la duración y el daño de la tabla |
| J3 | **Parry** | El parry en cada ataque marcado como parable produce la exposición declarada; en los rojos, el parry no los desvía |
| J4 | **Exposición** | El jefe es golpeable solo en los estados declarados; tras la ventana vuelve a defenderse |
| J5 | **Reinicio** | Morir del jugador o descansar reinicia al jefe a su vida y fase iniciales, abre los rastrillos y limpia invocaciones, proyectiles, copias, charcos, bloques y losas rotas |
| J6 | **Victoria persistente** | Vencerlo queda en `bosses` del guardado, no vuelve a aparecer y la recompensa existe en la sala aunque se cargue la partida sin haberla cogido |
| J7 | **No softlock de sala** | En todo momento hay al menos un camino desde cualquier posición del jugador a una zona de suelo; los rastrillos se abren al vencer o al morir; el jugador no queda dentro de un nodo sólido del jefe |
| J8 | **Vigilante** | Ningún estado del jefe dura más que su máximo declarado + 1 s (un watchdog en la prueba falla si el jefe se queda en un estado) |
| J9 | **Límites** | El jefe no sale de la arena (`arena_left/right/ceiling`) en 60 s de simulación aleatoria |
| J10 | **Bot de referencia** | Un bot sencillo (esquiva con salto cuando hay aviso, golpea si hay exposición) debe vencer al jefe en < 8 min sin parry; otro bot que solo pulsa ataque y salta al azar debe **perder** o tardar > 15 min (si lo vence sin leer el patrón, el jefe es demasiado fácil) |
| J11 | **Fuzz** | 60 s de entradas aleatorias sin excepciones, NaN ni nodos que crezcan sin tope |
| J12 | **Aleatoriedad** | Con 1.000 elecciones del `attack_picker`, ningún ataque se repite consecutivamente, y todos aparecen con frecuencia en un rango esperado |
| J13 | **Accesibilidad** | Con todas las ayudas activadas, los avisos se alargan según el factor y nunca bajan del mínimo |
| J14 | **Cámara y sonido** | El jefe emite sus señales de feedback (`shake`, `Sfx.play`) en los eventos listados |


**Pruebas de encuentro (las 30 combinaciones):** se cruza sin daño con las habilidades disponibles en ese punto; un bot cauto la supera con al menos el 60 % de la vida; un bot que solo corre sale dañado; ningún enemigo se atasca en tablones o paredes.

Todas las pruebas se añaden a `tests/smoke_test.gd` o a ficheros hermanos que la prueba de humo ejecuta; sustituyen a "mirar si va" pero no a **jugarlo** (los números de este documento son hipótesis).

---

## 9. Preguntas abiertas y riesgos

### 9.1 Preguntas abiertas (para la reunión)

| # | Pregunta | Quién | Mi recomendación |
|---|---|---|---|
| 1 | ¿Se aprueba el color **rojo** = no parable? | Diseño de combate + arte | Sí; es una regla sencilla y da variedad a los jefes |
| 2 | ¿El dash debe tener **invulnerabilidad** breve (0,10 a 0,15 s)? Afecta a Relevo, Oda, Maelis y a toda la arquitectura de avisos | Combate y movimiento | No al principio; estudiarlo después de jugar. Si se añade, hay que subir avisos y reducir ventanas |
| 3 | ¿El pogo recarga dash/doble salto? | Diseño de niveles | No: se protegen los puzles construidos. Se puede dar con la reliquia "Collar de pasos" |
| 4 | ¿Cuántos frascos por nivel de Frascos? ¿Y cuántos al principio? | Economía | 3 al principio, hasta 5; 1 curación = 1 punto de vida |
| 5 | ¿La Guardia sube de 0,2 a 0,38 s? | Economía + combate | Mejor que llegue a 0,32 como máximo; 0,38 con Alcance ya es casi automático. Bajar a +0,04 por nivel |
| 6 | ¿Jefes con vida compartida por partes (Maelis) o con una sola barra? | Combate + UI | Partes; la barra muestra manos y rostro. Es la única pelea que lo pide |
| 7 | ¿Se acepta el recorte de terreno (losas frágiles en lugar de editar baldosas)? | Programación | Sí; coste 1/5 del terreno dinámico real |
| 8 | ¿Los enemigos de dos regiones pueden aparecer en la otra (orden libre Minas/Costa)? | Diseño de niveles | Sí, solo variantes (cascarón de Cal en las Minas como refugiado) |
| 9 | Árbol de habilidades: ¿se amplía? (Ecos acumulables ≈ 2.200, árbol = 310) | Economía | Sí: ramas de reliquias y ampliar niveles hasta 4; si no, los Ecos pierden valor |
| 10 | ¿Los jefes opcionales (Casimar y Rufo) dan menos Ecos? | Economía | Más (compensación); su recompensa es una reliquia |
| 11 | ¿Nombrar como arma contra cascarones es un exceso? | Narrativa + combate | Recorte permitido (el guion maestro ya lo marca): solo aturdir 2 s cascarones, no jefes |
| 12 | ¿Cuántos esqueletos nuevos se pueden dibujar al mes? | Arte | Este documento asume 4 a 6 por región |

### 9.2 Riesgos

| Riesgo | Probabilidad | Impacto | Mitigación |
|---|---|---|---|
| **Sobredimensión:** 28 enemigos, 5 minijefes y 10 jefes superan lo que un desarrollador puede hacer en un tiempo razonable | Alta | Alto | Hacer primero el **núcleo mínimo**: 3 enemigos nuevos por región + 1 élite + jefe. Los minijefes pueden reutilizar esqueletos de los jefes (recolor y partes) |
| **Los jefes no se divierten** porque los números son teóricos | Alta | Alto | Jugar cada jefe 10 veces antes de cerrarlo; bajar siempre antes la armadura/vida que la dificultad de los ataques |
| **Retroceso en la mecánica de parry:** si todos los ataques son parables, es la única respuesta | Media | Medio | Regla del rojo; Hesper y Maelis tienen ataques no parables clave |
| **Estados del jugador** (Olvido, Fijado) frustran, parecen injustos | Media | Alto | Duraciones cortas (≤ 4 s), siempre con aviso rojo, sin encadenar dos estados; opción de accesibilidad |
| **Terreno cambiante** (Magda, Hesper) crea softlocks | Media | Alto | Recorte a objetos preubicados; pruebas J7 |
| **Voladores fastidian** si el ataque arriba no se siente bien | Media | Medio | Implementar P1 antes de colocar un solo volador; en su defecto, que los voladores sean cortos de vida (2) |
| **Fatiga de jefe:** 10 jefes con avisos amarillos acaban pareciéndose | Media | Medio | Cada jefe tiene un verbo propio (arco, copia, sello, suelo, coro, calma, luz, quietud, seguir) |
| **El Centinela como plantilla es demasiado duro** y marca un listón que luego no se mantiene | Media | Alto | Jugarlo primero; si sobra tiempo de pelea (> 5 min), recortar antes de construir Jacinto |


Las decisiones de arriba son propuestas: el usuario toma las decisiones finales del proyecto.
