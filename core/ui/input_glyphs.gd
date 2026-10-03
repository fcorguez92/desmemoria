class_name InputGlyphs
extends RefCounted
## Iconos de botones que se adaptan al dispositivo: la tecla en el teclado y, en un
## mando, el botón con su aspecto (colores de Xbox, símbolos de PlayStation, letras de
## Nintendo). Todo se dibuja por código; no hay texto explicativo, solo el botón.
##
## Se pregunta por una *acción* del Mapa de entrada ("interact", "pause"...): se busca
## qué tecla o botón del dispositivo actual la dispara y se dibuja eso. Los botones
## del mando se identifican por posición (abajo, derecha, izquierda, arriba), igual
## que en el resto del juego, así que el mismo botón lleva el icono que toca en cada mando.
##
## Para dibujar: `InputGlyphs.draw(canvas, acción, centro)` dentro de un `_draw()`.
## Para mantenerlos al día, ver `InputGlyphTracker` y `ensure_tracker()`.

enum Kind { KEYBOARD, XBOX, PLAYSTATION, NINTENDO }
## Símbolos que acompañan a un icono para decir a qué se refiere.
enum Hint { NONE, POINTER, MENU, UP_DOWN, CHECK, BACK, LEFT_RIGHT }

## Dispositivo en uso ahora mismo (lo actualiza InputGlyphTracker).
static var kind: int = Kind.KEYBOARD
static var tracker: InputGlyphTracker

const RADIUS := 7.0
const FONT_SIZE := 9
const DARK := Color(0.09, 0.09, 0.11)
const LIGHT := Color(0.96, 0.96, 0.98)
const XBOX_COLORS := [Color(0.42, 0.78, 0.27), Color(0.9, 0.27, 0.22), Color(0.27, 0.52, 0.93), Color(0.98, 0.82, 0.16)]
const PLAYSTATION_COLORS := [Color(0.45, 0.62, 0.98), Color(0.98, 0.38, 0.4), Color(0.95, 0.55, 0.8), Color(0.38, 0.85, 0.6)]


## Crea (una vez) el vigilante de dispositivo, colgado de la raíz del árbol.
static func ensure_tracker(tree: SceneTree) -> InputGlyphTracker:
	if not is_instance_valid(tracker):
		tracker = InputGlyphTracker.new()
		tracker.name = "InputGlyphTracker"
		tree.root.add_child.call_deferred(tracker)
	return tracker


## Qué dispositivo corresponde a este evento, o -1 si no dice nada (movimiento
## del ratón, una palanca que apenas se mueve...).
static func kind_from_event(event: InputEvent) -> int:
	if event is InputEventKey and event.pressed:
		return Kind.KEYBOARD
	if event is InputEventJoypadButton and event.pressed:
		return kind_from_name(Input.get_joy_name(event.device))
	if event is InputEventJoypadMotion:
		# Algunos mandos dejan los gatillos en reposo en -1: ahí solo cuenta pulsarlos a fondo.
		var is_trigger: bool = event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT
		if (event.axis_value > 0.6) if is_trigger else (absf(event.axis_value) > 0.6):
			return kind_from_name(Input.get_joy_name(event.device))
	return -1


static func kind_from_name(joy_name: String) -> int:
	var lowered := joy_name.to_lower()
	if "nintendo" in lowered or "switch" in lowered or "joy-con" in lowered or "joycon" in lowered:
		return Kind.NINTENDO
	if "ps3" in lowered or "ps4" in lowered or "ps5" in lowered or "dualshock" in lowered or "dualsense" in lowered or "playstation" in lowered or "sony" in lowered:
		return Kind.PLAYSTATION
	return Kind.XBOX


## Lo que dispara `action` en el dispositivo `for_kind`: un diccionario con `type`
## ("key", "button", "trigger") y los datos para dibujarlo, o vacío si no hay.
static func binding(action: StringName, for_kind: int) -> Dictionary:
	if not InputMap.has_action(action):
		return {}
	for event in InputMap.action_get_events(action):
		if for_kind == Kind.KEYBOARD and event is InputEventKey:
			var code: int = event.keycode
			if code == 0:
				# La tecla física puede llevar otra letra según la distribución del
				# teclado; sin pantalla (pruebas) no se puede consultar y se usa tal cual.
				code = event.physical_keycode
				if DisplayServer.get_name() != "headless":
					var mapped := DisplayServer.keyboard_get_keycode_from_physical(event.physical_keycode)
					if mapped != 0:
						code = mapped
			return { type = "key", label = _key_label(code) }
		if for_kind != Kind.KEYBOARD:
			if event is InputEventJoypadButton:
				return { type = "button", index = event.button_index }
			if event is InputEventJoypadMotion and (event.axis == JOY_AXIS_TRIGGER_LEFT or event.axis == JOY_AXIS_TRIGGER_RIGHT):
				return { type = "trigger", right = event.axis == JOY_AXIS_TRIGGER_RIGHT }
	return {}


