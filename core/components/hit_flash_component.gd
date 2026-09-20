class_name HitFlashComponent
extends Node
## Parpadeo de color breve al recibir un golpe, sobre cualquier CanvasItem.

@export var target: CanvasItem
@export var flash_color: Color = Color(1.0, 0.4, 0.4)
@export var duration: float = 0.1

var _timer: Timer


func _ready() -> void:
	_timer = Timer.new()
	_timer.one_shot = true
	_timer.timeout.connect(_on_timeout)
	add_child(_timer)


## Un nuevo flash mientras hay otro en curso reinicia el temporizador.
func flash() -> void:
	target.modulate = flash_color
	_timer.start(duration)


func _on_timeout() -> void:
	target.modulate = Color.WHITE
