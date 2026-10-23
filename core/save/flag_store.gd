class_name FlagStore
extends Node
## Almacén de marcas: un diccionario `id -> valor` con lo que ha pasado en el mundo
## (una palanca accionada, una grieta rota, un objeto recogido). Es genérico: no
## sabe qué significa ningún id ni cuántos hay; cada sala o puzle pone los suyos, así
## que crece con el mundo sin tocar este archivo.
##
## Convención de ids (ver docs/puzles.md): `prefijo:sala.objeto` en minúsculas,
## p. ej. `d:ultimo_umbral.verja_patio`. Los ids que empiezan por `transient_prefix`
## son temporales: no se guardan y `reset_transient()` los borra (descansar o morir).
## Los valores son lo que JSON entiende (booleano, número o texto); `true` por defecto.
##
## Quien lo usa lo añade al árbol; con `add_to_group(&"flag_store")` cualquier objeto
## del mundo lo encuentra con `get_tree().get_first_node_in_group(&"flag_store")`.

## Se emite al cambiar una marca (puesta con otro valor o borrada). No se emite si el
## valor es el mismo que ya había.
signal changed(id: StringName)

## Los ids con este prefijo no se guardan y se borran con `reset_transient()`.
@export var transient_prefix: String = "t:"

var _flags: Dictionary = {}


## Pone la marca `id`. Un id vacío o un valor que JSON no guardaría se ignoran.
## Devuelve true si algo cambió.
func set_flag(id: StringName, value: Variant = true) -> bool:
	if id == &"" or not _is_valid_value(value):
		return false
	if _flags.has(id) and _flags[id] == value:
		return false
	_flags[id] = value
	changed.emit(id)
	return true


## El valor de `id`, o `default` si no está puesta.
func get_flag(id: StringName, default: Variant = null) -> Variant:
	return _flags.get(id, default)


func has_flag(id: StringName) -> bool:
	return _flags.has(id)


## Borra la marca `id`. Devuelve true si estaba.
func clear_flag(id: StringName) -> bool:
	if not _flags.erase(id):
		return false
	changed.emit(id)
	return true


## Cuántas marcas hay cuyo id empieza por `prefix` (sin prefijo, todas).
func count(prefix: String = "") -> int:
	var total := 0
	for id: StringName in _flags:
		if String(id).begins_with(prefix):
			total += 1
	return total


## Los ids puestos cuyo valor es `value` y que empiezan por `prefix`.
func ids_with_value(value: Variant, prefix: String = "") -> Array[StringName]:
	var ids: Array[StringName] = []
	for id: StringName in _flags:
		if _flags[id] == value and String(id).begins_with(prefix):
			ids.append(id)
	return ids


## Contrato del grupo `resettable` (se llama al descansar o morir): borra las temporales.
func reset() -> void:
	reset_transient()


## Borra las marcas temporales (al descansar en un Ancla o al morir).
func reset_transient() -> void:
	for id: StringName in _flags.keys():
		if _is_transient(id):
			clear_flag(id)


## Lo que se guarda: `{ id: valor }` sin las marcas temporales. Los ids van como texto.
func to_dict() -> Dictionary:
	var data := {}
	for id: StringName in _flags:
		if not _is_transient(id):
			data[String(id)] = _flags[id]
	return data


## Carga lo guardado, sustituyendo lo que hubiera. Tolera cualquier cosa: ignora lo
## que no sea un diccionario (o una lista de ids, que cuentan como `true`), los ids
## vacíos o que no son texto, los valores que JSON no guardaría y los temporales.
## Si se pasa `known_ids` (no vacío), también ignora los ids que no estén en esa
## lista, p. ej. los de un objeto que ya no existe en el mundo. No emite `changed`.
func from_dict(data: Variant, known_ids: Array = []) -> void:
	_flags.clear()
	var pairs := {}
	if data is Dictionary:
		pairs = data
	elif data is Array:
		for id: Variant in data:
			pairs[id] = true
	for id: Variant in pairs:
		if not id is String or (id as String).is_empty() or _is_transient(StringName(id)):
			continue
		if not known_ids.is_empty() and not (id in known_ids or StringName(id) in known_ids):
			continue
		if _is_valid_value(pairs[id]):
			_flags[StringName(id)] = pairs[id]


func _is_transient(id: StringName) -> bool:
	return transient_prefix != "" and String(id).begins_with(transient_prefix)


func _is_valid_value(value: Variant) -> bool:
	if value is float:
		return is_finite(value)  # JSON no guarda NAN ni INF.
	return value is bool or value is int or value is String
