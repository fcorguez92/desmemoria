# Registro de decisiones técnicas y de diseño

Cada entrada: qué se decidió, por qué, qué alternativas se descartaron y por qué. Se añade una entrada nueva por decisión importante, no se reescribe el historial.

## 2026-09-29 — Fix: el retroceso de un golpe mortal no debe aplicarse tras reaparecer

**Bug**: en `Player.take_hit()` (`game/player/player.gd`), el retroceso se aplicaba siempre que `health.take_hit(damage)` devolvía `true`, sin distinguir si el golpe había matado al jugador. `HealthComponent.take_hit()` (`core/components/health_component.gd`) emite `died` de forma síncrona en cuanto la vida llega a 0, y esa señal está conectada directamente a `Player.die()`, que reaparece al jugador (teletransporte, vida y velocidad reiniciadas) antes de devolver el control a `take_hit()`. El resultado: el empuje de un golpe mortal se aplicaba en el punto de reaparición, no donde murió el jugador. Casi imperceptible en la práctica (un empuje pequeño justo tras reaparecer), pero un orden de ejecución incorrecto.

**Arreglo**: `take_hit()` guarda `health.health` en `health_before` antes de llamar a `health.take_hit(damage)`, y solo aplica el retroceso si el golpe se aplicó y no fue mortal (`damage < health_before`). Como la regla de `HealthComponent` es `health -= amount; if health <= 0: died`, un golpe es mortal exactamente cuando `amount >= health_before`, así que esta comprobación es equivalente y no duplica ninguna constante mágica.

**`enemy.gd` tiene la misma estructura** (`if health.take_hit(...): knockback.apply(...)`) pero no se ha tocado: al morir, el enemigo llama a `queue_free()`, que solo marca el nodo para borrarlo al final del frame; no vuelve a correr `_physics_process` antes de desaparecer, así que el `knockback.apply()` posterior no tiene ningún efecto observable. Cambiarlo habría sido una modificación sin ningún beneficio real.

**Prueba añadida**: `_test_lethal_hit_does_not_knockback_at_respawn` en `tests/smoke_test.gd` comprueba que, tras un golpe mortal, `knockback.is_active` sigue en `false` y el jugador reaparece exactamente en `respawn.spawn_position`, sin ningún desplazamiento.

## 2026-09-28 — Narrativa ambiental de El Último Umbral: inscripción legible y decorado fijo

**Decisión**: tres detalles que se explican solos, sin ningún diálogo. Una inscripción junto a la entrada (Z para leerla, texto fijo en `game/environment/inscription.tscn`) con nombres grabados por los supervivientes. Un carro volcado y un saco reventado dentro de la cabaña, y marcas de arrastre en el suelo junto al foso, los tres como polígonos fijos sin colisión dentro de `ultimo_umbral.tscn` (nodo `SetDressing`), no como objetos reutilizables.

**Nuevo contrato "lector"**: `Readable` (`core/objects/`) es igual que `Checkpoint` en estructura (área, `target_group`, `action_interact`, aviso opcional) pero llama a `read_text(text)` en vez de `rest_at(position)`, y no cambia ningún estado del juego. El tiempo que el texto queda en el HUD se calcula por su longitud (`MIN_READING_SECONDS`, `READING_CHARS_PER_SECOND` en `player.gd`), no es un tiempo fijo como los mensajes de habilidad.

**Alternativas**: un sistema de diálogo con ventanas y retratos — descartado, muy por encima de lo que hace falta para un solo texto corto (ver filosofía de ingeniería). Colocar el carro, el saco y las marcas como objetos reutilizables con marcador en el mapa (como la urna) — descartado: son una composición única de esta cabaña y este foso, no un tipo de objeto que vaya a repetirse en otro sitio con la misma forma.

**Un fallo al construirlo**: la primera posición elegida para la inscripción (junto al Ancla, muy cerca) quedaba dentro del área de detección del Ancla; al pulsar Z se activaban las dos a la vez y el Ancla pausaba el juego a mitad de la prueba. Se movió la inscripción junto a la entrada, lejos de cualquier otra zona de interacción; queda como aviso para futuras zonas: comprobar que las áreas de objetos interactivos cercanos no se solapen.

## 2026-09-27 — Ambiente de El Último Umbral: parallax y objetos rompibles decorativos

