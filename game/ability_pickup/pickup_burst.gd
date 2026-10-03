extends Node2D
## Efecto de recogida de una reliquia: destello, onda expansiva, ráfaga de
## partículas y motas que vuelan hacia quien la recoge. Se autodestruye. Cuelga
## del padre del objeto (que se libera al instante), como `HitSpark`.
## Uso: `PickupBurst.spawn(parent, posición_global, color, destino)`.

const MOTES := 12
const FLY_TIME := 0.7

static var _ring_texture: ImageTexture
static var _halo_texture: ImageTexture
static var _dot_texture: ImageTexture

var _color := Color.WHITE
var _target: Node2D


static func spawn(parent: Node, at: Vector2, glow: Color, target: Node2D = null) -> void:
	var burst: Node2D = load("res://game/ability_pickup/pickup_burst.gd").new()
	burst.set("_color", glow)
	burst.set("_target", target)
	burst.z_index = 10
	parent.add_child(burst)
	burst.global_position = at


func _ready() -> void:
	var additive := CanvasItemMaterial.new()
	additive.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = additive
	var tween := create_tween().set_parallel(true)
	# Destello: un halo blanco que se hincha y se apaga.
	var flash := _sprite(_get_halo_texture(), Color(1.4, 1.4, 1.4, 1.0), 0.6)
	tween.tween_property(flash, "scale", Vector2.ONE * 2.2, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Onda expansiva, de color.
	var ring := _sprite(_get_ring_texture(), Color(_color, 0.9), 0.15)
	tween.tween_property(ring, "scale", Vector2.ONE * 1.6, 0.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	# Ráfaga de partículas.
	var sparks := CPUParticles2D.new()
	sparks.amount = 22
	sparks.lifetime = 0.9
	sparks.one_shot = true
	sparks.explosiveness = 1.0
	sparks.spread = 180.0
	sparks.gravity = Vector2(0, -10)
	sparks.initial_velocity_min = 30.0
	sparks.initial_velocity_max = 90.0
	sparks.damping_min = 30.0
	sparks.damping_max = 60.0
	sparks.scale_amount_min = 1.0
	sparks.scale_amount_max = 2.2
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.3, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 1), Color(_color, 0.9), Color(_color, 0.0)])
	sparks.color_ramp = ramp
	sparks.use_parent_material = true
	add_child(sparks)
	sparks.emitting = true
	# Motas que vuelan hacia el jugador.
	for i in MOTES:
		_fly_mote(i)
	# Limpieza: tras el último vuelo y el último destello.
	var cleanup := create_tween()
	cleanup.tween_interval(1.2)
	cleanup.tween_callback(queue_free)


func _sprite(texture: Texture2D, tint: Color, start_scale: float) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.modulate = tint
	sprite.scale = Vector2.ONE * start_scale
	sprite.use_parent_material = true
	add_child(sprite)
	return sprite


func _fly_mote(index: int) -> void:
	var mote := _sprite(_get_dot_texture(), Color(_color, 1.0), 1.0)
	mote.scale = Vector2.ONE * (1.0 + float(index % 3) * 0.5)
	var angle := TAU * index / MOTES
	var start := Vector2.from_angle(angle) * (6.0 + float(index % 4) * 3.0)
	mote.position = start
	var delay := 0.08 + 0.03 * float(index % 6)
	var fly := create_tween()
	fly.tween_interval(delay)
	fly.tween_method(_move_mote.bind(mote, start, angle), 0.0, 1.0, FLY_TIME).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	fly.tween_callback(mote.queue_free)


## Va del punto de salida al jugador (que se mueve: se lee cada fotograma) con
## una curva lateral para que no sea una línea recta.
func _move_mote(t: float, mote: Sprite2D, start: Vector2, angle: float) -> void:
	if not is_instance_valid(mote):
		return
	var goal := Vector2.ZERO
	if _target != null and is_instance_valid(_target):
		goal = to_local(_target.global_position + Vector2(0, -14))
	var curve := Vector2.from_angle(angle + PI / 2.0) * sin(t * PI) * 10.0
	mote.position = start.lerp(goal, t) + curve
	mote.modulate.a = 1.0 - t * t * 0.6


static func _get_halo_texture() -> ImageTexture:
	if _halo_texture == null:
		var size := 96
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center := (size - 1) / 2.0
		for y in size:
			for x in size:
				var d := Vector2(x - center, y - center).length() / center
				var a := clampf(1.0 - d, 0.0, 1.0)
				image.set_pixel(x, y, Color(1, 1, 1, a * a))
		_halo_texture = ImageTexture.create_from_image(image)
	return _halo_texture


static func _get_ring_texture() -> ImageTexture:
	if _ring_texture == null:
		var size := 128
		var image := Image.create(size, size, false, Image.FORMAT_RGBA8)
		var center := (size - 1) / 2.0
		for y in size:
			for x in size:
				var d := Vector2(x - center, y - center).length() / center
				var a := clampf(1.0 - absf(d - 0.8) / 0.10, 0.0, 1.0)
				image.set_pixel(x, y, Color(1, 1, 1, a * a))
		_ring_texture = ImageTexture.create_from_image(image)
	return _ring_texture


static func _get_dot_texture() -> ImageTexture:
	if _dot_texture == null:
		var image := Image.create(2, 2, false, Image.FORMAT_RGBA8)
		image.fill(Color.WHITE)
		_dot_texture = ImageTexture.create_from_image(image)
	return _dot_texture
