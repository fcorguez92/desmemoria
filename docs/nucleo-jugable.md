# Núcleo jugable (documento vivo)

Estado: diseño aprobado, pendiente de validar con el prototipo grey-box. Estas reglas son la hipótesis de partida — si al jugarlo no se siente bien, se ajusta aquí antes de seguir construyendo contenido encima.

## Movimiento

Ágil y preciso, inspirado en Hollow Knight: salto con arco controlable en el aire, sin inercia pesada tipo Souls. Caminar y saltar disponibles desde el inicio del juego; el resto de movilidad se desbloquea como habilidad de progresión.

## Arma: "el Filo" (nombre de trabajo)

Un único arma cuerpo a cuerpo que mejora en tiers (4-5 previstos) gastando Ecos, en vez de un inventario de armas distintas. Moveset fijo: ataque horizontal, ataque hacia arriba y hacia abajo (necesario para combate vertical en un mapa con plataformas).

## Habilidades de progresión (boceto inicial — ampliable si el desarrollo lo permite)

Cada habilidad es narrativamente una técnica recordada de otra persona (ver docs/historia.md); desbloquearla es a la vez progreso mecánico y revelación de historia.

1. **Dash** — desplazamiento horizontal rápido.
2. **Trepar/saltar en pared** — asciende por grietas específicas marcadas en el entorno.
3. **Doble salto** — alcance vertical adicional.
4. **Excavar/romper suelo** — abre Las Minas del Origen como red de atajos entre regiones de superficie (ver docs/mundo.md).

## Economía: Ecos

Los enemigos derrotados sueltan **Ecos** — fragmentos de memoria ajena liberados al vencerlos. Se gastan en mejorar el Filo y (pendiente de diseñar) en objetos/mejoras a través de algún NPC.

## Muerte y recuperación

Al morir, el jugador pierde todos sus Ecos, que quedan marcados como **un Eco de sí mismo** en la última posición en la que pisó suelo firme (no en el punto exacto de la muerte, para que una caída a un hueco no deje el Eco inalcanzable). El Eco no es hostil: basta con tocarlo para recuperar los Ecos al instante. Si el jugador muere otra vez antes de llegar a él, ese Eco anterior (y sus Ecos) se pierde para siempre, y se forma uno nuevo en el nuevo punto de muerte.

Se probó una versión hostil (había que derrotarlo en combate) durante el prototipo y se descartó: no aportaba la tensión buscada y complicaba la recuperación sin necesidad.

El Eco aparece siempre al morir, aunque no se llevaran Ecos encima (en ese caso, tocarlo no da nada). Así sirve también como señal de "aquí moriste la última vez", pensando en un futuro sistema de mapa que podría marcarlo — todavía no decidido.

## Curación: Anclas de Memoria

Un objeto curativo de usos limitados, que se recarga solo en los puntos de descanso, llamados **Anclas de Memoria**. Las Anclas también:
- Sirven de punto de guardado.
- Se activan **a propósito** con el botón Z (no al pasar por encima), y muestran un aviso "Z: Recordar" al estar al alcance. Descansar es una parada, no un accidente.
- Al usarlas, reinician (respawnean) a los enemigos normales — como en los juegos souls, para mantener el riesgo al volver a explorar. Los enemigos también reaparecen cuando el jugador muere. Hoy se reinician **todos** los enemigos del nivel, no solo los "del área"; delimitar zonas queda para cuando haya un mundo con varias.

### Aspecto: el Hito de Nombres

El Ancla es un **hito de piedras apiladas**, cada una con grabado el nombre de alguien que la Desmemoria borró. Los supervivientes lo levantan para que al menos ese nombre siga existiendo. Como el protagonista no puede olvidar, descansar ahí es pronunciar esos nombres en voz alta. Se eligió porque no es un banco (Hollow Knight) ni una hoguera (Dark Souls), y expresa la premisa del juego en un objeto cotidiano.

## Pendiente de definir en próximas sesiones de diseño

- Sistema de estadísticas del personaje (¿solo vida, o también algo como stamina/resistencia?).
- Qué se compra con Ecos aparte del Filo, y a través de qué NPC.
- Tiers exactos de mejora del Filo y sus requisitos.
- Diseño de enemigos y jefes concretos.
