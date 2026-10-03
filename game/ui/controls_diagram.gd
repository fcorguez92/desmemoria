extends Control
## Esquema de controles: un dibujo del teclado o del mando (Xbox, PlayStation o Nintendo)
## con cada botón que se usa señalado y lo que hace. Arriba, pestañas para cambiar de
## dispositivo con izquierda y derecha; empieza en el que se esté usando.
##
## Los botones del mando van por posición (abajo, derecha, izquierda, arriba), así que
## los mismos cuatro botones llevan el aspecto que toca en cada mando (ver InputGlyphs).
## El dibujo es solo presentación: los textos se corresponden con el Mapa de entrada
## del proyecto (project.godot, sección [input]).

const TAB_NAMES := ["Teclado", "Xbox", "PlayStation", "Nintendo"]
const AMBER := Color(0.953, 0.769, 0.416)
const BLUE := Color(0.663, 0.89, 0.949)
const GREY := Color(0.64, 0.62, 0.69)
const DIM := Color(0.32, 0.31, 0.36)
const BODY := Color(0.17, 0.17, 0.21)
const BODY_EDGE := Color(0.62, 0.6, 0.68)
const KEY_FACE := Color(0.16, 0.16, 0.2)
const FONT_SIZE := 13
const POSITION_OF_FACE_BUTTON := { south = 0, east = 1, west = 2, north = 3 }

## Dispositivo que se muestra (InputGlyphs.Kind).
var device: int = InputGlyphs.Kind.KEYBOARD


func _ready() -> void:
	# Funciona también con el juego en pausa (la pausa del menú).
	process_mode = Node.PROCESS_MODE_ALWAYS
	custom_minimum_size = Vector2(700, 300)
	device = InputGlyphs.kind
	visibility_changed.connect(_on_visibility_changed)
	if is_visible_in_tree():
		_on_visibility_changed()


func _on_visibility_changed() -> void:
	# Al mostrarse, empieza en el dispositivo en uso.
	if is_visible_in_tree():
		device = InputGlyphs.kind
		queue_redraw()


func cycle(step: int) -> void:
	device = posmod(device + step, TAB_NAMES.size())
	queue_redraw()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		return
	if event.is_action_pressed(&"ui_left") and not event.is_echo():
		get_viewport().set_input_as_handled()
		cycle(-1)
	elif event.is_action_pressed(&"ui_right") and not event.is_echo():
		get_viewport().set_input_as_handled()
		cycle(1)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	_draw_tabs(font)
	draw_string(font, Vector2(0.0, 50.0), "Bajar de un tablón: ↓ + saltar", HORIZONTAL_ALIGNMENT_CENTER, size.x, 12, DIM)
	var origin := Vector2(size.x / 2.0, 44.0 + (size.y - 44.0) / 2.0)
	if device == InputGlyphs.Kind.KEYBOARD:
		_draw_keyboard(font, origin)
	else:
		_draw_gamepad(font, origin)


func _draw_tabs(font: Font) -> void:
	var tab_width := 118.0
	var start := (size.x - tab_width * TAB_NAMES.size()) / 2.0
	for i in TAB_NAMES.size():
		var rect := Rect2(start + i * tab_width, 2.0, tab_width - 6.0, 24.0)
		var active := i == device
		draw_rect(rect, Color(AMBER, 0.16) if active else Color(0, 0, 0, 0.25))
		draw_rect(rect, AMBER if active else DIM, false, 1.0)
		draw_string(font, Vector2(rect.position.x, rect.position.y + 17.0), TAB_NAMES[i], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 14, AMBER if active else GREY)
	draw_polyline(PackedVector2Array([Vector2(start - 18.0, 14.0), Vector2(start - 10.0, 8.0), Vector2(start - 10.0, 20.0), Vector2(start - 18.0, 14.0)]), GREY, 1.4)
	var end := start + tab_width * TAB_NAMES.size()
	draw_polyline(PackedVector2Array([Vector2(end + 12.0, 8.0), Vector2(end + 20.0, 14.0), Vector2(end + 12.0, 20.0), Vector2(end + 12.0, 8.0)]), GREY, 1.4)


# ---------------------------------------------------------------- mando

