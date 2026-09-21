class_name SheetAnimator
extends Node
## Anima un Sprite2D que usa una hoja de sprites: cada animación es una fila de la
## hoja y cada fotograma una columna (el formato que genera tools/build_sprites.gd
## y que exportan Pixelorama o LibreSprite).
##
## Es solo presentación: el dueño decide qué animación toca con `play()`.

## El Sprite2D, con `hframes` (columnas) y `vframes` (filas) ya configurados.
@export var sprite: Sprite2D
## Nombre -> [fila, número de fotogramas, fotogramas por segundo, ¿en bucle?].
@export var animations: Dictionary = {}
@export var default_animation: String = "idle"

var current: String = ""

var _time: float = 0.0


func _ready() -> void:
	play(default_animation)


func _process(delta: float) -> void:
	_time += delta
	_apply()


## Cambia de animación (no hace nada si ya es la actual).
func play(animation: String) -> void:
	if animation == current:
		return
	if not animations.has(animation):
		push_warning("SheetAnimator: no existe la animación '%s'" % animation)
		return
	current = animation
	_time = 0.0
	_apply()


func _apply() -> void:
	var data: Array = animations[current]
	var count: int = data[1]
	var frame := int(_time * float(data[2]))
	frame = frame % count if data[3] else mini(frame, count - 1)
	sprite.frame = int(data[0]) * sprite.hframes + frame
