# Decisiones del editor de sistemas, combate y progresión

Autor: editor de sistemas, combate y progresión. Estado: **propuesta unificada para que el usuario la apruebe**; las decisiones finales del proyecto son suyas. Resuelve las contradicciones entre las propuestas `04-combate-enemigos-jefes.md` y `05-progresion-y-economia.md` (y las de mapa, puzles y arte que las tocan) y deja escritos los documentos vivos `docs/nucleo-jugable.md`, `docs/jefes.md` y `docs/enemigos.md`. No se ha tocado código ni ningún otro documento.

Criterios, por orden: (1) **coherencia con el canon cerrado** (`historia.md`, `guion-maestro.md`, `personajes.md`, `textos-del-juego.md`), que manda; (2) **simplicidad** y "nada por si acaso" (`CLAUDE.md`); (3) **alcance realista para una sola persona**; (4) que ningún sistema rompa los puzles ya validados (el movimiento no se compra). Todas las cifras son de partida y se ajustan jugando.

## 1. Tabla de decisiones

| # | Asunto | Propuestas | Decisión | Por qué |
|---|---|---|---|---|
| 1 | **Frasco de curación** | Hoy: cura del todo e instantáneo. 04: "cura 1 vida, lanzamiento de 0,9 s (lo es hoy)". 05: cura 3 (hasta 5), sorbo de 0,70 s interrumpible, hasta 6 frascos | **Se adopta la de 05 con ajustes**: cura base 3 → 5 (Aliento), sorbo de 0,70 s (la carga se gasta y la vida se recupera **al terminar**), un golpe lo interrumpe y no gasta carga, saltar o hacer dash lo cancela sin coste, hasta **5** frascos | El dato de 04 es incorrecto: el código cura del todo (`HealthComponent.use_heal_charge()` pone `health = max_health`). Con 13 de vida, 5 frascos de cura total serían 65 vidas de colchón y ningún jefe sería peligroso. Con 1 vida por frasco (04), 3 frascos = 3 vidas sobre una barra de 5-7: el frasco apenas importaría. Con 3 vidas, un jefe del Centinela (varios golpes de 2) se afronta con 7 + 9 = 16 vidas, unos 8 golpes de tolerancia en toda la pelea, frente a los 3-6 intentos esperados. Es compatible con la curva de 04 porque sus transiciones entre fases (2 s sin ataques) dan sitio a un sorbo de 0,70 s |
| 2 | Número de frascos y fragmentos de frasco | 05: tope 6 (3 + 2 del árbol + 1 por 3 fragmentos de frasco) | **Tope 5, sin fragmentos de frasco** | 6 × 5 = 30 vidas de cura son más del doble de la barra; los 3 fragmentos añadían una clase de coleccionable, 3 puzles y 3 iconos para un frasco más. Los fragmentos de vida (12) ya cubren la recompensa de explorar |
| 3 | Vida máxima | 05: 5 + 4 (Vitalidad) + 3 (12 fragmentos / 4) + 1 (Trapo) = 13 | **Adoptada**: 12 fragmentos de vida, tope 13 con el Trapo de Iria equipado (12 sin él) | Cuadra con el canon (el Trapo es +1 vida máxima) y con la sensación de "cinco golpes" (daño enemigo 1-2). Los fragmentos llegan en hitos emocionales y nunca en las dos primeras horas. HUD: una sola fila de 13 placas de 16 px cabe en 864 px (se cierra el riesgo R13 de 05) |
| 4 | **Árbol de habilidades** | 05: 21 mejoras, 43 niveles, 2.180 Ecos (12 mejoras nuevas) | **14 mejoras, 29 niveles, 1.800 Ecos** (5 nuevas: Aliento, Brasa, Castigo, Paso fantasma, Voz). Se conservan los 9 ids actuales | Cada mejora nueva es código en `player.gd`/`enemy.gd`. Caen: **Sorbo** (la Aguja ya acorta el sorbo), **Fortaleza** (retroceso), **Rompecorazas** (solo sirve en el Centinela y el Custodio), **Peso**, **Desvío** (devolver proyectiles pasa a ser comportamiento base de los que ya lo soportan), **Latido** y **Asidero** (tolerancia de ejecución, mejor como corrección base). Caben en una vista de 3 × 5 sin scroll y se revisan con jefes que existen. Conserva las puertas de historia que dan sentido al reparto (Brasa-Hesper, Castigo-Jacinto, Paso fantasma-Dash, Voz-Nombrar) |
| 5 | Costes del árbol | 05: "los costes actuales ×2,3 → 710 las nueve" | **Costes recalculados** (tabla en `nucleo-jugable.md`): 9 originales suben de 310 a 1.060 Ecos y las 5 nuevas suman 740 | Aritmética de 05: las nueve originales con sus precios nuevos suman **835**, no 710 (error de la propuesta). Se recalcula con la regla "primer nivel de lo útil 10-35, último 70-110, lo que cambia el estilo 100-160" y se fija un test que verifique la suma (1.800) |
| 6 | **Reliquias** | 05: 22 con "Hilos" (3 base, +5 por Nombres, +1 Piedra; 9 máx; coste 0-3). Canon: 15 (14 + Insignia). Arte (03): 3 ranuras → 6, cuestan 1-2 | **16 reliquias**: las 15 del canon + **Hebra de Cal** (Casilda promete "una reliquia"). **Ranuras**: 3 al empezar, **+1 por cada Sello** (Cera, Piedra, Cal), 6 máx; cada reliquia ocupa 1 o 2 | Sin canon y sin PNJ que las pida, las 6 reliquias nuevas de 05 (Hoz mellada, Clavo de Cano, Piedra menor de Linde, Brújula de Mirena, Pizarra de Brunel, Moneda sin cara) son 6 iconos, 6 textos y 6 efectos por si acaso. Ranuras y Sellos reutilizan hitos que ya existen y coinciden con la propuesta de los artistas (3 → 6, 1-2). **Hay que añadir la Hebra de Cal a `textos-del-juego.md` §7** (lo cierra quien lleve el canon) |
| 7 | **Hilos por Nombres leídos** (05) | +1 Hilo por cada 6 Nombres leídos | **Descartado** | Contradice el canon: los Nombres "no dan Ecos, ni vida, ni daño. Nada más" (`guion-maestro.md` §10.1) y "un solo contador" (§10.5). Habría convertido un coleccionable narrativo en poder y en la razón de no callar |
| 8 | **El Paño y los Nombres** (qué dan) | 05: leer = Hilos y diario; callar = 40 Ecos, sin quitar Hilos | **Leer**: diario, Compartir (20 de 30 sostenidos), epílogos; nada más. **Callar**: **50 Ecos**, no cuenta como sostenido, fuente en blanco para siempre, confirmación con "No" por defecto y contador visible | Canon: el pago es "del orden de un nivel medio del árbol", una ventaja real. Con los precios nuevos (35-110), 50 lo es. Se calla hasta 8 sin perder el final (400-500 Ecos como máximo), así que no hace falta tope artificial. El pago es el único número que se ajusta jugando |
| 9 | **Aviso rojo** y arte (simetría de pose) | 04: amarillo parable, rojo no parable. Arte (05): pose asimétrica = parable, simétrica = rojo, como regla | **Adoptado el rojo.** La simetría es una **guía de dibujo, no una ley**: el código manda (`parryable`) y **todo rojo lleva marca de suelo con bandas diagonales** | Sin la distinción, el parry es la respuesta a todo y los jefes pierden variedad. La pose no basta: Jacinto, Eudora y Casimar tensan la regla (las propias artistas lo admiten), y a 100 px un píxel de pose no se lee. La marca en el suelo y el sonido grave resuelven los casos límite y la accesibilidad. El aviso es una capa de código (hoy `modulate`), como proponen los artistas |
| 10 | Mínimos de aviso | 04: tabla por daño (0,28/0,40; 0,55/0,70/0,90; 1,10). 05: 0,45 s para un golpe, 0,35 s para 1 de daño rápido | **Tabla de 04**; en fases 2-3 se acorta (−15 %/−25 %) **sin bajar del mínimo de su fila** | La regla de 05 contradice lo ya construido (cascarón 0,30 s, acechador 0,28 s). La tabla por daño es coherente con los enemigos actuales y deja a los de 2 de daño siempre ≥ 0,55 s |
| 11 | Daño máximo por golpe | 05: ≤ 25 % de la vida esperada. 04: ≤ 2, 3 solo en el remate de Maelis | **Regla de 04** más "nada mata de un golpe a vida llena" | El 25 % no se cumple ni en lo construido: el mazazo del Centinela (2) quita el 29-40 % de una vida de 5-7. Se mantiene el 3 (remate de Maelis con 12-13 de vida = 23 %) |
| 12 | **Ataque arriba, abajo (pogo) y Golpe Hondo** | 04 P1-P3; 03 (puzles) Q1: ¿Excavar rompe suelos con "abajo + atacar en suelo" o con el pogo? | **Arriba** (Arriba + X), **abajo con pogo** (Abajo + X en el aire) y **Excavar = el ataque hacia abajo rompe lo hondo (suelos) y el tajo rompe muros hondos**. Sin caída cargada con onda. El pogo **no rebota en pinchos** y **no recarga dash ni doble salto** | Los voladores y varios jefes no tienen respuesta sin ellos: es la prioridad nº 1 de combate antes de colocar el primer volador. Un pogo sobre pinchos continuos permitiría cruzar La Pasarela sin dash (rebotes encadenados) y rompe los puzles validados. La caída cargada del Golpe Hondo (velocidad, onda, recuperación) es un estado más para un solo uso: el verbo de Excavar es romper |
| 13 | Lienzo del Caminante | Arte 04: 112×64 → **112×96** (S, primero de todo) o 112×80 con un golpe más corto | **112×96**, antes de dibujar ninguna animación nueva | La punta de la daga hacia arriba se sale hoy del lienzo. Es un cambio S (la colisión no cambia, solo se desplaza el `Sprite2D` 16 px y se regenera) y evita rehacer después |
| 14 | Invulnerabilidad del dash | 04 Q2: no al principio. 05: Paso fantasma (35 %/60 % de la duración) | **Sin invulnerabilidad de base**; **Paso fantasma** como mejora de árbol (2 niveles, puerta: tener el Dash) | Todos los avisos y las ventanas se diseñan sin ella (04); una mejora opcional que da 0,05-0,09 s no altera los jefes del personaje esperado. Es la más "divertida" de las nuevas de Espíritu y cuesta una línea (invulnerabilidad durante el dash) |
| 15 | **Tipos de cuerpo de enemigo** | Arte: 6 (H, A, Q, V, S, P); 04 los usa todos | **Tres tipos (H, A, V) + "objetos animados" dibujados a mano**; el multiparte solo para Maelis como escena de `Sprite2D`, sin rig genérico. Caen **Q** (cuadrúpedo) y **S** (segmentado) | Q costaba 5-6 días por dos criaturas y S 2-3 por tres; sus enemigos o caen (Mastín, Pez de Plata, Gusano de Veta, Contorno) o se dibujan como objeto (Chinche = bola, Geoda = roca). H cubre más de la mitad del bestiario y 8 jefes |
| 16 | **Número de enemigos y jefes** | 04: 28 comunes + 5 élites + 5 minijefes (+ 10 jefes), 30 combinaciones. Arte: 196 puntos, mínimo viable ~140 | **20 comunes + 5 élites + 2 minijefes + 10 jefes (37 entradas), 21 combinaciones** (≈123-138 puntos de arte) | Para una persona, 48 entradas y 6 tipos de cuerpo es el riesgo nº 1 que el propio 04 señala. Se queda lo que enseña un verbo único o es barato (humanoide). Cae todo lo que solo aportaba un cuerpo caro o duplicaba a otro. La Herida reutiliza enemigos de otras regiones (es canon: reconstruye fragmentos) |
| 17 | Reparto de jefes y producción | 10 jefes, 7 obligatorios; orden de recorte del canon | **Se mantienen los 10**; se construyen en orden: Centinela (hecho), Jacinto, Ilara, Hesper, Magda, Eudora, Maelis, y al final Oda (barata: carrera), Casimar y Rufo | El canon prohíbe recortar los 7 obligatorios y marca que lo primero en caer son los opcionales (§13). Oda no es un combate: es barata |
| 18 | **Vida y Ecos de los jefes 2-10** | 04: 36, 40, 54, 70, 66, 58, Calma 100 + 60, 24 + 24 + 32; Ecos 80-400. 05: 52-144 y Ecos 60-200 | **Vida de 04** (diseñada junto a los ciclos de ataque y a las fases); **Ecos de 05** (la economía manda sobre sus propios números) | La vida de 05 era un presupuesto ("N × 8 s por golpe") sin ciclo de ataques; la de 04 sale de pelea limpia de 2,5-4 min (estándar de la reunión). Los Ecos son un tema de economía: 790 los obligatorios |
| 19 | **Oda (jefe 10)** | 05: vida 150, personaje con vida 13 y Garrán, dificultad 10. 04: es una carrera sin vida | **Carrera** (04 y canon: "La Última Carrera") | Contradicción de 05 con el canon. La tabla de "personaje esperado" no incluye a Oda; solo exige dominar el movimiento |
| 20 | **Viaje rápido** | 05: "Decir los nombres" desde cualquier Ancla al Hito del Umbral y vuelta, tras Nombrar. 01/03: barca, 14 atajos, el Metro (Excavar). 03: válvula "Volver al Ancla" | **Sin viaje libre antes del acto IV.** Atajos físicos + barca de Mirena (gratis, plataforma sobre carril). Con **Nombrar**: ida a y vuelta desde el Hito del Umbral a cualquier Ancla visitada **fuera de la Herida**. **"Volver al Ancla"** en la pausa = igual que morir (deja un Eco con los Ecos), sin contar como muerte | Hacia/desde el Hito es lo mínimo con sentido narrativo y evita 15 min de vuelta en el 100 %. Se hace desde el menú del Ancla, así que no hay enemigos persiguiendo que comprobar. Una válvula sin coste permitiría escapar de cualquier pelea sin perder Ecos: por eso cuesta lo mismo que morir |
| 21 | **Mapa**: 6 planos, Hallazgos, candado, alfileres, Brújula, Pizarra | 05: 6 planos sustituyen a la cartógrafa (canon la eliminó); el mapa se rellena solo | **Sin planos, sin Hallazgos, sin Brújula ni Pizarra.** Candado automático y 8 alfileres: **pendientes, prioridad baja** | El canon elimina cartógrafos y mapas de pago; no hace falta *sustituirlos*. Los planos pedían una capa de "silueta conocida" en el mapa más 6 objetos y su texto. El candado sí ayuda a volver sobre cerraduras, pero no es de la primera versión |
| 22 | **Tope de 600 Ecos llevables** | 05 | **Descartado** | No resuelve ningún problema que exista (los precios llegan a 160) y castiga recoger de más con Ecos que se pierden sin avisar. El riesgo de acumular ya es el de morir |
| 23 | **Fatiga del Rastro** (100/50/25/0 %) | 05, con un contador por enemigo guardado | **Descartada**; se vigila el farmeo y, si aparece, se añade "100 % la primera vez y 50 % al reaparecer" (en memoria, sin guardado) | Exige guardar un contador por sala y posición. El farmeo real es de 2-8 Ecos por muerte; no es un problema hasta que se juegue |
| 24 | Bolsas de Rastro | 05: 40 fijas, 15-40 Ecos | **~24, de 12 a 30 Ecos** | Comparten sistema (pickup con id guardado) con los fragmentos; menos objetos que colocar, ajustables a las salas reales |
| 25 | **Presupuesto de Ecos** | 05: sumideros 2.600, camino principal 2.553 brutos; 216 apariciones de enemigos | **Sumideros 2.060** (árbol 1.800 + Garrán 150 + Cano 110; barca gratis). **Invariante**: el bruto del camino principal debe estar entre el **90 % y el 110 %** de los sumideros del camino principal | El mapa macro sugiere 100-130 apariciones de enemigos, no 216; el balance no puede cerrarse en papel. Se fija el invariante y se ajusta con los Ecos por enemigo y las Bolsas, no con los precios |
| 26 | Cano (tienda) | 05: 4 reliquias (Medalla 50, Llave 60, Moneda 70, Clavo 90) | **2 reliquias: Medalla (50) y Llave sin puerta (60)**; el canon dice que "vende un puñado de las que no se encuentran" | Moneda sin cara y Clavo de Cano caen con las reliquias nuevas |
| 27 | Garrán | 05: Filo Hondo = tope de daño 3 → 4, 150 Ecos | **Adoptado** (pregunta 4 de 05: se sube el tope) | La mejora más clara y única, como pide el canon. Cambiar el comportamiento (rompe armaduras) añade código |
| 28 | **Modo asistido** | 05: 7 interruptores (daño 100/75/50 con redondeo hacia arriba…). 04: 13 opciones (daño −1 a golpes de 2+, avisos ×1,25-1,5, contrastes, temblor…) | **11 opciones**: la ayuda de juego de 04 y 05 unificada (Daño reducido = −1 a golpes ≥ 2, Eco seguro, Margen del parry, Avisos más largos, Vida de jefes, Velocidad) + la accesibilidad visual y sensorial (Marca de aviso, Alto contraste, Temblor, Parpadeos, Olvido sin ocultar) | El 75 % con redondeo hacia arriba de 05 **no hace nada** con daños de 1-2 (2 × 0,75 = 1,5 → 2). La regla de 04 sí. No hay "frasco extra" (lo cubre el árbol). Cada opción se añade cuando existe su efecto |
| 29 | Nombrar en combate | 04 P4 (aturde un cascarón y un brazo de Maelis); 05 Voz (2 niveles); canon (recortable) | **Voz**: 1 nivel, aturde 2 s a un vaciado cercano, espera 25 s, **no afecta a jefes** (tampoco a Maelis). Marcada **[Recorte]** | El canon dice que los usos de combate de Nombrar son lo primero que cae (§13 punto 4). Necesita una acción nueva de entrada y nada más |
| 30 | Estado **Olvido** | 04: la curación a la mitad y el contador difuminado; 05: aliento | **El sorbo cura la mitad (redondeo hacia arriba, mínimo 1) y el contador se difumina sin ocultarse**; opción "sin ocultar la vida" | Es el efecto del canon ("reducen la curación y la barra de vida visible") encajado en el frasco nuevo |
| 31 | Guardia máxima | 04: 0,38 s. 05: 0,35 s | **0,35 s** (Guardia III) | Con el aviso mínimo de 0,28 s, 0,38 s sería ya casi automático |
| 32 | Progreso en la pausa | 05: "Camino %" y "Completado %" | **Solo "Completado %"** | Dos porcentajes complican la pausa para el mismo dato; el canon usa "% de camino" como medida de diseño, no de interfaz |
| 33 | Post-juego | 05: Memorias de jefe, Pruebas de la Pasarela, Modo sin Ecos, Nuevo Ciclo con tienda de 4 reliquias | **Continuar tras el final (ya funciona), estadísticas, logros narrativos, Modo sin Ecos y un Nuevo Ciclo sin tienda** (Ciclo es **[Recorte]**) | El canon ya lista logros, Modo sin Ecos y Nuevo ciclo; Memorias y Pruebas son contenido nuevo; la tienda del ciclo son 4 reliquias más |
| 34 | **Guardado** | 05: `version: 2`. 03: no subir `FORMAT_VERSION` | **No se sube** `FORMAT_VERSION` | `SaveSlot.load` descarta cualquier archivo con otra versión: subirla borraría las partidas existentes. Las claves nuevas son opcionales y una partida antigua carga con valores iniciales |
| 35 | Enemigos que se dañan entre sí (Penitente, Sellador) | 04: el Penitente se hace daño y golpea al Sellador | **Cae**; solo explotan entre sí los enemigos con el barril del Zapador | La arquitectura hoy filtra a `player`; el Penitente conserva la cadena circular y el Sellador el charco. Una excepción declarada, no una mecánica general |
| 36 | `hurt_zone` genérica | 04: pieza E6 de `core/` | **Local de Maelis** | La única pelea que la exige; no merece una pieza genérica |
| 37 | Terreno cambiante | 04: terreno dinámico; recorte a losas frágiles | **Recorte aceptado**: losas frágiles (la "grieta honda" de 03), bloques destructibles, espejos | Coste 1/5 del real y sin riesgo de atasco |
| 38 | Pieza `attack_picker`, `phase_tracker`, `boss_base` | 04 §3.1 | **Adoptadas, construidas con Jacinto** (no antes) | Cuando existe el segundo jefe se ve qué se repite de verdad |
| 39 | Música de jefe | 04: 2 capas por jefe y un timbre propio | Esquema adoptado, marcada **[Recorte]** (un tema común con capa de furia) | Sin músicos, un tema por jefe son 10 piezas de síntesis |
| 40 | Brasa y Cuenta del Rosario | Dos protecciones de "una vez por descanso" | Las dos, con efectos distintos: Brasa (golpe mortal, árbol) y Cuenta (caída o pinchos, reliquia) | No se pisan y no se aplican a la misma muerte |

