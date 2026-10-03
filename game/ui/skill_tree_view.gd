extends Control
## Dibujo y navegación del árbol de habilidades en el menú del Ancla: tres ramas en
## columnas, cada mejora un círculo con su icono y sus niveles, unidos por líneas a
## la mejora que piden, y debajo el detalle de la seleccionada (qué hace, qué cuesta).
##
## No conoce al jugador ni al árbol: recibe los datos ya preparados con `set_skills()`
## (los datos bajan, ver docs/arquitectura.md) y se maneja con `move()`. Cada
## elemento es un diccionario con: id, name, text, branch, row, requires, level,
## max, cost (-1 si está al máximo), unlocked, affordable, now (texto del valor
## actual) y next (texto del valor del siguiente nivel, o "").

const NODE_RADIUS := 19.0
const COLUMN_TOP := 46.0
const ROW_STEP := 62.0
const DETAIL_TOP := 238.0
const AMBER := Color(0.953, 0.769, 0.416)
const BLUE := Color(0.663, 0.89, 0.949)
const GREY := Color(0.64, 0.62, 0.69)
const DIM := Color(0.32, 0.31, 0.36)
const RED := Color(0.94, 0.54, 0.42)

var branch_names: PackedStringArray = []
var selected_id: StringName = &""

var _skills: Array = []


func _ready() -> void:
	custom_minimum_size = Vector2(500, 330)


## Sustituye los datos. Conserva la selección si la mejora sigue existiendo.
func set_skills(skills: Array, branches: PackedStringArray) -> void:
	_skills = skills
	branch_names = branches
	if _find(selected_id).is_empty() and not _skills.is_empty():
		selected_id = _skills[0].id
	queue_redraw()


func selected() -> Dictionary:
	return _find(selected_id)


## Mueve la selección: `dx` entre ramas, `dy` dentro de una rama.
func move(dx: int, dy: int) -> void:
	var current := selected()
	if current.is_empty():
		return
	if dy != 0:
		var target := _in_branch(current.branch, current.row + dy)
		if not target.is_empty():
			selected_id = target.id
	if dx != 0:
		var branch: int = posmod(current.branch + dx, branch_names.size())
		var best := {}
		for skill in _skills:
			if skill.branch == branch and (best.is_empty() or absi(skill.row - current.row) < absi(best.row - current.row)):
				best = skill
		if not best.is_empty():
			selected_id = best.id
	queue_redraw()


func _find(id: StringName) -> Dictionary:
	for skill in _skills:
		if skill.id == id:
			return skill
	return {}


func _in_branch(branch: int, row: int) -> Dictionary:
	for skill in _skills:
		if skill.branch == branch and skill.row == row:
			return skill
	return {}


func _center(skill: Dictionary) -> Vector2:
	var columns := maxi(branch_names.size(), 1)
	return Vector2(size.x * (skill.branch + 0.5) / columns, COLUMN_TOP + ROW_STEP * skill.row)


func _draw() -> void:
	var font := ThemeDB.fallback_font
	# Títulos de las ramas.
	for i in branch_names.size():
		var x := size.x * (i + 0.5) / branch_names.size()
		draw_string(font, Vector2(x - 60.0, 14.0), branch_names[i], HORIZONTAL_ALIGNMENT_CENTER, 120.0, 14, AMBER)
		draw_line(Vector2(x - 40.0, 20.0), Vector2(x + 40.0, 20.0), Color(AMBER, 0.35), 1.0)
	# Líneas hacia la mejora previa (debajo de los nodos).
	for skill in _skills:
		var previous := _find(skill.requires)
		if not previous.is_empty():
			var from := _center(previous) + Vector2(0, NODE_RADIUS)
			var to := _center(skill) - Vector2(0, NODE_RADIUS)
			var lit: bool = previous.level >= 1
			draw_line(from, to, Color(AMBER, 0.7) if lit else DIM, 2.0)
	for skill in _skills:
		_draw_node(skill, skill.id == selected_id)
	_draw_detail(font)


func _draw_node(skill: Dictionary, is_selected: bool) -> void:
	var c := _center(skill)
	var maxed: bool = skill.level >= skill.max
	var color: Color = DIM
	if skill.unlocked:
		color = AMBER if skill.level > 0 else GREY
	draw_circle(c, NODE_RADIUS, Color(0.07, 0.07, 0.1))
	if maxed:
		draw_circle(c, NODE_RADIUS - 2.0, Color(AMBER, 0.22))
	draw_arc(c, NODE_RADIUS, 0.0, TAU, 32, color, 2.0)
	_draw_icon(skill.id, c, color if skill.unlocked else DIM)
	# Niveles: un cuadradito por nivel, lleno si está conseguido.
	var pip := 5.0
	var total: float = skill.max * (pip + 2.0) - 2.0
	for i in skill.max:
		var rect := Rect2(c.x - total / 2.0 + i * (pip + 2.0), c.y + NODE_RADIUS + 5.0, pip, pip)
		if i < skill.level:
			draw_rect(rect, AMBER)
		else:
			draw_rect(rect, Color(0.2, 0.2, 0.25))
			draw_rect(rect, DIM, false, 1.0)
	if is_selected:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 220.0)
		draw_arc(c, NODE_RADIUS + 5.0, 0.0, TAU, 40, Color(BLUE, 0.55 + 0.45 * pulse), 2.0)
		queue_redraw()


