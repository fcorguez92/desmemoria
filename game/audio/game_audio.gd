extends RefCounted
## Prepara los efectos de sonido de este juego: apunta el reproductor genérico
## (core/audio/sfx.gd) a la carpeta con los sonidos que genera tools/sonidos.js.
## Lo llaman las escenas que arrancan solas: el menú principal y el jugador.

const SFX_DIRECTORY := "res://game/audio/sfx"


static func setup(tree: SceneTree) -> void:
	Sfx.setup(tree, SFX_DIRECTORY)
