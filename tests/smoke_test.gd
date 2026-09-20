extends SceneTree
## Prueba de humo: comprueba los contratos de core/ y el ciclo jugable de
## game/ cargando el nivel de prueba real, sin ventana ni intervención manual.
##
## Ejecutar desde la raíz del proyecto:
##   godot --headless --path . --script res://tests/smoke_test.gd
## Sale con código 0 si todo pasa y con 1 si algo falla.
##
## Notas:
## - Al teletransportar cuerpos hay que esperar varios frames de físicas para
##   que el motor detecte solapamientos; por eso los `_wait()`.
## - Si el jugador muere sin haberse alejado de su punto de reaparición, el Eco
##   nace bajo sus pies y lo recoge al instante; por eso `_stand_at()`.

const LEVEL := "res://game/levels/test_level.tscn"

var _failures: int = 0
var _level: Node
var _player: Node


func _init() -> void:
	await _run()
	print("\n%s (%d fallos)" % ["TODO OK" if _failures == 0 else "HAY FALLOS", _failures])
	quit(1 if _failures > 0 else 0)


func _run() -> void:
	await _test_health_and_healing()
	await _test_death_drops_echo_at_last_ground()
	await _test_fall_kills_and_second_death_replaces_echo()
	await _test_echo_pickup_returns_ecos()
	await _test_checkpoint_heals_and_moves_respawn()
	await _test_enemy_reward_and_contact_damage()
	await _test_enemies_respawn_on_rest_and_death()
	await _test_weapon_upgrade_at_anchor()
	await _test_dash_gates_the_far_platform()


# --- Tests -------------------------------------------------------------------

func _test_health_and_healing() -> void:
	await _fresh_level("Vida, invulnerabilidad y curación")
	var health: HealthComponent = _player.health
	_check(health.health == 5, "empieza con vida completa")
	_player.take_hit(1, 0)
	_check(health.health == 4, "un golpe quita 1 de vida")
	_player.take_hit(1, 0)
	_check(health.health == 4, "invulnerable justo después de un golpe")
	_check(health.use_heal_charge(), "puede curarse con cargas y vida incompleta")
	_check(health.health == 5 and health.heal_charges == 2, "curar restaura vida y gasta 1 carga")
	_check(not health.use_heal_charge(), "no gasta carga a vida completa")


func _test_death_drops_echo_at_last_ground() -> void:
	await _fresh_level("Muerte: Eco en el último suelo y pérdida de Ecos")
	await _stand_at(330.0)
	var ground: Vector2 = _player.respawn.last_grounded_position
	_player.add_ecos(4)
	_player.global_position = Vector2(300, 100)
	_player.health.take_hit(99)
	_check(_player.ecos == 0, "los Ecos se pierden al morir")
	_check(_player.health.health == 5, "la vida se restaura al reaparecer")
	_check(is_instance_valid(_player.active_echo), "aparece un Eco")
	_check(_player.active_echo.ecos_held == 4, "el Eco guarda los Ecos perdidos")
	_check(_player.active_echo.global_position == ground, "el Eco está en el último suelo pisado")
	await _wait(10)
	_check(is_instance_valid(_player.active_echo), "el Eco sigue ahí (nadie lo destruye solo)")


func _test_fall_kills_and_second_death_replaces_echo() -> void:
	await _fresh_level("Caída al vacío y sustitución del Eco")
	await _stand_at(330.0)
	_player.add_ecos(3)
	_player.global_position.y = _player.respawn.fall_limit_y + 50.0
	await _wait(3)
	_check(_player.ecos == 0, "caer al vacío cuenta como muerte")
	var first_echo: Node = _player.active_echo
	_check(is_instance_valid(first_echo), "aparece un Eco tras la caída")
	await _stand_at(385.0)
	_player.add_ecos(7)
	_player.health.take_hit(99)
	await _wait(2)
	_check(not is_instance_valid(first_echo), "morir otra vez destruye el Eco anterior")
	_check(_player.active_echo.ecos_held == 7, "el Eco nuevo solo guarda los Ecos de la última vida")


