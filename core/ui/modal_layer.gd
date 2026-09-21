class_name ModalLayer
extends CanvasLayer
## Capa de interfaz modal (menús, pantallas de pausa): al abrirse pausa el juego y
## al cerrarse lo reanuda. Sus hijos deben tener `process_mode = When Paused` para
## seguir funcionando con el juego en pausa (basta con ponerlo en esta capa).
##
## El contenido visible cuelga de un nodo `root` (Control) que esta clase muestra u
## oculta; así el resto de nodos de la capa siguen existiendo aunque estén ocultos.
##
## Al cerrar, el juego se reanuda dos frames de física DESPUÉS, no en el mismo: la
## pulsación que cierra el menú seguiría contando como "recién pulsada" y el juego
## la ejecutaría (p. ej. Espacio, que acepta en el menú, también es el salto).

signal opened
signal closed

## Nodo cuyo `visible` indica si la capa está abierta.
@export var root: Control


func _ready() -> void:
	root.visible = false


func is_open() -> bool:
	return root.visible


func open() -> void:
	if root.visible:
		return
	root.visible = true
	get_tree().paused = true
	opened.emit()


func close() -> void:
	if not root.visible:
		return
	root.visible = false
	closed.emit()
	var tree := get_tree()
	await tree.physics_frame
	await tree.physics_frame
	# Si mientras tanto se volvió a abrir (esta capa u otra), no se reanuda.
	if not root.visible:
		tree.paused = false
