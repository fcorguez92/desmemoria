class_name HitStop
extends RefCounted
## Pausa breve del tiempo de juego al golpear, para dar peso al impacto
## ("hit stop"). Escala `Engine.time_scale` un instante y lo restaura.
##
## Como afecta a todo el juego a la vez (no solo a quien golpea), hay que
## mantenerlo muy breve. La pausa se mide en tiempo real, no de juego, o al
## escalar el tiempo la propia espera para restaurarlo se alargaría con él.
##
## Uso: `HitStop.trigger(self, duration, scale)`. `caller` solo hace falta para
## llegar al árbol de escena (`get_tree()`); si dos golpes se solapan, el
## segundo manda y el primero no restaura el tiempo encima del suyo.

static var _active_id: int = 0


static func trigger(caller: Node, duration: float = 0.06, scale: float = 0.05) -> void:
	_active_id += 1
	var this_id := _active_id
	Engine.time_scale = scale
	await caller.get_tree().create_timer(duration, true, false, true).timeout
	if this_id == _active_id:
		Engine.time_scale = 1.0
