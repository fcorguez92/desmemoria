# Núcleo jugable (documento vivo)

Estado: diseño aprobado, pendiente de validar con el prototipo grey-box. Estas reglas son la hipótesis de partida — si al jugarlo no se siente bien, se ajusta aquí antes de seguir construyendo contenido encima.

## Movimiento

Ágil y preciso, inspirado en Hollow Knight: salto con arco controlable en el aire, sin inercia pesada tipo Souls. Caminar y saltar disponibles desde el inicio del juego; el resto de movilidad se desbloquea como habilidad de progresión.

## Arma: "el Filo" (nombre de trabajo)

Un único arma cuerpo a cuerpo que mejora por niveles gastando Ecos, en vez de un inventario de armas distintas. Moveset fijo: ataque horizontal, ataque hacia arriba y hacia abajo (necesario para combate vertical en un mapa con plataformas; hoy solo existe el horizontal).

### Mejora del Filo (implementada)

- Se mejora **en un Ancla de Memoria** pulsando **C** (junto a Z para descansar). El Ancla muestra el coste de la siguiente mejora y, si no llegan los Ecos, cuántos faltan.
- Cinco niveles. Cada subida aumenta el **daño**: 1, 2, 3, 4, 5. Costes de cada subida en Ecos: 4, 8, 14, 22.
- Los enemigos de prueba tienen 3 de vida y dan 2 Ecos, así que la primera mejora cuesta matar a 2 enemigos y con el nivel 3 caen de un golpe.
- Las mejoras son permanentes: morir no las pierde (los Ecos sí).
- Los costes y valores son de partida y se ajustarán jugando. Solo sube el daño; alcance y velocidad de ataque quedan sin decidir.

## Combate contra enemigos (implementado, cifras de partida)

El combate se apoya en dos ideas: **las amenazas se ven venir** y **los golpes tienen peso**.

- **Enemigo básico** (`game/enemy/`): patrulla cerca de su punto de origen (60 px), te detecta a 220 px si estás a una altura parecida, y te persigue más rápido de lo que patrulla. No se cae por los bordes del suelo.
- **Ataque con aviso:** al acercarse a unos 44 px se queda quieto y se pone **amarillo** durante 0,4 s; después golpea (1 de daño) por delante y descansa 0,7 s. Alejarte o esquivar durante el aviso evita el golpe.
- **Retroceso en ambos sentidos:** cuando el golpe cae, empuja a quien lo recibe. Un golpe tuyo al enemigo lo empuja y **cancela su ataque**, dejándolo aturdido 0,3 s.
- Tras recibir un golpe tienes 0,6 s de invulnerabilidad.
- Los enemigos ya no dañan por contacto: solo con su ataque.

**Feedback visual (implementado, provisional):** el combate se lee con sprites de píxeles y efectos sencillos.
- **Arma integrada en el sprite:** el caminante empuña su espada y el cascarón un cuchillo oxidado, dibujados en el propio personaje. El del enemigo se **alza durante el aviso** (además del tono amarillo) y cae al golpear; el tuyo golpea al instante al pulsar X.
- **Destello del arco** del golpe, muy sutil, blanco el tuyo y anaranjado el del enemigo.
- **Chispazo** en el punto de impacto cuando un golpe alcanza a alguien.
- **Temblor de cámara:** fuerte al recibir un golpe, leve al darlo.
- El destello rojo al recibir daño y el retroceso ya existían.
- Falta la pausa breve al impactar ("hit stop"), que da mucho peso al golpe; se ha dejado fuera porque escala el tiempo del juego y hay que probarla con cuidado.

Estas cifras son de partida y sirven para comprobar el ritmo del combate; el diseño de enemigos y jefes concretos sigue pendiente.

## Habilidades de progresión (boceto inicial — ampliable si el desarrollo lo permite)

Cada habilidad es narrativamente una técnica recordada de otra persona (ver docs/historia.md); desbloquearla es a la vez progreso mecánico y revelación de historia.

1. **Dash** — desplazamiento horizontal rápido. *(implementado)*
2. **Salto de pared** — te agarras a una pared manteniendo la dirección hacia ella (resbalas despacio) y saltas desde ella, empujado hacia el lado contrario, lo que permite subir pozos estrechos saltando de una pared a la otra. Funciona en **cualquier pared**, no solo en grietas marcadas como se pensó al principio: encaja con el manejo tipo Hollow Knight y es más simple; si más adelante se quiere restringir a superficies concretas, es un cambio pequeño. *(implementado)*
3. **Doble salto** — un salto extra en el aire, algo más corto que el primero. *(implementado)*
4. **Excavar/romper suelo** — abre Las Minas del Origen como red de atajos entre regiones de superficie (ver docs/mundo.md).

### Cómo se consiguen (implementado)

Ninguna habilidad se tiene al empezar: se consiguen recogiendo un **recuerdo** (objeto con forma de rombo azul claro) que aparece en el mundo, y el juego avisa con "Has recordado: ...". Son permanentes: morir no las pierde. Cada una está colocada justo antes del obstáculo que abre:

- El **dash** está en la plataforma elevada, y abre el hueco ancho que hay detrás.
- El **doble salto** está en la última plataforma verde, y abre una plataforma alta a la derecha que sin él es inalcanzable.
- El **salto de pared** está en la plataforma alta del doble salto, y abre un pozo estrecho a su derecha: sin él no se puede salir por arriba, ni siquiera con doble salto. Arriba hay una plataforma con otro Ancla.

Es el bucle metroidvania: encuentro una técnica, y un camino antes cerrado se abre.

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
- En qué más se gastan los Ecos aparte del Filo, y si las mejoras piden algo además de Ecos (p. ej. un material raro).
- Diseño de enemigos y jefes concretos.
