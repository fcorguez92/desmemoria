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
const WORLD := "res://game/levels/world.tscn"
## Partida de las pruebas: nunca la de quien juega.
const TEST_SAVE := "user://partida_pruebas.json"

var _failures: int = 0
var _level: Node
var _player: Node
## El Último Umbral dentro del mundo (ver `_load_world()`).
var _room: Node


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
	await _test_attack_feedback()
	await _test_hit_stop()
	await _test_parry()
	await _test_sprites_and_animations()
	await _test_enemies_respawn_on_rest_and_death()
	await _test_weapon_upgrade_at_anchor()
	await _test_anchor_menu_keyboard_and_pause()
	await _test_pause_menu()
	await _test_ability_pickups()
	await _test_dash_gates_the_far_platform()
	await _test_double_jump_reaches_high_platform()
	await _test_wall_slide_and_wall_jump()
	await _test_wall_jump_opens_the_shaft()
	await _test_ultimo_umbral_builds_from_text_map()
	await _test_planks_are_one_way_platforms()
	await _test_breakable_props()
	await _test_inscription_is_readable()
	await _test_enemy_does_not_jitter_against_a_wall()
	await _test_map_data()
	await _test_world_is_made_of_connected_rooms()
	await _test_walking_into_the_next_room()
	await _test_the_gap_drops_into_the_cistern()
	await _test_dash_crosses_the_terraces_gap()
	await _test_climbing_back_out_of_the_cistern()
	await _test_tower_needs_double_jump()
	await _test_minimap_and_pause_map()
	await _test_save_slot()
	await _test_autosave_triggers()
	await _test_loading_restores_progress()
	await _test_new_game_from_pause()
	SaveSlot.new(TEST_SAVE).erase()


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
	_check(_player.anchor_menu.is_open(), "descansar abre el menú del Ancla")
	_player.anchor_menu.close()
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
	# La animación de golpe dura 0.25 s nominales (bastante más que lo que tarda
	# en llegar esta comprobación), así que es segura aunque el hit stop la
	# ralentice un poco. El propio hit stop (0.06 s en tiempo real) se prueba
	# aparte, en _test_hit_stop(), donde no compite con ningún otro _wait().
	_check(_player.animator.current == "hit", "el jugador reproduce su animación de recibir un golpe")
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