**Decisión**: un `ParallaxBackground` con dos capas de siluetas (colinas lejanas y ruinas a media distancia) da profundidad al fondo negro. Se añaden urnas rompibles junto al camino: `BreakableProp` (`core/objects/`) implementa el contrato "golpeable" y se destruye de un golpe con un chispazo; hasta entonces es un obstáculo físico normal. No sueltan nada ni dan Ecos, así que no reaparecen al reiniciar el mundo (no pertenecen al grupo `resettable`).

**Alternativas**: dibujar el fondo y las urnas con el pipeline de sprites de texto (como los personajes y las baldosas) — descartado por ahora: el entorno y los objetos siguen en fase de geometría de colores planos (ver `docs/estado.md`), y una silueta de colinas grande e irregular encaja peor en una rejilla de caracteres que en polígonos ajustados a mano. Objetos rompibles que sueltan Ecos o curaciones — descartado: el usuario pidió que fuesen solo decoración, sin afectar al balance del juego.

**Técnico**: las siluetas del parallax son más anchas que el nivel entero (unos 2100 px) para cubrir todo el recorrido de la cámara sin necesitar mosaico ni repetición. Al colocar una urna cerca de un enemigo hubo que comprobar que no cayera dentro de su radio de patrulla: al ser un obstáculo físico, el enemigo la trata como una pared y patrulla contra ella, lo que en la prueba automática de patrulla se contaba como más cambios de dirección de los esperados (bloqueo legítimo, no la vibración corregida antes) — se resolvió recolocando la urna, no cambiando la IA.

## 2026-09-26 — Menú de pausa con Personaje y Controles; capa modal común

**Decisión**: Esc abre un menú de pausa con *Continuar*, *Personaje* (vida, Ecos, Filo y habilidades recordadas), *Controles* (las teclas, que salen del HUD) y *Salir del juego*. Las habilidades sin recordar aparecen como `???` para no desvelar qué queda por encontrar. El HUD solo conserva la nota "Esc: pausa y controles". La lógica de pausar y reanudar se extrae a `ModalLayer` (`core/ui`), que usan el menú de pausa y el del Ancla.

**Alternativas**: un inventario completo (descartado: aún no hay objetos) y mantener las teclas fijas en el HUD (ocupan sitio y crecen con cada mecánica).

**Técnico**: la tecla Esc que abre la pausa la escucha el jugador (`_unhandled_input`), no el propio menú: un nodo con `process_mode = When Paused` no recibe teclas mientras se juega. Con el juego ya en pausa (menú del Ancla abierto) Esc no abre la pausa. Todas las pantallas del menú miden lo mismo, para que no "se mueva" al cambiar de una a otra.

## 2026-09-25 — Menú del Ancla con el juego en pausa; sin inventario ni entradas vacías

**Decisión**: descansar en un Ancla (Z) cura, fija la reaparición y abre un menú con el juego en pausa. Hoy tiene dos opciones: *Mejorar el Filo* y *Salir*. Desaparece la tecla C. La lista de opciones (`MenuList`) es un control genérico en `core/ui/`; el menú (`game/ui/anchor_menu`) recibe los números del jugador y avisa con señales, como el HUD.

**Alternativas**: un menú con tienda, viaje entre Anclas e inventario desde el principio (descartado: no existe ninguna de esas mecánicas, serían entradas vacías) y mantener las teclas Z y C sin menú (no crece).

**Por qué**: el menú es la estructura donde irán las nuevas opciones cuando existan; añadirlas será una entrada más. Para el inventario se esperará a que haya objetos que guardar.

**Técnico**: el menú pausa el árbol y sus nodos usan `process_mode = When Paused`. Las pruebas simulan teclas con eventos de acción reales (`Input.parse_input_event`) y deben soltarlas después, o la acción queda pulsada para las pruebas siguientes. Al cerrar, el juego se reanuda dos frames de física más tarde (no en el mismo): la tecla que cierra el menú (Espacio, que también es el salto; Z, que también abre el Ancla) seguiría contando como "recién pulsada" y el juego la ejecutaría. `Input.action_release` no sirve para esto: pone la acción en "no pulsada" pero Godot sigue devolviendo `is_action_just_pressed` verdadero en ese frame. Al mover la selección, las filas de `MenuList` se reutilizan en vez de recrearse: `queue_free` deja las viejas vivas un frame y el panel temblaba.