func _test_echo_pickup_returns_ecos() -> void:
	await _fresh_level("Recoger el Eco devuelve los Ecos")
	await _wait(10)
	_player.add_ecos(5)
	_player.health.take_hit(99)
	var echo: Node = _player.active_echo
	_check(is_instance_valid(echo), "el Eco no se recoge solo al aparecer")
	_player.global_position = echo.global_position
	await _wait(30)
	_check(_player.ecos == 5, "tocar el Eco devuelve los Ecos")
	_check(_player.active_echo == null, "el Eco desaparece al recogerlo")


func _test_checkpoint_heals_and_moves_respawn() -> void:
	await _fresh_level("Checkpoint: curar, recargar y mover el respawn")
	var anchor: Node2D = _level.get_node("MemoryAnchor2")
	_player.health.health = 2
	_player.health.heal_charges = 0
	_player.global_position = anchor.global_position
	await _wait(10)
	_check(_player.health.health == 2, "acercarse al checkpoint no descansa sin pulsar interactuar")
	_check(anchor.get_node("Prompt").visible, "se muestra el aviso al estar al alcance")
	Input.action_press("interact")
	await _wait(2)
	Input.action_release("interact")
	await _wait(2)
	_check(_player.health.health == 5, "el checkpoint cura del todo")
	_check(_player.health.heal_charges == 3, "el checkpoint recarga las curaciones")
	_check(_player.respawn.spawn_position == anchor.global_position, "el checkpoint fija el respawn")
	_player.global_position = Vector2(700, 300)
	await _wait(10)
	_check(not anchor.get_node("Prompt").visible, "el aviso se oculta al alejarse")


func _test_enemy_reward_and_contact_damage() -> void:
	await _fresh_level("Enemigos: daño por contacto y recompensa")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	_player.global_position = enemy.global_position
	await _wait(10)
	_check(_player.health.health == 4, "el contacto con un enemigo daña al jugador")
	_check(is_instance_valid(enemy), "el enemigo no se daña a sí mismo")
	enemy.take_hit(1, 1)
	enemy.take_hit(1, 1)
	_check(_player.ecos == 0, "el enemigo aún no dio Ecos con vida restante")
	enemy.take_hit(1, 1)
	_check(_player.ecos == 2, "matar al enemigo da sus Ecos")
	await _wait(2)
	_check(not is_instance_valid(enemy), "el enemigo muerto se elimina")


func _test_enemies_respawn_on_rest_and_death() -> void:
	await _fresh_level("Los enemigos reaparecen al descansar y al morir")
	var spawner: EntitySpawner = _level.get_node("EnemySpawn1")

	var killed: Node = spawner.instance
	for i in 3:
		killed.take_hit(1, 1)
	await _wait(2)
	_check(not is_instance_valid(killed), "el enemigo muerto no está")
	_player.rest_at(_player.global_position)
	await _wait(3)
	_check(is_instance_valid(spawner.instance) and spawner.instance != killed, "reaparece al descansar")
	_check(spawner.instance.health.health == 3, "reaparece con vida completa")

	var wounded: Node = spawner.instance
	wounded.take_hit(1, 1)
	_check(wounded.health.health == 2, "el enemigo herido pierde vida")
	await _stand_at(330.0)
	_player.health.take_hit(99)
	await _wait(3)
	_check(spawner.instance != wounded and not is_instance_valid(wounded), "al morir el jugador se reemplaza al enemigo herido")
	_check(spawner.instance.health.health == 3, "el enemigo nuevo tiene la vida completa")
	_check(spawner.instance.global_position == spawner.global_position, "reaparece en su posición original")

	var count := 0
	for child in _level.get_children():
		if child is EntitySpawner and is_instance_valid(child.instance):
			count += 1
	_check(count == 3, "los tres generadores tienen un enemigo vivo")


