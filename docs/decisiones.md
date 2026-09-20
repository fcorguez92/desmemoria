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

## 2026-09-20 — Pruebas automáticas: prueba de humo propia, sin framework

**Decisión**: `tests/smoke_test.gd` carga el nivel real y comprueba el ciclo jugable y los contratos de `core/` sin ventana; sale con código 0/1.

**Por qué**: durante el refactor cazó dos fallos reales que solo se habrían descubierto jugando (referencias entre nodos vacías; el Eco recogiéndose al instante al reaparecer). Reemplaza a los scripts de diagnóstico desechables que veníamos escribiendo y borrando.

**Alternativa**: frameworks como GUT o gdUnit4. Descartados por ahora: son dependencias externas y el tamaño actual no lo justifica. Se reevaluará si la batería de pruebas crece mucho.

## 2026-09-18 — Alcance del proyecto: personal/aprendizaje, no comercial

**Decisión**: el proyecto se trata como aprendizaje y portfolio personal, sin presión de publicación. No se diseñan todavía economía, monetización ni requisitos de tienda.

**Por qué**: reduce el alcance a lo esencial (núcleo jugable + mundo coherente pequeño) y evita construir sistemas que el proyecto no necesita en esta fase.

**Decidido por**: el usuario.
