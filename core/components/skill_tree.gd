class_name SkillTree
extends Node
## Árbol de habilidades: una lista de mejoras por niveles (`define()`), cada una con
## el coste de cada nivel y, opcionalmente, otra mejora que hay que tener antes
## (`requires`: al menos nivel 1). Guarda el nivel de cada mejora.
##
## No gestiona la moneda ni aplica los efectos: el dueño comprueba si hay saldo
## (`can_buy`), cobra, llama a `advance()` y, al oír `changed`, aplica los efectos
## de los niveles actuales a sus estadísticas. Así el árbol sirve para vida, daño,
## velocidad... de cualquier juego (ver docs/arquitectura.md).

signal changed

## id -> { costs: PackedInt32Array, requires: StringName }
var _defs: Dictionary = {}
## id -> nivel actual (0 si nunca se ha subido)
var _levels: Dictionary = {}


## Da de alta una mejora. `costs[i]` es lo que cuesta pasar del nivel `i` al `i + 1`,
## así que `costs.size()` es el nivel máximo.
func define(id: StringName, costs: PackedInt32Array, requires: StringName = &"") -> void:
	_defs[id] = { costs = costs, requires = requires }
	_levels[id] = 0


func has_skill(id: StringName) -> bool:
	return _defs.has(id)


func ids() -> Array:
	return _defs.keys()


func level(id: StringName) -> int:
	return _levels.get(id, 0)


func max_level(id: StringName) -> int:
	return (_defs[id].costs as PackedInt32Array).size() if _defs.has(id) else 0


func is_max(id: StringName) -> bool:
	return level(id) >= max_level(id)


## Coste de la siguiente subida, o -1 si ya está al máximo (o no existe).
func next_cost(id: StringName) -> int:
	if not _defs.has(id) or is_max(id):
		return -1
	return (_defs[id].costs as PackedInt32Array)[level(id)]


## ¿Está desbloqueada, es decir, tiene ya la mejora previa que pide?
func is_unlocked(id: StringName) -> bool:
	if not _defs.has(id):
		return false
	var requires: StringName = _defs[id].requires
	return requires == &"" or level(requires) >= 1


func can_buy(id: StringName, currency: int) -> bool:
	return is_unlocked(id) and not is_max(id) and currency >= next_cost(id)


## Sube un nivel. Devuelve false si estaba bloqueada o al máximo. No cobra.
func advance(id: StringName) -> bool:
	if not is_unlocked(id) or is_max(id):
		return false
	_levels[id] = level(id) + 1
	changed.emit()
	return true


## Pone un nivel directamente, sin coste ni requisitos (p. ej. al cargar una partida).
func set_level(id: StringName, new_level: int) -> void:
	if _defs.has(id):
		_levels[id] = clampi(new_level, 0, max_level(id))
		changed.emit()


## Niveles para guardar: solo las mejoras con algún nivel, con el id como texto.
func get_save_data() -> Dictionary:
	var data := {}
	for id in _levels:
		if _levels[id] > 0:
			data[String(id)] = _levels[id]
	return data


## Restaura niveles guardados. Desconfía de los datos: ignora ids desconocidos y
## valores que no sean números, y recorta los niveles al máximo.
func load_save_data(data: Variant) -> void:
	for id in _levels:
		_levels[id] = 0
	if data is Dictionary:
		for key in data:
			var id := StringName(str(key))
			var value: Variant = data[key]
			if _defs.has(id) and (value is int or value is float):
				_levels[id] = clampi(int(value), 0, max_level(id))
	changed.emit()
