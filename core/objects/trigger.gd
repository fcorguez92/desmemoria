class_name Trigger
extends StaticBody2D
## Disparador: un objeto que pone o quita una marca de FlagStore (`flag_id`), que otra
## cosa (una Gate, un receptor...) lee. No sabe qué abre; solo escribe su marca.
##
## Tres modos:
## - LEVER (palanca): se acciona con la acción de interacción estando al alcance o
##   con un golpe. Se queda activada (latch); con `toggle` alterna cada vez.
## - PLATE (placa de presión): activa mientras haya alguien de `target_groups`
##   encima y `hold_time` segundos después de que se vaya (el testigo se apaga en
##   cuenta atrás).
## - BUTTON (botón): solo con un golpe; se queda activado.
##
## Que lo que escribe sea permanente o temporal lo decide el prefijo del id (ver
## FlagStore): una palanca de `d:` o `p:` queda para siempre; una `toggle` o una placa
## llevan `t:` y se reinician al descansar o morir (si la marca se borra desde fuera,
## el disparador se apaga también). Sin FlagStore funciona igual, con estado local.
##
## Se golpea como un objeto rompible: capa de física 2 ("rompibles") y sin máscara, así
## que se atraviesa y solo lo alcanza un ataque (contrato "golpeable": `take_hit`).
## El dibujo es de la escena: `witness` (testigo: se tiñe de `lit_color` o `dim_color`)
## y `flip` (se voltea al activarse, p. ej. el mango de la palanca) son opcionales y
## requieren `node_paths` en el .tscn.

enum Mode { LEVER, PLATE, BUTTON }

## Cambia entre activado y desactivado.
signal state_changed(active: bool)

@export var mode: Mode = Mode.LEVER
## Marca que escribe: `prefijo:sala.objeto`.
@export var flag_id: StringName = &""
## Palanca: alterna cada vez en lugar de quedarse activada.
@export var toggle: bool = false
## Placa: segundos que sigue activa después de que se vaya el último (0 = al instante).
@export_range(0.0, 10.0) var hold_time: float = 0.0
## Zona (relativa al nodo) en la que hay que estar para accionarla o pisarla.
@export var reach_rect: Rect2 = Rect2(-14.0, -16.0, 28.0, 32.0)
## Grupos de los cuerpos que la accionan o pisan.
@export var target_groups: Array[StringName] = [&"player"]
@export var action_interact: StringName = &"interact"
@export var witness: CanvasItem
@export var flip: Node2D
@export var lit_color: Color = Color(1.0, 0.78, 0.36)
@export var dim_color: Color = Color(0.32, 0.3, 0.34)
## Sonido al accionarse (ver core/audio/sfx.gd); vacío = ninguno.
@export var sound: StringName = &"armor_hit"
@export var sound_volume_db: float = -6.0

var active: bool = false
## Placa: segundos que le quedan activa tras irse el último (0 si hay alguien encima).
var hold_left: float = 0.0

var _store: FlagStore
var _in_reach: Array[Node] = []


func _ready() -> void:
	var area := Area2D.new()
	area.collision_layer = 0
	area.collision_mask = 1
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = reach_rect.size
	shape.shape = rect
	shape.position = reach_rect.get_center()
	area.add_child(shape)
	add_child(area)
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	_show(false)


func _physics_process(delta: float) -> void:
	if _ensure_store():
		_apply(_is_flag_on())
	match mode:
		Mode.PLATE:
			_step_plate(delta)
		Mode.LEVER:
			if not _in_reach.is_empty() and Input.is_action_just_pressed(action_interact):
				_use()


## Contrato "golpeable": una palanca o un botón se accionan de un golpe.
func take_hit(_damage: int, _from_direction: int, _attacker: Node = null) -> void:
	if mode != Mode.PLATE:
		_use()


func _use() -> void:
	if mode == Mode.LEVER and toggle:
		_set_active(not active)
	elif not active:
		_set_active(true)


func _step_plate(delta: float) -> void:
	if not _in_reach.is_empty():
		hold_left = hold_time
		_set_active(true)
	elif active:
		hold_left = maxf(hold_left - delta, 0.0)
		if hold_left <= 0.0:
			_set_active(false)
		else:
			_show(true)  # cuenta atrás: el testigo se va apagando


## Cambia de estado por una acción del jugador: escribe la marca y suena.
func _set_active(value: bool) -> void:
	if value == active:
		return
	_apply(value)
	_ensure_store()
	if _store != null:
		if value:
			_store.set_flag(flag_id)
		else:
			_store.clear_flag(flag_id)
	if sound != &"":
		Sfx.play(sound, global_position, sound_volume_db)


## Busca el almacén si aún no lo tiene. Devuelve true solo la vez que lo encuentra.
func _ensure_store() -> bool:
	if _store != null or flag_id == &"":
		return false
	_store = FlagStore.find(self)
	if _store == null:
		return false
	_store.changed.connect(_on_flag_changed)
	return true


## Pone el estado y el dibujo, sin tocar la marca ni sonar.
func _apply(value: bool) -> void:
	if value != active:
		active = value
		state_changed.emit(value)
	if not value:
		hold_left = 0.0
	_show(value)


func _show(value: bool) -> void:
	var level := 1.0 if value else 0.0
	if mode == Mode.PLATE and value and hold_time > 0.0 and _in_reach.is_empty():
		level = clampf(hold_left / hold_time, 0.0, 1.0)
	if witness != null:
		witness.modulate = dim_color.lerp(lit_color, level)
	if flip != null:
		flip.scale.x = -1.0 if value else 1.0


func _is_flag_on() -> bool:
	return _store != null and bool(_store.get_flag(flag_id, false))


## Una marca cambiada desde fuera (descansar o morir borran las temporales).
func _on_flag_changed(id: StringName) -> void:
	if id == flag_id:
		_apply(_is_flag_on())


func _on_body_entered(body: Node) -> void:
	for group in target_groups:
		if body.is_in_group(group):
			_in_reach.append(body)
			return


func _on_body_exited(body: Node) -> void:
	_in_reach.erase(body)