func _test_weapon_upgrade_at_anchor() -> void:
	await _fresh_level("Mejora del Filo con Ecos")
	var weapon: TieredUpgrade = _player.weapon
	_check(weapon.level == 0 and _player.melee.damage == 1, "el Filo empieza en el nivel 1 con daño 1")

	_player.add_ecos(3)
	_check(not _player.try_upgrade_weapon(), "no se puede mejorar sin Ecos suficientes")
	_check(_player.ecos == 3 and weapon.level == 0, "una mejora fallida no cobra nada")
	_check("te faltan 1" in _player.upgrade_prompt(), "el aviso indica cuántos Ecos faltan")

	_player.add_ecos(1)
	_check(_player.try_upgrade_weapon(), "se puede mejorar con Ecos suficientes")
	_check(_player.ecos == 0 and weapon.level == 1, "mejorar cobra el coste y sube un nivel")
	_check(_player.melee.damage == 2, "el ataque usa el daño del nuevo nivel")

	_player.health.take_hit(99)
	await _wait(2)
	_check(weapon.level == 1 and _player.melee.damage == 2, "morir no pierde las mejoras")

	# Desde el Ancla: la tecla de mejora funciona solo estando al alcance.
	var anchor: Node2D = _level.get_node("MemoryAnchor2")
	_player.add_ecos(8)
	Input.action_press("upgrade")
	await _wait(2)
	Input.action_release("upgrade")
	_check(weapon.level == 1, "la mejora no funciona lejos de un Ancla")
	_player.global_position = anchor.global_position
	await _wait(10)
	_check("Mejorar el Filo" in anchor.get_node("Prompt").text, "el Ancla muestra la opción de mejora")
	Input.action_press("upgrade")
	await _wait(2)
	Input.action_release("upgrade")
	await _wait(2)
	_check(weapon.level == 2 and _player.ecos == 0, "la tecla de mejora en el Ancla mejora el Filo")

	while not weapon.is_max():
		weapon.advance()
	_player.add_ecos(100)
	_check(not _player.try_upgrade_weapon(), "no se puede pasar del nivel máximo")
	_check(_player.melee.damage == 5, "el nivel máximo da el daño máximo")
	_check(_player.upgrade_prompt() == "El Filo está al máximo", "el aviso indica que está al máximo")


func _test_dash_gates_the_far_platform() -> void:
	# Mismo salto hacia el hueco final, con y sin dash a media altura.
	var reached_with_dash := await _jump_across_gap(true)
	var reached_without_dash := await _jump_across_gap(false)
	print("\n[Dash bloquea el hueco final]")
	_check(reached_with_dash, "saltar + dash alcanza la plataforma final")
	_check(not reached_without_dash, "saltar sin dash no alcanza la plataforma final")


func _jump_across_gap(use_dash: bool) -> bool:
	await _fresh_level("", false)
	_player.global_position = Vector2(1140, 210)
	_player.velocity = Vector2.ZERO
	Input.action_press("ui_right")
	await physics_frame
	Input.action_press("ui_accept")
	await physics_frame
	Input.action_release("ui_accept")
	var dashed := not use_dash
	for i in 90:
		await physics_frame
		if not dashed and _player.velocity.y > -50.0:
			Input.action_press("dash")
			await physics_frame
			Input.action_release("dash")
			dashed = true
	Input.action_release("ui_right")
	# Si cayó, murió (hay Eco) y reapareció lejos; si cruzó, sigue en la plataforma.
	return _player.active_echo == null and _player.global_position.x > 1430.0


# --- Utilidades --------------------------------------------------------------

func _fresh_level(title: String, announce: bool = true) -> void:
	if is_instance_valid(_level):
		_level.queue_free()
		await process_frame
	_level = load(LEVEL).instantiate()
	root.add_child(_level)
	await process_frame
	await process_frame
	_player = get_first_node_in_group("player")
	if announce:
		print("\n[%s]" % title)


## Coloca al jugador sobre el suelo inicial en `x` y espera a que lo pise, para
## que su "último suelo" sea ese punto y no el de reaparición.
func _stand_at(x: float) -> void:
	_player.global_position = Vector2(x, 330.0)
	_player.velocity = Vector2.ZERO
	await _wait(15)


func _wait(physics_frames: int) -> void:
	for i in physics_frames:
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok    %s" % description)
	else:
		print("  FALLA %s" % description)
		_failures += 1