## 2026-09-24 — Niveles como texto: mapa `.map` + `TileMapLayer` (sin editor de niveles)

**Decisión**: el terreno de cada zona se dibuja como un archivo de texto (`*.map`, un carácter por baldosa de 16 px) que el nodo `TextTileMap` (core) convierte en un `TileMapLayer` al cargar. Los caracteres sin baldosa asociada son marcadores (jugador, Ancla, enemigo) que el script del nivel convierte en entidades.

**Alternativas**: pintar en el editor de TileMap de Godot (lo estándar, pero Claude no puede verlo ni editarlo con fiabilidad, y el usuario tiene nivel técnico básico) o herramientas externas como LDtk/Tiled (una dependencia más y un formato que interpretar).

**Por qué**: es coherente con los sprites como texto: un solo flujo, revisable en Git y editable por la IA. Coste: no hay pintado visual y los `.map` requieren un filtro de exportación. Si el nivel crece demasiado para manejarlo así, se puede pasar al editor de Godot sin tirar nada, porque el resultado ya es un `TileMapLayer` normal.

## 2026-09-18 — Perspectiva del juego: 2D/2.5D lateral

**Decisión**: el juego se ve y se juega en 2D/2.5D con cámara de perfil (tipo *Blasphemous*, *Hollow Knight*, *Salt and Sanctuary*), no en 3D con cámara en tercera persona libre (tipo *Dark Souls*).

**Por qué**: el pilar "plataformas" que pide el proyecto encaja de forma natural con un lateral 2D, mientras que en un souls-like 3D las plataformas suelen ser secundarias. Además, el volumen de arte y animación que exige el 3D (modelos completos, animaciones desde todos los ángulos, sistemas de cámara y colisión 3D) es inviable para un desarrollador en solitario con nivel técnico básico, incluso con apoyo de IA. El 2D permite lograr el mismo tono y densidad narrativa con un alcance sostenible.

**Decidido por**: el usuario, a partir de una comparativa presentada por Claude.

## 2026-09-18 — Motor: Godot 4 + GDScript

**Decisión**: usar Godot 4 (rama estable más reciente) con su motor 2D nativo, y GDScript como lenguaje principal.

**Alternativas evaluadas**:
- **Unity**: canceló en 2024 la polémica "Runtime Fee" y volvió a suscripción por asiento; gratis hasta 200.000 $/año de ingresos. Descartado por: historial de cambios de política de precios a mitad de proyecto (riesgo no técnico pero real en un proyecto de años), y no aporta ventaja sobre Godot para un juego 2D en solitario.
- **Unreal Engine 5**: gratis hasta 1.000.000 $ de ingresos, luego 5% de royalty. Descartado por: pensado para equipos y proyectos 3D de alta fidelidad; C++/Blueprint, compilación pesada y requisitos de hardware añaden fricción innecesaria para un desarrollador con nivel técnico básico haciendo un juego 2D.
- **Godot 4** (elegido): motor libre y gratuito (licencia MIT, sin royalties ni cuotas, mantenido por una fundación sin ánimo de lucro — cero riesgo de que cambien las reglas del juego a mitad de desarrollo). GDScript está diseñado para ser legible (sintaxis similar a Python), adecuado al nivel técnico del usuario. Motor 2D maduro y usado activamente por la comunidad indie para souls-likes.

**Factor decisivo adicional**: existen en 2026 servidores MCP maduros (p. ej. GDAI MCP, StraySpark Godot MCP) que conectan Claude Code directamente con el editor de Godot en vivo, permitiendo crear escenas, nodos, scripts y ejecutar pruebas desde esta conversación en lugar de escribir archivos a ciegas. La integración equivalente con Unity es más limitada y con Unreal es inmadura en 2026.

**Decidido por**: Claude, con delegación explícita del usuario ("te dejo decidir el que entiendas óptimo").

**Fuentes consultadas**: blog oficial de Unity sobre cancelación de la Runtime Fee y subidas de precio 2025-2026; unrealengine.com/license; comunidad y plantillas de souls-likes en Godot 4; guías 2026 de integración MCP Godot/Claude Code (StraySpark, GDAI).

