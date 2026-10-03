extends AbilityPickup
## Reliquia de habilidad: un recuerdo cristalizado que flota. Elige su dibujo
## (fila de la hoja) y el color de su luz según `ability_id`, que `room.gd`
## asigna antes de añadirlo al árbol, por eso se lee en `_ready`. Al recogerlo,
## el efecto lo hace un nodo suelto (`PickupBurst`) para que el objeto se libere
## enseguida.

const PickupBurst := preload("res://game/ability_pickup/pickup_burst.gd")

const LOOKS := {
	&"dash": {"animation": "dash", "color": Color(0.45, 0.8, 1.0)},
	&"double_jump": {"animation": "double_jump", "color": Color(0.6, 0.9, 1.0)},
	&"wall_jump": {"animation": "wall_jump", "color": Color(0.9, 0.8, 0.35)},
}
const DEFAULT_LOOK := &"dash"

@onready var _visuals: Node2D = $Visuals
@onready var _halo: Sprite2D = $Visuals/Halo
@onready var _pool: Sprite2D = $Visuals/Pool
@onready var _motes: CPUParticles2D = $Visuals/Motes
@onready var _animator: SheetAnimator = $Visuals/SheetAnimator

var _color := Color.WHITE


func _ready() -> void:
	super._ready()
	var look: Dictionary = LOOKS.get(ability_id, LOOKS[DEFAULT_LOOK])
	_color = look["color"]
	_animator.play(look["animation"])
	_halo.self_modulate = Color(_color, 0.5)
	_pool.self_modulate = Color(_color, 0.35)
	_motes.color = _color
	collected.connect(_on_collected)
	_start_float()


## Vaivén suave y latido del halo. Cada reliquia empieza en un punto distinto.
func _start_float() -> void:
	var bob := create_tween().set_loops()
	bob.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	bob.tween_property(_visuals, "position:y", -4.0, 1.3)
	bob.tween_property(_visuals, "position:y", 2.0, 1.3)
	bob.custom_step(randf() * 2.6)
	var pulse := create_tween().set_loops()
	pulse.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(_halo, "self_modulate:a", 0.75, 0.9)
	pulse.parallel().tween_property(_halo, "scale", Vector2(1.0, 1.0), 0.9)
	pulse.tween_property(_halo, "self_modulate:a", 0.4, 1.1)
	pulse.parallel().tween_property(_halo, "scale", Vector2(0.85, 0.85), 1.1)
	pulse.custom_step(randf() * 2.0)


func _on_collected(body: Node) -> void:
	var parent := get_parent()
	if parent == null:
		return
	PickupBurst.spawn(parent, global_position + _visuals.position, _color, body as Node2D)
