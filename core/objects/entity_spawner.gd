class_name EntitySpawner
extends Node2D
## Crea una entidad al cargar y la recrea desde cero cada vez que el grupo de
## reinicio recibe `reset()`: si sigue viva se sustituye por una nueva, y si
## murió reaparece. Sirve para enemigos que renacen, objetos que se recolocan...
##
## Como se recrea la escena entera, cualquier entidad futura (con IA, con
## estado propio) se reinicia bien sin implementar nada especial.
##
## Contrato: quien decide cuándo reiniciar llama a
## `get_tree().call_group(reset_group, "reset")`.

@export var scene: PackedScene
@export var reset_group: StringName = &"resettable"

## La entidad actual (puede ser inválida si murió y aún no se reinició).
var instance: Node


func _ready() -> void:
	add_to_group(reset_group)
	_spawn()


func reset() -> void:
	# Diferido: se puede pedir desde dentro de una señal de físicas (p. ej. la
	# muerte del jugador por contacto), donde no se permite añadir cuerpos.
	_replace.call_deferred()


func _replace() -> void:
	if is_instance_valid(instance):
		remove_child(instance)
		instance.queue_free()
	_spawn()


func _spawn() -> void:
	instance = scene.instantiate()
	add_child(instance)
