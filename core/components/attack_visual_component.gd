class_name AttackVisualComponent
extends Node
## Animación básica de ataque: un "brazo" (Node2D) que se levanta durante el aviso
## y golpea hacia delante, más un destello opcional del arco del golpe.
##
## Es solo presentación: no decide cuándo se ataca ni hace daño. El dueño la
## llama en los momentos oportunos: `windup()` al empezar un aviso, `strike()`
## cuando cae el golpe, `swing()` para un ataque sin aviso, `reset()` al cancelar.
##
## Ángulos en radianes con el cuerpo mirando a la derecha: 0 = horizontal hacia
## delante, positivo = hacia abajo, negativo = hacia arriba.

@export var arm: Node2D
## Destello del arco del golpe (p. ej. un Polygon2D). Opcional.
@export var slash: CanvasItem
@export var rest_angle: float = 1.0
@export var windup_angle: float = -1.3
@export var strike_angle: float = 0.35
@export var strike_time: float = 0.07
@export var recover_time: float = 0.18
@export_range(0.0, 1.0) var slash_alpha: float = 0.6

var facing: int = 1

var _angle: float = 0.0
var _tween: Tween
var _slash_tween: Tween


func _ready() -> void:
	_set_angle(rest_angle)
	if slash:
		slash.modulate.a = 0.0


## Voltea el brazo y el destello según hacia dónde mira el cuerpo (-1 o 1).
func set_facing(new_facing: int) -> void:
	facing = new_facing
	arm.scale.x = facing
	if slash:
		slash.scale.x = facing
	_set_angle(_angle)


## Levanta el brazo durante `duration` segundos (aviso previo al golpe).
func windup(duration: float) -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_angle, _angle, windup_angle, duration)


## Golpe desde la posición actual del brazo y vuelta al reposo.
func strike() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_angle, _angle, strike_angle, strike_time)
	_tween.tween_method(_set_angle, strike_angle, rest_angle, recover_time)
	if slash:
		slash.modulate.a = slash_alpha
		if _slash_tween:
			_slash_tween.kill()
		_slash_tween = create_tween()
		_slash_tween.tween_property(slash, "modulate:a", 0.0, strike_time + recover_time)


## Ataque sin aviso: salta a la posición levantada y golpea al instante.
func swing() -> void:
	_set_angle(windup_angle)
	strike()


## Cancela cualquier animación y devuelve el brazo al reposo.
func reset() -> void:
	_kill_tween()
	_tween = create_tween()
	_tween.tween_method(_set_angle, _angle, rest_angle, 0.1)
	if slash:
		slash.modulate.a = 0.0


func _set_angle(angle: float) -> void:
	_angle = angle
	arm.rotation = angle * facing


func _kill_tween() -> void:
	if _tween:
		_tween.kill()
