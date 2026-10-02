class_name BreakableProp
extends StaticBody2D
## Objeto rompible puramente decorativo: implementa el contrato "golpeable"
## (ver docs/arquitectura.md) y se destruye con un chispazo tras `hits` golpes
## (1 por defecto). No suelta nada ni afecta a la partida, así que no necesita
## reaparecer al reiniciar el mundo (a diferencia de `EntitySpawner`).
##
## Se atraviesa caminando (como los tarros de Hollow Knight): vive en la capa de
## física 2 ("rompibles") y no choca con nadie, pero el hitbox de ataque del
## jugador la incluye en su máscara, así que los golpes sí lo alcanzan. Se dibuja
## detrás del personaje (las salas se pintan antes que el jugador).

signal broken

@export var hits: int = 1
@export var spark_color: Color = Color(0.8, 0.72, 0.6)

var _remaining_hits: int


func _ready() -> void:
	_remaining_hits = hits


## Contrato "golpeable".
func take_hit(_damage: int, _from_direction: int, _attacker: Node = null) -> void:
	_remaining_hits -= 1
	if _remaining_hits <= 0:
		_break()


func _break() -> void:
	HitSpark.spawn(get_parent(), global_position, spark_color)
	broken.emit()
	queue_free()