## 2026-09-20 — Base reutilizable: capas `core/` y `game/` en el mismo repositorio

**Decisión**: separar el código en `core/` (jugabilidad 2D genérica y reutilizable) y `game/` (lo específico de este juego), con la regla de que `core/` nunca referencia `game/`. `player.gd` (200 líneas mezcladas) se divide en componentes de una sola responsabilidad. La base se extraerá a plantilla o addon cuando exista un segundo proyecto.

**Por qué**: el usuario quiere reutilizar esta base en futuros proyectos y que una IA la entienda. Separar por capas hace la extracción posterior casi mecánica sin pagar hoy el coste de mantener un repositorio aparte.

**Alternativas descartadas**:
- *Repositorio/addon de motor separado ya*: más limpio a largo plazo, pero añade mantenimiento y complejidad antes de haber probado cómo se reutiliza realmente; riesgo de abstraer mal.
- *Solo documentar sin reestructurar*: lo más barato, pero dejaba lo genérico mezclado con lo específico y sin forma de comprobar qué es reutilizable.

**Riesgo asumido**: generalizar antes de un segundo proyecto puede producir abstracciones que no encajen. Se mitiga extrayendo solo lo que ya usan a la vez el jugador y los enemigos (vida, parpadeo, daño por contacto) o que es claramente genérico (movimiento, dash, checkpoint), y no añadiendo nada "por si acaso".

**Decidido por**: el usuario (opción recomendada por Claude).

## 2026-09-20 — Puntos de descanso: Hito de Nombres, activado con Z

**Decisión**: las Anclas de Memoria dejan de activarse al pasar por encima y requieren pulsar Z, con un aviso "Z: Recordar". Su aspecto pasa a ser un hito de piedras con nombres grabados de personas que la Desmemoria borró.

**Por qué**: el usuario quería que descansar fuese una parada deliberada, y un lugar propio del juego, no un banco (Hollow Knight) ni una hoguera (Dark Souls). El hito expresa la premisa: los supervivientes conservan nombres borrados y el protagonista, que no olvida, los pronuncia. Detalle en `nucleo-jugable.md`.

**Nombre**: la primera propuesta tenía una acepción vulgar en español y el usuario la rechazó; se sustituyó por "Hito". Alternativas de nombre disponibles si tampoco convence: "Túmulo de Nombres", "Estela de Nombres".

**Alternativas de concepto consideradas** (se eligió el hito de piedras): un atril donde se dicta la memoria al Archivo (recuerda a las máquinas de escribir de guardado de Resident Evil) y un sello de cera de los Custodios (muy ligado a una sola facción).

**Técnico**: `Checkpoint` (en `core/`) usa una acción de interacción configurable y un `prompt` opcional; sigue sin saber nada del juego.

**Decidido por**: el usuario pidió Z y un lugar temático; Claude propuso el concepto.

## 2026-09-22 — Estilo de arte: pixel art oscuro con paletas limitadas, con herramientas gratuitas

**Decisión**: pixel art oscuro (referencia *Blasphemous*), resolución interna de 864×486 con escalado entero, rejilla de 16 px y una paleta de rampas de 4 tonos. La Desmemoria se expresa desaturando la paleta por zonas. El arte lo produce el usuario con Pixelorama o LibreSprite (gratuitas). Detalles en `arte.md`.

**Alternativas evaluadas**: dibujo a mano/tinta tipo *Hollow Knight* (el más caro de sostener para una sola persona y difícil de mantener consistente) y siluetas con luz hechas en Godot (el más barato, con menos detalle de personaje).

**Por qué**: es lo más barato y consistente de producir en solitario, Godot 4 lo soporta de serie (filtro Nearest, escalado entero) y encaja con la premisa mediante la paleta. Los sprites (32×56 y 40×56) caben en las colisiones actuales, así que la jugabilidad no cambia.

**Producción**: se eligió empezar con herramientas gratuitas. La opción de IA de pago para sprites (p. ej. PixelLab, unos 12 $/mes) queda descartada por ahora; su punto débil es la consistencia entre fotogramas.

