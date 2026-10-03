extends Node2D
## Fondo animado del menú principal, dibujado por código (sin imágenes): cielo con
## estrellas que titilan y una luna, colinas y ruinas que se desplazan despacio, niebla,
## árboles muertos y brasas que suben. La capa de atrás va debajo de los personajes y la
## de delante (brasas y niebla) por encima, para dar profundidad.

enum Layer { BACK, FRONT }

@export var layer: Layer = Layer.BACK
## Tamaño de la pantalla (la resolución interna del juego).
@export var screen: Vector2 = Vector2(864, 486)
## Altura del suelo: lo que hay debajo lo tapan las baldosas.
@export var horizon: float = 392.0

var far_hills := PackedVector2Array([Vector2(-400, 360), Vector2(-400, 300), Vector2(-180, 240), Vector2(60, 270), Vector2(300, 210), Vector2(560, 260), Vector2(820, 200), Vector2(1080, 255), Vector2(1340, 215), Vector2(1600, 270), Vector2(1700, 300), Vector2(1700, 360)])
var mid_ruins := PackedVector2Array([Vector2(-400, 360), Vector2(-400, 320), Vector2(-300, 320), Vector2(-300, 260), Vector2(-260, 260), Vector2(-260, 320), Vector2(-150, 320), Vector2(-150, 280), Vector2(-120, 280), Vector2(-120, 230), Vector2(-90, 230), Vector2(-90, 320), Vector2(120, 320), Vector2(120, 300), Vector2(160, 300), Vector2(160, 340), Vector2(400, 340), Vector2(400, 280), Vector2(440, 280), Vector2(440, 240), Vector2(470, 240), Vector2(470, 320), Vector2(700, 320), Vector2(700, 300), Vector2(900, 300), Vector2(900, 250), Vector2(940, 250), Vector2(940, 300), Vector2(1150, 300), Vector2(1150, 330), Vector2(1400, 330), Vector2(1400, 300), Vector2(1450, 300), Vector2(1450, 320), Vector2(1700, 320), Vector2(1700, 360)])
const PERIOD := 2100.0

var _time: float = 0.0
var _stars: Array = []
var _embers: Array = []


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 80:
		_stars.append({ pos = Vector2(rng.randf() * screen.x, rng.randf() * (horizon - 120.0)), size = 1 + int(rng.randf() < 0.15), phase = rng.randf() * TAU, speed = 0.6 + rng.randf() * 1.6 })
	for i in 46:
		_embers.append({ x = rng.randf() * screen.x, y = rng.randf() * screen.y, speed = 8.0 + rng.randf() * 22.0, sway = rng.randf() * TAU, blue = rng.randf() < 0.3, size = 1 + int(rng.randf() < 0.3) })


func _process(delta: float) -> void:
	_time += delta
	for ember in _embers:
		ember.y -= ember.speed * delta
		if ember.y < -4.0:
			ember.y = screen.y + 4.0
			ember.x = randf() * screen.x
	queue_redraw()


func _draw() -> void:
	if layer == Layer.BACK:
		_draw_sky()
		_draw_moon()
		_draw_scrolling(far_hills, Color(0.161, 0.157, 0.184), 3.0, Vector2(0, 76))
		_draw_fog(0.5, Color(0.42, 0.46, 0.56, 0.10), 332.0, 6.0)
		_draw_scrolling(mid_ruins, Color(0.227, 0.216, 0.259), 7.0, Vector2(0, 66))
		_draw_fog(1.0, Color(0.42, 0.46, 0.56, 0.12), 360.0, 11.0)
		_draw_trees()
	else:
		_draw_fog(1.6, Color(0.5, 0.54, 0.64, 0.09), 408.0, 16.0)
		_draw_embers()
		_draw_vignette()


func _draw_sky() -> void:
	var points := PackedVector2Array([Vector2(0, 0), Vector2(screen.x, 0), Vector2(screen.x, horizon), Vector2(0, horizon)])
	var colors := PackedColorArray([Color(0.025, 0.03, 0.07), Color(0.025, 0.03, 0.07), Color(0.16, 0.17, 0.25), Color(0.16, 0.17, 0.25)])
	draw_polygon(points, colors)
	draw_rect(Rect2(0, horizon, screen.x, screen.y - horizon), Color(0.07, 0.07, 0.1))
	for star in _stars:
		var twinkle := 0.45 + 0.55 * (0.5 + 0.5 * sin(_time * star.speed + star.phase))
		draw_rect(Rect2(star.pos.floor(), Vector2(star.size, star.size)), Color(0.72, 0.8, 0.92, 0.7 * twinkle))


