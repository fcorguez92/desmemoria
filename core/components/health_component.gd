class_name HealthComponent
extends Node
## Vida, invulnerabilidad tras recibir daño y cargas de curación limitadas.
##
## No decide qué pasa al morir: emite `died` y el dueño reacciona (destruirse,
## reaparecer...). Tampoco dibuja nada: la UI y los efectos escuchan señales.

signal changed
signal damaged(amount: int)
signal died
## El sorbo de curación empieza, se completa o se interrumpe.
signal heal_started(duration: float)
signal heal_finished
signal heal_cancelled

@export var max_health: int = 5
## Segundos de invulnerabilidad tras recibir daño. 0 = sin invulnerabilidad.
@export var invulnerability_time: float = 0.0
@export var max_heal_charges: int = 0
## Vida que devuelve cada carga. 0 = cura del todo.
@export var heal_amount: int = 0
## Segundos que dura el sorbo de `begin_heal()`. 0 = instantáneo.
@export var heal_time: float = 0.0

var health: int
var heal_charges: int

var _invulnerable_timer: float = 0.0
var _heal_timer: float = 0.0
var _healing: bool = false


func _ready() -> void:
	restore()


func _physics_process(delta: float) -> void:
	_invulnerable_timer = maxf(_invulnerable_timer - delta, 0.0)
	if _healing:
		_heal_timer -= delta
		if _heal_timer <= 0.0:
			_healing = false
			if use_heal_charge():
				heal_finished.emit()


## Aplica daño. Devuelve false si se ignoró (invulnerable o ya sin vida).
func take_hit(amount: int) -> bool:
	if _invulnerable_timer > 0.0 or health <= 0:
		return false
	cancel_heal()
	health -= amount
	_invulnerable_timer = invulnerability_time
	damaged.emit(amount)
	changed.emit()
	if health <= 0:
		died.emit()
	return true


## ¿Está ahora mismo en invulnerabilidad (tras un golpe)?
func is_invulnerable() -> bool:
	return _invulnerable_timer > 0.0


## ¿Hay un sorbo en curso?
func is_healing() -> bool:
	return _healing


## Segundos que le faltan al sorbo en curso.
func heal_time_left() -> float:
	return maxf(_heal_timer, 0.0) if _healing else 0.0


## Empieza un sorbo de `heal_time` segundos. La carga se gasta y la vida se
## recupera al terminar; un golpe (o `cancel_heal()`) lo interrumpe sin gastar
## nada. Devuelve false si no procede (sin cargas, vida llena o ya bebiendo).
func begin_heal() -> bool:
	if _healing or heal_charges <= 0 or health <= 0 or health >= max_health:
		return false
	if heal_time <= 0.0:
		return use_heal_charge()
	_healing = true
	_heal_timer = heal_time
	heal_started.emit(heal_time)
	return true


## Interrumpe el sorbo en curso sin gastar la carga.
func cancel_heal() -> void:
	if _healing:
		_healing = false
		heal_cancelled.emit()


## Aplicación instantánea de una curación: gasta una carga y recupera
## `heal_amount` de vida (todo si es 0). Devuelve false si no procede. La llama
## el final del sorbo, pero también sirve sola.
func use_heal_charge() -> bool:
	if heal_charges <= 0 or health >= max_health:
		return false
	heal_charges -= 1
	health = max_health if heal_amount <= 0 else mini(health + heal_amount, max_health)
	changed.emit()
	return true


## Vida al máximo, sin tocar las cargas de curación.
func reset_health() -> void:
	health = max_health
	changed.emit()


## Vida y cargas de curación al máximo (p. ej. al descansar en un checkpoint).
func restore() -> void:
	cancel_heal()
	health = max_health
	heal_charges = max_heal_charges
	changed.emit()
