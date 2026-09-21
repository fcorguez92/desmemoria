extends SceneTree
## Convierte los sprites escritos como texto (art/source/*.sprite) en hojas de
## sprites PNG usando la paleta de art/palette.txt. También genera vistas previas
## ampliadas en art/preview/ para revisarlas a simple vista.
##
## Ejecutar desde la raíz del proyecto:
##   godot --headless --path . --script res://tools/build_sprites.gd
## Sale con código 0 si todo se generó y con 1 si hubo errores.
##
## Formato de un archivo .sprite (las líneas que empiezan por # son comentarios):
##   sheet 64x56                 tamaño del lienzo de cada fotograma
##   out res://game/x/y.png      dónde se guarda la hoja de sprites
##   part NOMBRE                 una pieza reutilizable; a continuación sus filas
##   ...filas de texto, un carácter por píxel, todas del mismo ancho...
##   anim NOMBRE                 una animación (una fila de la hoja)
##   frame PIEZA1 PIEZA2 ...     un fotograma. Las piezas normales se APILAN de
##                               arriba abajo y forman el cuerpo base. Las que
##                               llevan @x,y (p. ej. espada@14,20) se SUPERPONEN
##                               encima, con su esquina superior izquierda en esa
##                               posición del cuerpo base (puede ser negativa o
##                               salirse del cuerpo, mientras quepa en el lienzo).
## El cuerpo base de cada fotograma se coloca centrado abajo dentro del lienzo,
## para que el personaje quede apoyado en los pies. La hoja tiene una fila por
## animación y una columna por fotograma.

const SOURCE_DIR := "res://art/source"
const PALETTE_PATH := "res://art/palette.txt"
const PREVIEW_DIR := "res://art/preview"
const PREVIEW_SCALE := 8


func _init() -> void:
	var palette := _load_palette()
	if palette.is_empty():
		push_error("No se pudo leer la paleta: " + PALETTE_PATH)
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(PREVIEW_DIR))
	# Un .gdignore vacío hace que Godot no importe las vistas previas.
	FileAccess.open(PREVIEW_DIR.path_join(".gdignore"), FileAccess.WRITE)
	var ok := true
	for file in DirAccess.get_files_at(SOURCE_DIR):
		if file.ends_with(".sprite"):
			if not _build(SOURCE_DIR.path_join(file), palette):
				ok = false
	quit(0 if ok else 1)


func _load_palette() -> Dictionary:
	var palette := {}
	var file := FileAccess.open(PALETTE_PATH, FileAccess.READ)
	if file == null:
		return palette
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(" ", false)
		if parts.size() >= 2 and parts[0].length() == 1:
			palette[parts[0]] = Color.html(parts[1])
	return palette


