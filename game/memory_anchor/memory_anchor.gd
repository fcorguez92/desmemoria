extends Checkpoint
## El Ancla de Memoria: un Checkpoint con presencia. En reposo su halo respira
## despacio; al descansar (señal `activated`) la luz se dispara, sale una onda
## expansiva circular y una ráfaga de motas. Todo con Tweens y sin audio.
##
## Los nodos de luz son hijos de `Visuals` en la escena; este script solo los
## anima y se las apaña si falta alguno.

const RING_SIZE := 128
const HALO_BASE_SCALE := 1.25

static var _ring_texture: ImageTexture

@onready var _halo: Sprite2D = get_node_or_null("Visuals/Halo")
@onready var _pool: Sprite2D = get_node_or_null("Visuals/Pool")
@onready var _crystal: Sprite2D = get_node_or_null("Visuals/Sprite")
@onready var _burst: CPUParticles2D = get_node_or_null("Visuals/Burst")
@onready var _visuals: Node2D = get_node_or_null("Visuals")

var _breath: Tween
var _flash: Tween


func _ready() -> void:
	super._ready()
	activated.connect(_on_activated)
	_start_breathing()


## Respiración lenta de la luz de reposo. Va sobre `self_modulate` para no
## chocar con el destello, que usa `modulate`.
func _start_breathing() -> void:
	if _halo == null:
		return
	_breath = create_tween().set_loops()
	_breath.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_breath.tween_property(_halo, "self_modulate:a", 0.6, 1.7)
	if _pool:
		_breath.parallel().tween_property(_pool, "self_modulate:a", 0.6, 1.7)
	_breath.tween_property(_halo, "self_modulate:a", 0.38, 1.9)
	if _pool:
		_breath.parallel().tween_property(_pool, "self_modulate:a", 0.32, 1.9)
	# Cada ancla empieza en un punto distinto de la respiración.
	_breath.custom_step(randf() * 3.0)


func _on_activated() -> void:
	Sfx.play(&"anchor_rest", global_position, -5.0)
	if _flash and _flash.is_valid():
		_flash.kill()
	_flash = create_tween().set_parallel(true)
	if _halo:
		_halo.modulate = Color(1.7, 1.5, 1.2, 1.7)
		_halo.scale = Vector2.ONE * HALO_BASE_SCALE * 1.45
		_flash.tween_property(_halo, "modulate", Color.WHITE, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		_flash.tween_property(_halo, "scale", Vector2.ONE * HALO_BASE_SCALE, 1.6).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	if _pool:
		_pool.modulate = Color(1.8, 1.5, 1.1, 1.8)
		_flash.tween_property(_pool, "modulate", Color.WHITE, 1.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _crystal:
		_crystal.modulate = Color(1.6, 1.45, 1.2, 1.0)
		_flash.tween_property(_crystal, "modulate", Color.WHITE, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	if _burst:
		_burst.restart()
		_burst.emitting = true
	_spawn_ring()


## Onda expansiva: un anillo suave que crece y se desvanece. Se crea al vuelo y
## se borra al terminar, así en reposo no cuesta ningún nodo.
func _spawn_ring() -> void:
	if _visuals == null:
		return
	var ring := Sprite2D.new()
	ring.texture = _get_ring_texture()
	ring.material = _additive_material()
	ring.position = Vector2(0, -34)
	ring.scale = Vector2.ONE * 0.15
	ring.modulate = Color(1.0, 0.85, 0.6, 0.75)
	_visuals.add_child(ring)
	var tween := ring.create_tween().set_parallel(true)
	tween.tween_property(ring, "scale", Vector2.ONE * 2.2, 0.9).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tween.tween_property(ring, "modulate:a", 0.0, 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.chain().tween_callback(ring.queue_free)


static func _additive_material() -> CanvasItemMaterial:
	var material := CanvasItemMaterial.new()
	material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return material


## Textura del anillo, generada una vez para todas las anclas: un aro de brillo
## máximo en el 80 % del radio que se funde por dentro y por fuera.
static func _get_ring_texture() -> ImageTexture:
	if _ring_texture == null:
		var image := Image.create(RING_SIZE, RING_SIZE, false, Image.FORMAT_RGBA8)
		var center := (RING_SIZE - 1) / 2.0
		for y in RING_SIZE:
			for x in RING_SIZE:
				var d := Vector2(x - center, y - center).length() / center
				var a := clampf(1.0 - absf(d - 0.8) / 0.10, 0.0, 1.0)
				image.set_pixel(x, y, Color(0.95, 0.8, 0.55, a * a))
		_ring_texture = ImageTexture.create_from_image(image)
	return _ring_texture
