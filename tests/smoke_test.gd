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
	await _test_enemy_reward()
	await _test_enemy_patrols_and_respects_ledges()
	await _test_enemy_chases_telegraphs_and_hits()
	await _test_enemy_attack_can_be_dodged_and_interrupted()
	await _test_enemies_respawn_on_rest_and_death()
	await _test_weapon_upgrade_at_anchor()
	await _test_ability_pickups()
	await _test_dash_gates_the_far_platform()
	await _test_double_jump_reaches_high_platform()


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


func _test_enemy_reward() -> void:
	await _fresh_level("Enemigos: vida y recompensa", true, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	enemy.take_hit(1, 1)
	enemy.take_hit(1, 1)
	_check(_player.ecos == 0, "el enemigo aún no dio Ecos con vida restante")
	enemy.take_hit(1, 1)
	_check(_player.ecos == 2, "matar al enemigo da sus Ecos")
	await _wait(2)
	_check(not is_instance_valid(enemy), "el enemigo muerto se elimina")


func _test_enemy_patrols_and_respects_ledges() -> void:
	await _fresh_level("IA: patrulla sin caerse de los bordes", true, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	var home_x := enemy.global_position.x
	var min_x := home_x
	var max_x := home_x
	for i in 240:
		await physics_frame
		min_x = minf(min_x, enemy.global_position.x)
		max_x = maxf(max_x, enemy.global_position.x)
	var reach: float = enemy.ai.patrol_distance + 6.0
	_check(max_x - min_x > 20.0, "el enemigo patrulla (se mueve)")
	_check(min_x >= home_x - reach and max_x <= home_x + reach, "la patrulla no se aleja de su zona")

	# Con el origen pegado al borde derecho del suelo (880), patrullar hacia
	# allí lo llevaría al vacío: el sondeo de bordes debe frenarlo.
	enemy.global_position = Vector2(850, 356)
	enemy.ai._home_x = 850.0
	var fell := false
	for i in 300:
		await physics_frame
		if enemy.global_position.y > 400.0:
			fell = true
	_check(not fell, "el enemigo no se cae por el borde del suelo")


func _test_enemy_chases_telegraphs_and_hits() -> void:
	await _fresh_level("IA: persecución, aviso y golpe con retroceso", true, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	_player.global_position = Vector2(660, 330)
	var start_x := 660.0
	var windup_frames := 0
	var saw_windup := false
	for i in 150:
		await physics_frame
		if _player.health.health < 5:
			break
		if enemy.ai.state == PatrolChaseAI.State.WINDUP:
			saw_windup = true
			windup_frames += 1
	await _wait(3)
	_check(saw_windup, "el enemigo avisa antes de atacar")
	_check(windup_frames >= 20, "el aviso dura lo bastante para reaccionar")
	_check(_player.health.health == 4, "el ataque acaba dañando al jugador")
	_check(_player.global_position.x < start_x, "el golpe empuja al jugador lejos del enemigo")


func _test_enemy_attack_can_be_dodged_and_interrupted() -> void:
	await _fresh_level("IA: el ataque se puede esquivar e interrumpir", true, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	_player.global_position = Vector2(660, 330)
	while enemy.ai.state != PatrolChaseAI.State.WINDUP:
		await physics_frame
	_player.global_position = Vector2(600, 330)
	await _wait(35)
	_check(_player.health.health == 5, "alejarse durante el aviso esquiva el golpe")

	await _fresh_level("", false, true, "EnemySpawn1")
	enemy = _level.get_node("EnemySpawn1").instance
	_player.global_position = Vector2(660, 330)
	while enemy.ai.state != PatrolChaseAI.State.WINDUP:
		await physics_frame
	var x_before := enemy.global_position.x
	enemy.take_hit(1, 1)
	await _wait(10)
	_check(enemy.global_position.x > x_before + 10.0, "un golpe recibido empuja al enemigo")
	_check(enemy.ai.state == PatrolChaseAI.State.RECOVER, "un golpe recibido cancela su ataque")
	await _wait(25)
	_check(_player.health.health == 5, "el ataque interrumpido no daña")


func _test_enemies_respawn_on_rest_and_death() -> void:
	await _fresh_level("Los enemigos reaparecen al descansar y al morir", true, true)
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
	_player.health.take_hit(99)
	await _wait(3)
	_check(spawner.instance != wounded and not is_instance_valid(wounded), "al morir el jugador se reemplaza al enemigo herido")
	_check(spawner.instance.health.health == 3, "el enemigo nuevo tiene la vida completa")
	_check(spawner.instance.global_position.distance_to(spawner.global_position) < 30.0, "reaparece junto a su posición original")

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
	var reached_with_dash := await _jump_across_gap(true, true)
	var reached_pressing_locked := await _jump_across_gap(true, false)
	var reached_without_dash := await _jump_across_gap(false, true)
	print("\n[El dash abre el hueco final]")
	_check(reached_with_dash, "saltar + dash alcanza la plataforma final")
	_check(not reached_pressing_locked, "pulsar dash sin haberlo conseguido no sirve")
	_check(not reached_without_dash, "saltar sin dash no alcanza la plataforma final")


func _test_ability_pickups() -> void:
	await _fresh_level("Habilidades: se consiguen con objetos")
	_check(not _player.dash.unlocked, "el dash empieza bloqueado")
	_check(_player.motor.max_air_jumps == 0, "el doble salto empieza bloqueado")
	var pickup: Node2D = _level.get_node("DashPickup")
	_player.global_position = pickup.global_position
	await _wait(10)
	_check(_player.dash.unlocked, "recoger el objeto desbloquea el dash")
	_check(not is_instance_valid(pickup), "el objeto desaparece al recogerlo")
	_check("Dash" in _player.message_label.text, "se muestra un mensaje con la habilidad")
	_player.health.take_hit(99)
	await _wait(2)
	_check(_player.dash.unlocked, "morir no pierde las habilidades")


func _test_double_jump_reaches_high_platform() -> void:
	var reached_with := await _reach_high_platform(true)
	var reached_without := await _reach_high_platform(false)
	print("\n[El doble salto abre la plataforma alta]")
	_check(reached_with, "con doble salto se alcanza la plataforma alta")
	_check(not reached_without, "sin doble salto no se alcanza")


func _reach_high_platform(double_jump: bool) -> bool:
	await _fresh_level("", false)
	if double_jump:
		_player.unlock_ability(&"double_jump")
	_player.global_position = Vector2(1700, 200)
	_player.velocity = Vector2.ZERO
	Input.action_press("ui_right")
	await physics_frame
	# Se mantiene el salto pulsado hasta el punto más alto: soltarlo antes
	# lo acortaría (salto de altura variable).
	Input.action_press("ui_accept")
	for i in 10:
		await physics_frame
	while _player.velocity.y < -50.0:
		await physics_frame
	Input.action_release("ui_accept")
	# Sin ventana, "acaba de soltarse" dura varios pasos de físicas y acortaría
	# también el segundo salto; se espera a que caduque antes de volver a pulsar.
	for i in 4:
		await physics_frame
	Input.action_press("ui_accept")
	var landed_on_platform := false
	for i in 100:
		await physics_frame
		# Si se sigue avanzando, se cae por el otro extremo: se comprueba al aterrizar.
		if _player.is_on_floor() and _player.global_position.y < -40.0 and _player.global_position.x > 1900.0:
			landed_on_platform = true
			break
	Input.action_release("ui_accept")
	Input.action_release("ui_right")
	return landed_on_platform


func _jump_across_gap(press_dash: bool, dash_unlocked: bool) -> bool:
	await _fresh_level("", false)
	if dash_unlocked:
		_player.unlock_ability(&"dash")
	_player.global_position = Vector2(1140, 210)
	_player.velocity = Vector2.ZERO
	Input.action_press("ui_right")
	await physics_frame
	Input.action_press("ui_accept")
	await physics_frame
	Input.action_release("ui_accept")
	var dashed := not press_dash
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

## Carga el nivel de prueba desde cero. Por defecto SIN enemigos, para que no
## interfieran con pruebas de otras cosas; los tests de enemigos los piden.
## `only_spawner` deja solo ese generador de enemigos (por nombre), para que los
## demás no ataquen al jugador durante una prueba de IA concreta.
func _fresh_level(title: String, announce: bool = true, with_enemies: bool = false, only_spawner: String = "") -> void:
	if is_instance_valid(_level):
		_level.queue_free()
		await process_frame
	_level = load(LEVEL).instantiate()
	for child in _level.get_children():
		if child is EntitySpawner and (not with_enemies or (only_spawner != "" and child.name != only_spawner)):
			child.free()
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
