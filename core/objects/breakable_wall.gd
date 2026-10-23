class_name BreakableWall
extends StaticBody2D
## Muro (o suelo) frágil: una pieza sólida de una o varias celdas que se rompe a
## golpes (`hits`, 3 por defecto; con menos golpes solo se agrieta más). Implementa el
## contrato "golpeable" (`take_hit`). Al romperse desaparece entera en `fade_time`
## segundos, sin colisión desde el primer momento, y **no vuelve**: escribe su marca
## (`flag_id`) en el FlagStore y, al cargar una partida con la marca puesta, ya no
## aparece. Que la marca sea permanente o temporal (`t:`) la decide el prefijo del id.
##
## A diferencia de BreakableProp, es sólido: está en la capa de física 1 ("mundo"),
## que el ataque del jugador también alcanza. Se dibuja solo: un bloque por celda con
## grietas en zigzag que se alargan con cada golpe. Los colores son exports para que
## el juego los ajuste a su paleta.

## Se rompe del todo.
signal broken
## Recibe un golpe sin romperse; `remaining` son los que le quedan.
signal cracked(remaining: int)

@export var hits: int = 3
## Marca que escribe al romperse: `prefijo:sala.objeto`. Vacío = no recuerda nada.
@export var flag_id: StringName = &""
## Centros de sus celdas relativos al nodo (píxeles).
@export var cells: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
@export var cell_size: float = 16.0
@export var body_color: Color = Color(0.3, 0.29, 0.34)
@export var edge_color: Color = Color(0.17, 0.16, 0.2)
@export var crack_color: Color = Color(0.86, 0.84, 0.8)
@export var spark_color: Color = Color(0.8, 0.78, 0.74)
## Sonidos al recibir un golpe y al romperse (ver core/audio/sfx.gd); vacío = ninguno.
@export var hit_sound: StringName = &"shard_hit"
@export var break_sound: StringName = &"rock_break"
@export var sound_volume_db: float = -6.0
@export var fade_time: float = 0.4

var remaining_hits: int
var is_broken: bool = false

var _store: FlagStore


func _ready() -> void:
	remaining_hits = hits
	for offset in cells:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2.ONE * cell_size
		shape.shape = rect
		shape.position = offset
		add_child(shape)
	_bind.call_deferred()


func _physics_process(_delta: float) -> void:
	if _store == null:
		_bind()


## Contrato "golpeable".
func take_hit(_damage: int, _from_direction: int, _attacker: Node = null) -> void:
	if is_broken:
		return
	remaining_hits -= 1
	if remaining_hits <= 0:
		_break(true)
		return
	if hit_sound != &"":
		Sfx.play(hit_sound, global_position, sound_volume_db)
	HitSpark.spawn(get_parent(), global_position, spark_color, 0.6)
	queue_redraw()
	cracked.emit(remaining_hits)


func _bind() -> void:
	if _store != null or is_broken or flag_id == &"":
		return
	_store = FlagStore.find(self)
	if _store == null:
		return
	if _store.has_flag(flag_id):
		_break(false)  # ya estaba rota en la partida guardada


func _break(announce: bool) -> void:
	is_broken = true
	for child in get_children():
		if child is CollisionShape2D:
			child.set_deferred("disabled", true)
	if announce:
		_bind()  # por si aún no tenía el almacén
		if _store != null and flag_id != &"":
			_store.set_flag(flag_id)
		if break_sound != &"":
			Sfx.play(break_sound, global_position, sound_volume_db)
		for offset in cells:
			HitSpark.spawn(get_parent(), to_global(offset), spark_color)
	broken.emit()
	if announce and fade_time > 0.0:
		var tween := create_tween()
		tween.tween_property(self, "modulate:a", 0.0, fade_time)
		tween.tween_callback(queue_free)
	else:
		queue_free()


func _draw() -> void:
	var damage := clampi(hits - remaining_hits, 0, 3)
	var half := cell_size / 2.0
	for offset in cells:
		var rect := Rect2(offset - Vector2.ONE * half, Vector2.ONE * cell_size)
		draw_rect(rect, body_color)
		draw_rect(rect, edge_color, false, 1.0)
		# Grieta en zigzag: corta de entrada y más larga con cada golpe.
		var steps := 2 + damage * 2
		var points := PackedVector2Array()
		for i in steps + 1:
			var t := float(i) / float(steps)
			points.append(offset + Vector2((-half + 2.0 + (cell_size - 4.0) * t) * 0.6 + 2.0 * (i % 2) - 1.0, -half + 1.0 + (cell_size - 2.0) * t))
		draw_polyline(points, crack_color, 1.0)
