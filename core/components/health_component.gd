class_name HealthComponent
extends Node
## Vida, invulnerabilidad tras recibir daño y cargas de curación limitadas.
##
## No decide qué pasa al morir: emite `died` y el dueño reacciona (destruirse,
## reaparecer...). Tampoco dibuja nada: la UI y los efectos escuchan señales.

signal changed
signal damaged(amount: int)
signal died

@export var max_health: int = 5
## Segundos de invulnerabilidad tras recibir daño. 0 = sin invulnerabilidad.
@export var invulnerability_time: float = 0.0
@export var max_heal_charges: int = 0

var health: int
var heal_charges: int

var _invulnerable_timer: float = 0.0


func _ready() -> void:
	restore()


func _physics_process(delta: float) -> void:
	_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)


## Aplica daño. Devuelve false si se ignoró (invulnerable o ya sin vida).
func take_hit(amount: int) -> bool:
	if _invulnerable_timer > 0.0 or health <= 0:
		return false
	health -= amount
	_invulnerable_timer = invulnerability_time
	damaged.emit(amount)
	changed.emit()
	if health <= 0:
		died.emit()
	return true


## Gasta una carga para curar del todo. Devuelve false si no procede.
func use_heal_charge() -> bool:
	if heal_charges <= 0 or health >= max_health:
		return false
	heal_charges -= 1
	health = max_health
	changed.emit()
	return true


## Vida al máximo, sin tocar las cargas de curación.
func reset_health() -> void:
	health = max_health
	changed.emit()


## Vida y cargas de curación al máximo (p. ej. al descansar en un checkpoint).
func restore() -> void:
	health = max_health
	heal_charges = max_heal_charges
	changed.emit()
