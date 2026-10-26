class_name TelegraphZone
extends Node2D
## Marca de aviso de un ataque de zona: pinta un rectángulo o un círculo en el suelo
## (o en el aire) durante `duration` segundos y, al terminar el aviso, hace daño a lo
## que haya dentro. No hace nada antes: pisar la marca durante el aviso es seguro.
##
## Es el aviso del código de color de docs/enemigos.md: **amarillo** = se puede parar o
## esquivar; **rojo** = no se puede parar (`parryable` a false) y además lleva bandas
## diagonales, para que no dependa solo del color (accesibilidad). Un golpe de zona
## rojo atraviesa la guardia del jugador (ver ParryComponent.try_deflect, que lee la
## propiedad `parryable` del atacante, que aquí es la propia zona).
##
## Uso: instanciar, configurar los exports, añadir al árbol y colocar (la posición es el
## centro de la zona; con rotación gira). Empieza solo al entrar en el árbol. Se borra
## sola poco después de golpear. Quien la crea escucha `resolved` si quiere reaccionar.

## Termina el aviso y se ha aplicado el daño; `hit_bodies` son los cuerpos alcanzados.
signal resolved(hit_bodies: Array)
## Un objetivo ha desviado el golpe de zona con un parry.
signal parried

enum Shape { RECT, CIRCLE }

@export var shape_kind: Shape = Shape.RECT
## RECT: ancho y alto. CIRCLE: el radio es `size.x`.
@export var size: Vector2 = Vector2(64.0, 24.0)
## Solo CIRCLE: radio del hueco central. Un objetivo cuyo centro esté más cerca que
## esto del centro de la zona no recibe el golpe (el arco "por dentro" de un jefe: la
## zona pegada al atacante es segura). 0 = círculo entero.
@export var inner_radius: float = 0.0
## Segundos de aviso antes del golpe (ver los mínimos de docs/enemigos.md).
@export var duration: float = 0.7
@export var damage: int = 1
## Si es false, el golpe no se puede parar (aviso rojo con bandas).
@export var parryable: bool = true
## Hacia dónde viaja el golpe (-1 o 1), para la guardia del jugador (solo desvía los golpes
## que llegan de frente) y el retroceso. 0 = alejándose del centro de la zona, que sirve para
## un círculo; en un rectángulo delante del atacante hay que decirlo.
@export var blow_direction: int = 0
## Grupo al que hace daño (con el contrato "golpeable": `take_hit`).
@export var target_group: StringName = &"player"
## Capas de física en las que busca objetivos.
@export_flags_2d_physics var query_mask: int = 1
## Segundos que se queda dibujado el destello del golpe antes de borrarse.
@export var flash_time: float = 0.18
## Mismos valores que `Enemy.TELEGRAPH_COLOR` y `Enemy.TELEGRAPH_RED` (game/ no se
## puede referenciar desde core/; una prueba comprueba que coinciden).
@export var parryable_color: Color = Color(1.0, 0.85, 0.3)
@export var unparryable_color: Color = Color(1.0, 0.25, 0.2)

## Segundos transcurridos del aviso.
var elapsed: float = 0.0
var is_resolved: bool = false

var _flash_left: float = 0.0
var _deflected: bool = false


func _physics_process(delta: float) -> void:
	if is_resolved:
		_flash_left -= delta
		queue_redraw()
		if _flash_left <= 0.0:
			queue_free()
		return
	elapsed += delta
	queue_redraw()
	if elapsed >= duration:
		_resolve()


## Fracción del aviso transcurrida, de 0 a 1.
func progress() -> float:
	return clampf(elapsed / duration, 0.0, 1.0) if duration > 0.0 else 1.0


## Color del aviso según se pueda parar o no.
func warning_color() -> Color:
	return parryable_color if parryable else unparryable_color


## Cancela el aviso sin golpear (el atacante ha muerto o ha sido interrumpido).
func cancel() -> void:
	if not is_resolved:
		is_resolved = true
		_flash_left = 0.0
		queue_free()


