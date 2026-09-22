class_name Readable
extends Area2D
## Objeto legible (una inscripción, un cartel...): al pulsar la acción de
## interacción con un cuerpo del grupo objetivo dentro, le hace leer `text`.
##
## Contrato "lector": el objetivo implementa `read_text(text: String)`, que
## decide cómo se muestra (normalmente el HUD, un rato acorde a lo que hay que
## leer). No es un Checkpoint (no cambia el estado del juego, solo enseña texto).

@export var target_group: StringName = &"player"
@export var action_interact: StringName = &"interact"
@export var text: String = ""
## Elemento opcional (p. ej. un Label) que se muestra mientras hay alguien al alcance.
@export var prompt: CanvasItem

var targets_in_range: Array[Node] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	_update_prompt()


func _physics_process(_delta: float) -> void:
	if targets_in_range.is_empty() or not Input.is_action_just_pressed(action_interact):
		return
	for body in targets_in_range:
		body.read_text(text)


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group) and body.has_method("read_text"):
		targets_in_range.append(body)
		_update_prompt()


func _on_body_exited(body: Node) -> void:
	targets_in_range.erase(body)
	_update_prompt()


func _update_prompt() -> void:
	if prompt:
		prompt.visible = not targets_in_range.is_empty()