## 2. Contradicciones resueltas que no son un asunto propio

- 04 §5.2 ponía el daño del Filo en 1-2 en el Centinela y 05 en 2: se adopta el personaje esperado de 05 (vida 7, daño 2) con margen (vida 5, daño 1).
- 04 asumía "3 a 5 frascos, 1 o 2 curaciones planificadas" y 05 "6 frascos": el tope es **5**.
- El 25 % de "ventana segura" de 04 y el 1,2 s de 05: se adopta **≥ 1,2 s por ciclo** (de 05).
- 04 daba al Doble Vacío 50 Ecos; 05 no lo trata: **40**, en la banda de la Herida.
- 05 §4.7 contaba 40 Bolsas con 1.050 Ecos; no se reproduce porque las Bolsas se reducen a ~24.

## 3. Coordinación con las otras salas (acciones para quien las edite)

| Sala | Qué hay que cambiar o confirmar |
|---|---|
| **Canon (`textos-del-juego.md`)** | Añadir la reliquia **Hebra de Cal** (nº 16; heading "Reliquias y amuletos (15)" → 16) con su texto. Texto de "Callar un nombre" con el pago de 50 Ecos y el contador. Cinco o seis líneas de pista (una por habilidad) para el Hito |
| **Mapa macro (01)** | La sala MIN-20 da la **Brújula de Mirena**: cae (se sustituye por nada o por un Fragmento). La sala SEC-08 da la **Pluma sin tinta**: el canon la da Sabela con las 6 Páginas, así que SEC-08 debe dar otro premio. Confirmar el reparto de los 12 fragmentos de vida (1 + 3 + 3 + 3 + 2 + 0) y las ~24 Bolsas por región |
| **Puzles (03)** | Excavar se resuelve con el ataque hacia abajo (suelos hondos) y el tajo (muros hondos), como en `nucleo-jugable.md`; el pogo no rebota en pinchos. "Volver al Ancla" adoptada. El `FlagStore` (`flags`) entra en el guardado sin subir la versión |
| **Arte** | Lienzo del Caminante 112×96 (primero). Animaciones del Caminante `attack_up`, `attack_down`, `heal` (beber). Icono "bebiendo" del frasco. 16 iconos de reliquia (no 22). "Hilos" pasa a **ranuras** (hexágonos de 1-2 unidos). HUD de vida hasta 13 placas en una fila. Tres tipos de cuerpo (H, A, V) más objetos animados. La pose simétrica es guía, no ley; el aviso es una capa de código |
| **Escritores** | Texto de las confirmaciones ("Es para siempre."), del Paño y de las ayudas. Nada de los Nombres da ranuras, así que ningún texto debe prometerlo |