func _draw_gamepad(font: Font, c: Vector2) -> void:
	# Cuerpo: dos empuñaduras y un puente central.
	var outline := BODY_EDGE
	for grip in [Vector2(-96.0, 52.0), Vector2(96.0, 52.0)]:
		draw_circle(c + grip, 46.0, outline)
	draw_rect(Rect2(c + Vector2(-118.0, -52.0), Vector2(236.0, 108.0)), outline)
	for grip in [Vector2(-96.0, 52.0), Vector2(96.0, 52.0)]:
		draw_circle(c + grip, 44.0, BODY)
	draw_rect(Rect2(c + Vector2(-116.0, -50.0), Vector2(232.0, 104.0)), BODY)
	# Hombros: gatillos y gatillos superiores.
	var left_trigger := c + Vector2(-82.0, -66.0)
	var right_trigger := c + Vector2(82.0, -66.0)
	InputGlyphs.draw_trigger(self, false, left_trigger, device)
	InputGlyphs.draw_trigger(self, true, right_trigger, device)
	# Palanca izquierda y cruceta.
	var stick := c + Vector2(-62.0, -14.0)
	draw_circle(stick, 19.0, Color(0.06, 0.06, 0.08))
	draw_circle(stick, 12.0, Color(0.3, 0.3, 0.36))
	draw_arc(stick, 19.0, 0.0, TAU, 28, BODY_EDGE, 1.0)
	var dpad := c + Vector2(-36.0, 30.0)
	draw_rect(Rect2(dpad + Vector2(-4.0, -13.0), Vector2(8.0, 26.0)), Color(0.3, 0.3, 0.36))
	draw_rect(Rect2(dpad + Vector2(-13.0, -4.0), Vector2(26.0, 8.0)), Color(0.3, 0.3, 0.36))
	# Palanca derecha.
	var right_stick := c + Vector2(34.0, 30.0)
	draw_circle(right_stick, 15.0, Color(0.06, 0.06, 0.08))
	draw_circle(right_stick, 9.0, Color(0.22, 0.22, 0.27))
	draw_arc(right_stick, 15.0, 0.0, TAU, 24, DIM, 1.0)
	# Botones de acción, por posición.
	var face := c + Vector2(70.0, -14.0)
	var places := {
		POSITION_OF_FACE_BUTTON.north: face + Vector2(0.0, -20.0),
		POSITION_OF_FACE_BUTTON.south: face + Vector2(0.0, 20.0),
		POSITION_OF_FACE_BUTTON.west: face + Vector2(-20.0, 0.0),
		POSITION_OF_FACE_BUTTON.east: face + Vector2(20.0, 0.0),
	}
	for index in places:
		InputGlyphs.draw_button(self, index, places[index], device)
	# Menú.
	var menu_button := c + Vector2(2.0, -14.0)
	InputGlyphs.draw_menu_button(self, menu_button, device)

	# Rótulos: a la izquierda lo del lado izquierdo, a la derecha lo del derecho.
	_callout(font, stick + Vector2(-20.0, 0.0), c + Vector2(-190.0, -14.0), "Moverse · mirar (↑ ↓)", true, AMBER)
	_callout(font, dpad + Vector2(-14.0, 6.0), c + Vector2(-190.0, 36.0), "Cruceta: igual que la palanca", true, GREY)
	_callout(font, left_trigger + Vector2(-20.0, 0.0), c + Vector2(-190.0, -66.0), "Guardia (parry)", true, BLUE)
	_callout(font, right_trigger + Vector2(20.0, 0.0), c + Vector2(190.0, -66.0), "Dash", false, BLUE)
	_callout(font, places[POSITION_OF_FACE_BUTTON.north] + Vector2(9.0, 0.0), c + Vector2(190.0, -38.0), "Interactuar (Ancla, Eco)", false, AMBER)
	_callout(font, places[POSITION_OF_FACE_BUTTON.west] + Vector2(-9.0, 4.0), c + Vector2(190.0, -8.0), "Atacar", false, AMBER)
	_callout(font, places[POSITION_OF_FACE_BUTTON.east] + Vector2(9.0, 2.0), c + Vector2(190.0, 22.0), "Curarse", false, AMBER)
	_callout(font, places[POSITION_OF_FACE_BUTTON.south] + Vector2(9.0, 3.0), c + Vector2(190.0, 52.0), "Saltar · doble salto", false, AMBER)
	_callout(font, menu_button + Vector2(0.0, -10.0), c + Vector2(0.0, -96.0), "Pausa", true, GREY, true)


# --------------------------------------------------------------- teclado

