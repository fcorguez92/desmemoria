class_name MapData
extends RefCounted
## Lo que sabe el mapa del mundo: qué zonas hay, qué baldosas de cada una se han
## visto, dónde está el foco (normalmente el jugador) y qué marcadores mostrar.
## Todo en baldosas, no en píxeles. Lo dibujan uno o varios `MapView` (un
## minimapa y un mapa completo comparten los mismos datos).
##
## El mapa se descubre baldosa a baldosa: `reveal_around()` marca como vistas
## las que quedan cerca del foco. Lo no visto no se dibuja.
##
## No sabe nada del juego: quien lo rellena decide qué es una zona, qué significa
## cada marcador, cuánto se ve alrededor y de qué color se pinta.

## Algo ha cambiado y las vistas deben redibujarse.
signal changed

## Una entrada por zona, en el orden en que se añadieron:
## { id: StringName, title: String, rect: Rect2i, visited: bool,
##   texture: ImageTexture (baldosas vistas), mask: ImageTexture (blanco donde
##   se ha visto), ... } (los campos que empiezan por _ son internos).
var areas: Array[Dictionary] = []
## id -> { cell: Vector2, color: Color }
var markers: Dictionary = {}
## Celda (con decimales) donde está el foco.
var focus_cell: Vector2 = Vector2.ZERO


## Añade una zona sin visitar ni ver. `rect` es su sitio en el mundo, en
## baldosas; `image` es su dibujo, un píxel por baldosa (ver `image_from_layer()`).
func add_area(id: StringName, title: String, rect: Rect2i, image: Image) -> void:
	var size := rect.size
	var seen_image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var mask_image := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
	var seen := PackedByteArray()
	seen.resize(size.x * size.y)
	areas.append({
		id = id,
		title = title,
		rect = rect,
		visited = false,
		texture = ImageTexture.create_from_image(seen_image),
		mask = ImageTexture.create_from_image(mask_image),
		_tiles = image,
		_seen = seen,
		_seen_image = seen_image,
		_mask_image = mask_image,
		_seen_bounds = Rect2i(),
	})
	changed.emit()


## Marca la zona como visitada (no descubre ninguna baldosa). Devuelve true la
## primera vez: sirve para anunciar una zona nueva.
func visit(id: StringName) -> bool:
	for area in areas:
		if area.id == id and not area.visited:
			area.visited = true
			return true
	return false


func is_visited(id: StringName) -> bool:
	for area in areas:
		if area.id == id:
			return area.visited
	return false


## Descubre las baldosas a menos de `radius` baldosas de `cell`, en todas las
## zonas que alcance el círculo. Devuelve true si se descubrió alguna nueva.
func reveal_around(cell: Vector2, radius: float) -> bool:
	var reach := Rect2i(Vector2i((cell - Vector2(radius, radius)).floor()), Vector2i.ONE * int(ceilf(radius * 2.0) + 1.0))
	var any := false
	for area in areas:
		var span: Rect2i = area.rect.intersection(reach)
		if span.size.x <= 0 or span.size.y <= 0:
			continue
		var changed_here := false
		for y in range(span.position.y, span.end.y):
			for x in range(span.position.x, span.end.x):
				if Vector2(x + 0.5, y + 0.5).distance_to(cell) <= radius:
					changed_here = _see(area, Vector2i(x, y) - area.rect.position) or changed_here
		if changed_here:
			area.texture.update(area._seen_image)
			area.mask.update(area._mask_image)
			any = true
	if any:
		changed.emit()
	return any


## ¿Se ha visto la baldosa `cell` (del mundo)?
func is_seen(cell: Vector2) -> bool:
	var area := area_at(cell)
	if area.is_empty():
		return false
	var local: Vector2i = Vector2i(cell.floor()) - area.rect.position
	return area._seen[local.y * area.rect.size.x + local.x] != 0


## La zona que contiene `cell`, o un diccionario vacío si ninguna.
func area_at(cell: Vector2) -> Dictionary:
	for area in areas:
		if Rect2(area.rect).has_point(cell):
			return area
	return {}


