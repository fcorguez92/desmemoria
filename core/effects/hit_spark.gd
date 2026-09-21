class_name HitSpark
extends Node2D
## Chispazo breve de impacto: unas líneas que salen disparadas y se desvanecen.
## Se autodestruye. Uso: `HitSpark.spawn(parent, posición_global)`.

@export var color: Color = Color(1.0, 0.95, 0.7)
@export var rays: int = 6
@export var inner_radius: float = 6.0
@export var length: float = 20.0
@export var duration: float = 0.18


static func spawn(parent: Node, at: Vector2, spark_color: Color = Color(1.0, 0.95, 0.7)) -> void:
	var spark := HitSpark.new()
	parent.add_child(spark)
	spark.color = spark_color
	spark.global_position = at


func _ready() -> void:
	z_index = 10
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.6, 1.6), duration)
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	for i in rays:
		var direction := Vector2.from_angle(TAU * i / rays + 0.3)
		draw_line(direction * inner_radius, direction * length, color, 3.0)
