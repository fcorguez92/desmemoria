class_name Checkpoint
extends Area2D
## Punto de control que se activa al pulsar la acción de interacción mientras
## un cuerpo del grupo objetivo está dentro del área.
##
## Contrato con el objetivo: debe tener `rest_at(position: Vector2)`, que
## decide qué significa "descansar" (curar, fijar reaparición...).

@export var target_group: StringName = &"player"
@export var action_interact: StringName = &"interact"
## Elemento opcional (p. ej. un Label) que se muestra mientras hay un objetivo
## al alcance, para indicar que se puede interactuar.
@export var prompt: CanvasItem

## Objetivos válidos que están ahora mismo dentro del área. Público para que
## un checkpoint más específico (que herede de este) ofrezca más acciones.
var targets_in_range: Array[Node] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_prompt()


func _physics_process(_delta: float) -> void:
	if targets_in_range.is_empty() or not Input.is_action_just_pressed(action_interact):
		return
	for body in targets_in_range:
		body.rest_at(global_position)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("rest_at"):
		targets_in_range.append(body)
		_update_prompt()


func _on_body_exited(body: Node) -> void:
	targets_in_range.erase(body)
	_update_prompt()


func _update_prompt() -> void:
	if prompt:
		prompt.visible = not targets_in_range.is_empty()
