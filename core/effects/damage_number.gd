class_name DamageNumber
extends Node2D
## Número de daño flotante: aparece con un pequeño salto, sube mientras se
## desvanece y se autodestruye. Uso: `DamageNumber.spawn(parent, posición_global,
## cantidad)`. Es solo presentación; quien hace el daño lo pide.

@export var amount: int = 1
@export var color: Color = Color(1.0, 0.97, 0.9)
@export var font_size: int = 16
@export var rise: float = 26.0
@export var duration: float = 0.7


static func spawn(parent: Node, at: Vector2, damage: int, text_color: Color = Color(1.0, 0.97, 0.9)) -> void:
	var number := DamageNumber.new()
	number.amount = damage
	number.color = text_color
	# Los golpes fuertes se ven más grandes.
	number.font_size = 16 + 3 * mini(damage - 1, 3)
	parent.add_child(number)
	number.global_position = at


func _ready() -> void:
	z_index = 20
	# Un desvío lateral pequeño y distinto cada vez, para que varios números seguidos no se tapen.
	var drift := randf_range(-10.0, 10.0)
	scale = Vector2(0.6, 0.6)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", Vector2(drift, -rise), duration).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, duration * 0.45).set_delay(duration * 0.55)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	var text := str(amount)
	var size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
	var origin := Vector2(-size.x / 2.0, size.y / 4.0)
	draw_string_outline(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, 4, Color(0.05, 0.03, 0.04, 0.95))
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)
