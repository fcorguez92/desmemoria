# Registro de decisiones técnicas y de diseño

Cada entrada: qué se decidió, por qué, qué alternativas se descartaron y por qué. Se añade una entrada nueva por decisión importante, no se reescribe el historial.

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