static func _key_label(code: int) -> String:
	match code:
		KEY_ESCAPE:
			return "Esc"
		KEY_ENTER, KEY_KP_ENTER:
			return "Intro"
		KEY_SPACE:
			return "Espacio"
		KEY_SHIFT:
			return "Shift"
		KEY_LEFT:
			return "←"
		KEY_RIGHT:
			return "→"
		KEY_UP:
			return "↑"
		KEY_DOWN:
			return "↓"
	return OS.get_keycode_string(code)


## Ancho que ocupará el icono de `action` con el dispositivo actual.
static func width(action: StringName) -> float:
	var b := binding(action, kind)
	if b.is_empty():
		return RADIUS * 2.0
	if b.type == "key":
		var font := ThemeDB.fallback_font
		return maxf(RADIUS * 2.0, font.get_string_size(b.label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x + 8.0)
	if b.type == "trigger" or (b.type == "button" and b.index == JOY_BUTTON_START):
		return RADIUS * 2.6
	return RADIUS * 2.0


## Dibuja el icono de `action` centrado en `center`. Devuelve su ancho.
static func draw(canvas: CanvasItem, action: StringName, center: Vector2) -> float:
	var b := binding(action, kind)
	if b.is_empty():
		return 0.0
	match b.type:
		"key":
			return _draw_key(canvas, b.label, center)
		"trigger":
			return _draw_trigger(canvas, b.right, center)
		_:
			return _draw_button(canvas, b.index, center)


static func _draw_key(canvas: CanvasItem, label: String, center: Vector2) -> float:
	var font := ThemeDB.fallback_font
	var text_size := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE)
	var w := maxf(RADIUS * 2.0, text_size.x + 8.0)
	var rect := Rect2(center - Vector2(w, RADIUS * 2.0) / 2.0, Vector2(w, RADIUS * 2.0))
	canvas.draw_rect(Rect2(rect.position + Vector2(0, 2), rect.size), Color(0, 0, 0, 0.5))
	canvas.draw_rect(rect, Color(0.16, 0.16, 0.2))
	canvas.draw_rect(rect, Color(0.78, 0.78, 0.84), false, 1.0)
	canvas.draw_string(font, Vector2(rect.position.x, center.y + text_size.y * 0.32), label, HORIZONTAL_ALIGNMENT_CENTER, w, FONT_SIZE, LIGHT)
	return w


static func _draw_trigger(canvas: CanvasItem, right: bool, center: Vector2) -> float:
	var label := "RT" if right else "LT"
	if kind == Kind.PLAYSTATION:
		label = "R2" if right else "L2"
	elif kind == Kind.NINTENDO:
		label = "ZR" if right else "ZL"
	var w := RADIUS * 2.6
	var rect := Rect2(center - Vector2(w, RADIUS * 1.7) / 2.0, Vector2(w, RADIUS * 1.7))
	canvas.draw_rect(rect, Color(0.2, 0.2, 0.25))
	canvas.draw_rect(rect, Color(0.78, 0.78, 0.84), false, 1.0)
	var font := ThemeDB.fallback_font
	canvas.draw_string(font, Vector2(rect.position.x, center.y + 3.0), label, HORIZONTAL_ALIGNMENT_CENTER, w, FONT_SIZE - 1, LIGHT)
	return w