## 4. Preguntas para el usuario

1. **¿Aceptas que el frasco deje de curar del todo** (3 → 5 vidas, sorbo comprometido de 0,70 s)? Es el cambio que más toca la sensación de juego actual. Si prefieres mantener la cura total, hay que bajar el techo a 3 frascos, eliminar Aliento y la vida de 13 pierde sentido.
2. **¿Se añade la Hebra de Cal al canon** (16 reliquias en vez de 15)? La alternativa es que Casilda no dé reliquia.
3. **¿Tres tipos de cuerpo y 37 entradas de bestiario** o prefieres recortar aún más (los élites como comunes con más vida)?
4. **¿Ranuras ligadas a los Sellos** (3 + 3) o prefieres un número fijo?
5. **¿Se mantiene Voz** (Nombrar en combate) o se elimina desde ya, dejando Nombrar solo para puzles y final?
6. **Topes de 13 de vida y 5 frascos**: cualquiera de los dos se puede bajar sin tocar el resto.

## 5. Cambios de código necesarios, ordenados por dependencia

Costes: **S** = ≤ 1 día, **M** = 2-4 días, **L** = 5 o más. "Dep." = lo que debe estar hecho antes. Cada fase es una rama y un PR (`docs/flujo-git.md`), con su prueba en `tests/smoke_test.gd` y la comprobación obligatoria (`godot --headless --path . --script res://tests/smoke_test.gd`, código 0). Las fases 0 y 1 son lo único que bloquea la calibración del juego; lo demás se enchufa sin romper nada. Estimación global: del orden de **110 días-persona de ingeniería de sistemas**, sin contar el arte (~123-138 puntos), el contenido de niveles ni la construcción de cada jefe (cada uno L); es una estimación gruesa para ordenar, no un compromiso.