func _draw_detail(font: Font) -> void:
	var skill := selected()
	if skill.is_empty():
		return
	var x := 20.0
	var width := size.x - 40.0
	draw_line(Vector2(x, DETAIL_TOP - 14.0), Vector2(x + width, DETAIL_TOP - 14.0), Color(GREY, 0.3), 1.0)
	draw_string(font, Vector2(x, DETAIL_TOP + 6.0), skill.name, HORIZONTAL_ALIGNMENT_LEFT, width, 17, AMBER)
	draw_string(font, Vector2(x, DETAIL_TOP + 6.0), "Nivel %d / %d" % [skill.level, skill.max], HORIZONTAL_ALIGNMENT_RIGHT, width, 13, GREY)
	draw_multiline_string(font, Vector2(x, DETAIL_TOP + 26.0), skill.text, HORIZONTAL_ALIGNMENT_LEFT, width, 13, 3, GREY)
	var effect: String = skill.now
	if skill.next != "":
		effect += "   →   " + skill.next
	draw_string(font, Vector2(x, DETAIL_TOP + 62.0), effect, HORIZONTAL_ALIGNMENT_LEFT, width, 13, BLUE)
	var status := ""
	var status_color := GREY
	if skill.level >= skill.max:
		status = "Al máximo"
		status_color = AMBER
	elif not skill.unlocked:
		status = "Bloqueada: antes hay que conseguir " + _find(skill.requires).get("name", "la anterior")
		status_color = DIM
	elif skill.affordable:
		status = "Coste: %d Ecos" % skill.cost
		status_color = AMBER
	else:
		status = "Coste: %d Ecos (te faltan más)" % skill.cost
		status_color = RED
	draw_string(font, Vector2(x, DETAIL_TOP + 84.0), status, HORIZONTAL_ALIGNMENT_LEFT, width, 14, status_color)


## Iconos sencillos dibujados con formas, uno por mejora.
func _draw_icon(id: StringName, c: Vector2, color: Color) -> void:
	match id:
		&"vitalidad": # corazón
			draw_circle(c + Vector2(-3.2, -2.2), 3.4, color)
			draw_circle(c + Vector2(3.2, -2.2), 3.4, color)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6.4, -0.6), c + Vector2(6.4, -0.6), c + Vector2(0, 7)]), color)
		&"frascos": # frasco
			draw_rect(Rect2(c + Vector2(-2, -8), Vector2(4, 4)), color)
			draw_colored_polygon(PackedVector2Array([c + Vector2(-2, -4), c + Vector2(2, -4), c + Vector2(6, 6), c + Vector2(-6, 6)]), color)
		&"temple": # escudo
			draw_colored_polygon(PackedVector2Array([c + Vector2(-6, -7), c + Vector2(6, -7), c + Vector2(6, 1), c + Vector2(0, 8), c + Vector2(-6, 1)]), color)
		&"filo": # hoja
			draw_line(c + Vector2(-6, 6), c + Vector2(6, -6), color, 3.0)
			draw_line(c + Vector2(-6, 2), c + Vector2(-2, 6), color, 2.0)
		&"ritmo": # tres barras que crecen
			for i in 3:
				draw_rect(Rect2(c + Vector2(-7 + i * 5, 6 - 5 - i * 3), Vector2(3, 5 + i * 3)), color)
		&"alcance": # flecha hacia fuera
			draw_line(c + Vector2(-7, 0), c + Vector2(7, 0), color, 2.0)
			draw_colored_polygon(PackedVector2Array([c + Vector2(8, 0), c + Vector2(2, -5), c + Vector2(2, 5)]), color)
		&"guardia": # arco de guardia
			draw_arc(c + Vector2(0, 2), 7.0, PI * 1.05, PI * 1.95, 14, color, 3.0)
			draw_line(c + Vector2(0, -6), c + Vector2(0, 7), color, 2.0)
		&"impulso": # dos flechas hacia delante
			for dx in [-5.0, 1.0]:
				draw_polyline(PackedVector2Array([c + Vector2(dx, -6), c + Vector2(dx + 5, 0), c + Vector2(dx, 6)]), color, 2.2)
		&"contragolpe": # destello
			for i in 8:
				var dir := Vector2.from_angle(TAU * i / 8.0)
				draw_line(c + dir * 2.5, c + dir * (8.0 if i % 2 == 0 else 5.5), color, 2.0)
