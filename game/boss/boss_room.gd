extends "res://game/levels/room.gd"
## Sala de jefe: una sala normal (room.gd) con una pelea. Cuando el jugador
## cruza la línea del disparador se cierran las rejas de entrada y el jefe
## despierta; al vencerlo se abren todas y aparece su recompensa. Si el jugador
## muere o descansa en un Ancla, la pelea se reinicia (la sala está en el grupo
## `resettable`) con el jefe entero y las rejas abiertas.
##
## Marcadores del mapa (además de los de room.gd):
##   b = dónde duerme el jefe, t = línea del disparador (columna), [ = celdas de
##   la reja de entrada (se cierra al empezar), ] = celdas de la reja de salida
##   (cerrada hasta vencer), r = dónde aparece la recompensa.
##
## Qué jefe y qué recompensa lo decide la escena (`boss_scene`, `reward_ability`).

## El jefe ha muerto: se abren las rejas y aparece la recompensa.
signal boss_defeated

const GateScene := preload("res://game/boss/arena_gate.tscn")
const BossBarScript := preload("res://game/boss/boss_bar.gd")
const BOSS_HALF_HEIGHT := 44.0

@export var boss_scene: PackedScene
## Habilidad que suelta el jefe al morir (identificador de AbilityPickup).
@export var reward_ability: StringName = &"dash"

var defeated: bool = false

var boss: Node
var _entry_gates: Array[Node] = []
var _exit_gates: Array[Node] = []
var _bar: CanvasLayer
var _started: bool = false
var _trigger_x: float = INF
var _boss_at: Vector2
var _reward_at: Vector2


func _ready() -> void:
	super._ready()
	add_to_group(&"resettable")
	for at in tiles.markers.get("b", []):
		_boss_at = at
	for at in tiles.markers.get("r", []):
		_reward_at = at
	for at in tiles.markers.get("t", []):
		_trigger_x = at.x
	for at in tiles.markers.get("[", []):
		_entry_gates.append(_make_gate(at))
	for at in tiles.markers.get("]", []):
		_exit_gates.append(_make_gate(at))
	_bar = BossBarScript.new()
	add_child(_bar)
	_set_gates(_exit_gates, true, false)
	_spawn_boss()


func _physics_process(_delta: float) -> void:
	if defeated or _started or boss == null:
		return
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return
	# Dentro de la arena (entre las rejas), no en el hueco de una puerta.
	var inside := world_rect().grow_individual(-2.0 * CELL, 0.0, -2.0 * CELL, 0.0).has_point(player.global_position)
	if inside and player.global_position.x >= _trigger_x:
		_start_fight()


func is_defeated() -> bool:
	return defeated


## Al cargar una partida en la que ya se venció al jefe: sin pelea, rejas
## abiertas y la recompensa a la vista (el mundo la retira si ya se tiene).
func mark_defeated() -> void:
	if defeated:
		return
	_clear_fight()
	_finish(false)


## Reinicio del mundo (al morir o descansar): la pelea empieza de cero.
func reset() -> void:
	# Si el jugador muere mientras el jefe acaba de morir, la victoria no se pierde.
	if defeated or (is_instance_valid(boss) and boss.state == boss.State.DYING):
		return
	_reset_fight.call_deferred()


func _reset_fight() -> void:
	if defeated:
		return
	_clear_fight()
	_set_gates(_entry_gates, false, false)
	_set_gates(_exit_gates, true, false)
	_started = false
	_spawn_boss()


func _clear_fight() -> void:
	if is_instance_valid(boss):
		boss.queue_free()
	boss = null
	for debris in get_tree().get_nodes_in_group(&"boss_debris"):
		if is_ancestor_of(debris):
			debris.queue_free()
	_bar.hide_boss()


func _spawn_boss() -> void:
	if boss_scene == null or _boss_at == Vector2.ZERO:
		return
	boss = boss_scene.instantiate()
	boss.arena_left = world_rect().position.x + 2.0 * CELL
	boss.arena_right = world_rect().end.x - 2.0 * CELL
	boss.arena_ceiling = world_rect().position.y + CELL
	_place(boss, _boss_at, BOSS_HALF_HEIGHT)
	boss.status_changed.connect(_update_bar)
	boss.defeated.connect(_on_boss_defeated)


func _start_fight() -> void:
	_started = true
	_set_gates(_entry_gates, true, true)
	_bar.show_boss(boss.display_name)
	_update_bar()
	boss.wake()


func _update_bar() -> void:
	if is_instance_valid(boss):
		_bar.set_values(boss.armor_hp, boss.armor_max(), boss.core_hp, boss.core_health)


func _on_boss_defeated() -> void:
	boss = null
	_finish(true)
	boss_defeated.emit()


func _finish(announce: bool) -> void:
	defeated = true
	_bar.hide_boss()
	_set_gates(_entry_gates, false, announce)
	_set_gates(_exit_gates, false, announce)
	var pickup := AbilityPickupScene.instantiate()
	pickup.ability_id = reward_ability
	_place(pickup, _reward_at, PICKUP_HALF_HEIGHT)


func _make_gate(at: Vector2) -> Node:
	var gate := GateScene.instantiate()
	gate.position = at - global_position
	add_child(gate)
	return gate


func _set_gates(gates: Array[Node], closed: bool, animate: bool) -> void:
	if animate and not gates.is_empty():
		Sfx.play(&"gate_close" if closed else &"gate_open", gates[0].global_position, -4.0)
	for gate in gates:
		gate.set_closed(closed, animate)
