class_name MeleeAttackComponent
extends Node
## Ataque cuerpo a cuerpo: golpea una vez, con enfriamiento, a todo lo que
## esté dentro de `hitbox` y tenga un método `take_hit(damage, from_direction)`.
##
## Consulta los solapamientos en el instante del ataque en lugar de usar
## señales, para evitar depender del orden de eventos de la física.

## Área (normalmente hija del cuerpo) que define el alcance del golpe.
@export var hitbox: Area2D
@export var cooldown: float = 0.25
## Distancia horizontal del centro del hitbox al cuerpo.
@export var reach: float = 20.0
@export var damage: int = 1
## Si no está vacío, solo golpea a cuerpos de este grupo (p. ej. un enemigo solo
## golpea al jugador). Vacío = golpea a cualquier cosa golpeable.
@export var target_group: StringName = &""

var _cooldown_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)


## Coloca el hitbox delante del cuerpo según hacia dónde mira (-1 o 1).
func set_facing(facing: int) -> void:
	hitbox.position.x = reach * facing


## Ataca si no está en enfriamiento. `attacker` se excluye de los objetivos:
## el hitbox es hijo del propio cuerpo y se solapa con él.
func try_attack(attacker: Node, facing: int) -> bool:
	if _cooldown_timer > 0.0:
		return false
	_cooldown_timer = cooldown
	for body in hitbox.get_overlapping_bodies():
		if body == attacker or not body.has_method("take_hit"):
			continue
		if target_group != &"" and not body.is_in_group(target_group):
			continue
		body.take_hit(damage, facing)
	return true