func _draw_keyboard(font: Font, c: Vector2) -> void:
	var u := 30.0 # lado de una tecla
	# Cada tecla: [etiqueta, columna, fila, ancho en teclas, color o null si no se usa]
	var keys := [
		["Esc", -7.6, -2.55, 1.0, GREY],
		["H", 0.45, -0.8, 1.0, AMBER],
		["Shift", -7.1, 0.35, 1.8, BLUE],
		["Z", -5.2, 0.35, 1.0, AMBER],
		["X", -4.1, 0.35, 1.0, AMBER],
		["C", -3.0, 0.35, 1.0, null],
		["V", -1.9, 0.35, 1.0, BLUE],
		["Espacio", -5.0, 1.5, 5.6, AMBER],
		["↑", 5.2, 0.35, 1.0, GREY],
		["←", 4.1, 1.5, 1.0, AMBER],
		["↓", 5.2, 1.5, 1.0, GREY],
		["→", 6.3, 1.5, 1.0, AMBER],
	]
	var rects := {}
	for key in keys:
		var rect := Rect2(c + Vector2(key[1], key[2]) * u - Vector2(0.0, 6.0), Vector2(key[3] * u - 3.0, u - 3.0))
		rects[key[0]] = rect
		var color = key[4]
		draw_rect(Rect2(rect.position + Vector2(0, 2), rect.size), Color(0, 0, 0, 0.5))
		draw_rect(rect, KEY_FACE if color == null else Color(color, 0.22))
		draw_rect(rect, DIM if color == null else color, false, 1.5)
		draw_string(font, Vector2(rect.position.x, rect.position.y + 20.0), key[0], HORIZONTAL_ALIGNMENT_CENTER, rect.size.x, 13, DIM if color == null else Color(0.97, 0.96, 0.98))
	# Rótulos.
	_callout(font, rects["Esc"].get_center() + Vector2(0, -15.0), c + Vector2(-216.0, -112.0), "Pausa", true, GREY, true)
	_callout(font, rects["H"].get_center() + Vector2(0, -15.0), c + Vector2(34.0, -112.0), "Curarse", true, AMBER, true)
	_callout(font, rects["Z"].get_center() + Vector2(0, -15.0), c + Vector2(-100.0, -84.0), "Interactuar (Ancla, Eco)", true, AMBER, true)
	_callout(font, rects["X"].get_center() + Vector2(0, -15.0), c + Vector2(-66.0, -56.0), "Atacar", true, AMBER, true)
	_callout(font, rects["V"].get_center() + Vector2(0, -15.0), c + Vector2(-26.0, -28.0), "Guardia (parry)", true, BLUE, true)
	_callout(font, rects["Shift"].get_center() + Vector2(0, 15.0), c + Vector2(-216.0, 96.0), "Dash", true, BLUE, true)
	_callout(font, rects["Espacio"].get_center() + Vector2(0, 15.0), c + Vector2(-110.0, 108.0), "Saltar · doble salto", true, AMBER, true)
	_callout(font, rects["←"].get_center() + Vector2(0, 15.0), c + Vector2(150.0, 108.0), "← → Moverse", true, AMBER, true)
	_callout(font, rects["↑"].get_center() + Vector2(0, -15.0), c + Vector2(176.0, -22.0), "↑ ↓ Mirar", true, GREY, true)


# ---------------------------------------------------------------- rótulos

## Un rótulo con una línea que lo une al botón. `to` es el borde del texto: con
## `above_below` el texto se centra en `to` y la línea llega en vertical; si no, el texto
## empieza (derecha) o acaba (izquierda) en `to` y la línea llega en horizontal.
func _callout(font: Font, from: Vector2, to: Vector2, text: String, left_side: bool, color: Color, centered: bool = false) -> void:
	var line_color := Color(color, 0.7)
	var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	if centered:
		var below := to.y > from.y
		var end := Vector2(to.x, to.y - 12.0 if below else to.y + 5.0)
		draw_polyline(PackedVector2Array([from, Vector2(from.x, end.y), end]) if absf(from.x - end.x) < 1.0 else PackedVector2Array([from, Vector2(from.x, (from.y + end.y) / 2.0), Vector2(end.x, (from.y + end.y) / 2.0), end]), line_color, 1.2)
		draw_string(font, Vector2(to.x - width / 2.0, to.y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
		return
	var gap := 8.0
	var anchor_x := to.x + (-gap if left_side else gap)
	draw_polyline(PackedVector2Array([from, Vector2(from.x + (-12.0 if left_side else 12.0), from.y), Vector2(anchor_x - (-0.0), to.y), Vector2(anchor_x, to.y)]), line_color, 1.2)
	var text_x := to.x - width - gap * 2.0 if left_side else to.x + gap * 2.0
	draw_string(font, Vector2(text_x, to.y + 4.0), text, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, color)
