class_name PlatformerMotor
extends Node
## Movimiento lateral con salto ágil: coyote time, jump buffering, altura de
## salto variable y caída más rápida que la subida. Opcionalmente, saltos extra
## en el aire y agarre/salto de pared.
##
## No se mueve solo: el dueño llama a `step()` cada frame de físicas y después
## a `move_and_slide()`. Así el orden respecto a otros componentes (p. ej. el
## dash, que pisa la velocidad) queda visible en un único sitio.
##
## Prioridad al pulsar salto: suelo (o margen de coyote) > pared > salto extra.

## Se emite cuando cambia la dirección a la que mira el cuerpo (-1 o 1).
signal facing_changed(facing: int)
## Se emite al saltar, con el tipo: &"ground" (suelo o coyote), &"wall" o &"air" (salto extra).
signal jumped(kind: StringName)

@export var speed: float = 300.0
@export var jump_velocity: float = -900.0
@export var gravity: float = 2250.0
@export var fall_gravity_multiplier: float = 1.4
## Margen tras salir de una plataforma en el que aún se puede saltar.
@export var coyote_time: float = 0.1
## Margen en el que un salto pulsado justo antes de aterrizar se recuerda.
@export var jump_buffer_time: float = 0.12
## Fracción de la velocidad de subida que se conserva al soltar el salto pronto.
@export_range(0.0, 1.0) var jump_cut_factor: float = 0.5
## Saltos extra en el aire (0 = ninguno, 1 = doble salto). Se recargan al tocar suelo.
@export var max_air_jumps: int = 0
@export var air_jump_velocity: float = -800.0

@export_group("Pared")
## Si es false no hay agarre ni salto de pared (habilidad aún no conseguida).
@export var can_wall_jump: bool = false
## Velocidad máxima de caída agarrado a una pared (pulsando hacia ella).
@export var wall_slide_speed: float = 120.0
## Empuje horizontal al saltar de una pared, alejándose de ella.
@export var wall_jump_push: float = 350.0
@export var wall_jump_velocity: float = -850.0
## Tras saltar de una pared, segundos que se ignora la dirección pulsada para
## que el empuje no se cancele al instante.
@export var wall_jump_lock_time: float = 0.15
## Margen tras separarse de la pared en el que aún se puede saltar desde ella.
@export var wall_coyote_time: float = 0.1

@export_group("Plataformas de un solo sentido")
## Si es true, abajo + salto sobre una plataforma de un solo sentido la atraviesa
## hacia abajo. Sobre suelo sólido, abajo + salto sigue siendo un salto normal.
@export var can_drop_through: bool = true
## Píxeles que se baja el cuerpo de golpe al atravesar: más que el grosor de la
## franja de colisión de la plataforma, para quedar por debajo de ella.
@export var drop_through_distance: float = 5.0
## Velocidad de caída inicial al atravesar.
@export var drop_through_speed: float = 60.0

@export_group("Esquinas")
## Corrección de esquina: si al saltar la cabeza rozaría el borde de un techo por
## menos de estos píxeles, el cuerpo se desplaza hacia el lado libre y sigue subiendo
## en vez de chocar. Es lo que evita "quedarse pillado" en huecos justos. 0 = sin ella.
@export var ceiling_corner_correction: float = 8.0

@export_group("Entrada")
@export var action_left: StringName = &"ui_left"
@export var action_right: StringName = &"ui_right"
@export var action_jump: StringName = &"ui_accept"
@export var action_down: StringName = &"ui_down"

var facing: int = 1

var _coyote_timer: float = 0.0
var _jump_buffer_timer: float = 0.0
var _air_jumps_left: int = 0
var _wall_normal_x: int = 0
var _wall_timer: float = 0.0
var _wall_lock_timer: float = 0.0
var _bounce_lock_timer: float = 0.0

## Segundos tras un rebote en los que soltar el salto no recorta la subida.
const BOUNCE_JUMP_CUT_LOCK := 0.1