### Fase 0 · Combate legible y frasco (primero, bloquea la calibración)

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K01 | **Lienzo del Caminante a 112×96**: `setCanvas(112, 96)`, regenerar, desplazar el `Sprite2D` 16 px, verificar que los fotogramas existentes son idénticos desplazados (diff controlado) | `tools/rig_caminante.js`, `game/player/player.tscn`, `art/` | — | S |
| K02 | **`parryable` y aviso rojo**: `ParryComponent.try_deflect` ignora al atacante con `parryable == false`; `Enemy` gana `parryable` y `TELEGRAPH_RED`; el golpe no parable atraviesa la guardia sin aturdir; (la marca de suelo viene con `telegraph_zone`, en K29) | `core/components/parry_component.gd`, `game/enemy/enemy.gd` | — | S |
| K03 | **Frasco rediseñado en `HealthComponent`**: `heal_amount` (0 = cura total, compatible con las pruebas actuales), `heal_time`, `begin_heal()`, cancelación por daño, señales `heal_started`/`heal_cancelled`; `use_heal_charge()` sigue siendo la aplicación instantánea. En `player.gd`: el sorbo (quieto, sin atacar ni parar, cancelable con salto o dash) y el sonido. Actualizar las pruebas de curación y la del botón B / Círculo | `core/components/health_component.gd`, `game/player/player.gd`, `tests/smoke_test.gd` | — | M |
| K04 | **Hoja de estadísticas con topes**: `Skills.stat()` + modificadores (reliquias, fragmentos) con `clamp()` al tope absoluto; `heal_amount` y `heal_time` salen de aquí; prueba de topes con todo comprado | `game/player/skills.gd`, nuevo `game/player/stats.gd` | K03 | S |
| K05 | **HUD**: estado "bebiendo" del frasco (3 fotogramas), 13 placas de vida en una fila, iconos de estado (Lento/Fijado/Olvido) cuando existan | `game/ui/hud.gd`, `core/ui/segmented_bar.gd` | K03 | S |
| K06 | **Ataque hacia arriba** (Arriba + X; hitbox 36×44; no cancela el parry) y su animación `attack_up` | `game/player/player.gd`, `player.tscn` | K01 | M |
| K07 | **Ataque hacia abajo con pogo**: hitbox bajo los pies, grupo `pogoable`, rebote ~126 px, sin recarga de dash ni doble salto, sin rebote en pinchos; animación `attack_down` | `game/player/player.gd`, `core/components/melee_attack_component.gd` (hitbox direccional) | K06 | M |
| K08 | **Animaciones nuevas del Caminante**: `attack_up`, `attack_down`, `heal` (arte generado por rig, no código) | `tools/rig_caminante.js`, `art/source/` | K01 | M |

