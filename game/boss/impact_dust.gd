extends Node2D
## Polvo de un impacto grande: nubecillas que suben y se desvanecen, puestas solo
## donde hay suelo debajo (en un tablón estrecho no sale polvo flotando en el aire,
## que era lo que pasaba cuando el polvo iba dibujado en la hoja del jefe).
## Uso: `ImpactDust.spawn(parent, x, y_del_suelo, mitad_del_ancho)`.

const LIFETIME := 0.7
const COLOR := Color(0.66, 0.62, 0.56)

var _puffs: Array[Dictionary] = []
var _age: float = 0.0


static func spawn(parent: Node, center_x: float, floor_y: float, half_width: float, count: int = 11) -> void:
	var dust: Node2D = load("res://game/boss/impact_dust.gd").new()
	dust.z_index = 3
	parent.add_child(dust)
	dust.global_position = Vector2(center_x, floor_y)
	dust.call("_build", half_width, count)


func _build(half_width: float, count: int) -> void:
	var space := get_world_2d().direct_space_state
	for i in count:
		var t := float(i) / maxf(count - 1, 1)
		var x := lerpf(-half_width, half_width, t) + randf_range(-6.0, 6.0)
		var from := global_position + Vector2(x, -14.0)
		var query := PhysicsRayQueryParameters2D.create(from, from + Vector2(0.0, 30.0), 1)
		var found := space.intersect_ray(query)
		if found.is_empty() or found.collider is CharacterBody2D:
			continue
		_puffs.append({ x = x, y = found.position.y - global_position.y, r = randf_range(9.0, 15.0), rise = randf_range(26.0, 46.0), drift = randf_range(-16.0, 16.0) })
	if _puffs.is_empty():
		queue_free()


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFETIME:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _age / LIFETIME
	for puff in _puffs:
		var radius: float = puff.r * (0.6 + 0.9 * k)
		var at := Vector2(puff.x + puff.drift * k, puff.y - puff.rise * k - radius * 0.4)
		draw_circle(at, radius, Color(COLOR, 0.8 * (1.0 - k)))