## Contrato "parable": si un objetivo desvía el golpe, solo se avisa; los demás
## objetivos de la zona siguen recibiéndolo.
func on_parried(_extra_stun: float = 0.0) -> void:
	_deflected = true
	parried.emit()


func _resolve() -> void:
	is_resolved = true
	_flash_left = flash_time
	var hit: Array = []
	for body in _bodies_inside():
		if target_group != &"" and not body.is_in_group(target_group):
			continue
		if not body.has_method("take_hit"):
			continue
		var from_direction := blow_direction if blow_direction != 0 else (1 if body.global_position.x >= global_position.x else -1)
		_deflected = false
		body.take_hit(damage, from_direction, self)
		# Un cuerpo que ha parado el golpe (zona amarilla) no cuenta como golpeado.
		if not _deflected:
			hit.append(body)
	resolved.emit(hit)


func _bodies_inside() -> Array:
	var query := PhysicsShapeQueryParameters2D.new()
	if shape_kind == Shape.CIRCLE:
		var circle := CircleShape2D.new()
		circle.radius = size.x
		query.shape = circle
	else:
		var rect := RectangleShape2D.new()
		rect.size = size
		query.shape = rect
	query.transform = global_transform
	query.collision_mask = query_mask
	query.collide_with_areas = false
	var bodies: Array = []
	for result in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var body := result.collider as Node2D
		# Anillo: el centro de quien está en el hueco central no cuenta.
		if shape_kind == Shape.CIRCLE and inner_radius > 0.0 and body != null \
				and body.global_position.distance_to(global_position) < inner_radius:
			continue
		bodies.append(result.collider)
	return bodies


func _draw() -> void:
	var color := warning_color()
	var fill_alpha := lerpf(0.12, 0.42, progress())
	var edge_alpha := 0.95
	if is_resolved:
		# Destello del golpe: relleno casi opaco que se apaga.
		var k := clampf(_flash_left / maxf(flash_time, 0.001), 0.0, 1.0)
		color = color.lerp(Color.WHITE, 0.6)
		fill_alpha = 0.7 * k
		edge_alpha = k
	var half := size / 2.0
	if shape_kind == Shape.CIRCLE:
		if inner_radius > 0.0:
			# Anillo: la banda peligrosa, con el hueco seguro en el centro.
			var middle := (size.x + inner_radius) / 2.0
			draw_arc(Vector2.ZERO, middle, 0.0, TAU, 64, Color(color, fill_alpha), size.x - inner_radius)
			draw_arc(Vector2.ZERO, inner_radius, 0.0, TAU, 48, Color(color, edge_alpha * 0.6), 1.0)
		else:
			draw_circle(Vector2.ZERO, size.x, Color(color, fill_alpha))
		draw_arc(Vector2.ZERO, size.x, 0.0, TAU, 48, Color(color, edge_alpha), 2.0)
	else:
		draw_rect(Rect2(-half, size), Color(color, fill_alpha))
		draw_rect(Rect2(-half, size), Color(color, edge_alpha), false, 2.0)
	if not parryable:
		_draw_bands(Color(color, edge_alpha * 0.75))


## Bandas diagonales (x + y = c) recortadas a la forma: la marca del aviso rojo.
func _draw_bands(color: Color) -> void:
	var reach := size.x * 1.42 if shape_kind == Shape.CIRCLE else (size.x + size.y) / 2.0
	var step := 9.0
	var c := -reach
	while c <= reach:
		var from_x: float
		var to_x: float
		if shape_kind == Shape.CIRCLE:
			var disc := 2.0 * size.x * size.x - c * c
			if disc < 0.0:
				c += step
				continue
			from_x = (c - sqrt(disc)) / 2.0
			to_x = (c + sqrt(disc)) / 2.0
		else:
			from_x = maxf(c - size.y / 2.0, -size.x / 2.0)
			to_x = minf(c + size.y / 2.0, size.x / 2.0)
		if to_x > from_x:
			draw_line(Vector2(from_x, c - from_x), Vector2(to_x, c - to_x), color, 1.0)
		c += step