### Fase 1 · Economía legible

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K09 | **Pickup con id guardado** (fragmentos de vida y Bolsas de Rastro): escena genérica, contador, clave `fragments` y `bags` en la partida (opcionales) | `game/pickups/`, `game/levels/world.gd`, `player.gd` | — | M |
| K10 | **Fórmula de vida máxima** (`5 + Vitalidad + fragmentos/4 + Trapo`) y notificación "Fragmento de vida n/4" | `game/player/stats.gd`, `player.gd` | K04, K09 | S |
| K11 | **Precios nuevos** del árbol en `Skills.LIST` y prueba de la suma (1.800) | `game/player/skills.gd` | — | S |
| K12 | **Prueba de presupuesto de Ecos** (suma de `ecos_reward` + jefes + Bolsas en el rango del invariante) y, cuando haya salas reales, ajustar | `tests/smoke_test.gd`, escenas de enemigos | K09 | S |

### Fase 2 · Árbol ampliado

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K13 | `SkillTree.define()` admite **nivel mínimo del requisito** y una **puerta** resuelta por el dueño (`Callable`); ids nuevos en `Skills.LIST` con sus textos | `core/components/skill_tree.gd`, `skills.gd` | K11 | S |
| K14 | **Vista del árbol** de 3 columnas × 5 filas con el texto de por qué algo está bloqueado y confirmación por segunda pulsación | `game/ui/anchor_menu.gd` | K13 | M |
| K15 | **Efectos nuevos**: Aliento (cura +1; en K04) S · Brasa (golpe mortal con ≥ 3 de vida, una vez por descanso, no por caída) S-M · Castigo (+1 vs común en RECOVER) S · Paso fantasma (invulnerabilidad durante el dash) S | `player.gd`, `enemy.gd`, `health_component.gd` | K03, K13 | M (en total) |
| K16 | **Voz** (Nombrar en combate): acción nueva, aturdir vaciados con espera de 25 s **[Recorte]** | `player.gd`, `enemy.gd`, `project.godot` | K13, Nombrar | M |