func _draw_moon() -> void:
	var c := Vector2(772, 138)
	for i in 5:
		draw_circle(c, 46.0 + 14.0 * (5 - i), Color(0.45, 0.6, 0.8, 0.025 + 0.005 * i))
	draw_circle(c, 46.0, Color(0.62, 0.74, 0.86))
	draw_circle(c + Vector2(-8, -6), 40.0, Color(0.7, 0.8, 0.9))
	for crater in [[Vector2(10, 8), 9.0], [Vector2(-14, 16), 6.0], [Vector2(18, -14), 5.0], [Vector2(-4, -20), 4.0]]:
		draw_circle(c + crater[0], crater[1], Color(0.52, 0.64, 0.78))
	# El borde en sombra, como si faltara un trozo: una luna incompleta.
	draw_circle(c + Vector2(26, -8), 40.0, Color(0.16, 0.17, 0.25, 0.55))


func _draw_scrolling(poly: PackedVector2Array, color: Color, speed: float, offset: Vector2) -> void:
	var shift := fmod(_time * speed, PERIOD)
	for copy in 2:
		var moved := PackedVector2Array()
		for p in poly:
			moved.append(p + offset + Vector2(-shift + copy * PERIOD - 300.0, 0.0))
		draw_colored_polygon(moved, color)


func _draw_fog(scale: float, color: Color, base_y: float, speed: float) -> void:
	var shift := fmod(_time * speed, 300.0)
	var points := PackedVector2Array()
	for x in range(-300, int(screen.x) + 301, 30):
		var wave := sin((x + shift) * 0.021 * scale + scale) * 9.0 + sin((x + shift) * 0.047 + scale * 2.0) * 4.0
		points.append(Vector2(x - shift, base_y + wave))
	points.append(Vector2(screen.x + 300.0, screen.y))
	points.append(Vector2(-300.0, screen.y))
	draw_colored_polygon(points, color)


## Árboles muertos a los lados, en silueta.
func _draw_trees() -> void:
	var color := Color(0.105, 0.1, 0.125)
	for tree in [[70.0, 190.0], [790.0, 170.0], [20.0, 120.0]]:
		var x: float = tree[0]
		var h: float = tree[1]
		var base := Vector2(x, horizon + 6.0)
		draw_line(base, base + Vector2(0, -h), color, 9.0)
		draw_line(base + Vector2(0, -h * 0.55), base + Vector2(-34, -h * 0.85), color, 5.0)
		draw_line(base + Vector2(0, -h * 0.7), base + Vector2(38, -h * 1.0), color, 5.0)
		draw_line(base + Vector2(0, -h), base + Vector2(-14, -h - 28.0), color, 4.0)
		draw_line(base + Vector2(0, -h), base + Vector2(16, -h - 22.0), color, 4.0)
		draw_line(base + Vector2(38, -h * 1.0), base + Vector2(58, -h * 1.0 - 18.0), color, 3.0)
		draw_line(base + Vector2(-34, -h * 0.85), base + Vector2(-54, -h * 0.85 - 16.0), color, 3.0)


func _draw_embers() -> void:
	for ember in _embers:
		var x: float = ember.x + sin(_time * 0.8 + ember.sway) * 8.0
		var flicker := 0.5 + 0.5 * sin(_time * 3.0 + ember.sway * 3.0)
		var color := Color(0.66, 0.89, 0.95, 0.55 * flicker + 0.15) if ember.blue else Color(0.95, 0.67, 0.25, 0.6 * flicker + 0.15)
		draw_rect(Rect2(Vector2(floorf(x), floorf(ember.y)), Vector2(ember.size, ember.size)), color)


## Bordes oscurecidos para centrar la mirada.
func _draw_vignette() -> void:
	var dark := Color(0.02, 0.02, 0.04, 0.0)
	var edge := Color(0.02, 0.02, 0.04, 0.7)
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(150, 0), Vector2(150, screen.y), Vector2(0, screen.y)]), PackedColorArray([edge, dark, dark, edge]))
	draw_polygon(PackedVector2Array([Vector2(screen.x - 150, 0), Vector2(screen.x, 0), Vector2(screen.x, screen.y), Vector2(screen.x - 150, screen.y)]), PackedColorArray([dark, edge, edge, dark]))
	draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(screen.x, 0), Vector2(screen.x, 90), Vector2(0, 90)]), PackedColorArray([edge, edge, dark, dark]))