func _test_attack_feedback() -> void:
	await _fresh_level("Feedback visual del combate", true, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	var player_animator: SheetAnimator = _player.animator
	var camera: Camera2D = _player.get_node("Camera2D")
	_player.global_position = Vector2(665, 330)
	await _wait(12)
	Input.action_press("attack")
	await _wait(3)
	Input.action_release("attack")
	_check(player_animator.current == "attack", "atacar reproduce la animación de ataque del jugador (con la espada)")
	_check(enemy.health.health == 2, "el ataque alcanzó al enemigo")
	_check(_count_sparks() >= 1, "un golpe que alcanza deja un chispazo")
	_check(camera.position.length() > 0.0, "un golpe que alcanza sacude la cámara")
	_check(enemy.animator.current == "hit", "el enemigo reproduce su animación de recibir un golpe")
	await _wait(30)
	_check(player_animator.current != "attack", "tras el ataque el jugador recupera sus animaciones de movimiento")
	_check(camera.position == Vector2.ZERO, "el temblor termina y la cámara vuelve a su sitio")
	_check(enemy.animator.current in ["idle", "walk"], "el enemigo recupera sus animaciones de movimiento tras encajar el golpe")

	await _fresh_level("", false, true, "EnemySpawn1")
	enemy = _level.get_node("EnemySpawn1").instance
	var enemy_animator: SheetAnimator = enemy.animator
	_player.global_position = Vector2(660, 330)
	while enemy.ai.state != PatrolChaseAI.State.WINDUP:
		await physics_frame
	await _wait(4)
	_check(enemy_animator.current == "windup", "el enemigo alza el arma durante el aviso")
	while enemy.ai.state != PatrolChaseAI.State.RECOVER:
		await physics_frame
	await _wait(1)
	_check(enemy_animator.current == "strike", "al caer el golpe el enemigo reproduce su animación de golpe")
	await _wait(25)
	_check(enemy_animator.current in ["idle", "walk"], "tras golpear, el enemigo recupera sus animaciones de movimiento")


## HitStop aparte de cualquier combate real: así su margen de tiempo (medido en
## segundos reales, no en fotogramas de física) no compite con ningún otro _wait().
func _test_hit_stop() -> void:
	print("\n[HitStop: pausa breve del tiempo al golpear]")
	_check(Engine.time_scale == 1.0, "el tiempo empieza a velocidad normal")
	HitStop.trigger(_player, 0.06, 0.05)
	_check(Engine.time_scale == 0.05, "activarlo escala el tiempo de inmediato, sin esperar a nada")
	await _wait(10)
	_check(Engine.time_scale == 1.0, "y lo restaura solo pasada su duración (aquí, con margen de sobra)")

	# Dos golpes seguidos: el segundo manda; cuando el primero termina su espera
	# (hacia el tick 6 desde que empezó), no debe restaurar el tiempo encima del
	# segundo (que empezó 3 ticks más tarde y sigue corriendo hasta el tick 9).
	HitStop.trigger(_player, 0.10, 0.05)
	await _wait(3)
	HitStop.trigger(_player, 0.10, 0.05)
	await _wait(4)
	_check(Engine.time_scale == 0.05, "un segundo golpe durante la pausa la alarga en vez de cortarla")
	await _wait(6)
	_check(Engine.time_scale == 1.0, "y al final ambos golpes dejan el tiempo restaurado")


func _test_parry() -> void:
	await _fresh_level("Parry: ventana, golpes frontales y aturdimiento", true, true, "EnemySpawn1")
	var parry: ParryComponent = _player.parry
	_check(_player.hud.heal_flasks.count == _player.health.heal_charges and _player.hud.heal_flasks.max_count == _player.health.max_heal_charges, "el HUD muestra los frascos de curación")
	_check(not parry.try_deflect(-1, 1), "sin abrir la guardia no se desvía nada")
	_check(parry.try_start(), "se puede abrir la guardia")
	_check(not parry.try_start(), "no se puede reabrir con la guardia ya abierta")
	_check(not parry.try_deflect(1, 1), "un golpe por la espalda no se desvía")
	_check(parry.try_deflect(-1, 1), "un golpe frontal se desvía")
	_check(not parry.is_active, "desviar consume la ventana")
	await _wait(60)
	_check(parry.try_start(), "pasado el enfriamiento se puede volver a parar")
	await _wait(20)
	_check(not parry.is_active, "la ventana se cierra sola si nadie ataca")

	# Parry a tiempo contra un ataque real.
	await _fresh_level("", false, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	_player.global_position = Vector2(660, 330)
	while enemy.ai.state != PatrolChaseAI.State.WINDUP:
		await physics_frame
	# Se pulsa cuando ya queda poco para que caiga el golpe.
	while enemy.ai._timer > 0.1:
		await physics_frame
	Input.action_press("parry")
	await _wait(2)
	Input.action_release("parry")
	_check(_player.animator.current == "parry", "al parar se reproduce la pose de guardia")
	await _wait(10)
	_check(_player.health.health == 5, "un parry a tiempo evita el daño")
	_check(enemy.ai.state == PatrolChaseAI.State.RECOVER and enemy._stun_timer > 0.0, "el enemigo queda aturdido")
	# Contraataque: mientras está aturdido recibe doble daño.
	Input.action_press("attack")
	await _wait(3)
	Input.action_release("attack")
	_check(enemy.health.health == 1, "el aturdido recibe doble daño (3 de vida - 2 = 1)")

	# Un parry demasiado pronto no salva: la ventana se cierra antes del golpe.
	await _fresh_level("", false, true, "EnemySpawn1")
	enemy = _level.get_node("EnemySpawn1").instance
	_player.global_position = Vector2(660, 330)
	while enemy.ai.state != PatrolChaseAI.State.WINDUP:
		await physics_frame
	Input.action_press("parry")
	await _wait(2)
	Input.action_release("parry")
	for i in 60:
		await physics_frame
		if _player.health.health < 5:
			break
	_check(_player.health.health == 4, "un parry demasiado pronto no evita el golpe")


func _test_sprites_and_animations() -> void:
	await _fresh_level("Sprites y animaciones", true, true, "EnemySpawn1")
	var enemy: Node2D = _level.get_node("EnemySpawn1").instance
	var player_sprite: Sprite2D = _player.visual
	var enemy_sprite: Sprite2D = enemy.visual
	_check(player_sprite.texture.get_size() == Vector2(player_sprite.hframes * 64, player_sprite.vframes * 56), "la hoja del jugador cuadra con su cuadrícula de 64x56")
	_check(enemy_sprite.texture.get_size() == Vector2(enemy_sprite.hframes * 64, enemy_sprite.vframes * 56), "la hoja del enemigo cuadra con su cuadrícula de 64x56")

	await _wait(15)
	_check(_player.animator.current == "idle", "quieto en el suelo usa la animación de reposo")
	Input.action_press("ui_right")
	await _wait(10)
	Input.action_release("ui_right")
	_check(_player.animator.current == "run", "andando usa la animación de correr")
	_check(player_sprite.frame >= player_sprite.hframes and player_sprite.frame < player_sprite.hframes * 2, "correr muestra fotogramas de la segunda fila de la hoja")

	Input.action_press("ui_accept")
	await _wait(6)
	Input.action_release("ui_accept")
	_check(_player.animator.current == "jump", "subiendo usa la animación de salto")
	await _wait(60)
	_check(_player.animator.current in ["idle", "run"], "al aterrizar vuelve a reposo o correr")

	await _wait(30)
	_check(enemy.animator.current in ["idle", "walk"], "el enemigo usa una de sus animaciones")


func _test_enemies_respawn_on_rest_and_death() -> void:
	await _fresh_level("Los enemigos reaparecen al descansar y al morir", true, true)
	var spawner: EntitySpawner = _level.get_node("EnemySpawn1")

	var killed: Node = spawner.instance
	for i in 3:
		killed.take_hit(1, 1)
	await _wait(2)
	_check(not is_instance_valid(killed), "el enemigo muerto no está")
	_player.rest_at(_player.global_position)
	_player.anchor_menu.close()
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

	_player.add_ecos(1)
	_check(_player.try_upgrade_weapon(), "se puede mejorar con Ecos suficientes")
	_check(_player.ecos == 0 and weapon.level == 1, "mejorar cobra el coste y sube un nivel")
	_check(_player.melee.damage == 2, "el ataque usa el daño del nuevo nivel")

	_player.health.take_hit(99)
	await _wait(2)
	_check(weapon.level == 1 and _player.melee.damage == 2, "morir no pierde las mejoras")

	# Desde el menú del Ancla: la primera opción mejora el Filo y cobra.
	var options: MenuList = _player.anchor_menu.menu
	_player.add_ecos(8)
	_player.rest_at(_player.global_position)
	_check(options.activate(), "la opción de mejorar está activa con Ecos suficientes")
	_check(weapon.level == 2 and _player.ecos == 0, "elegir mejorar en el menú sube el Filo y cobra")
	_check(not options.activate(), "sin Ecos la opción de mejora queda desactivada")
	_player.anchor_menu.close()

	while not weapon.is_max():
		weapon.advance()
	_player.add_ecos(100)
	_check(not _player.try_upgrade_weapon(), "no se puede pasar del nivel máximo")
	_check(_player.melee.damage == 5, "el nivel máximo da el daño máximo")
	_player.rest_at(_player.global_position)
	options.selected = 0
	_check(not options.activate(), "al máximo la opción de mejora queda desactivada")
	_player.anchor_menu.close()


func _test_anchor_menu_keyboard_and_pause() -> void:
	await _fresh_level("Menú del Ancla: pausa y teclado")
	var menu = _player.anchor_menu
	_player.add_ecos(6)
	_check(not menu.is_open() and not paused, "el menú empieza cerrado y el juego sin pausa")
	_player.rest_at(_player.global_position)
	_check(menu.is_open() and paused, "descansar abre el menú y pausa el juego")
	var before: Vector2 = _player.global_position
	_player.velocity = Vector2(300, 0)
	await _wait(10)
	_check(_player.global_position == before, "con el menú abierto el jugador no se mueve")

	var panel: Control = menu.get_node("Root/Panel")
	var size_before := panel.size
	var rows_before: int = menu.menu.get_child_count()
	await _press_action("ui_down")
	_check(menu.menu.selected == 1, "la flecha abajo mueve la selección")
	_check(panel.size == size_before, "el tamaño del menú no cambia al mover la selección")
	_check(menu.menu.get_child_count() == rows_before, "mover la selección no duplica filas (ni un frame)")
	await _press_action("ui_down")
	_check(menu.menu.selected == 0, "la selección da la vuelta")
	await _press_action("ui_cancel")
	_check(not menu.is_open() and not paused, "Esc cierra el menú y reanuda el juego")

	_player.rest_at(_player.global_position)
	await _press_action("interact")
	_check(not menu.is_open() and not paused, "volver a pulsar Z cierra el menú")

	_player.rest_at(_player.global_position)
	await _wait(30)
	var standing_y: float = _player.global_position.y
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(not menu.is_open() and not paused, "la opción Salir cierra el menú")
	var highest_y := standing_y
	for i in 30:
		await physics_frame
		highest_y = minf(highest_y, _player.global_position.y)
	_check(highest_y > standing_y - 5.0, "aceptar Salir no hace saltar al personaje")

	# Lo mismo con Z estando junto al Ancla: abrir y cerrar con Z no debe reabrir el menú.
	var anchor: Node2D = _level.get_node("MemoryAnchor2")
	_player.global_position = anchor.global_position
	_player.velocity = Vector2.ZERO
	await _wait(15)
	await _press_action("interact")
	await _wait(5)
	_check(menu.is_open(), "Z junto al Ancla abre el menú")
	await _press_action("interact")
	await _wait(15)
	_check(not menu.is_open() and not paused, "cerrar con Z cierra el menú y no lo reabre")
	# Sin Ecos suficientes, la mejora sale atenuada y el cursor empieza en Salir.
	_player.ecos = 0
	_player.rest_at(_player.global_position)
	_check(menu.menu.selected == 1, "sin Ecos el cursor empieza en la primera opción disponible")
	await _press_action("ui_accept")
	_check(not menu.is_open() and not paused, "Intro sobre la opción disponible funciona a la primera")


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
	_check("Dash" in _player.hud.message_label.text, "se muestra un mensaje con la habilidad")
	_check(_player.hud.message_box.visible, "el recuadro del mensaje se muestra mientras hay texto")
	await _wait(int(_player.MESSAGE_SECONDS * 60) + 5)
	_check(not _player.hud.message_box.visible, "el recuadro se oculta al desaparecer el mensaje")
	_player.health.take_hit(99)
	await _wait(2)
	_check(_player.dash.unlocked, "morir no pierde las habilidades")


func _test_wall_slide_and_wall_jump() -> void:
	var with_wall := await _wall_probe(true)
	var without_wall := await _wall_probe(false)
	print("\n[Agarre y salto de pared]")
	_check(with_wall["slide_speed"] <= 125.0, "agarrado a la pared, la caída se ralentiza")
	_check(without_wall["slide_speed"] > 300.0, "sin la habilidad se cae con normalidad")
	_check(with_wall["jump_vx"] > 150.0 and with_wall["jump_vy"] < -400.0, "saltar desde la pared empuja hacia fuera y hacia arriba")
	_check(without_wall["jump_vy"] > -400.0, "sin la habilidad no hay salto de pared")


## Coloca al jugador pegado a la pared izquierda del pozo, a media altura,
## manteniendo la dirección hacia ella. Devuelve la velocidad máxima de caída
## observada y la velocidad justo tras pulsar salto.
func _wall_probe(unlocked: bool) -> Dictionary:
	await _fresh_level("", false)
	_player.unlock_ability(&"double_jump")
	if unlocked:
		_player.unlock_ability(&"wall_jump")
	_player.global_position = Vector2(2332, -250)
	_player.velocity = Vector2.ZERO
	Input.action_press("ui_left")
	var max_fall := 0.0
	for i in 8:
		await physics_frame
		max_fall = maxf(max_fall, _player.velocity.y)
	Input.action_press("ui_accept")
	await physics_frame
	await physics_frame
	var result := {"slide_speed": max_fall, "jump_vx": _player.velocity.x, "jump_vy": _player.velocity.y}
	Input.action_release("ui_accept")
	Input.action_release("ui_left")
	return result


func _test_wall_jump_opens_the_shaft() -> void:
	var reached_with := await _climb_shaft(true)
	var reached_without := await _climb_shaft(false)
	print("\n[El salto de pared abre la salida del pozo]")
	_check(reached_with, "con salto de pared se sale del pozo por arriba")
	_check(not reached_without, "sin salto de pared (ni con doble salto) no se sale")


## "Robot" que sube el pozo saltando de una pared a la otra. Devuelve true si
## llega a la plataforma superior.
func _climb_shaft(wall_jump: bool) -> bool:
	await _fresh_level("", false)
	_player.unlock_ability(&"double_jump")
	if wall_jump:
		_player.unlock_ability(&"wall_jump")
	_player.global_position = Vector2(2380, -74)
	_player.velocity = Vector2.ZERO

	var holding_jump := false
	var cooldown := 0
	var reached := false
	Input.action_press("ui_left")
	for i in 1200:
		await physics_frame
		if _player.is_on_floor() and _player.global_position.y < -440.0:
			reached = true
			break
		cooldown = maxi(cooldown - 1, 0)
		# Se suelta el salto al pasar el punto más alto, como haría una persona.
		if holding_jump and _player.velocity.y >= -50.0:
			Input.action_release("ui_accept")
			holding_jump = false
		if holding_jump or cooldown > 0:
			continue
		var on_wall: bool = _player.is_on_wall() and not _player.is_on_floor()
		if _player.is_on_floor() or on_wall:
			if on_wall:
				# Hacia la pared contraria, es decir, hacia donde apunta la normal.
				var away: int = int(signf(_player.get_wall_normal().x))
				Input.action_release("ui_left")
				Input.action_release("ui_right")
				Input.action_press("ui_right" if away > 0 else "ui_left")
			Input.action_press("ui_accept")
			holding_jump = true
			cooldown = 14
	Input.action_release("ui_accept")
	Input.action_release("ui_left")
	Input.action_release("ui_right")
	return reached


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




func _test_planks_are_one_way_platforms() -> void:
	print("\n[Los tablones se atraviesan desde abajo y se pisan desde arriba]")
	await _load_world()
	var tiles: TextTileMap = _room.tiles
	# Tejado de la cabaña: fila de tablones en las columnas 15..22.
	var roof_cell := Vector2i(18, 15)
	_check(tiles.get_cell_atlas_coords(roof_cell) == Vector2i(4, 0), "hay un tablón donde se espera (tejado de la cabaña)")
	var roof_top: float = tiles.to_global(tiles.map_to_local(roof_cell)).y - 8.0
	var ground_top: float = tiles.to_global(tiles.map_to_local(Vector2i(18, 20))).y - 8.0
	_player.global_position = Vector2(tiles.to_global(tiles.map_to_local(roof_cell)).x, ground_top - 24.0)
	_player.velocity = Vector2.ZERO
	await _wait(20)
	_check(_player.is_on_floor() and _player.global_position.y > roof_top, "de pie bajo el tejado, sin que lo toque")
	Input.action_press("ui_accept")
	await _wait(60)
	Input.action_release("ui_accept")
	await _wait(30)
	_check(_player.is_on_floor() and _player.global_position.y < roof_top, "saltando desde abajo se atraviesa el tablón y se aterriza encima")
	_player.velocity = Vector2.ZERO
	await _wait(20)
	_check(_player.is_on_floor() and _player.global_position.y < roof_top, "se puede estar de pie sobre el tablón")

	# Sobre el tablón, solo saltar sigue siendo saltar.
	var standing_y: float = _player.global_position.y
	var highest_y := standing_y
	Input.action_press("ui_accept")
	await _wait(3)
	Input.action_release("ui_accept")
	for i in 30:
		await physics_frame
		highest_y = minf(highest_y, _player.global_position.y)
	_check(highest_y < standing_y - 20.0, "sobre el tablón, saltar sin pulsar abajo salta")
	await _wait(60)
	_check(_player.is_on_floor() and _player.global_position.y < roof_top, "y se vuelve a aterrizar sobre el tablón")

	# Abajo + salto: se baja atravesándolo.
	Input.action_press("ui_down")
	Input.action_press("ui_accept")
	await _wait(3)
	Input.action_release("ui_accept")
	await _wait(60)
	Input.action_release("ui_down")
	_check(_player.is_on_floor() and _player.global_position.y > roof_top, "abajo + salto sobre el tablón lo atraviesa hacia abajo")

	# En suelo sólido, abajo + salto sigue siendo un salto.
	await _wait(20)
	var ground_y: float = _player.global_position.y
	highest_y = ground_y
	Input.action_press("ui_down")
	Input.action_press("ui_accept")
	await _wait(3)
	Input.action_release("ui_accept")
	for i in 30:
		await physics_frame
		highest_y = minf(highest_y, _player.global_position.y)
	Input.action_release("ui_down")
	_check(highest_y < ground_y - 20.0, "en suelo sólido, abajo + salto sigue saltando")




func _test_breakable_props() -> void:
	print("\n[Los objetos rompibles bloquean, se rompen y no afectan a la partida]")
	await _load_world()
	var urn: BreakableProp = null
	for child in _room.get_children():
		if child is BreakableProp:
			urn = child
			break
	_check(urn != null, "hay objetos rompibles colocados por los marcadores R")
	_check(urn.hits == 1, "por defecto se rompen de un golpe")

	# Hasta romperse, es un obstáculo físico: el jugador no lo atraviesa caminando.
	_player.global_position = urn.global_position + Vector2(-30.0, -20.0)
	_player.velocity = Vector2.ZERO
	Input.action_press("ui_right")
	await _wait(30)
	Input.action_release("ui_right")
	_check(_player.global_position.x < urn.global_position.x, "antes de romperse bloquea el paso")

	var ecos_before: int = _player.ecos
	var health_before: int = _player.health.health
	urn.take_hit(1, 1)
	await _wait(2)
	_check(not is_instance_valid(urn), "un golpe lo destruye")
	_check(_count_sparks(_room) >= 1, "al romperse deja un chispazo")
	_check(_player.ecos == ecos_before and _player.health.health == health_before, "romperlo no da Ecos ni cambia la vida: es solo decoración")

	# Después de roto, ya no bloquea: se puede caminar por donde estaba.
	var before_x: float = _player.global_position.x - 30.0
	_player.global_position = Vector2(before_x, _player.global_position.y)
	Input.action_press("ui_right")
	await _wait(30)
	Input.action_release("ui_right")
	_check(_player.global_position.x > before_x + 25.0, "una vez roto ya no bloquea el paso")




func _test_inscription_is_readable() -> void:
	print("\n[La inscripción se lee con Z, sin afectar a la partida]")
	await _load_world()
	var inscription: Readable = null
	for child in _room.get_children():
		if child is Readable:
			inscription = child
			break
	_check(inscription != null, "hay una inscripción colocada por el marcador I")
	_check(not inscription.text.is_empty(), "tiene un texto que leer")

	_player.global_position = inscription.global_position
	_player.velocity = Vector2.ZERO
	await _wait(10)
	_check(inscription.get_node("Prompt").visible, "se muestra el aviso al estar al alcance")

	var ecos_before: int = _player.ecos
	Input.action_press("interact")
	await _wait(2)
	Input.action_release("interact")
	await _wait(2)
	_check(_player.hud.message_label.text == inscription.text, "leerla muestra el texto completo en el HUD")
	_check(_player.hud.message_box.visible, "el texto se muestra en su recuadro translúcido")
	_check(not paused, "leer no pausa el juego")
	_check(_player.ecos == ecos_before, "leer no da ni quita Ecos: es solo ambientación")

	_player.global_position = Vector2(700, 300)
	await _wait(10)
	_check(not inscription.get_node("Prompt").visible, "el aviso se oculta al alejarse")



func _test_enemy_does_not_jitter_against_a_wall() -> void:
	print("\n[Un enemigo pegado a una pared se aparta en vez de vibrar]")
	await _load_world()
	var enemy: Node2D = null
	for child in _room.get_children():
		if child is EntitySpawner:
			enemy = child.instance
			break
	var flips := [0]
	enemy.ai.facing_changed.connect(func(_facing: int) -> void: flips[0] += 1)
	# Mira hacia una pared cercana (un bloque de escombros a su derecha) desde el principio.
	var min_x := enemy.global_position.x
	var max_x := enemy.global_position.x
	for i in 240:
		await physics_frame
		min_x = minf(min_x, enemy.global_position.x)
		max_x = maxf(max_x, enemy.global_position.x)
	_check(flips[0] <= 6, "el enemigo no cambia de dirección cada frame (%d cambios en 4 s)" % flips[0])
	_check(max_x - min_x > 20.0, "el enemigo sigue patrullando en vez de quedarse pegado a la pared")



func _test_pause_menu() -> void:
	await _fresh_level("Menú de pausa: abrir con Esc, personaje, controles y continuar")
	var pause = _player.pause_menu
	var options: MenuList = pause.menu
	_check(not pause.is_open(), "la pausa empieza cerrada")
	await _wait(30)
	var standing_y: float = _player.global_position.y

	await _press_action("ui_cancel")
	_check(pause.is_open() and paused, "Esc abre la pausa y detiene el juego")
	_check(pause.title_label.text == "Pausa" and options.visible, "se muestra la lista principal")
	var pause_panel: Control = pause.get_node("Root/Panel")
	var pause_size := pause_panel.size
	await _press_action("ui_cancel")
	_check(not pause.is_open() and not paused, "Esc cierra la pausa y reanuda el juego")

	# Personaje: datos y habilidades por descubrir.
	_player.add_ecos(7)
	await _press_action("ui_cancel")
	await _press_action("ui_down")
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Personaje" and pause.info.visible, "Personaje abre su pantalla")
	_check("Vida: 5 / 5" in pause.info_label.text and "Ecos: 7" in pause.info_label.text, "muestra vida y Ecos")
	_check("Filo: nivel 1 (daño 1)" in pause.info_label.text, "muestra el Filo")
	_check(pause_panel.size == pause_size, "el panel mide lo mismo en Personaje que en el menú principal")
	_check("Dash" not in pause.info_label.text and "???" in pause.info_label.text, "las habilidades sin recordar salen como ???")
	await _press_action("ui_cancel")
	_check(pause.is_open() and pause.title_label.text == "Pausa", "Esc en una subpantalla vuelve al menú, sin cerrar la pausa")

	# Controles.
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Controles" and "Moverse" in pause.actions_label.text and "Espacio" in pause.info_label.text, "Controles muestra las teclas y su acción")
	_check(pause_panel.size == pause_size, "y lo mismo en Controles")
	await _press_action("ui_accept")
	_check(pause.is_open() and pause.title_label.text == "Pausa", "Intro en una subpantalla también vuelve")

	# Con una habilidad recordada, sale su nombre. La pantalla se recompone al reabrir.
	await _press_action("ui_cancel")
	_player.unlock_ability(&"dash")
	await _press_action("ui_cancel")
	await _press_action("ui_down")
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check("Dash" in pause.info_label.text, "la habilidad recordada aparece por su nombre")
	await _press_action("ui_cancel")

	# Continuar con Intro: no debe hacer saltar al personaje.
	await _press_action("ui_up")
	await _press_action("ui_up")
	await _press_action("ui_accept")
	_check(not pause.is_open() and not paused, "Continuar cierra la pausa")
	var highest_y: float = standing_y
	for i in 30:
		await physics_frame
		highest_y = minf(highest_y, _player.global_position.y)
	_check(highest_y > standing_y - 5.0, "Continuar con Intro no hace saltar al personaje")

	# Esc con el menú del Ancla abierto no abre la pausa encima.
	_player.rest_at(_player.global_position)
	await _press_action("ui_cancel")
	_check(not pause.is_open(), "Esc con el menú del Ancla abierto no abre la pausa")
	_check(not _player.anchor_menu.is_open(), "Esc cierra el menú del Ancla")


# --- Utilidades --------------------------------------------------------------

## Carga el nivel de prueba desde cero. Por defecto SIN enemigos, para que no
## interfieran con pruebas de otras cosas; los tests de enemigos los piden.
## `only_spawner` deja solo ese generador de enemigos (por nombre), para que los


func _test_ultimo_umbral_builds_from_text_map() -> void:
	print("\n[El Último Umbral se construye desde su mapa de texto]")
	await _load_world()
	var tiles: TextTileMap = _room.tiles
	_check(tiles.get_used_rect().end == Vector2i(80, 28), "el mapa llega hasta la columna 80 y la fila 28")
	_check(_player != null, "hay un jugador colocado por el marcador P")
	var spawners := 0
	for child in _room.get_children():
		if child is EntitySpawner:
			spawners += 1
	_check(spawners == 2, "dos enemigos colocados por los marcadores E")
	var anchors := 0
	for child in _room.get_children():
		if child is Checkpoint:
			anchors += 1
	_check(anchors == 2, "dos Anclas de Memoria colocadas por los marcadores A")
	await _wait(60)
	_check(_player.is_on_floor(), "el jugador se apoya en el suelo del mapa")
	var start_x: float = _player.global_position.x
	_player.velocity.x = -600.0
	await _wait(60)
	_check(absf(_player.global_position.x - start_x) < 200.0 and _player.global_position.x > 32.0, "el muro sellado del extremo izquierdo detiene al jugador")
	# El foso (x 32..41 baldosas) no tiene suelo: caer debe matar y reaparecer.
	_player.global_position = Vector2(36.0 * 16.0, 250.0)
	_player.velocity = Vector2.ZERO
	await _wait(90)
	_check(_player.global_position.x < 32.0 * 16.0 or _player.global_position.y < 400.0, "caer al foso reaparece al jugador")


## Simula que se pulsa una acción del Mapa de entrada como un evento real (llega a
## `_unhandled_input`, a diferencia de `Input.action_press`).
func _press_action(action: StringName) -> void:
	var event := InputEventAction.new()
	event.action = action
	event.pressed = true
	Input.parse_input_event(event)
	await _wait(2)
	# Hay que soltarla: si no, la acción queda pulsada para las pruebas siguientes.
	var release := InputEventAction.new()
	release.action = action
	release.pressed = false
	Input.parse_input_event(release)
	await _wait(2)


func _fresh_level(title: String, announce: bool = true, with_enemies: bool = false, only_spawner: String = "") -> void:
	paused = false
	Engine.time_scale = 1.0
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


## Chispazos que hay ahora mismo en `parent` (por defecto, el nivel).
func _count_sparks(parent: Node = null) -> int:
	var count := 0
	for child in (parent if parent else _level).get_children():
		if child is HitSpark:
			count += 1
	return count


func _wait(physics_frames: int) -> void:
	for i in physics_frames:
		await physics_frame


func _check(condition: bool, description: String) -> void:
	if condition:
		print("  ok    %s" % description)
	else:
		print("  FALLA %s" % description)
		_failures += 1


# --- Mundo de salas y mapa -----------------------------------------------------

## Carga el mundo entero (todas las salas) desde cero, sin partida guardada
## salvo que `keep_save` pida cargar la que dejó la prueba anterior. `_room` es El Último
## Umbral, que está en el origen: sus coordenadas son las mismas que antes de
## que hubiera más salas.
func _load_world(keep_save: bool = false) -> void:
	paused = false
	Engine.time_scale = 1.0
	if is_instance_valid(_level):
		_level.queue_free()
		await process_frame
	if not keep_save:
		SaveSlot.new(TEST_SAVE).erase()
	_level = load(WORLD).instantiate()
	_level.save_path = TEST_SAVE
	root.add_child(_level)
	await process_frame
	await process_frame
	_player = get_first_node_in_group("player")
	_room = _level.get_node("Rooms/UltimoUmbral")


## Centro en el mundo de la celda (col, fila) de una sala, en píxeles.
func _cell(room_name: String, col: float, row: float) -> Vector2:
	var room: Node2D = _level.get_node("Rooms/" + room_name)
	return room.global_position + Vector2(col * 16.0 + 8.0, row * 16.0 + 8.0)


## Posición del jugador de pie sobre la baldosa (col, fila) de una sala.
func _standing_on(room_name: String, col: float, row: float) -> Vector2:
	return _cell(room_name, col, row) - Vector2(0.0, 8.0 + 24.0)


## Salto completo desde `from` hacia `direction` (-1, 0 o 1), dejando de avanzar
## al pasar `release_x`. Con `air_jump`, vuelve a saltar en lo alto del primero.
## Devuelve si acabó de pie sobre algo.
func _hop(from: Vector2, direction: int, release_x: float, air_jump: bool = false) -> bool:
	_player.global_position = from
	_player.velocity = Vector2.ZERO
	await _wait(6)
	var move := &"ui_right" if direction > 0 else &"ui_left"
	Input.action_press(&"ui_accept")
	if direction != 0:
		Input.action_press(move)
	var air_jumped := not air_jump
	var rising := false
	for i in 150:
		await physics_frame
		rising = rising or _player.velocity.y < -100.0
		if direction != 0 and (_player.global_position.x - release_x) * direction >= 0.0:
			Input.action_release(move)
		if not air_jumped and rising and _player.velocity.y > -50.0:
			Input.action_release(&"ui_accept")
			await physics_frame
			Input.action_press(&"ui_accept")
			air_jumped = true
		if i > 10 and _player.is_on_floor():
			break
	Input.action_release(&"ui_accept")
	Input.action_release(&"ui_left")
	Input.action_release(&"ui_right")
	await _wait(4)
	return _player.is_on_floor()


func _test_map_data() -> void:
	print("\n[MapData: zonas, descubrimiento, marcadores y dibujo de baldosas]")
	var data := MapData.new()
	var blank := Image.create_empty(4, 2, false, Image.FORMAT_RGBA8)
	data.add_area(&"a", "Zona A", Rect2i(0, 0, 4, 2), blank)
	data.add_area(&"b", "Zona B", Rect2i(4, 0, 4, 2), blank)
	_check(data.area_at(Vector2(5.5, 1.0)).id == &"b" and data.area_at(Vector2(20, 20)).is_empty(), "area_at encuentra la zona que contiene una celda")
	_check(not data.is_visited(&"a") and data.seen_bounds().size == Vector2i.ZERO, "las zonas empiezan sin visitar y sin nada visto")
	_check(data.visit(&"a") and not data.visit(&"a"), "visit avisa solo la primera vez")
	_check(data.seen_bounds().size == Vector2i.ZERO, "visitar una zona no descubre nada de ella")
	_check(data.reveal_around(Vector2(1.5, 0.5), 1.0), "reveal_around descubre lo que está cerca")
	_check(data.is_seen(Vector2(1.5, 0.5)) and data.is_seen(Vector2(2.5, 0.5)) and not data.is_seen(Vector2(3.5, 1.5)), "solo dentro del radio")
	_check(data.seen_bounds() == Rect2i(0, 0, 3, 2), "los límites de lo visto crecen con lo descubierto")
	_check(not data.reveal_around(Vector2(1.5, 0.5), 1.0), "volver a mirar lo ya visto no descubre nada nuevo")
	data.reveal_around(Vector2(4.0, 1.0), 1.0)
	_check(data.is_seen(Vector2(3.5, 0.5)) and data.is_seen(Vector2(4.5, 0.5)), "un mismo círculo descubre en dos zonas vecinas")
	var copy := MapData.new()
	copy.add_area(&"a", "Zona A", Rect2i(0, 0, 4, 2), blank)
	copy.add_area(&"b", "Zona B", Rect2i(4, 0, 4, 2), blank)
	copy.set_seen_data(data.get_seen_data())
	_check(copy.seen_bounds() == data.seen_bounds() and copy.is_seen(Vector2(4.5, 0.5)) and not copy.is_seen(Vector2(7.5, 1.5)), "lo visto se puede exportar e importar (para guardarlo)")
	var emitted := [0]
	data.changed.connect(func() -> void: emitted[0] += 1)
	data.set_focus(Vector2(1, 1))
	data.set_focus(Vector2(1, 1))
	data.set_marker(&"m", Vector2(2, 1), Color.RED)
	data.set_marker(&"m", Vector2(2, 1), Color.RED)
	_check(emitted[0] == 2, "repetir el mismo foco o marcador no pide redibujar")
	data.remove_marker(&"m")
	_check(not data.markers.has(&"m") and emitted[0] == 3, "remove_marker quita el marcador")

	await _load_world()
	var tiles: TextTileMap = _room.tiles
	_check(tiles.map_size == Vector2i(80, 28), "map_size mide el mapa de texto entero (80×28), cielo incluido")
	var image := MapData.image_from_layer(tiles, tiles.map_size, Color.WHITE, { Vector2i(4, 0): Color.RED })
	var solid := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a > 0.0:
				solid += 1
	_check(image.get_size() == tiles.map_size and solid == tiles.get_used_cells().size(), "el dibujo del mapa tiene un píxel por baldosa")
	_check(image.get_pixel(18, 15) == Color.RED and image.get_pixel(5, 21) == Color.WHITE, "los tablones se pintan de su propio color")


func _test_world_is_made_of_connected_rooms() -> void:
	print("\n[El mundo: varias salas conectadas, un solo jugador]")
	await _load_world()
	var rooms: Array = _level.get_node("Rooms").get_children()
	_check(rooms.size() == 4, "hay cuatro salas")
	var overlaps := false
	for i in rooms.size():
		_check(not rooms[i].title.is_empty(), "%s tiene nombre" % rooms[i].name)
		for j in range(i + 1, rooms.size()):
			if rooms[i].world_rect().intersects(rooms[j].world_rect()):
				overlaps = true
	_check(not overlaps, "ninguna sala se solapa con otra")
	_check(get_nodes_in_group("player").size() == 1, "un solo jugador en todo el mundo")
	_check(_level.current_room == _room, "se empieza en El Último Umbral")
	var data: MapData = _level.map_data
	await _wait(2)
	_check(data.is_visited(&"UltimoUmbral") and not data.is_visited(&"TerrazasSecas"), "solo se ha visitado la sala de inicio")
	_check(data.is_seen(data.focus_cell) and not data.is_seen(Vector2(74, 10)), "en el mapa solo se ve lo que rodea al jugador, no la sala entera")
	var anchors := 0
	for id in data.markers:
		if String(id).begins_with("anchor_"):
			anchors += 1
	_check(anchors == 4, "las cuatro Anclas están marcadas en el mapa (se ven al pasar cerca)")
	_check(_player.hud.message_label.text.is_empty(), "la sala de inicio no se anuncia")
	var dash_pickup := 0
	var jump_pickup := 0
	for room in rooms:
		for child in room.get_children():
			if child is AbilityPickup:
				dash_pickup += 1 if child.ability_id == &"dash" and room.name == "Cisterna" else 0
				jump_pickup += 1 if child.ability_id == &"double_jump" and room.name == "TorreDeRiego" else 0
	_check(dash_pickup == 1 and jump_pickup == 1, "el dash está en la Cisterna y el doble salto en la Torre de Riego")


func _test_walking_into_the_next_room() -> void:
	print("\n[Caminando se pasa a la sala de al lado]")
	await _load_world()
	var camera: Camera2D = _player.get_node("Camera2D")
	_check(camera.limit_left == 0 and camera.limit_right == 1280, "la cámara está limitada al Último Umbral")
	_player.global_position = Vector2(1240.0, 296.0)
	_player.velocity = Vector2.ZERO
	await _wait(5)
	Input.action_press(&"ui_right")
	await _wait(30)
	Input.action_release(&"ui_right")
	_check(_level.current_room.name == "TerrazasSecas", "al cruzar el borde se está en Las Terrazas Secas")
	_check(_player.is_on_floor() and _player.active_echo == null, "el suelo continúa sin huecos entre las dos salas")
	_check(camera.limit_left == 1280 and camera.limit_right == 1280 + 64 * 16, "la cámara pasa a limitarse a la sala nueva")
	_check(_level.map_data.is_visited(&"TerrazasSecas") and _level.map_data.is_seen(_level.map_data.focus_cell), "la sala nueva cuenta como visitada y se ve en el mapa lo que la rodea")
	_check(not _level.map_data.is_seen(Vector2(80 + 60, 10)), "pero no el resto de la sala")
	_check(_player.hud.message_label.text == "Las Terrazas Secas", "la primera vez se anuncia su nombre")
	_check(_level.sky_shown, "en las Terrazas se ve el cielo")


func _test_the_gap_drops_into_the_cistern() -> void:
	print("\n[El foso de las Terrazas no mata: se cae a la Cisterna]")
	await _load_world()
	_player.global_position = _cell("TerrazasSecas", 44, 16)
	_player.velocity = Vector2.ZERO
	await _wait(120)
	_check(_player.active_echo == null, "caer por el foso no mata")
	_check(_level.current_room.name == "Cisterna" and _player.is_on_floor(), "se aterriza en la Cisterna")
	_check(not _level.sky_shown, "bajo tierra no se ve el cielo")
	_check(_player.respawn.fall_limit_y > _player.global_position.y, "el límite de caída mortal baja con la sala")

	# En cambio, el foso del Último Umbral sigue matando.
	_player.global_position = Vector2(36.0 * 16.0, 250.0)
	_player.velocity = Vector2.ZERO
	await _wait(120)
	_check(_player.active_echo != null, "caer al foso del Último Umbral sí mata (queda un Eco)")


## Intenta saltar el foso de las Terrazas desde su borde oeste. Devuelve si se
## acaba de pie en el lado este, a la altura del suelo.
func _cross_terraces_gap(use_dash: bool) -> bool:
	await _load_world()
	if use_dash:
		_player.unlock_ability(&"dash")
	_player.global_position = _standing_on("TerrazasSecas", 28.6, 20)
	_player.velocity = Vector2.ZERO
	await _wait(6)
	Input.action_press(&"ui_right")
	Input.action_press(&"ui_accept")
	var dashed := not use_dash
	var rising := false
	for i in 120:
		await physics_frame
		# Dash en lo alto del salto, no antes de despegar.
		rising = rising or _player.velocity.y < -100.0
		if not dashed and rising and _player.velocity.y > -50.0:
			Input.action_press(&"dash")
			await physics_frame
			Input.action_release(&"dash")
			dashed = true
	Input.action_release(&"ui_accept")
	Input.action_release(&"ui_right")
	var east_lip: float = _cell("TerrazasSecas", 50, 20).x - 8.0
	return _player.is_on_floor() and _player.global_position.x > east_lip and _player.global_position.y < 320.0


## El mejor salto posible sin dash: con carrerilla y saltando en el último
## instante, ya fuera del borde (el margen de "coyote time").
func _best_jump_without_dash() -> bool:
	await _load_world()
	_player.global_position = _standing_on("TerrazasSecas", 24, 20)
	_player.velocity = Vector2.ZERO
	await _wait(6)
	Input.action_press(&"ui_right")
	var jumped := false
	for i in 150:
		await physics_frame
		if not jumped and not _player.is_on_floor():
			Input.action_press(&"ui_accept")
			jumped = true
	Input.action_release(&"ui_accept")
	Input.action_release(&"ui_right")
	var east_lip: float = _cell("TerrazasSecas", 50, 20).x - 8.0
	return jumped and _player.is_on_floor() and _player.global_position.x > east_lip and _player.global_position.y < 320.0


func _test_dash_crosses_the_terraces_gap() -> void:
	print("\n[El foso de las Terrazas solo se cruza con el dash]")
	_check(not await _cross_terraces_gap(false), "sin dash no se llega al otro lado")
	_check(not await _best_jump_without_dash(), "ni con carrerilla saltando en el último instante")
	_check(await _cross_terraces_gap(true), "con dash sí")
	_player.global_position = _standing_on("TorreDeRiego", 6, 40)
	await _wait(10)
	_check(_level.current_room.name == "TorreDeRiego", "el otro lado lleva a la Torre de Riego")


func _test_climbing_back_out_of_the_cistern() -> void:
	print("\n[De la Cisterna se sale subiendo por los tablones, y allí está el dash]")
	await _load_world()
	_player.global_position = _standing_on("Cisterna", 58, 22)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	_check(_player.has_ability(&"dash"), "tocar el objeto del fondo de la Cisterna recuerda el dash")
	# Cada salto empieza encima del escalón anterior:
	# [col de inicio, fila de inicio, dirección, col de destino, fila de destino].
	var steps := [
		[21, 22, 1, 27, 18],
		[28, 18, 1, 34, 14],
		[36, 14, 1, 42, 10],
		[41, 10, -1, 36, 6],
		[35, 6, -1, 32, 2],
	]
	for step in steps:
		var landed: bool = await _hop(_standing_on("Cisterna", step[0], step[1]), step[2], _cell("Cisterna", step[3], 0).x)
		var target_y: float = _standing_on("Cisterna", step[3], step[4]).y
		_check(landed and absf(_player.global_position.y - target_y) < 4.0, "de la fila %d se sube al tablón de la fila %d" % [step[1], step[4]])
	var out: bool = await _hop(_standing_on("Cisterna", 31, 2), -1, _cell("TerrazasSecas", 27, 0).x)
	_check(out and _level.current_room.name == "TerrazasSecas" and _player.global_position.y < 320.0, "del último tablón se sale al suelo de las Terrazas")


func _test_tower_needs_double_jump() -> void:
	print("\n[La Torre de Riego: se sube por tablones y la cornisa del Ancla pide doble salto]")
	await _load_world()
	var steps := [
		[6, 40, 1, 10, 36],
		[12, 36, 1, 18, 32],
		[17, 32, -1, 11, 28],
		[12, 28, 1, 18, 24],
		[20, 24, 1, 26, 20],
	]
	for step in steps:
		var landed: bool = await _hop(_standing_on("TorreDeRiego", step[0], step[1]), step[2], _cell("TorreDeRiego", step[3], 0).x)
		var target_y: float = _standing_on("TorreDeRiego", step[3], step[4]).y
		_check(landed and absf(_player.global_position.y - target_y) < 4.0, "de la fila %d se sube al tablón de la fila %d" % [step[1], step[4]])
	var ledge_y: float = _standing_on("TorreDeRiego", 46, 7).y
	_check(not _player.has_ability(&"double_jump"), "subiendo la escalera aún no se ha tocado el doble salto")
	await _hop(_standing_on("TorreDeRiego", 32, 20), 1, _cell("TorreDeRiego", 46, 0).x)
	_check(_player.global_position.y > ledge_y + 20.0, "sin doble salto no se llega a la cornisa")
	_player.global_position = _standing_on("TorreDeRiego", 29, 20)
	await _wait(10)
	_check(_player.has_ability(&"double_jump"), "el doble salto está sobre el tablón más alto")
	var landed: bool = await _hop(_standing_on("TorreDeRiego", 32, 20), 1, _cell("TorreDeRiego", 46, 0).x, true)
	_check(landed and absf(_player.global_position.y - ledge_y) < 4.0, "con doble salto se llega a la cornisa del Ancla")


func _test_minimap_and_pause_map() -> void:
	print("\n[Minimapa en el HUD y mapa completo en la pausa]")
	await _fresh_level("", false)
	_check(not _player.hud.minimap.visible, "sin mundo (banco de pruebas) no hay minimapa")

	await _load_world()
	var minimap: MapView = _player.hud.minimap
	var data: MapData = _level.map_data
	_check(minimap.visible and minimap.data == data, "en el mundo, el minimapa muestra el mapa del mundo")
	_check(minimap.get_global_rect().position == Vector2(16, 16), "el minimapa está en la esquina superior izquierda")
	_check(not minimap.get_global_rect().intersects(_player.hud.health_bar.get_global_rect()), "la barra de vida no lo tapa")
	_check(minimap.cell_to_view(data.focus_cell).distance_to(minimap.size / 2.0) < 1.0, "el minimapa está centrado en el jugador")

	# Morir deja el Eco marcado en el mapa.
	await _stand_at(300.0)
	_player.die()
	await _wait(3)
	_check(data.markers.has(&"echo"), "el Eco de la última muerte sale en el mapa")

	var pause = _player.pause_menu
	var pause_panel: Control = pause.get_node("Root/Panel")
	await _press_action("ui_cancel")
	var pause_size := pause_panel.size
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Mapa · El Último Umbral", "Mapa abre su pantalla con el nombre de la sala actual")
	_check(pause.map_view.visible and not pause.info.visible and not pause.menu.visible, "se ve el mapa y no la lista ni el texto")
	_check(pause_panel.size == pause_size, "el panel mide lo mismo en Mapa que en el menú principal")
	var map_view: MapView = pause.map_view
	var bounds := data.seen_bounds()
	var drawn := Vector2(bounds.size) * map_view.current_scale()
	_check(drawn.x <= map_view.size.x and drawn.y <= map_view.size.y, "el mapa completo cabe en su recuadro")
	await _press_action("ui_cancel")
	_check(pause.is_open() and pause.title_label.text == "Pausa", "Esc vuelve al menú de pausa")
	await _press_action("ui_cancel")


# --- Guardado automático -------------------------------------------------------

func _saved() -> Dictionary:
	return SaveSlot.new(TEST_SAVE).read()


func _anchor_in(room_name: String) -> Checkpoint:
	for child in _level.get_node("Rooms/" + room_name).get_children():
		if child is Checkpoint:
			return child
	return null


func _test_save_slot() -> void:
	print("\n[SaveSlot: escribir, leer, ignorar archivos rotos y borrar]")
	var slot := SaveSlot.new(TEST_SAVE)
	slot.erase()
	_check(not slot.exists() and slot.read().is_empty(), "sin archivo no hay partida")
	_check(slot.write({ a = 1, b = [2.5, 3], c = { d = "texto" } }), "se puede escribir")
	var data := slot.read()
	_check(data.a == 1 and data.b == [2.5, 3.0] and data.c.d == "texto", "se lee lo mismo que se escribió")
	_check(not FileAccess.file_exists(TEST_SAVE + ".tmp"), "no queda el archivo temporal")
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("{ esto no es json")
	file.close()
	_check(slot.read().is_empty(), "un archivo roto se ignora en vez de romper el juego")
	file = FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string(JSON.stringify({ version = SaveSlot.FORMAT_VERSION + 1, data = {} }))
	file.close()
	_check(slot.read().is_empty(), "una partida de otra versión se ignora")
	slot.erase()
	_check(not slot.exists(), "erase borra la partida")


func _test_autosave_triggers() -> void:
	print("\n[Guardado automático: al cambiar de sala, al descansar y al reaparecer]")
	await _load_world()
	await _wait(10)
	_check(not FileAccess.file_exists(TEST_SAVE), "empezar a jugar no guarda nada todavía")

	_player.global_position = Vector2(1240.0, 296.0)
	_player.velocity = Vector2.ZERO
	await _wait(5)
	Input.action_press(&"ui_right")
	await _wait(30)
	Input.action_release(&"ui_right")
	_check("TerrazasSecas" in _saved().get("rooms", []), "al pasar a otra sala se guarda, con la sala descubierta")

	SaveSlot.new(TEST_SAVE).erase()
	var anchor := _anchor_in("TerrazasSecas") if _anchor_in("TerrazasSecas") else _anchor_in("UltimoUmbral")
	_player.rest_at(anchor.global_position)
	await _wait(2)
	var spawn: Array = _saved().get("player", {}).get("spawn", [])
	_check(spawn.size() == 2 and Vector2(spawn[0], spawn[1]) == anchor.global_position, "al descansar en un Ancla se guarda, y ella es el punto de reaparición")
	_player.anchor_menu.close()
	await _wait(4)

	SaveSlot.new(TEST_SAVE).erase()
	_player.add_ecos(6)
	await _stand_at(300.0)
	_player.die()
	await _wait(2)
	var echo: Dictionary = _saved().get("player", {}).get("echo", {})
	_check(echo.get("ecos", 0) == 6, "al reaparecer tras morir se guarda, con el Eco y sus Ecos")


func _test_loading_restores_progress() -> void:
	print("\n[Al abrir el juego se carga la partida y se aparece en la última Ancla]")
	await _load_world()
	_player.unlock_ability(&"dash")
	_player.weapon.set_level(2)
	_level.map_data.reveal(&"TerrazasSecas")
	_level.map_data.reveal(&"Cisterna")
	var anchor_at: Vector2 = _anchor_in("Cisterna").global_position
	_player.rest_at(anchor_at)
	await _wait(2)
	_player.anchor_menu.close()
	await _wait(4)
	_player.add_ecos(7)
	await _stand_at(300.0)
	var echo_at: Vector2 = _player.respawn.last_grounded_position
	_player.die()
	await _wait(4)

	await _load_world(true)
	await _wait(4)
	_check(_player.global_position.distance_to(anchor_at) < 8.0, "se aparece en la última Ancla en la que se descansó")
	_check(_level.current_room.name == "Cisterna", "y la cámara y la sala son las de esa Ancla")
	_check(_player.has_ability(&"dash") and not _player.has_ability(&"double_jump"), "se conservan las habilidades conseguidas, y solo esas")
	_check(_player.weapon.level == 2 and _player.melee.damage == _player.weapon.current_value(), "se conserva el nivel del Filo, y su daño")
	_check(_player.ecos == 0 and is_instance_valid(_player.active_echo) and _player.active_echo.ecos_held == 7, "el Eco de la última muerte sigue esperando con sus Ecos")
	_check(_player.active_echo.global_position.distance_to(echo_at) < 1.0, "en el mismo sitio")
	_check(_player.health.health == _player.health.max_health, "con la vida completa")
	var data: MapData = _level.map_data
	_check(data.is_revealed(&"TerrazasSecas") and data.is_revealed(&"Cisterna") and not data.is_revealed(&"TorreDeRiego"), "el mapa recuerda las salas descubiertas")
	var dash_pickups := 0
	for child in _level.get_node("Rooms/Cisterna").get_children():
		if child is AbilityPickup and not child.is_queued_for_deletion():
			dash_pickups += 1
	_check(dash_pickups == 0, "el recuerdo del dash ya recogido no vuelve a aparecer")

	# Sin partida (o con una ilegible) se empieza desde el principio.
	var file := FileAccess.open(TEST_SAVE, FileAccess.WRITE)
	file.store_string("roto")
	file.close()
	await _load_world(true)
	_check(_level.current_room == _room and not _player.has_ability(&"dash"), "una partida ilegible no rompe nada: se empieza de cero")

	# Posiciones que ya no valen (p. ej. se movió un Ancla al editar un mapa).
	SaveSlot.new(TEST_SAVE).write({ player = {
		spawn = [-5000.0, -5000.0], ecos = 3.0, abilities = ["dash"],
		echo = { position = [-5000.0, -5000.0], ecos = 3.0 },
	}, rooms = [] })
	await _load_world(true)
	await _wait(60)
	_check(_level.current_room == _room and _player.active_echo == null and _player.ecos == 3, "un punto de reaparición que ya no es un Ancla lleva al inicio, sin morir")
	_check(_player.has_ability(&"dash"), "y el resto de la partida se conserva")

	# Tipos equivocados (partida editada a mano): se ignoran sin errores.
	SaveSlot.new(TEST_SAVE).write({ player = { spawn = "x", ecos = "mucho", abilities = 3, echo = [1] }, rooms = 5 })
	await _load_world(true)
	_check(_level.current_room == _room and _player.ecos == 0 and not _player.has_ability(&"dash"), "campos con tipos equivocados se ignoran")
	SaveSlot.new(TEST_SAVE).write({ player = [1, 2] })
	await _load_world(true)
	_check(_level.current_room == _room, "aunque lo equivocado sea la partida entera")


func _test_new_game_from_pause() -> void:
	print("\n[Nueva partida desde la pausa, con confirmación]")
	await _load_world()
	_level.save_game()
	_check(FileAccess.file_exists(TEST_SAVE), "hay una partida guardada")
	var pause = _player.pause_menu
	await _press_action("ui_cancel")
	for i in 4:
		await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Nueva partida" and pause.menu.selected == 0, "Nueva partida pide confirmación, con el no por defecto")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Pausa" and pause.menu.selected == pause.OPTION_NEW_GAME, "decir que no vuelve al menú sin borrar")
	_check(FileAccess.file_exists(TEST_SAVE), "y la partida sigue ahí")
	await _press_action("ui_accept")
	await _press_action("ui_cancel")
	_check(pause.is_open() and pause.title_label.text == "Pausa" and FileAccess.file_exists(TEST_SAVE), "Esc en la confirmación tampoco borra")
	await _press_action("ui_accept")
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(not FileAccess.file_exists(TEST_SAVE), "confirmar borra la partida")
	_level.save_game()
	_check(not FileAccess.file_exists(TEST_SAVE), "y ya no se vuelve a guardar hasta empezar de nuevo")
	paused = false
