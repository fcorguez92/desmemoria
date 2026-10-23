extends Area2D
## Coleccionable `!` del mundo: un fragmento de vida, una Bolsa de Rastro o un objeto.
## Tiene un `id` estable (lo pone la sala, ver room.gd) con el que el mundo recuerda
## que ya se recogió. No sabe qué hace cada tipo: solo avisa con `collected` y el
## mundo cuenta, guarda y notifica. Se recoge al tocarlo.

## Se emite al recogerlo, antes de liberarse.
signal collected(pickup: Area2D)

## Color provisional de cada tipo (el dibujo definitivo llegará con el arte).
const COLORS := {
	&"fragment": Color(0.85, 0.35, 0.4),
	&"bag": Color(0.9, 0.75, 0.35),
	&"item": Color(0.6, 0.85, 0.9),
}

## Identificador estable `sala.cXXfYY`; lo asigna la sala antes de añadirlo al árbol.
@export var id: StringName
## `fragment`, `bag` o `item`.
@export var kind: StringName = &"fragment"

var _time: float = 0.0


func _ready() -> void:
	add_to_group(&"collectible")
	collision_layer = 0
	collision_mask = 1  # La capa del jugador.
	var shape := CollisionShape2D.new()
	var rectangle := RectangleShape2D.new()
	rectangle.size = Vector2(20.0, 20.0)
	shape.shape = rectangle
	add_child(shape)
	body_entered.connect(_on_body_entered)


func _process(delta: float) -> void:
	_time += delta
	queue_redraw()


func _draw() -> void:
	var color: Color = COLORS.get(kind, Color.WHITE)
	var bob := sin(_time * 2.4) * 2.0
	draw_circle(Vector2(0.0, bob), 9.0, Color(color, 0.25 + 0.1 * sin(_time * 3.0)))
	var points := PackedVector2Array([Vector2(0, -6 + bob), Vector2(5, bob), Vector2(0, 6 + bob), Vector2(-5, bob)])
	draw_colored_polygon(points, color)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(&"player"):
		collected.emit(self)
		queue_free()