**Datos verificados (2026)**: Aseprite cuesta 19,99 € y LibreSprite/Pixelorama son gratuitas; Steam pide declarar solo la IA cuyo contenido consume el jugador (formulario reescrito en enero de 2026); la Oficina de Derechos de Autor de EE. UU. exige autoría humana y no considera autor a quien solo elige el texto de entrada.

**Técnico**: se ajusta `project.godot` (ventana 864×486, ampliación a 1728×972, estirado "viewport" con escalado entero, filtro "Nearest" y ajuste al píxel). Se probó primero 640×360 y el usuario lo encontró demasiado cerrado; 864×486 muestra un 35 % más de mundo y cabe en ventana con escalado ×2 en su pantalla de 1920×1080 (área útil 1032 px de alto). Con la resolución por defecto de Godot (1152×648) se veía más mundo pero sin píxeles nítidos.

## 2026-09-23 — Parry con ventana breve, aturdimiento y doble daño

**Decisión**: V abre una ventana de 0,2 s en la que un golpe frontal se desvía sin daño. Si acierta, el enemigo queda aturdido 1,2 s y recibe doble daño; si falla, no hay protección. Enfriamiento de 0,7 s y sin poder atacar con la guardia alzada. Se añade `ParryComponent` (core) y una pose de guardia en el sprite.

**Por qué**: lo pidió el usuario y encaja con el aviso de 0,4 s del enemigo: además de esquivar con el dash (seguro) hay una opción arriesgada que premia el buen tiempo con un contraataque potente, que es la esencia del combate "souls".

**Alternativas**: parry sin riesgo (ventana larga) o bloqueo mantenido con stamina. Descartadas: la primera resta tensión y la segunda exige un sistema de stamina que aún no existe.

**Técnico**: los golpes cuerpo a cuerpo ahora pasan quién golpea (`take_hit(damage, from_direction, attacker)`), para poder aturdir al atacante; el parámetro es opcional. Solo se desvían golpes frontales (la dirección del golpe debe ser opuesta a hacia dónde mira quien para). El HUD ahora muestra los controles (y "Curación (H)"), porque el usuario no sabía cuál era la tecla de curarse.

**Pendiente**: ajustar la ventana y el aturdimiento jugando (0,2 s es exigente; si se hace demasiado difícil, subirla).

## 2026-09-22 — Armas integradas en los sprites

**Decisión**: el arma deja de ser una barra que gira sobre el sprite y pasa a dibujarse en el propio personaje. El caminante lleva una espada (acero con canto azul, guarda ámbar) y el cascarón un cuchillo pesado oxidado, cada uno en varias poses (reposo, aviso, golpe). `AttackVisualComponent` ya no gira un brazo: pide animaciones al `SheetAnimator`, que gana "acciones" (`play_action`) para que el movimiento no pise un ataque en curso.

**Por qué**: lo pidió el usuario y es más coherente con el arte pixel: las armas y los personajes comparten estilo, y el aviso del enemigo se lee mejor con el arma alzada.

**Técnico**: la herramienta de sprites gana piezas superpuestas (`pieza@x,y`), para dibujar brazo y arma encima del cuerpo sin repetir el cuerpo en cada pose. Los lienzos pasan a 64×56 para que quepa el arma extendida. El destello del arco se conserva, mucho más suave. Los tests comprueban que cada bando reproduce sus animaciones de ataque y vuelve a las de movimiento.

**Límite**: el arma sale del sprite, no de un nodo, así que al mejorar el Filo no cambia su aspecto (habría que dibujar variantes).

## 2026-09-22 — Sprites escritos como texto y convertidos a PNG

**Decisión**: los sprites se escriben como cuadrículas de texto con una paleta (`art/source/*.sprite`, `art/palette.txt`) y `tools/build_sprites.gd` los convierte en hojas PNG. Se define en piezas reutilizables (cabeza y torso, capa, piernas) que se apilan para formar los fotogramas. `SheetAnimator` (core) los anima en el juego.

**Por qué**: el usuario no sabe dibujar y Claude no genera imágenes. Como texto, el arte es legible, se versiona en Git y Claude puede escribirlo y corregirlo; además Claude puede **ver** el resultado (vistas previas ampliadas y capturas del juego) y iterar, algo que no ocurre con herramientas de IA externas. Coste cero y sin dependencias.