## Los marcadores solo se dibujan en baldosas ya vistas.
func set_marker(id: StringName, cell: Vector2, color: Color) -> void:
	var marker: Dictionary = markers.get(id, {})
	if not marker.is_empty() and marker.cell == cell and marker.color == color:
		return
	markers[id] = { cell = cell, color = color }
	changed.emit()


func remove_marker(id: StringName) -> void:
	if markers.erase(id):
		changed.emit()


## Solo avisa (y hace redibujar los mapas) al cambiar de baldosa: dentro de una
## baldosa el desplazamiento mide menos que un píxel del minimapa.
func set_focus(cell: Vector2) -> void:
	if cell == focus_cell:
		return
	var moved_tile := Vector2i(cell.floor()) != Vector2i(focus_cell.floor())
	focus_cell = cell
	if moved_tile:
		changed.emit()


## Rectángulo (en baldosas) que abarca todo lo visto.
func seen_bounds() -> Rect2i:
	var bounds := Rect2i()
	for area in areas:
		var seen: Rect2i = area._seen_bounds
		if seen.size != Vector2i.ZERO:
			bounds = seen if bounds.size == Vector2i.ZERO else bounds.merge(seen)
	return bounds


## Lo visto de cada zona, para guardarlo: id -> texto (comprimido y en base64).
func get_seen_data() -> Dictionary:
	var data := {}
	for area in areas:
		if area._seen_bounds.size != Vector2i.ZERO:
			data[String(area.id)] = Marshalls.raw_to_base64(area._seen.compress(FileAccess.COMPRESSION_DEFLATE))
	return data


## Restaura lo que dio `get_seen_data()`, sumándolo a lo ya visto: está pensado
## para un MapData recién creado (al cargar una partida). Ignora zonas que ya no
## existen o cuyo tamaño ha cambiado (un mapa editado desde que se guardó); un
## texto estropeado se ignora igual, aunque Godot puede avisar en la consola.
func set_seen_data(data: Dictionary) -> void:
	for area in areas:
		var encoded: Variant = data.get(String(area.id))
		if not encoded is String:
			continue
		var cells: int = area.rect.size.x * area.rect.size.y
		var raw := Marshalls.base64_to_raw(encoded)
		if raw.is_empty():
			continue
		var seen := raw.decompress(cells, FileAccess.COMPRESSION_DEFLATE)
		if seen.size() != cells:
			continue
		for i in cells:
			if seen[i] != 0:
				_see(area, Vector2i(i % area.rect.size.x, i / area.rect.size.x))
		area.texture.update(area._seen_image)
		area.mask.update(area._mask_image)
	changed.emit()


## Dibujo de una capa de baldosas para el mapa: un píxel de `color` por baldosa
## ocupada en un lienzo de `size` baldosas, transparente en el resto. `colors`
## (coordenadas en el atlas -> Color) pinta algunas baldosas de otro color, p. ej.
## las plataformas de un solo sentido.
static func image_from_layer(layer: TileMapLayer, size: Vector2i, color: Color, colors: Dictionary = {}) -> Image:
	var image := Image.create_empty(maxi(size.x, 1), maxi(size.y, 1), false, Image.FORMAT_RGBA8)
	for cell in layer.get_used_cells():
		if cell.x < 0 or cell.y < 0 or cell.x >= size.x or cell.y >= size.y:
			continue
		image.set_pixelv(cell, colors.get(layer.get_cell_atlas_coords(cell), color))
	return image


## Marca como vista la baldosa `local` (relativa a la zona). Devuelve true si no
## lo estaba. No actualiza las texturas: lo hace quien llama, una vez al final.
func _see(area: Dictionary, local: Vector2i) -> bool:
	var index: int = local.y * area.rect.size.x + local.x
	if area._seen[index] != 0:
		return false
	area._seen[index] = 1
	area._mask_image.set_pixelv(local, Color.WHITE)
	if local.x < area._tiles.get_width() and local.y < area._tiles.get_height():
		area._seen_image.set_pixelv(local, area._tiles.get_pixelv(local))
	var cell := Rect2i(area.rect.position + local, Vector2i.ONE)
	area._seen_bounds = cell if area._seen_bounds.size == Vector2i.ZERO else area._seen_bounds.merge(cell)
	return true
