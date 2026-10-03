extends Node2D
## Marca el punto donde perdiste tus Ecos (o tu última posición en suelo, si
## moriste cayendo). No es hostil: se recoge acercándose y pulsando la acción de
## interactuar (Z, o Y / Triángulo en el mando; el icono aparece encima). Si
## mueres otra vez antes de recogerlo, Player.die() lo borra sin más y se
## pierden para siempre.

@export var ecos_held: int = 0
## Segundos tras aparecer durante los que ignora al jugador. El motor de
## físicas tarda un paso en reflejar que el jugador ya reapareció lejos; sin
## este margen lo "vería" aún en su posición antigua y se podría recoger al instante.
@export var arm_delay: float = 0.3

@onready var pickup_area: Area2D = $PickupArea
@onready var visual: Sprite2D = $Visual
@onready var prompt: CanvasItem = $Prompt

## Jugadores al alcance ahora mismo.
var _in_range: Array[Node] = []


func _ready() -> void:
	pickup_area.monitoring = false
	pickup_area.body_entered.connect(_on_body_entered)
	pickup_area.body_exited.connect(_on_body_exited)
	prompt.visible = false
	get_tree().create_timer(arm_delay).timeout.connect(_arm)
	_start_hover()


## El recuerdo flota y respira: sube y baja despacio y su brillo late. Un solo
## Tween en bucle (muere con el nodo), sin trabajo por frame.
func _start_hover() -> void:
	var hover := create_tween().set_loops()
	hover.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	hover.tween_property(visual, "position:y", visual.position.y - 3.0, 1.1)
	hover.tween_property(visual, "position:y", visual.position.y, 1.1)
	var glow := create_tween().set_loops()
	glow.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	glow.tween_property(visual, "modulate:a", 0.6, 0.9)
	glow.tween_property(visual, "modulate:a", 0.95, 0.9)


func _arm() -> void:
	pickup_area.monitoring = true


func _physics_process(_delta: float) -> void:
	if _in_range.is_empty() or not Input.is_action_just_pressed(&"interact"):
		return
	_collect(_in_range[0])


func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		_in_range.append(body)
		prompt.visible = true


func _on_body_exited(body: Node) -> void:
	_in_range.erase(body)
	prompt.visible = not _in_range.is_empty()


func _collect(body: Node) -> void:
	Sfx.play(&"echo_collect", null, -7.0)
	body.add_ecos(ecos_held)
	if body.active_echo == self:
		body.active_echo = null
	queue_free()