func _build(path: String, palette: Dictionary) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("No se pudo abrir " + path)
		return false

	var canvas := Vector2i.ZERO
	var out_path := ""
	var parts := {}
	var animations: Array = []
	var current_part := ""
	var errors := 0

	var line_number := 0
	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		line_number += 1
		if line.is_empty() or line.begins_with("#"):
			continue
		var words := line.split(" ", false)
		match words[0]:
			"sheet":
				var size := words[1].split("x")
				canvas = Vector2i(int(size[0]), int(size[1]))
			"out":
				out_path = words[1]
			"part":
				current_part = words[1]
				parts[current_part] = []
			"anim":
				current_part = ""
				animations.append({"name": words[1], "frames": []})
			"frame":
				current_part = ""
				var frame := {"base": [], "overlays": []}
				for i in range(1, words.size()):
					var token := words[i]
					var offset := Vector2i.ZERO
					if "@" in token:
						var split := token.split("@")
						token = split[0]
						var xy := split[1].split(",")
						offset = Vector2i(int(xy[0]), int(xy[1]))
						if not parts.has(token):
							push_error("%s:%d pieza desconocida '%s'" % [path, line_number, token])
							errors += 1
						else:
							frame["overlays"].append({"rows": parts[token], "offset": offset})
					elif not parts.has(token):
						push_error("%s:%d pieza desconocida '%s'" % [path, line_number, token])
						errors += 1
					else:
						frame["base"].append_array(parts[token])
				animations[-1]["frames"].append(frame)
			_:
				if current_part.is_empty():
					push_error("%s:%d línea inesperada: %s" % [path, line_number, line])
					errors += 1
				else:
					parts[current_part].append(line)

	if errors > 0 or canvas == Vector2i.ZERO or out_path.is_empty() or animations.is_empty():
		push_error("%s: falta sheet, out o alguna animación, o hay errores previos" % path)
		return false

	var columns := 0
	for anim in animations:
		columns = maxi(columns, anim["frames"].size())
	var sheet := Image.create(canvas.x * columns, canvas.y * animations.size(), false, Image.FORMAT_RGBA8)

	for row in animations.size():
		var frames: Array = animations[row]["frames"]
		for column in frames.size():
			var label := "%s [%s, fotograma %d]" % [path, animations[row]["name"], column]
			if not _draw_frame(sheet, frames[column], palette, canvas, Vector2i(column, row), label):
				return false

	var real_out := ProjectSettings.globalize_path(out_path)
	if sheet.save_png(real_out) != OK:
		push_error("No se pudo guardar " + out_path)
		return false

	var preview := sheet.duplicate() as Image
	preview.resize(sheet.get_width() * PREVIEW_SCALE, sheet.get_height() * PREVIEW_SCALE, Image.INTERPOLATE_NEAREST)
	preview.save_png(ProjectSettings.globalize_path(PREVIEW_DIR.path_join(path.get_file().get_basename() + "_x%d.png" % PREVIEW_SCALE)))

	print("%s -> %s (%dx%d, %d animaciones)" % [path.get_file(), out_path, sheet.get_width(), sheet.get_height(), animations.size()])
	return true


func _draw_frame(sheet: Image, frame: Dictionary, palette: Dictionary, canvas: Vector2i, cell: Vector2i, label: String) -> bool:
	var base_rows: Array = frame["base"]
	var width: int = base_rows[0].length()
	var height: int = base_rows.size()
	if width > canvas.x or height > canvas.y:
		push_error("%s: el dibujo (%dx%d) no cabe en el lienzo (%dx%d)" % [label, width, height, canvas.x, canvas.y])
		return false
	# Esquina superior izquierda del cuerpo base dentro de la hoja.
	var origin := Vector2i(cell.x * canvas.x + (canvas.x - width) / 2, cell.y * canvas.y + canvas.y - height)
	var cell_origin := Vector2i(cell.x * canvas.x, cell.y * canvas.y)
	if not _draw_rows(sheet, base_rows, origin, cell_origin, canvas, palette, label):
		return false
	for overlay in frame["overlays"]:
		if not _draw_rows(sheet, overlay["rows"], origin + overlay["offset"], cell_origin, canvas, palette, label + " (pieza superpuesta)"):
			return false
	return true


func _draw_rows(sheet: Image, rows: Array, origin: Vector2i, cell_origin: Vector2i, canvas: Vector2i, palette: Dictionary, label: String) -> bool:
	var width: int = rows[0].length()
	for y in rows.size():
		var text: String = rows[y]
		if text.length() != width:
			push_error("%s: la fila %d mide %d y debería medir %d: %s" % [label, y, text.length(), width, text])
			return false
		for x in width:
			var symbol := text[x]
			if symbol == ".":
				continue
			if not palette.has(symbol):
				push_error("%s: carácter '%s' sin color en la paleta (fila %d, columna %d)" % [label, symbol, y, x])
				return false
			var position := origin + Vector2i(x, y)
			var local := position - cell_origin
			if local.x < 0 or local.y < 0 or local.x >= canvas.x or local.y >= canvas.y:
				push_error("%s: el píxel de la fila %d, columna %d cae fuera del lienzo" % [label, y, x])
				return false
			sheet.set_pixel(position.x, position.y, palette[symbol])
	return true
