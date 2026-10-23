class_name Gate
extends Node2D
## Compuerta: una pieza (una o varias celdas) que cierra o abre un paso. Cerrada,
## bloquea; abierta, no. Baja desde arriba al cerrarse, como un rastrillo, para que
## se vea y se oiga que se ha cerrado.
##
## Dos formas de usarla:
## - A mano: quien la tiene llama a `set_closed()` (las rejas de una sala de jefe).
## - Por marcas: con `requires` (ids de FlagStore) se abre sola cuando **todas** están
##   puestas ("Y"); con `inverted`, al revés: se cierra cuando lo están. Reacciona al
##   cambiar las marcas, también al descansar o morir (las temporales se borran). Si
##   al cerrarse hay alguien dentro (cuerpos de `blockers`), **espera a que salga**:
##   nunca se cierra encima del jugador.
##
## La escena debe tener `StaticBody2D/CollisionShape2D` (la celda de colisión) y
## `Bars` (el dibujo de la celda); para una pieza de varias celdas se duplican en
## cada posición de `cells`. El estado inicial de una compuerta con marcas se pone
## sin animación (y sin sonido) al encontrar el almacén.

## Cambia entre cerrada y abierta (también en la animación a mano).
signal closed_changed(closed: bool)

## Marcas que la abren. Vacío = no lee marcas (se maneja con `set_closed`).
@export var requires: Array[StringName] = []
## Si es true, se cierra cuando se cumplen `requires` (y se abre si no).
@export var inverted: bool = false
## Centros de sus celdas relativos al nodo (píxeles). Una celda en el origen por defecto.
@export var cells: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
## Lado de cada celda, para comprobar si hay alguien dentro al cerrarse.
@export var cell_size: float = 16.0
## Grupos cuyos cuerpos impiden que se cierre mientras están dentro.
@export var blockers: Array[StringName] = [&"player", &"enemy"]
## Sonidos al abrirse y cerrarse por marcas (ver core/audio/sfx.gd); vacío = ninguno.
@export var open_sound: StringName = &"gate_open"
@export var close_sound: StringName = &"gate_close"
@export var sound_volume_db: float = -2.0
## Cuánto baja el dibujo al cerrarse (px) y lo que dura la animación (s).
@export var slide: float = 96.0
@export var slide_time: float = 0.45

var closed: bool = false

var _bars: Array[Node2D] = []
var _shapes: Array[CollisionShape2D] = []
var _tween: Tween
var _store: FlagStore
## Hay que recalcular si debe estar cerrada (cambió una marca, o no se pudo cerrar).
var _dirty: bool = true
var _evaluated_once: bool = false


func _ready() -> void:
	var template_shape: CollisionShape2D = $StaticBody2D/CollisionShape2D
	var template_bars: Node2D = $Bars
	var offsets: Array = Array(cells) if not cells.is_empty() else [Vector2.ZERO]
	for i in offsets.size():
		var shape := template_shape if i == 0 else template_shape.duplicate() as CollisionShape2D
		var bars := template_bars if i == 0 else template_bars.duplicate() as Node2D
		shape.position = offsets[i]
		bars.position = offsets[i]
		if i > 0:
			template_shape.get_parent().add_child(shape)
			add_child(bars)
		_shapes.append(shape)
		_bars.append(bars)
	set_closed(not requires.is_empty(), false)


func _physics_process(_delta: float) -> void:
	if requires.is_empty():
		return
	if _store == null:
		_store = FlagStore.find(self)
		if _store == null:
			return
		_store.changed.connect(_on_flag_changed)
		_dirty = true
	if _dirty:
		_evaluate()


## Cierra o abre ya, sin mirar las marcas ni si hay alguien dentro. `delay`: espera
## antes de moverse (para que las celdas de una reja caigan escalonadas).
func set_closed(value: bool, animate: bool = true, delay: float = 0.0) -> void:
	var changed := closed != value
	closed = value
	for shape in _shapes:
		shape.set_deferred("disabled", not value)
	if _tween:
		_tween.kill()
	if not animate:
		for bars in _bars:
			bars.visible = value
			bars.position.y = _rest_y(bars)
	else:
		_tween = create_tween().set_parallel()
		for i in _bars.size():
			var bars := _bars[i]
			var rest := _rest_y(bars)
			bars.visible = true
			var step := delay + 0.015 * i
			if value:
				bars.position.y = rest - slide
				_tween.tween_property(bars, "position:y", rest, slide_time).set_delay(step).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
			else:
				_tween.tween_property(bars, "position:y", rest - slide, slide_time).set_delay(step).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
		if not value:
			_tween.chain().tween_callback(func() -> void:
				for bars in _bars:
					bars.visible = false
					bars.position.y = _rest_y(bars))
	if changed:
		closed_changed.emit(value)


## Si, según sus marcas, debería estar cerrada ahora mismo.
func wants_closed() -> bool:
	if requires.is_empty() or _store == null:
		return closed
	var satisfied := true
	for id in requires:
		if not _store.get_flag(id, false):
			satisfied = false
			break
	return satisfied == inverted


## Si hay alguien de `blockers` dentro de alguna celda.
func is_blocked() -> bool:
	if not is_inside_tree():
		return false
	var space := get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE * (cell_size - 2.0)  # sin rozar las baldosas de al lado
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	for offset in cells:
		query.transform = Transform2D(0.0, to_global(offset))
		for hit in space.intersect_shape(query, 16):
			var collider := hit.get("collider") as Node
			if collider == null:
				continue
			for group in blockers:
				if collider.is_in_group(group):
					return true
	return false


func _evaluate() -> void:
	var want := wants_closed()
	var animate := _evaluated_once
	if want == closed:
		_dirty = false
		_evaluated_once = true
		return
	if want and animate and is_blocked():
		return  # sigue pendiente (_dirty): se cierra en cuanto salga
	_dirty = false
	_evaluated_once = true
	set_closed(want, animate)
	if animate:
		var sound := close_sound if want else open_sound
		if sound != &"":
			Sfx.play(sound, global_position, sound_volume_db)


func _on_flag_changed(id: StringName) -> void:
	if id in requires:
		_dirty = true


func _rest_y(bars: Node2D) -> float:
	return cells[_bars.find(bars)].y if not cells.is_empty() else 0.0
