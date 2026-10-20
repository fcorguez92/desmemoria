extends Node2D
## Una celda de reja de una sala de jefe: cerrada, bloquea el paso; abierta, no.
## La sala (boss_room.gd) las cierra al empezar la pelea y las abre al ganarla
## (o al reiniciarse, si el jugador muere). Al cerrarse baja desde arriba, como un
## rastrillo, para que se vea y se oiga que la sala se ha cerrado.

## Cuánto bajan las barras al cerrarse (px): el hueco de una puerta de 6 baldosas.
const SLIDE := 96.0
const SLIDE_TIME := 0.45

var closed: bool = false

var _tween: Tween

@onready var _body: StaticBody2D = $StaticBody2D
@onready var _bars: Node2D = $Bars


func _ready() -> void:
	set_closed(false, false)


## `delay`: espera antes de moverse (para que las celdas de una reja caigan escalonadas).
func set_closed(value: bool, animate: bool = true, delay: float = 0.0) -> void:
	closed = value
	_body.get_node("CollisionShape2D").set_deferred("disabled", not value)
	if _tween:
		_tween.kill()
	if not animate:
		_bars.visible = value
		_bars.position.y = 0.0
		return
	_bars.visible = true
	_tween = create_tween()
	if value:
		_bars.position.y = -SLIDE
		_tween.tween_interval(delay)
		_tween.tween_property(_bars, "position:y", 0.0, SLIDE_TIME).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	else:
		_tween.tween_interval(delay)
		_tween.tween_property(_bars, "position:y", -SLIDE, SLIDE_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		_tween.tween_callback(func() -> void:
			_bars.visible = false
			_bars.position.y = 0.0)