**Alternativas**: instalar Pixelorama/LibreSprite para que el usuario dibuje (sigue disponible para retocar), o una IA de sprites de pago (descartada por ahora por coste y consistencia).

**Límite conocido**: las piezas apiladas dan animaciones sencillas y algo rígidas (el torso no se mueve entre fotogramas). Sirve para una primera versión; el arte final podrá retocarse a mano. Regla: una sola fuente de verdad por sprite (ver `arte.md`).

**Resultado**: primer caminante (jugador) y primer cascarón (enemigo) con animaciones de reposo, correr/andar, salto y caída, integrados y probados.

## 2026-09-22 — Salto de pared en cualquier pared, dentro del movimiento

**Decisión**: con la habilidad conseguida, mantener la dirección hacia una pared en el aire hace resbalar despacio (120 px/s), y saltar desde ella empuja hacia el lado contrario (350 px/s horizontal, -850 vertical) con un breve bloqueo de la dirección para que el empuje no se anule al instante. Funciona en cualquier pared. El salto de pared no gasta el doble salto.

**Por qué**: es la última habilidad del conjunto y encaja con el manejo tipo Hollow Knight que pidió el usuario. El diseño original hablaba de "grietas marcadas"; se ha simplificado porque marcar superficies añade trabajo de nivel sin aportar nada a esta fase. Decisión tomada por Claude por defecto y comunicada; fácil de restringir después.

**Técnico**: va dentro de `PlatformerMotor` (como el doble salto) para compartir los márgenes de salto. Prioridad al pulsar salto: suelo o coyote > pared > salto extra. El nivel de prueba gana un pozo estrecho cuya salida solo se alcanza con esta habilidad, y un test con un "robot" que sube el pozo saltando de pared a pared demuestra que es posible y que sin la habilidad no.

## 2026-09-21 — Feedback visual del combate con formas simples

**Decisión**: brazo con arma que golpea (y se levanta durante el aviso del enemigo), destello del arco del golpe, chispazo en el impacto y temblor de cámara. Todo genérico en `core/` (`AttackVisualComponent`, `ScreenShakeComponent`, `HitSpark`) y sin arte final.

**Por qué**: el usuario no podía valorar el combate porque solo sabía que recibía o hacía daño, sin ver cómo atacaba cada uno ni notar el golpe. El feedback es una parte de la sensación del combate, no un adorno posterior al arte.

**Alternativa aplazada**: pausa breve al impactar ("hit stop"). Escala `Engine.time_scale`, lo que altera los tiempos de las pruebas automáticas y del resto de temporizadores; se hará cuando se pueda probar con cuidado.

**Técnico**: el brazo se voltea con `scale.x` y `rotation = ángulo * facing`, lo que refleja bien el giro. El temblor mueve `camera.position` para no chocar con el `offset` de mirar arriba/abajo.

## 2026-09-21 — Enemigos con IA: aviso esquivable y retroceso, sin daño por contacto

**Decisión**: el enemigo básico patrulla, persigue y ataca con un aviso visual de 0,4 s (se pone amarillo) que se puede esquivar. Los golpes, del jugador o del enemigo, hacen retroceder a quien los recibe; un golpe al enemigo cancela su ataque. Se elimina el daño por contacto.

**Por qué**: con enemigos quietos el combate, la mitad de la identidad "souls", no se podía validar. Un ataque con aviso convierte la muerte en algo justo (se pudo evitar) y prueba el ataque del jugador, el dash y la invulnerabilidad tras un golpe. Las cifras las propuso Claude (aviso corto de unos 0,4 s, daño 1, retroceso en ambos sentidos) y las aprobó el usuario.

**Técnico**: `PatrolChaseAI` (core) solo decide y avisa mediante señales; el enemigo del juego pone la gravedad y el golpe (`MeleeAttackComponent` con `target_group = player`). `KnockbackComponent` es genérico y lo usan jugador y enemigos. Se retira `ContactDamageArea` de `core/` por quedar sin uso; si hacen falta trampas o pinchos se recuperará entonces. La IA usa un `RayCast2D` para no caerse de los bordes.

**Pendiente**: ajustar tiempos jugando, y decidir tipos de enemigo distintos (a distancia, voladores) y jefes.

## 2026-09-20 — Habilidades que se consiguen, y doble salto

