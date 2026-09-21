class_name SheetAnimator
extends Node
## Anima un Sprite2D que usa una hoja de sprites: cada animación es una fila de la
## hoja y cada fotograma una columna (el formato que genera tools/build_sprites.gd
## y que exportan Pixelorama o LibreSprite).
##
## Es solo presentación: el dueño decide qué animación toca. Hay dos tipos:
## - Animaciones normales (`play`): reposo, correr... El dueño puede pedirlas cada
##   frame; no hacen nada si ya es la actual.
## - Acciones (`play_action`): un ataque, por ejemplo. Mientras dura una acción se
##   ignoran las llamadas a `play`, para que el movimiento no la pise.

## El Sprite2D, con `hframes` (columnas) y `vframes` (filas) ya configurados.
@export var sprite: Sprite2D
## Nombre -> [fila, número de fotogramas, fotogramas por segundo, ¿en bucle?].
@export var animations: Dictionary = {}
@export var default_animation: String = "idle"

var current: String = ""

var _time: float = 0.0
var _action_active: bool = false
var _action_hold: bool = false
var _action_duration: float = 0.0


func _ready() -> void:
	play(default_animation)


func _process(delta: float) -> void:
	_time += delta
	_apply()


## Cambia de animación normal (no hace nada si ya es la actual o hay una acción en curso).
func play(animation: String) -> void:
	if _action_active or animation == current:
		return
	if not animations.has(animation):
		push_warning("SheetAnimator: no existe la animación '%s'" % animation)
		return
	current = animation
	_time = 0.0
	_apply()


## Reproduce una acción una vez. Sustituye a la acción anterior, si la hay.
## - `hold`: al llegar al último fotograma se queda en él hasta `release_action()`
##   o hasta otra acción (útil para el aviso de un ataque).
## - `duration`: si es mayor que 0, la acción entera dura ese tiempo en lugar de
##   usar los fps de la tabla.
## Al terminar una acción sin `hold`, el dueño recupera el control con `play`.
func play_action(animation: String, hold: bool = false, duration: float = 0.0) -> void:
	if not animations.has(animation):
		push_warning("SheetAnimator: no existe la animación '%s'" % animation)
		return
	_action_active = true
	_action_hold = hold
	_action_duration = duration
	current = animation
	_time = 0.0
	_apply()


## Cancela la acción en curso; la siguiente llamada a `play` toma el control.
func release_action() -> void:
	_action_active = false
	current = ""


func _apply() -> void:
	if current == "":
		return
	var data: Array = animations[current]
	var count: int = data[1]
	var fps := float(data[2])
	if _action_active and _action_duration > 0.0:
		fps = count / _action_duration
	var frame := int(_time * fps)
	if _action_active:
		if frame >= count:
			if _action_hold:
				frame = count - 1
			else:
				_action_active = false
				current = ""
				return
	else:
		frame = frame % count if data[3] else mini(frame, count - 1)
	sprite.frame = int(data[0]) * sprite.hframes + frame
