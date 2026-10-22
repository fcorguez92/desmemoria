extends Hazard
## Estacas de hierro: un Hazard con dibujo. Las fijas se ven siempre extendidas;
## las pulsantes (period > 0) se retraen, avisan a medias y salen con un
## chasquido. La escena se coloca mirando hacia arriba; `room.gd` la gira para
## el techo.

const FRAME_EXTENDED := 0
const FRAME_HALF := 1
const FRAME_RETRACTED := 2

@onready var _sprite: Sprite2D = $Sprite2D


func _ready() -> void:
	super._ready()
	state_changed.connect(_on_state_changed)
	_show(state)


func _on_state_changed(new_state: State) -> void:
	_show(new_state)
	if new_state == State.ACTIVE:
		Sfx.play(&"spikes_pulse", global_position, -16.0)


func _show(for_state: State) -> void:
	match for_state:
		State.ACTIVE:
			_sprite.frame = FRAME_EXTENDED
		State.WARNING:
			_sprite.frame = FRAME_HALF
		_:
			_sprite.frame = FRAME_RETRACTED
