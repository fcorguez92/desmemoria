class_name Cycle
extends Node2D
## Ciclo (ritmos y mareas): una pieza de una o varias celdas que alterna entre
## **presente y sólida** y **ausente**, con un periodo fijo. Sirve para suelo de
## tinta, puentes de luz, mareas o ventanas que se abren y se cierran.
##
## Es determinista: su reloj (`time`) avanza solo con el tiempo de física del nodo
## (pausa y cámara lenta incluidas) y arranca en `phase * period`, así que dos piezas
## con el mismo periodo y fase van a la vez y con fases distintas hacen una ola.
## No es aleatorio y no guarda nada.
##
## Cada periodo, durante `on_fraction` está presente (`ON`) y el resto ausente (`OFF`).
## **Avisa `warning_time` antes de cada cambio**, con el mismo gesto: la pieza
## parpadea entre dos fotogramas (`blink_rate` cambios por segundo). Antes de
## desaparecer sigue sólida mientras parpadea (`WARNING_OFF`); antes de aparecer es
## todavía un fantasma sin colisión que parpadea (`WARNING_ON`).
##
## Nunca atrapa ni aplasta: quien está encima no estorba (la pieza solo cae bajo sus
## pies al desaparecer) y, si al volver a ser sólida hay alguien de `blockers` dentro
## de una celda, **espera a que salga**, como la Gate.
##
## Opcionalmente (`flag_id`) escribe una marca de FlagStore mientras es sólida, para
## que otras cosas la lean. Úsese un id temporal (`t:`): no tiene sentido guardarla.

enum State { ON, WARNING_OFF, OFF, WARNING_ON }

## Cambia el estado del ciclo (para dibujo y sonido).
signal state_changed(state: State)
## Cambia entre sólida y no sólida.
signal solid_changed(solid: bool)

## Segundos de un ciclo completo.
@export_range(0.2, 120.0, 0.1, "or_greater") var period: float = 4.0
## Fracción del ciclo en la que está presente y sólida.
@export_range(0.05, 0.95) var on_fraction: float = 0.75
## Desfase, en fracción del ciclo.
@export_range(0.0, 1.0) var phase: float = 0.0
## Segundos de aviso antes de cada cambio (se recorta para caber en el ciclo).
@export var warning_time: float = 0.4
## Cambios de fotograma por segundo del parpadeo de aviso.
@export var blink_rate: float = 12.0
## Centros de sus celdas relativos al nodo (píxeles).
@export var cells: PackedVector2Array = PackedVector2Array([Vector2.ZERO])
@export var cell_size: float = 16.0
## Grupos cuyos cuerpos impiden que se haga sólida mientras están dentro.
@export var blockers: Array[StringName] = [&"player", &"enemy"]
## Marca que escribe mientras es sólida (vacío = ninguna).
@export var flag_id: StringName = &""
@export var body_color: Color = Color(0.1, 0.09, 0.16)
@export var edge_color: Color = Color(0.46, 0.42, 0.62)

var state: State = State.ON
## Reloj del ciclo, en segundos.
var time: float = 0.0

var _body: StaticBody2D
var _shapes: Array[CollisionShape2D] = []
var _solid: bool = false
var _store: FlagStore


func _ready() -> void:
	_body = StaticBody2D.new()
	add_child(_body)
	for offset in cells:
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2.ONE * cell_size
		shape.shape = rect
		shape.position = offset
		shape.disabled = true
		_body.add_child(shape)
		_shapes.append(shape)
	time = phase * period
	state = state_at(time)
	_set_solid(_wants_solid(state), false)
	_update_look()


func _physics_process(delta: float) -> void:
	time += delta
	var new_state := state_at(time)
	if new_state != state:
		state = new_state
		state_changed.emit(state)
	var want := _wants_solid(state)
	if want != _solid and (not want or not is_blocked()):
		_set_solid(want, true)
	_update_look()


## El estado que le toca en el instante `at` del reloj (función pura, sin efectos).
func state_at(at: float) -> State:
	var t := fposmod(at, period)
	var on_time := period * on_fraction
	var warn := minf(warning_time, minf(on_time, period - on_time) * 0.5)
	if t < on_time - warn:
		return State.ON
	if t < on_time:
		return State.WARNING_OFF
	if t < period - warn:
		return State.OFF
	return State.WARNING_ON


## Si ahora mismo se puede pisar (colisión activa).
func is_solid() -> bool:
	return _solid


## Opacidad con la que se dibuja ahora (el parpadeo de aviso alterna dos valores).
func visual_alpha() -> float:
	var frame := int(floorf(time * blink_rate)) % 2 == 0
	match state:
		State.ON:
			return 1.0 if _solid else 0.4  # le toca estar, pero hay alguien dentro
		State.WARNING_OFF:
			return 1.0 if frame else 0.35
		State.WARNING_ON:
			return 0.5 if frame else 0.12
	return 0.0


## Si hay alguien de `blockers` dentro de alguna celda.
func is_blocked() -> bool:
	if not is_inside_tree():
		return false
	var space := get_world_2d().direct_space_state
	var shape := RectangleShape2D.new()
	shape.size = Vector2.ONE * (cell_size - 2.0)
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


func _wants_solid(of_state: State) -> bool:
	return of_state == State.ON or of_state == State.WARNING_OFF


func _set_solid(value: bool, notify: bool) -> void:
	_solid = value
	for shape in _shapes:
		shape.set_deferred("disabled", not value)
	if flag_id != &"":
		if _store == null:
			_store = FlagStore.find(self)
		if _store != null:
			if value:
				_store.set_flag(flag_id)
			else:
				_store.clear_flag(flag_id)
	if notify:
		solid_changed.emit(value)


func _update_look() -> void:
	var alpha := visual_alpha()
	visible = alpha > 0.0
	modulate.a = alpha


func _draw() -> void:
	for offset in cells:
		var rect := Rect2(offset - Vector2.ONE * cell_size / 2.0, Vector2.ONE * cell_size)
		draw_rect(rect, body_color)
		draw_rect(Rect2(rect.position, Vector2(cell_size, 2.0)), edge_color)
		draw_rect(rect.grow(-1.0), edge_color, false, 1.0)
