class_name PhaseTracker
extends RefCounted
## Vida de un jefe en tramos (docs/jefes.md): una vida total y una marca ("suelo")
## por fase. El daño nunca baja de la marca de la fase en curso, así que un golpe
## fuerte no se salta una fase; al llegar a la marca avisa (`floor_reached`) y
## espera a que el dueño llame a `advance()` (tras su transición) para seguir.
## En la última fase la marca es 0: llegar a ella es morir.
##
## No sabe nada de jefes concretos: el dueño le da los números y reacciona a las
## señales. Equivale a `CORE_FLOORS` del Centinela, pero para vida simple.

## La vida llegó a la marca de la fase `phase` (en la última, el jefe ha muerto).
signal floor_reached(phase: int)
## Se pasó a la fase `phase`.
signal phase_changed(phase: int)

var max_health: int = 1
var health: int = 1
var phase: int = 0
## Vida en la que termina cada fase (la última, 0).
var floors: Array[int] = [0]


## `total`: vida inicial. `phase_floors`: marca de cada fase, de mayor a menor
## (p. ej. [24, 12, 0] para 36 puntos en tres fases).
func setup(total: int, phase_floors: Array[int]) -> void:
	max_health = total
	floors = phase_floors.duplicate()
	if floors.is_empty() or floors[floors.size() - 1] != 0:
		floors.append(0)
	reset()


func reset() -> void:
	health = max_health
	phase = 0


## Resta `amount` sin bajar de la marca de la fase. Devuelve el daño que se aplicó.
## Con la vida ya en la marca no hace nada (el dueño está en su transición).
func damage(amount: int) -> int:
	var floor_hp := floors[phase]
	var dealt := clampi(amount, 0, maxi(health - floor_hp, 0))
	if dealt <= 0:
		return 0
	health -= dealt
	if health <= floor_hp:
		floor_reached.emit(phase)
	return dealt


## ¿La vida está en la marca de la fase en curso (pendiente de `advance()` o muerto)?
func at_floor() -> bool:
	return health <= floors[phase]


func is_last_phase() -> bool:
	return phase >= floors.size() - 1


func is_dead() -> bool:
	return is_last_phase() and health <= 0


## Pasa a la fase siguiente (no hace nada en la última).
func advance() -> void:
	if is_last_phase():
		return
	phase += 1
	phase_changed.emit(phase)