## Posición en el mando: 0 abajo, 1 derecha, 2 izquierda, 3 arriba (los índices de Godot).
static func _draw_button(canvas: CanvasItem, index: int, center: Vector2) -> float:
	if index == JOY_BUTTON_START:
		return _draw_menu_button(canvas, center)
	if index < 0 or index > 3:
		canvas.draw_circle(center, RADIUS, Color(0.2, 0.2, 0.25))
		canvas.draw_arc(center, RADIUS, 0.0, TAU, 20, Color(0.78, 0.78, 0.84), 1.0)
		return RADIUS * 2.0
	var font := ThemeDB.fallback_font
	match kind:
		Kind.XBOX:
			var letters := ["A", "B", "X", "Y"]
			canvas.draw_circle(center, RADIUS, XBOX_COLORS[index])
			canvas.draw_arc(center, RADIUS, 0.0, TAU, 20, DARK, 1.0)
			canvas.draw_string(font, Vector2(center.x - RADIUS, center.y + 3.2), letters[index], HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, FONT_SIZE, DARK)
		Kind.PLAYSTATION:
			canvas.draw_circle(center, RADIUS, Color(0.12, 0.13, 0.17))
			canvas.draw_arc(center, RADIUS, 0.0, TAU, 20, Color(0.7, 0.7, 0.78), 1.0)
			_draw_playstation_symbol(canvas, index, center, PLAYSTATION_COLORS[index])
		_:
			var nintendo := ["B", "A", "Y", "X"]
			canvas.draw_circle(center, RADIUS, Color(0.17, 0.17, 0.2))
			canvas.draw_arc(center, RADIUS, 0.0, TAU, 20, Color(0.8, 0.8, 0.86), 1.0)
			canvas.draw_string(font, Vector2(center.x - RADIUS, center.y + 3.2), nintendo[index], HORIZONTAL_ALIGNMENT_CENTER, RADIUS * 2.0, FONT_SIZE, LIGHT)
	return RADIUS * 2.0


static func _draw_playstation_symbol(canvas: CanvasItem, index: int, center: Vector2, color: Color) -> void:
	var r := 3.4
	match index:
		0: # cruz
			canvas.draw_line(center + Vector2(-r, -r), center + Vector2(r, r), color, 1.8)
			canvas.draw_line(center + Vector2(-r, r), center + Vector2(r, -r), color, 1.8)
		1: # círculo
			canvas.draw_arc(center, r + 0.4, 0.0, TAU, 16, color, 1.8)
		2: # cuadrado
			canvas.draw_rect(Rect2(center - Vector2(r, r), Vector2(r, r) * 2.0), color, false, 1.8)
		3: # triángulo
			var tri := PackedVector2Array([center + Vector2(0, -r - 0.6), center + Vector2(r + 0.6, r), center + Vector2(-r - 0.6, r), center + Vector2(0, -r - 0.6)])
			canvas.draw_polyline(tri, color, 1.8)


## Botón de menú: tres rayas (Xbox y PlayStation) o un más (Nintendo).
static func _draw_menu_button(canvas: CanvasItem, center: Vector2) -> float:
	var w := RADIUS * 2.6
	var rect := Rect2(center - Vector2(w, RADIUS * 1.5) / 2.0, Vector2(w, RADIUS * 1.5))
	canvas.draw_rect(rect, Color(0.2, 0.2, 0.25))
	canvas.draw_rect(rect, Color(0.78, 0.78, 0.84), false, 1.0)
	if kind == Kind.NINTENDO:
		canvas.draw_line(center + Vector2(-3, 0), center + Vector2(3, 0), LIGHT, 1.6)
		canvas.draw_line(center + Vector2(0, -3), center + Vector2(0, 3), LIGHT, 1.6)
	else:
		for dy in [-2.6, 0.0, 2.6]:
			canvas.draw_line(center + Vector2(-3.4, dy), center + Vector2(3.4, dy), LIGHT, 1.2)
	return w


## Dibuja un símbolo de ayuda (menú, elegir arriba/abajo, aceptar, volver) centrado en `at`.
static func draw_hint(canvas: CanvasItem, which: int, at: Vector2, color: Color = Color(0.95, 0.9, 0.7)) -> void:
	match which:
		Hint.MENU: # lista: tres rayas
			for dy in [-3.0, 0.0, 3.0]:
				canvas.draw_line(at + Vector2(-3, dy), at + Vector2(4, dy), color, 1.4)
		Hint.UP_DOWN: # dos triángulos, uno arriba y otro abajo
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, -6), at + Vector2(4, -1.5), at + Vector2(-4, -1.5)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(0, 6), at + Vector2(4, 1.5), at + Vector2(-4, 1.5)]), color)
		Hint.LEFT_RIGHT: # dos triángulos, uno a la izquierda y otro a la derecha
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(-6, 0), at + Vector2(-1.5, -4), at + Vector2(-1.5, 4)]), color)
			canvas.draw_colored_polygon(PackedVector2Array([at + Vector2(6, 0), at + Vector2(1.5, -4), at + Vector2(1.5, 4)]), color)
		Hint.CHECK: # visto bueno
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, 0), at + Vector2(-1, 3.5), at + Vector2(5, -4)]), color, 1.8)
		Hint.BACK: # flecha de volver
			canvas.draw_polyline(PackedVector2Array([at + Vector2(-4, 0), at + Vector2(1, -4), at + Vector2(1, 4), at + Vector2(-4, 0)]), color, 1.4)
			canvas.draw_line(at + Vector2(1, 0), at + Vector2(5, 0), color, 1.6)
