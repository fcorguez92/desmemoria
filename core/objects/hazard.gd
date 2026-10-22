class_name Hazard
extends Area2D
## Zona peligrosa (pinchos, estacas...): mientras está activa, cualquier cuerpo
## del grupo `target_group` que la toque recibe el contrato "peligroso" con
## `hazard_hit(damage, hazard)`. Qué significa tocarla (daño, volver al último
## suelo seguro...) lo decide el cuerpo, no la zona.
##
## Puede ser fija (`period` = 0) o pulsante: en cada ciclo de `period` segundos
## está activa `active_fraction` de él, y avisa `warning_time` antes de salir
## (`state_changed` deja que la escena cambie su dibujo). `phase` desfasa unas
## de otras para hacer olas. Entra en el grupo `hazard`.

enum State { RETRACTED, WARNING, ACTIVE }

## Cambia el estado (pulsantes): para dibujo y sonido.
signal state_changed(state: State)

@export var damage: int = 1
@export var target_group: StringName = &"player"
## Segundos de un ciclo completo. 0 = siempre activa.
@export var period: float = 0.0
## Fracción del ciclo en la que está activa.
@export_range(0.05, 0.95) var active_fraction: float = 0.5
## Desfase, en fracción del ciclo.
@export_range(0.0, 1.0) var phase: float = 0.0
## Segundos de aviso antes de salir.
@export var warning_time: float = 0.35

var state: State = State.ACTIVE

var _clock: float = 0.0


func _ready() -> void:
	add_to_group(&"hazard")
	_clock = phase * period
	if period > 0.0:
		state = _state_at(_clock)


func _physics_process(delta: float) -> void:
	if period > 0.0:
		_clock += delta
		var new_state := _state_at(_clock)
		if new_state != state:
			state = new_state
			state_changed.emit(state)
	if state != State.ACTIVE:
		return
	for body in get_overlapping_bodies():
		if body.is_in_group(target_group) and body.has_method("hazard_hit"):
			body.hazard_hit(damage, self)


func _state_at(time: float) -> State:
	var t := fposmod(time, period)
	var active_time := period * active_fraction
	if t < active_time:
		return State.ACTIVE
	if t >= period - warning_time:
		return State.WARNING
	return State.RETRACTED
