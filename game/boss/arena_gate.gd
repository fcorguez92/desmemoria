extends Node2D
## Una celda de reja de una sala de jefe: cerrada, bloquea el paso; abierta, no.
## La sala (boss_room.gd) las cierra al empezar la pelea y las abre al ganarla
## (o al reiniciarse, si el jugador muere).

@onready var _body: StaticBody2D = $StaticBody2D
@onready var _bars: Node2D = $Bars

var closed: bool = false

var _tween: Tween


func _ready() -> void:
	set_closed(false, false)


func set_closed(value: bool, animate: bool = true) -> void:
	closed = value
	_body.get_node("CollisionShape2D").set_deferred("disabled", not value)
	if not animate:
		_bars.visible = value
		_bars.modulate.a = 1.0
		return
	if _tween:
		_tween.kill()
	_bars.visible = true
	_tween = create_tween()
	_tween.tween_property(_bars, "modulate:a", 1.0 if value else 0.0, 0.35)
	if not value:
		_tween.tween_callback(func() -> void: _bars.visible = false)
