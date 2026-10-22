extends Area2D
## Roca que se desprende del techo: primero un aviso de polvo en el punto del
## suelo donde va a caer, después cae y hace 1 de daño a quien esté debajo.
## Se rompe al llegar al suelo. La coloca el jefe con `start()`.

const WARNING_TIME := 0.85
const FALL_GRAVITY := 2400.0
const DAMAGE := 1

var _floor_y: float = 0.0
var _age: float = 0.0
var _vy: float = 0.0
var _falling: bool = false

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _marker: Polygon2D = $Marker


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_marker.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-15, -5), Vector2(15, -5), Vector2(26, 0), Vector2(15, 4), Vector2(-15, 4)])
	_sprite.visible = false
	monitoring = false


## `from` es dónde empieza (en el techo). Cae hasta lo primero sólido que haya
## debajo (suelo o tablón); `fallback_floor_y` solo se usa si no hay nada.
func start(from: Vector2, fallback_floor_y: float) -> void:
	global_position = from
	_floor_y = _find_floor(from, fallback_floor_y)
	_marker.top_level = true
	_marker.global_position = Vector2(from.x, _floor_y - 2.0)


## Lo primero que toca un rayo hacia abajo desde el techo, saltándose a los que se
## mueven (el jugador, el jefe): la roca cae a través de ellos y se rompe contra el
## escenario. Los tablones cuentan: una roca no atraviesa un tablón.
func _find_floor(from: Vector2, fallback: float) -> float:
	var space := get_world_2d().direct_space_state
	var start := from
	for i in 6:
		var query := PhysicsRayQueryParameters2D.create(start, Vector2(start.x, start.y + 4000.0), 1)
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return fallback
		if not hit.collider is CharacterBody2D:
			return hit.position.y
		start = hit.position + Vector2(0.0, 2.0)
	return fallback


func _physics_process(delta: float) -> void:
	_age += delta
	if not _falling:
		# El polvo del suelo late cada vez más deprisa.
		_marker.modulate.a = 0.35 + 0.5 * absf(sin(_age * (8.0 + 14.0 * _age / WARNING_TIME)))
		if _age >= WARNING_TIME:
			_falling = true
			_sprite.visible = true
			_marker.visible = false
			monitoring = true
			Sfx.play(&"rock_fall", global_position, -10.0)
		return
	_vy += FALL_GRAVITY * delta
	position.y += _vy * delta
	_sprite.rotation += 6.0 * delta
	if global_position.y + 14.0 >= _floor_y:
		_shatter()


func _on_body_entered(body: Node) -> void:
	if _falling and body.is_in_group("player") and body.has_method("take_hit"):
		# Dirección 0: una roca que cae no se desvía con un parry.
		body.take_hit(DAMAGE, 0, self)
		_shatter()


func _shatter() -> void:
	Sfx.play(&"rock_break", global_position, -8.0)
	HitSpark.spawn(get_parent(), Vector2(global_position.x, _floor_y - 10.0), Color(0.7, 0.66, 0.6), 1.2)
	queue_free()