### Fase 3 · Reliquias, Cano y Garrán

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K17 | **Componente genérico `Loadout`** (ranuras, equipar, capacidad) y datos de las 16 reliquias; modificadores aplicados en `Stats`; claves `relics` en la partida | `core/components/loadout.gd`, `game/player/relics.gd`, `stats.gd` | K04 | L |
| K18 | **Menú de reliquias** en el Ancla (solo se cambian descansando) y la vista de solo lectura en la pausa; iconos | `game/ui/anchor_menu.gd`, `pause_menu.gd` | K17 | M |
| K19 | **Primeras 10 reliquias** (efectos): Cuenta, Dedal, Medalla, Aguja, Pesa, Lacre, Diente, Piedra blanca, Hebra, Trapo. El resto (Campanilla, Llave, Pluma, Corona, Vela, Insignia) con su PNJ o jefe | `player.gd`, `enemy.gd`, `parry`, objetos | K17 | M (cada una S) |
| K20 | **Recompensa genérica de jefe** (`reward_scene`: habilidad, Sello, llave o reliquia) y Sellos que dan una ranura | `game/boss/boss_room.gd` | K17 | S |
| K21 | **Cano** (tienda de 2 reliquias) y **Garrán** (hierro de misión, Filo Hondo, tope de daño 4, clave `forge`) | `game/npc/`, `stats.gd` | K17 | M + S |

