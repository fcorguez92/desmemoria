extends CharacterBody2D
## Lo que comparten los jefes (game/boss): buscar al jugador, temblor de cámara, mirar
## si hay suelo, y "traspasar" al jugador cuando el jefe cae encima de él para que no
## se quede subido a su cabeza. Salió del Centinela al construir a Jacinto; solo
## contiene lo que usan los dos. Cada jefe pone su pelea (estados, ataques, fases).

## Mientras salta y justo después de caer no choca con el jugador (ni el jugador con él).
var _ghosted: CollisionObject2D


func _exit_tree() -> void:
	if is_instance_valid(_ghosted):
		_ghosted.remove_collision_exception_with(self)


func _player() -> Node2D:
	return get_tree().get_first_node_in_group("player") as Node2D


## Distancia horizontal al jugador (INF si no hay).
func _distance_to_player() -> float:
	var player := _player()
	return absf(player.global_position.x - global_position.x) if player else INF


## Y de los pies del jugador (mide 48 de alto).
func player_feet_y(player: Node2D) -> float:
	return player.global_position.y + 24.0


func _shake(strength: float, duration: float) -> void:
	var player := _player()
	if player and player.get("screen_shake") != null:
		player.screen_shake.shake(strength, duration)


## ¿Hay suelo (no un cuerpo con movimiento) justo bajo `(x, y)`?
func _has_ground(x: float, y: float) -> bool:
	var start := Vector2(x, y - 10.0)
	var space := get_world_2d().direct_space_state
	for i in 4:
		var query := PhysicsRayQueryParameters2D.create(start, Vector2(x, y + 24.0), 1, [get_rid()])
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return false
		if not hit.collider is CharacterBody2D:
			return true
		start = hit.position + Vector2(0.0, 2.0)
	return false


## Y del primer suelo (o tablón) por debajo de `(x, from_y)`, saltándose a los cuerpos
## con movimiento; `fallback` si no hay nada.
func _floor_below(x: float, from_y: float, fallback: float) -> float:
	var space := get_world_2d().direct_space_state
	var start := Vector2(x, from_y)
	for i in 6:
		var query := PhysicsRayQueryParameters2D.create(start, Vector2(x, start.y + 2000.0), 1, [get_rid()])
		var hit := space.intersect_ray(query)
		if hit.is_empty():
			return fallback
		if not hit.collider is CharacterBody2D:
			return hit.position.y
		start = hit.position + Vector2(0.0, 2.0)
	return fallback


## Deja de chocar con el jugador (en los dos sentidos) hasta separarse de él.
func _ghost(player: Node2D) -> void:
	if player is CollisionObject2D and _ghosted == null:
		_ghosted = player
		add_collision_exception_with(player)
		player.add_collision_exception_with(self)


## Mientras el jugador "traspasado" siga solapado con el jefe (de `half_width` x
## `half_height`, con `separation` de margen) devuelve el lado (-1 o 1) hacia el que el
## jefe debe apartarse; `fallback_side` si están justo uno sobre otro. Cuando ya no se
## tocan, vuelven a chocar y devuelve 0.
func _ghost_push(half_width: float, half_height: float, separation: float, fallback_side: int) -> int:
	if _ghosted == null:
		return 0
	var offset := _ghosted.global_position - global_position
	if absf(offset.x) < half_width + separation and absf(offset.y) < half_height + 30.0:
		return -int(signf(offset.x)) if offset.x != 0.0 else fallback_side
	remove_collision_exception_with(_ghosted)
	_ghosted.remove_collision_exception_with(self)
	_ghosted = null
	return 0
