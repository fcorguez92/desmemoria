class_name Spawner
extends Node
## Crea entidades de una escena con un **tope de vivas** a la vez (docs/jefes.md,
## "Invocaciones"): un jefe que invoca no puede llenar la sala. Sin pooling: se crea
## y se libera. No confundir con EntitySpawner, que recrea una entidad al reiniciar.
##
## Uso: poner `scene` y `max_alive`; `spawn(parent, at)` devuelve la entidad o null si
## el tope está cubierto. Las que mueren (o se liberan) dejan de contar solas.
## `clear()` libera todas (el invocador muere o la pelea se reinicia).

## Se emite al crear una entidad.
signal spawned(entity: Node)

@export var scene: PackedScene
@export var max_alive: int = 2

var _alive: Array[Node] = []


## Cuántas siguen vivas.
func alive_count() -> int:
	_prune()
	return _alive.size()


func can_spawn() -> bool:
	return scene != null and alive_count() < max_alive


## Crea una entidad como hija de `parent`, con su posición global en `at`. `setup`
## (opcional) se llama con la entidad antes de añadirla al árbol, para ajustarla.
## Devuelve null si ya hay `max_alive` vivas.
func spawn(parent: Node, at: Vector2, setup: Callable = Callable()) -> Node:
	if not can_spawn():
		return null
	var entity := scene.instantiate()
	if setup.is_valid():
		setup.call(entity)
	parent.add_child(entity)
	if entity is Node2D:
		entity.global_position = at
	_alive.append(entity)
	spawned.emit(entity)
	return entity


## Libera todas las entidades vivas.
func clear() -> void:
	_prune()
	for entity in _alive:
		entity.queue_free()
	_alive.clear()


func _prune() -> void:
	var alive: Array[Node] = []
	for entity in _alive:
		if is_instance_valid(entity) and not entity.is_queued_for_deletion():
			alive.append(entity)
	_alive = alive