func step(body: CharacterBody2D, delta: float) -> void:
	var on_floor := body.is_on_floor()
	# Todo o nada, como con el teclado: con la palanca del mando, pasar de la zona
	# muerta ya es correr a toda velocidad (no hay paso lento a media inclinación).
	var direction := signf(Input.get_axis(action_left, action_right))

	if on_floor:
		body.velocity.y = 0.0
		_coyote_timer = coyote_time
		_air_jumps_left = max_air_jumps
	else:
		var g := gravity * fall_gravity_multiplier if body.velocity.y > 0.0 else gravity
		body.velocity.y += g * delta
		_coyote_timer = maxf(_coyote_timer - delta, 0.0)

	# Contacto con pared: se recuerda un instante para poder saltar "justo tarde".
	_wall_lock_timer = maxf(_wall_lock_timer - delta, 0.0)
	if can_wall_jump and not on_floor and _touching_grippable_wall(body):
		_wall_normal_x = int(signf(body.get_wall_normal().x))
		_wall_timer = wall_coyote_time
		var pressing_toward_wall := int(signf(direction)) == -_wall_normal_x
		if pressing_toward_wall and body.velocity.y > wall_slide_speed:
			body.velocity.y = wall_slide_speed
	else:
		_wall_timer = maxf(_wall_timer - delta, 0.0)

	var jump_pressed := Input.is_action_just_pressed(action_jump)
	if jump_pressed and on_floor and can_drop_through and Input.is_action_pressed(action_down) \
			and is_standing_on_one_way(body):
		# Abajo + salto sobre una plataforma de un solo sentido: bajar en vez de saltar.
		body.position.y += drop_through_distance
		body.velocity.y = drop_through_speed
		_coyote_timer = 0.0
		_jump_buffer_timer = 0.0
		jump_pressed = false
		on_floor = false
	if jump_pressed:
		_jump_buffer_timer = jump_buffer_time
	else:
		_jump_buffer_timer = maxf(_jump_buffer_timer - delta, 0.0)

	if _jump_buffer_timer > 0.0 and _coyote_timer > 0.0:
		body.velocity.y = jump_velocity
		_jump_buffer_timer = 0.0
		_coyote_timer = 0.0
		jumped.emit(&"ground")
	elif jump_pressed and can_wall_jump and not on_floor and _wall_timer > 0.0:
		body.velocity = Vector2(_wall_normal_x * wall_jump_push, wall_jump_velocity)
		_wall_lock_timer = wall_jump_lock_time
		_wall_timer = 0.0
		_jump_buffer_timer = 0.0
		_set_facing(_wall_normal_x)
		jumped.emit(&"wall")
	elif jump_pressed and not on_floor and _air_jumps_left > 0:
		# Solo si ni el suelo (ni su margen de coyote) ni una pared sirvieron.
		body.velocity.y = air_jump_velocity
		_air_jumps_left -= 1
		_jump_buffer_timer = 0.0
		jumped.emit(&"air")

	_bounce_lock_timer = maxf(_bounce_lock_timer - delta, 0.0)
	if Input.is_action_just_released(action_jump) and body.velocity.y < 0.0 and _bounce_lock_timer <= 0.0:
		body.velocity.y *= jump_cut_factor

	if _wall_lock_timer <= 0.0:
		body.velocity.x = direction * speed
		if direction != 0.0:
			_set_facing(int(signf(direction)))


## Nombre del dato de baldosa (bool) que marca una pared lisa: sólida, pero el
## agarre y el salto de pared no se sujetan a ella (ver docs/puzles.md, T1).
const SMOOTH_DATA := "smooth"


## ¿Toca el cuerpo una pared a la que agarrarse? Las paredes lisas no cuentan.
func _touching_grippable_wall(body: CharacterBody2D) -> bool:
	if not body.is_on_wall():
		return false
	for i in body.get_slide_collision_count():
		var hit := body.get_slide_collision(i)
		if absf(hit.get_normal().x) > 0.7 and not is_smooth_surface(hit):
			return true
	return false


## ¿Es la superficie de este choque una baldosa lisa (dato `smooth`)?
static func is_smooth_surface(hit: KinematicCollision2D) -> bool:
	var layer := hit.get_collider() as TileMapLayer
	if layer == null or layer.tile_set == null or layer.tile_set.get_custom_data_layer_by_name(SMOOTH_DATA) == -1:
		return false
	var inside := hit.get_position() - hit.get_normal()
	var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(inside)))
	return data != null and bool(data.get_custom_data(SMOOTH_DATA))


## Llamar antes de `move_and_slide()`, con la velocidad ya final: si el cuerpo sube y
## chocaría con la esquina de un techo, lo desplaza de lado hasta `ceiling_corner_correction`
## píxeles para que pase.
func correct_ceiling_corner(body: CharacterBody2D, delta: float) -> void:
	if ceiling_corner_correction <= 0.0 or body.velocity.y >= 0.0:
		return
	var motion := Vector2(0.0, body.velocity.y * delta)
	if not body.test_move(body.global_transform, motion):
		return
	for step in range(1, int(ceiling_corner_correction) + 1):
		for side in [1, -1]:
			var shift := Vector2(side * step, 0.0)
			if body.test_move(body.global_transform, shift):
				continue
			if not body.test_move(body.global_transform.translated(shift), motion):
				body.global_position.x += shift.x
				return


## ¿Lo que hay justo bajo los pies es una plataforma de un solo sentido? Sirve
## tanto para baldosas (TileMapLayer) como para formas con `one_way_collision`.
static func is_standing_on_one_way(body: CharacterBody2D) -> bool:
	var hit := KinematicCollision2D.new()
	if not body.test_move(body.global_transform, Vector2(0.0, 2.0), hit):
		return false
	var collider := hit.get_collider()
	if collider is TileMapLayer:
		var layer := collider as TileMapLayer
		# La baldosa es la que contiene el punto de contacto, un píxel hacia dentro.
		var inside := hit.get_position() - hit.get_normal()
		var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(inside)))
		return data != null and data.get_collision_polygons_count(0) > 0 \
				and data.is_collision_polygon_one_way(0, 0)
	if collider is CollisionObject2D:
		var object := collider as CollisionObject2D
		var owner_id := object.shape_find_owner(hit.get_collider_shape_index())
		var shape_node := object.shape_owner_get_owner(owner_id) as CollisionShape2D
		return shape_node != null and shape_node.one_way_collision
	return false


## Impulsa el cuerpo hacia arriba hasta `height` píxeles (rebote). No recarga saltos
## extra, y soltar el salto justo después no recorta la subida.
func bounce(body: CharacterBody2D, height: float) -> void:
	body.velocity.y = -sqrt(2.0 * gravity * height)
	_bounce_lock_timer = BOUNCE_JUMP_CUT_LOCK


func _set_facing(new_facing: int) -> void:
	if new_facing != 0 and new_facing != facing:
		facing = new_facing
		facing_changed.emit(facing)
