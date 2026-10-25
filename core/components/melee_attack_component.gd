class_name MeleeAttackComponent
extends Node
## Ataque cuerpo a cuerpo: golpea una vez, con enfriamiento, a todo lo que
## esté dentro de `hitbox` y tenga un método `take_hit(damage, from_direction, attacker)`.
##
## Consulta los solapamientos en el instante del ataque en lugar de usar
## señales, para evitar depender del orden de eventos de la física.

## Hacia dónde se golpea: de lado (el hitbox de la escena), hacia arriba o hacia abajo.
enum Direction { SIDE, UP, DOWN }

## Se emite por cada cuerpo alcanzado por un golpe (para chispas, temblor...).
signal hit_landed(body: Node)

## Área (normalmente hija del cuerpo) que define el alcance del golpe.
@export var hitbox: Area2D
@export var cooldown: float = 0.25
## Distancia horizontal del centro del hitbox al cuerpo.
@export var reach: float = 20.0
@export var damage: int = 1
## Si no está vacío, solo golpea a cuerpos de este grupo (p. ej. un enemigo solo
## golpea al jugador). Vacío = golpea a cualquier cosa golpeable.
@export var target_group: StringName = &""

@export_group("Golpe direccional")
## Zona del golpe hacia arriba/abajo: centro relativo al cuerpo y tamaño. Solo se
## usan si el dueño pide `Direction.UP` o `Direction.DOWN`.
@export var up_offset: Vector2 = Vector2(0.0, -44.0)
@export var up_size: Vector2 = Vector2(36.0, 44.0)
@export var down_offset: Vector2 = Vector2(0.0, 38.0)
@export var down_size: Vector2 = Vector2(30.0, 36.0)

## Dirección del último golpe lanzado (para que el dueño sepa si fue hacia abajo).
var last_direction: Direction = Direction.SIDE

var _cooldown_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)


## Coloca el hitbox delante del cuerpo según hacia dónde mira (-1 o 1).
func set_facing(facing: int) -> void:
	hitbox.position.x = reach * facing


## Ataca si no está en enfriamiento. `attacker` se excluye de los objetivos:
## el hitbox es hijo del propio cuerpo y se solapa con él.
## Con `direction` UP o DOWN usa la zona direccional y consulta la física al
## instante (el hitbox de la escena no se mueve, así no hay que esperar un frame).
func try_attack(attacker: Node, facing: int, direction: Direction = Direction.SIDE) -> bool:
	if _cooldown_timer > 0.0:
		return false
	_cooldown_timer = cooldown
	last_direction = direction
	var bodies: Array = hitbox.get_overlapping_bodies() if direction == Direction.SIDE \
			else _bodies_in_zone(attacker, direction)
	for body in bodies:
		if body == attacker or not body.has_method("take_hit"):
			continue
		if target_group != &"" and not body.is_in_group(target_group):
			continue
		body.take_hit(damage, facing, attacker)
		hit_landed.emit(body)
	return true


func _bodies_in_zone(attacker: Node, direction: Direction) -> Array:
	var owner_2d := attacker as Node2D
	if owner_2d == null:
		return []
	var shape := RectangleShape2D.new()
	shape.size = up_size if direction == Direction.UP else down_size
	var offset := up_offset if direction == Direction.UP else down_offset
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, owner_2d.global_position + offset)
	query.collision_mask = hitbox.collision_mask
	query.collide_with_areas = false
	var bodies: Array = []
	for result in owner_2d.get_world_2d().direct_space_state.intersect_shape(query, 16):
		bodies.append(result.collider)
	return bodies