### Fase 4 · Nombres y el Paño

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K22 | **Registro de Nombres** (30 ids, leídos y callados, clave `names`): las inscripciones notifican, el descanso los pronuncia, pestaña "Nombres que sostienes" por región | `game/names.gd`, `pause_menu.gd`, `inscription` | — | M |
| K23 | **El Paño**: entrada "Callar un nombre" en el menú del Ancla, confirmación con "No" por defecto, +50 Ecos, marca el Nombre | `anchor_menu.gd`, `names.gd` | K22 | S |

### Fase 5 · Mapa y viaje

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K24 | **"Volver al Ancla"** en la pausa (como morir, sin contar como muerte, con confirmación) | `pause_menu.gd`, `player.gd` | — | S |
| K25 | **Barca de Mirena**: plataforma sobre carril y Mirena (gratis) | `core/objects/rail_platform.gd` (de `03-puzles`, M7) | M1 de 03 | S-M |
| K26 | **"Decir los nombres"**: lista de Anclas visitadas fuera de la Herida, carga de la sala y animación de 3 s; se enciende al obtener Nombrar | `anchor_menu.gd`, `world.gd` | K22, escena de Nombrar | M |
| K27 | Candado automático y alfileres del mapa **[Recorte, prioridad baja]** | `world.gd`, mapa de la pausa | — | M |