**Decisión**: ninguna habilidad se tiene al empezar. Se consiguen recogiendo un "recuerdo" en el mundo (`AbilityPickup`), son permanentes, y cada una se coloca justo antes del obstáculo que abre. El dash pasa a estar bloqueado de inicio y se añade el doble salto (un salto extra en el aire, `air_jump_velocity` = -800 frente a -900 del primero).

**Por qué**: sin conseguirlas no existía el bucle metroidvania (encuentro una técnica, se abre un camino) y encaja con la premisa (cada habilidad es una técnica recordada).

**Técnico**: el doble salto va dentro de `PlatformerMotor` (`max_air_jumps`) y no como componente aparte, porque comparte con el salto normal el margen de coyote y el buffer; separado se pisaría con él. `DashComponent` gana `unlocked`. `AbilityPickup` (core) solo entrega un identificador y el jugador decide qué activa: así `core/` no conoce las habilidades del juego.

**Pendiente**: trepar pared (la más delicada, toca el feeling del movimiento).

## 2026-09-20 — Mejora del arma: se gasta en el Ancla y sube el daño

**Decisión**: los Ecos se gastan en mejorar el Filo en un Ancla de Memoria con la tecla C. Cinco niveles; cada uno sube el daño (1 a 5) y cuesta 4, 8, 14 y 22 Ecos.

**Por qué**: sin un sitio donde gastarlos, el riesgo de perder los Ecos al morir no significaba nada. Hacerlo en el Ancla aprovecha un lugar que el jugador ya visita, sin construir menús ni personajes que vendan. Se eligió la opción más simple propuesta por Claude y aprobada por el usuario.

**Técnico**: `TieredUpgrade` (core) es genérico (niveles, costes y valores); el jugador cobra y aplica el daño al ataque. El Ancla del juego hereda de `Checkpoint` para añadir la opción de mejora sin ensuciar `core/`.

**Pendiente**: solo sube el daño; decidir si alcance o velocidad también mejoran, y si hay más cosas en las que gastar Ecos. Cifras de partida, a ajustar jugando.

## 2026-09-20 — Reaparición de enemigos: generador que recrea la entidad

**Decisión**: los enemigos se colocan mediante `EntitySpawner` (core). Al morir o descansar el jugador, se llama al grupo `resettable` y cada generador destruye su enemigo (vivo o muerto) y crea uno nuevo desde cero.

**Por qué**: el usuario quería que los enemigos reaparezcan al morir o descansar. Recrear la escena entera garantiza vida completa y posición original sin que cada enemigo implemente su propio reinicio, así que sirve igual para enemigos futuros con IA o estado.

**Alternativa descartada**: no destruir a los enemigos, sino desactivarlos y darles un método `reset()`. Obliga a cada tipo de enemigo a limpiar correctamente su estado y a desactivar colisiones a mano; más propenso a errores.

**Limitación conocida**: se reinician todos los enemigos del nivel. Delimitar por zonas se hará cuando existan varias zonas.

**Técnico**: el reinicio se aplaza (`call_deferred`) porque puede pedirse desde dentro de una señal de físicas, donde Godot no permite añadir cuerpos.

## 2026-09-20 — Pruebas automáticas: prueba de humo propia, sin framework

**Decisión**: `tests/smoke_test.gd` carga el nivel real y comprueba el ciclo jugable y los contratos de `core/` sin ventana; sale con código 0/1.

**Por qué**: durante el refactor cazó dos fallos reales que solo se habrían descubierto jugando (referencias entre nodos vacías; el Eco recogiéndose al instante al reaparecer). Reemplaza a los scripts de diagnóstico desechables que veníamos escribiendo y borrando.

**Alternativa**: frameworks como GUT o gdUnit4. Descartados por ahora: son dependencias externas y el tamaño actual no lo justifica. Se reevaluará si la batería de pruebas crece mucho.

## 2026-09-18 — Alcance del proyecto: personal/aprendizaje, no comercial

**Decisión**: el proyecto se trata como aprendizaje y portfolio personal, sin presión de publicación. No se diseñan todavía economía, monetización ni requisitos de tienda.

**Por qué**: reduce el alcance a lo esencial (núcleo jugable + mundo coherente pequeño) y evita construir sistemas que el proyecto no necesita en esta fase.

**Decidido por**: el usuario.