### Fase 6 · Piezas de motor para el bestiario y los jefes (en el orden en que llegan los enemigos; detalle en `enemigos.md`)

| # | Cambio | Primer usuario | Dep. | Coste |
|---|---|---|---|---|
| K28 | `fly_ai` (vuelo) | Cuervo | K06 | M |
| K29 | `telegraph_zone` (con marca de suelo del rojo) | Jacinto, Sellador | K02 | M |
| K30 | Estado DORMANT en `PatrolChaseAI` | Espantapájaros | — | S |
| K31 | `attack_picker`, `phase_tracker`, `boss_base` y refactor opcional del Centinela | Jacinto | K29 | M |
| K32 | `Spawner` con tope; modo retorno del `Projectile` | Jacinto, Relator | — | S + S |
| K33 | `status_effects` (Lento, Fijado) y su aviso en el HUD | Sellador, Hesper | K05 | M |
| K34 | `directional_guard` | Armadura Vacía | K02 | S-M |
| K35 | `attack_kind` ROLL | Chinche | — | S |
| K36 | Estado Olvido (cura a la mitad, contador difuminado, opción) | Hermano de Cal | K03, K33 | S |
| K37 | `teleport` y dash en la IA | Eco Borrado, Relevo Vacío | — | S + S |
| K38 | Partes golpeables y arrastre (Maelis), controlador de ruta (Oda) | Maelis, Oda | K29 | L + M |

### Fase 7 · Ayuda, estadísticas y post-juego

| # | Cambio | Dónde | Dep. | Coste |
|---|---|---|---|---|
| K39 | **Opciones de ayuda y accesibilidad** (11 interruptores, en `opciones.cfg`) | `title_screen`, `pause_menu`, `player.gd`, `enemy.gd` | K03, K02 | M |
| K40 | **Estadísticas** (tiempo, muertes, Ecos, % Completado) y **logros narrativos** | `game/`, pausa | K22 | S + S |
| K41 | **Modo sin Ecos** y **Nuevo Ciclo** **[Recorte]** | `game/`, guardado (`cycle`) | K17 | S + M |

### Guardado: qué entra con cada fase y qué se prueba

Sin subir `FORMAT_VERSION`. Cada clave nueva es opcional y se ignora si falta o si el id es desconocido.

| Fase | Claves | Pruebas |
|---|---|---|
| 1 | `fragments`, `bags` | Ida y vuelta; mismo id dos veces no suma; 3 fragmentos = vida base, 4 = +1, 12 = +3 |
| 2 | `skills` (ids nuevos) | Niveles que superan el máximo se recortan; costes suman 1.800; el grafo no tiene requisitos inexistentes ni ciclos; las puertas referencian jefes o habilidades reales |
| 3 | `relics`, `forge` | Equipar más de lo que caben falla; equipar fuera de un Ancla falla; Trapo +1 vida (tope 13); Pesa +1 daño y +0,12 s; Medalla conserva el 25 %; Garrán no se cobra dos veces |
| 4 | `names` | Callar da 50, quita de "sostenidos" y no de "leídos"; no se puede callar uno no leído |
| 5, 7 | `flags` (de 03), `stats`, `cycle` | Partida antigua sin ninguna: carga con valores iniciales y conserva Ecos, habilidades y árbol |

### Pruebas nuevas de la fase 0 en adelante (resumen de las T de 05, ajustadas)

Topes absolutos con todo comprado; suma del árbol; grafo del árbol; partida antigua; ids desconocidos; fragmentos; ranuras; reliquias; **frasco** (cura exactamente `heal_amount`, un golpe durante el sorbo lo cancela sin gastar carga, no se bebe con vida llena, saltar o hacer dash lo cancela); **parry rojo**; Brasa (una vez por descanso, solo con ≥ 3 de vida, no vale contra caída); Castigo y Voz **no cambian el daño a jefes**; Nombres; Garrán; movimiento intacto (la suite `puzzle_plans.json` sigue verde con todas las reliquias y el árbol completo); presupuesto de Ecos; asistido (cada interruptor modifica solo su magnitud). Y la comprobación humana, no automatizable: **jugarlo**, con 30-60 min y cronómetro por fase, apuntando muertes por jefe y Ecos en la mano al morir.
