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
	await _test_skill_tree_at_anchor()
	await _test_enemy_damage_feedback()
	await _test_anchor_menu_keyboard_and_pause()
	await _test_pause_menu()
	await _test_gamepad_controls()
	await _test_ability_pickups()
	await _test_dash_gates_the_far_platform()
	await _test_double_jump_reaches_high_platform()
	await _test_wall_slide_and_wall_jump()
	await _test_wall_jump_opens_the_shaft()
	await _test_ultimo_umbral_builds_from_text_map()
	await _test_planks_are_one_way_platforms()
	await _test_breakable_props()
	await _test_scenery_is_dense_and_harmless()
	await _test_enemy_types()
	await _test_player_cannot_stand_on_enemies()
	await _test_input_glyphs()
	await _test_sound_effects()
	await _test_landing_sound_is_in_sync()
	await _test_inscription_is_readable()
	await _test_enemy_does_not_jitter_against_a_wall()
	await _test_map_data()
	await _test_world_is_made_of_connected_rooms()
	await _test_walking_into_the_next_room()
	await _test_the_gap_drops_into_the_cistern()
	await _test_dash_crosses_the_terraces_gap()
	await _test_climbing_back_out_of_the_cistern()
	await _test_tower_needs_double_jump()
	await _test_dash_is_once_per_air_time()
	await _test_spikes_hurt_and_return_to_safe_ground()
	await _test_pulsing_hazards_cycle()
	await _test_the_way_to_the_boss()
	await _test_boss_phases_and_reward()
	await _test_boss_attacks_and_parry()
	await _test_boss_planks_and_rocks()
	await _test_boss_does_not_stay_on_top_of_the_player()
	await _test_boss_waves_follow_the_ground_and_dust_needs_ground()
	await _test_enemies_only_act_in_their_own_room()
	await _test_boss_resets_and_stays_dead()
	await _test_boss_death_survives_the_player_dying()
	await _test_dash_puzzle_needs_dash()
	await _test_the_bridge_ends_in_a_lookout()
	await _test_minimap_and_pause_map()
	await _test_save_slot()
	await _test_autosave_triggers()
	await _test_loading_restores_progress()
	await _test_title_screen()
	await _test_pause_returns_to_title()
	await _test_menu_list_survives_leaving_the_tree()
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
	_player.health.heal_charges = 0
	_player.health.take_hit(99)
	_check(_player.ecos == 0, "los Ecos se pierden al morir")
	_check(_player.health.health == 5, "la vida se restaura al reaparecer")
	_check(_player.health.heal_charges == _player.health.max_heal_charges, "y las curaciones se recargan del todo")
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
	_check(_player.ecos == 0 and is_instance_valid(echo), "tocar el Eco no basta: hay que interactuar")
	_check(echo.get_node("Prompt").visible, "al estar al alcance aparece el icono del botón")
	Input.action_press("interact")
	await _wait(2)
	Input.action_release("interact")
	await _wait(2)
	_check(_player.ecos == 5, "interactuar con el Eco devuelve los Ecos")
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
	_check(windup_frames >= 14, "el aviso dura lo bastante para reaccionar")
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
	_check(player_sprite.texture.get_size() == Vector2(player_sprite.hframes * 112, player_sprite.vframes * 64), "la hoja del jugador cuadra con su cuadrícula de 112x64")
	_check(enemy_sprite.texture.get_size() == Vector2(enemy_sprite.hframes * 96, enemy_sprite.vframes * 64), "la hoja del enemigo cuadra con su cuadrícula de 96x64")

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


func _test_skill_tree_at_anchor() -> void:
	await _fresh_level("Árbol de habilidades en el Ancla")
	var skills: SkillTree = _player.skills
	_check(_player.melee.damage == 1 and _player.health.max_health == 5, "sin mejoras: daño 1 y 5 de vida")
	_check(skills.is_unlocked(&"vitalidad") and not skills.is_unlocked(&"frascos"), "la rama empieza por su primera mejora; las siguientes están bloqueadas")

	_player.add_ecos(3)
	_check(not _player.try_buy_skill(&"vitalidad"), "no se compra sin Ecos suficientes")
	_check(_player.ecos == 3 and skills.level(&"vitalidad") == 0, "una compra fallida no cobra nada")
	_player.add_ecos(2)
	_check(_player.try_buy_skill(&"vitalidad"), "se compra con Ecos suficientes")
	_check(_player.ecos == 0 and skills.level(&"vitalidad") == 1, "comprar cobra el coste y sube un nivel")
	_check(_player.health.max_health == 6 and _player.health.health == 6, "Vitalidad sube la vida máxima y cura esa vida")

	_player.add_ecos(100)
	_check(not _player.try_buy_skill(&"ritmo"), "una mejora bloqueada no se puede comprar aunque sobren Ecos")
	_check(_player.try_buy_skill(&"frascos") and _player.health.max_heal_charges == 4 and _player.health.heal_charges == 4, "Frascos da una carga más, llena")
	_check(_player.try_buy_skill(&"filo") and _player.melee.damage == 2, "Filo afilado sube el daño")
	_check(_player.try_buy_skill(&"ritmo") and is_equal_approx(_player.melee.cooldown, 0.26), "Ritmo acorta la espera entre golpes")
	_check(_player.try_buy_skill(&"alcance") and _player.melee.reach > 20.0, "Alcance alarga el golpe")
	_check(_player.try_buy_skill(&"guardia") and _player.parry.window > 0.2, "Guardia alarga la ventana del parry")
	_check(_player.try_buy_skill(&"impulso") and _player.dash.cooldown < 0.4, "Impulso acorta la espera del dash")
	_check(_player.try_buy_skill(&"temple") and _player.health.invulnerability_time > 0.6, "Temple alarga la invulnerabilidad")
	_check(_player.try_buy_skill(&"contragolpe"), "Contragolpe se compra al tener la anterior")

	# Los niveles máximos no se pasan, y morir no pierde las mejoras (los Ecos sí).
	while not skills.is_max(&"filo"):
		skills.advance(&"filo")
	_player.add_ecos(500)
	_check(not _player.try_buy_skill(&"filo"), "no se puede pasar del nivel máximo")
	_check(_player.melee.damage == 3, "el máximo del Filo es daño 3: el arma ya no escala sin límite")
	_player.health.take_hit(99)
	await _wait(2)
	_check(_player.melee.damage == 3 and skills.level(&"vitalidad") == 1, "morir no pierde las mejoras")

	# Desde el menú del Ancla: abrir el árbol, moverse, comprar y volver.
	await _fresh_level("Árbol de habilidades en el menú")
	var menu = _player.anchor_menu
	_player.add_ecos(30)
	_player.rest_at(_player.global_position)
	_check(menu.is_open() and not menu.is_tree_open(), "descansar abre el menú principal del Ancla")
	_check(menu.menu.activate() and menu.is_tree_open(), "la primera opción abre el árbol")
	_check(menu.tree_view.selected().id == &"vitalidad", "el árbol empieza en la primera mejora")
	await _press_action("ui_down")
	_check(menu.tree_view.selected().id == &"frascos", "abajo baja por la rama")
	await _press_action("ui_right")
	_check(menu.tree_view.selected().branch == 1, "derecha cambia de rama")
	await _press_action("ui_left")
	await _press_action("ui_up")
	await _press_action("ui_accept")
	_check(_player.skills.level(&"vitalidad") == 1 and _player.ecos == 25, "aceptar compra la mejora seleccionada, sin cerrar el menú")
	_check(menu.is_open() and menu.is_tree_open() and paused, "el menú sigue abierto en el árbol")
	await _press_action("ui_cancel")
	_check(menu.is_open() and not menu.is_tree_open(), "Esc en el árbol vuelve al menú del Ancla")
	await _press_action("ui_cancel")
	_check(not menu.is_open(), "y otro Esc lo cierra")


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

	# Z también es aceptar: abre el árbol sin cerrar el menú...
	_player.rest_at(_player.global_position)
	await _press_action("interact")
	_check(menu.is_open() and paused and menu.is_tree_open(), "Z sobre el árbol de habilidades lo abre sin cerrar el menú")
	await _press_action("ui_cancel")
	# ...y sobre Salir, cierra.
	await _press_action("ui_down")
	await _press_action("interact")
	_check(not menu.is_open() and not paused, "Z sobre Salir cierra el menú")
	_player.ecos = 20

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

	# Lo mismo con Z estando junto al Ancla: abrir y cerrar con Z no debe reabrir el
	# menú (se baja a Salir y Z lo elige).
	_player.ecos = 0
	var anchor: Node2D = _level.get_node("MemoryAnchor2")
	_player.global_position = anchor.global_position
	_player.velocity = Vector2.ZERO
	await _wait(15)
	await _press_action("interact")
	await _wait(5)
	_check(menu.is_open(), "Z junto al Ancla abre el menú")
	await _press_action("ui_down")
	await _press_action("interact")
	await _wait(15)
	_check(not menu.is_open() and not paused, "cerrar con Z cierra el menú y no lo reabre")
	# El árbol está siempre disponible: el cursor empieza en él, aunque no haya Ecos.
	_player.ecos = 0
	_player.rest_at(_player.global_position)
	_check(menu.menu.selected == 0, "el cursor empieza en la primera opción")
	await _press_action("ui_accept")
	_check(menu.is_open() and menu.is_tree_open(), "Intro sobre el árbol lo abre a la primera")
	await _press_action("ui_cancel")
	await _press_action("ui_cancel")
	_check(not menu.is_open() and not paused, "y Esc dos veces cierra el menú")


func _test_dash_gates_the_far_platform() -> void:
	# Mismo salto hacia el hueco final, con y sin dash a media altura.
	var reached_with_dash := await _jump_across_gap(true, true)
	var reached_pressing_locked := await _jump_across_gap(true, false)
	var reached_without_dash := await _jump_across_gap(false, true)
	print("\n[El dash abre el hueco final]")
	_check(reached_with_dash, "saltar + dash alcanza la plataforma final")
	_check(not reached_pressing_locked, "pulsar dash sin haberlo conseguido no sirve")
	_check(not reached_without_dash, "saltar sin dash no alcanza la plataforma final")


func _test_gamepad_controls() -> void:
	await _fresh_level("Mando: mismos botones por posición en Xbox, PlayStation y Nintendo")
	# Godot numera los botones del mando por POSICIÓN, no por la letra impresa:
	# JOY_BUTTON_A es el de abajo (A en Xbox, Cruz en PlayStation, B en Nintendo).
	# Así, cada acción cae en el mismo sitio en todos los mandos.
	var expected := {
		&"ui_accept": _pad_button(JOY_BUTTON_A),
		&"attack": _pad_button(JOY_BUTTON_X),
		&"heal": _pad_button(JOY_BUTTON_B),
		&"ui_cancel": _pad_button(JOY_BUTTON_B),
		&"interact": _pad_button(JOY_BUTTON_Y),
		&"dash": _pad_axis(JOY_AXIS_TRIGGER_RIGHT),
		&"parry": _pad_axis(JOY_AXIS_TRIGGER_LEFT),
		&"pause": _pad_button(JOY_BUTTON_START),
	}
	var all_mapped := true
	for action in expected:
		if not InputMap.event_is_action(expected[action], action, true):
			all_mapped = false
			print("    falta el botón de %s" % action)
	_check(all_mapped, "cada acción tiene su botón del mando (saltar abajo, atacar izquierda, curar derecha, Ancla arriba, dash RT, guardia LT, pausa Start)")
	_check(not InputMap.event_is_action(_pad_button(JOY_BUTTON_B), &"pause"), "el botón de curarse no abre la pausa")

	# Moverse con la palanca: pasada la zona muerta, a toda velocidad.
	await _stand_at(400.0)
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_X, 0.6))
	await _wait(3)
	_check(is_equal_approx(_player.velocity.x, _player.motor.speed), "con la palanca a media inclinación se corre a toda velocidad")
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_X, 0.0))
	await _stand_at(400.0)

	var standing_y: float = _player.global_position.y
	await _press_event(_pad_button(JOY_BUTTON_A))
	_check(_player.global_position.y < standing_y - 1.0, "A / Cruz salta")
	await _stand_at(400.0)
	await _press_event(_pad_button(JOY_BUTTON_X))
	_check(_player.animator.current == "attack", "X / Cuadrado ataca")
	await _wait(30)
	_player.take_hit(1, 0)
	await _press_event(_pad_button(JOY_BUTTON_B))
	_check(_player.health.health == _player.health.max_health and not paused, "B / Círculo cura y no abre la pausa")
	await _press_event(_pad_axis(JOY_AXIS_TRIGGER_LEFT))
	_check(_player.parry.is_active, "LT / L2 alza la guardia")
	await _wait(60)
	_player.unlock_ability(&"dash")
	await _press_event(_pad_axis(JOY_AXIS_TRIGGER_RIGHT))
	_check(_player.dash.is_dashing, "RT / R2 hace el dash")
	await _wait(2)
	_check(_player.animator.current == "dash", "el dash tiene su propia animación")
	await _wait(30)

	# Start abre y cierra la pausa, también desde una subpantalla.
	var pause = _player.pause_menu
	await _press_event(_pad_button(JOY_BUTTON_START))
	_check(pause.is_open() and paused, "Start abre la pausa")
	await _press_event(_pad_button(JOY_BUTTON_START))
	_check(not pause.is_open(), "Start la cierra")
	await _wait(5)
	await _press_event(_pad_button(JOY_BUTTON_START))
	await _press_action("ui_down")
	await _press_action("ui_down")
	await _press_action("ui_down")
	await _press_event(_pad_button(JOY_BUTTON_A))
	_check(pause.title_label.text == "Controles" and pause.controls_view.visible, "Controles muestra el esquema de teclado y mandos")
	await _press_event(_pad_button(JOY_BUTTON_START))
	_check(not pause.is_open(), "Start cierra la pausa desde una subpantalla")
	await _wait(5)

	# En los menús, la palanca mueve una opción por inclinación, no una por evento.
	_player.add_ecos(6)
	_player.rest_at(_player.global_position)
	var menu: MenuList = _player.anchor_menu.menu
	_check(menu.selected == 0, "el menú del Ancla empieza en la primera opción")
	for value in [0.6, 0.8, 1.0, 0.9]:
		Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_Y, value))
		await physics_frame
	_check(menu.selected == 1, "inclinar la palanca hacia abajo baja una sola opción")
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_Y, 0.0))
	await physics_frame
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_Y, 1.0))
	await physics_frame
	_check(menu.selected == 0, "soltarla y volver a inclinarla baja otra")
	Input.parse_input_event(_pad_axis(JOY_AXIS_LEFT_Y, 0.0))
	await _press_event(_pad_button(JOY_BUTTON_B))
	_check(not _player.anchor_menu.is_open(), "B / Círculo cierra el menú del Ancla")


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
	print("\n[Los objetos rompibles se atraviesan, se rompen al golpearlos y no afectan a la partida]")
	await _load_world()
	var urn: BreakableProp = null
	for child in _room.get_children():
		if child is BreakableProp:
			urn = child
			break
	_check(urn != null, "hay objetos rompibles colocados por los marcadores R")
	_check(urn.hits == 1, "por defecto se rompen de un golpe")

	# Se atraviesa caminando: no es un obstáculo.
	_player.global_position = urn.global_position + Vector2(-30.0, -20.0)
	_player.velocity = Vector2.ZERO
	Input.action_press("ui_right")
	await _wait(30)
	Input.action_release("ui_right")
	_check(_player.global_position.x > urn.global_position.x, "el jugador atraviesa la urna caminando")
	_check(urn.z_index <= _player.z_index, "la urna se dibuja detrás del personaje, no encima")

	var ecos_before: int = _player.ecos
	var health_before: int = _player.health.health
	# Un ataque real del jugador la alcanza aunque no bloquee.
	_player.global_position = urn.global_position + Vector2(-8.0, 0.0)
	_player.velocity = Vector2.ZERO
	await _wait(3)
	Input.action_press("attack")
	await _wait(2)
	Input.action_release("attack")
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




func _test_scenery_is_dense_and_harmless() -> void:
	print("
[El entorno está cargado de decorado y objetos rompibles que no estorban]")
	await _load_world()
	var decor := 0
	var crates := 0
	var barrels := 0
	for room in _level.get_node("Rooms").get_children():
		for child in room.get_children():
			if child is Sprite2D:
				decor += 1
			elif child is BreakableProp:
				if child.hits == 2:
					barrels += 1
				elif child.scene_file_path.ends_with("breakable_crate.tscn"):
					crates += 1
	_check(decor >= 100, "las salas tienen mucho decorado (%d piezas)" % decor)
	_check(crates >= 8 and barrels >= 8, "hay cajas (%d) y barriles (%d) rompibles" % [crates, barrels])

	var barrel: BreakableProp = null
	for child in _room.get_children():
		if child is BreakableProp and child.hits == 2:
			barrel = child
			break
	_check(barrel != null, "El Último Umbral tiene barriles")
	barrel.take_hit(1, 1)
	_check(is_instance_valid(barrel), "un barril aguanta el primer golpe")
	barrel.take_hit(1, 1)
	await _wait(2)
	_check(not is_instance_valid(barrel), "y se rompe con el segundo")


## Pone un enemigo de `scene_path` en el suelo plano de El Último Umbral, a `distance`
## píxeles a la derecha del jugador (que se coloca en x = 60: a su izquierda hay un
## muro y a la derecha, más allá de x = 250, la cabaña, que pararía los proyectiles).
func _spawn_enemy_next_to_player(scene_path: String, distance: float) -> Node2D:
	_player.global_position = Vector2(100.0, 296.0)
	_player.velocity = Vector2.ZERO
	var enemy: Node2D = load(scene_path).instantiate()
	_room.add_child(enemy)
	var half_height: float = enemy.get_node("CollisionShape2D").shape.size.y / 2.0
	enemy.global_position = Vector2(100.0 + distance, 320.0 - half_height)
	enemy.ai._home_x = enemy.global_position.x
	return enemy


func _test_enemy_types() -> void:
	print("
[Enemigos distintos, ataques distintos]")

	# Lancero: la estocada llega mucho más lejos que un tajo.
	await _load_world()
	var lancero := await _spawn_enemy_next_to_player("res://game/enemy/enemy_lancero.tscn", 78.0)
	var hp_before: int = _player.health.health
	await _wait(150)
	_check(_player.health.health < hp_before, "el lancero alcanza al jugador desde lejos (78 px) con la lanza")
	var melee_reach: float = lancero.melee.reach
	_check(melee_reach > 40.0, "su alcance es mayor que el del cascarón")

	# Cascarón a la misma distancia: ni siquiera inicia el ataque.
	await _load_world()
	var casc := await _spawn_enemy_next_to_player("res://game/enemy/enemy.tscn", 78.0)
	await _wait(3)
	_check(casc.ai.state == PatrolChaseAI.State.CHASE, "el cascarón a 78 px aún no ataca: tiene que acercarse (su alcance es corto)")

	# Arrojador: lanza una esquirla que hiere al jugador.
	await _load_world()
	var thrower := await _spawn_enemy_next_to_player("res://game/enemy/enemy_arrojador.tscn", 130.0)
	var shot: Projectile = null
	for i in 150:
		await _wait(1)
		for child in _room.get_children():
			if child is Projectile:
				shot = child
				break
		if shot:
			break
	_check(shot != null, "el arrojador lanza un proyectil")
	_check(shot != null and shot.direction.x < 0.0, "el proyectil viaja hacia el jugador")
	hp_before = _player.health.health
	await _wait(60)
	_check(_player.health.health < hp_before, "el proyectil hiere al jugador")
	_check(thrower.health.max_health == 2, "el arrojador es frágil (2 de vida)")

	# Un proyectil desviado con parry vuelve hacia quien lo lanzó y hiere a los enemigos.
	await _load_world()
	var shard: Projectile = load("res://game/enemy/shard.tscn").instantiate()
	_room.add_child(shard)
	shard.global_position = Vector2(300.0, 296.0)
	shard.launch(Vector2.LEFT)
	shard.on_parried()
	_check(shard.direction.x > 0.0 and shard.target_group == &"enemy", "un proyectil desviado se devuelve y pasa a herir a los enemigos")
	shard.queue_free()

	# Acechador: la embestida lo lleva hacia el jugador a gran velocidad.
	await _load_world()
	var stalker := await _spawn_enemy_next_to_player("res://game/enemy/enemy_acechador.tscn", 120.0)
	var x_at_windup := 0.0
	var lunged_far := false
	hp_before = _player.health.health
	for i in 200:
		await _wait(1)
		if stalker.ai.state == PatrolChaseAI.State.WINDUP:
			x_at_windup = stalker.global_position.x
		if x_at_windup > 0.0 and x_at_windup - stalker.global_position.x > 70.0:
			lunged_far = true
			break
	_check(lunged_far, "el acechador se lanza hacia delante más de 70 px en un instante")
	await _wait(30)
	_check(_player.health.health < hp_before, "y la embestida hiere al jugador")

	# Coloso: aguanta mucho y su mazazo hace doble daño.
	await _load_world()
	var colossus := await _spawn_enemy_next_to_player("res://game/enemy/enemy_coloso.tscn", 70.0)
	_check(colossus.health.max_health == 10, "el coloso tiene 10 de vida")
	hp_before = _player.health.health
	await _wait(240)
	_check(hp_before - _player.health.health >= 2, "su mazazo quita 2 de vida de una vez")
	_check(colossus.ai.windup_time >= 0.7, "y avisa el golpe durante más de medio segundo")


func _test_input_glyphs() -> void:
	print("
[Los iconos de botones se adaptan al dispositivo]")
	_check(InputGlyphs.kind_from_name("Xbox 360 Controller") == InputGlyphs.Kind.XBOX, "un mando de Xbox se reconoce")
	_check(InputGlyphs.kind_from_name("PS5 Controller") == InputGlyphs.Kind.PLAYSTATION, "un mando de PlayStation se reconoce")
	_check(InputGlyphs.kind_from_name("Nintendo Switch Pro Controller") == InputGlyphs.Kind.NINTENDO, "un mando de Nintendo se reconoce")
	_check(InputGlyphs.kind_from_name("Mando raro") == InputGlyphs.Kind.XBOX, "uno desconocido usa la disposición de Xbox")

	var key := InputGlyphs.binding(&"interact", InputGlyphs.Kind.KEYBOARD)
	_check(key.get("type") == "key" and key.get("label") == "Z", "en teclado, interactuar es la tecla Z")
	var pad := InputGlyphs.binding(&"interact", InputGlyphs.Kind.PLAYSTATION)
	_check(pad.get("type") == "button" and pad.get("index") == JOY_BUTTON_Y, "en el mando, interactuar es el botón de arriba (Y / Triángulo / X)")
	var trigger := InputGlyphs.binding(&"dash", InputGlyphs.Kind.XBOX)
	_check(trigger.get("type") == "trigger" and trigger.get("right") == true, "el dash es el gatillo derecho")
	_check(InputGlyphs.binding(&"no_existe", InputGlyphs.Kind.KEYBOARD).is_empty(), "una acción que no existe no da icono")

	# Dibujar un indicador y una fila de ayuda con cada dispositivo no da errores.
	var prompt := InputPrompt.new()
	prompt.action = &"interact"
	root.add_child(prompt)
	var bar := InputHintBar.new()
	bar.size = Vector2(300, 22)
	bar.set_entries([{ hint = InputGlyphs.Hint.UP_DOWN }, { action = &"ui_accept", hint = InputGlyphs.Hint.CHECK }, { action = &"pause", hint = InputGlyphs.Hint.MENU }, { color = Color.RED }])
	root.add_child(bar)
	var widths := {}
	for device in [InputGlyphs.Kind.KEYBOARD, InputGlyphs.Kind.XBOX, InputGlyphs.Kind.PLAYSTATION, InputGlyphs.Kind.NINTENDO]:
		InputGlyphs.kind = device
		prompt.queue_redraw()
		bar.queue_redraw()
		await process_frame
		widths[device] = InputGlyphs.width(&"pause")
	_check(widths[InputGlyphs.Kind.KEYBOARD] != widths[InputGlyphs.Kind.XBOX] or widths[InputGlyphs.Kind.XBOX] > 0.0, "se dibuja el icono de cada dispositivo")

	# El vigilante cambia de dispositivo con la última entrada recibida.
	InputGlyphs.kind = InputGlyphs.Kind.KEYBOARD
	var button := InputEventJoypadButton.new()
	button.button_index = JOY_BUTTON_Y
	button.pressed = true
	root.get_viewport().push_input(button)
	await process_frame
	_check(InputGlyphs.kind != InputGlyphs.Kind.KEYBOARD, "pulsar un botón del mando cambia los iconos a los del mando")
	var typed := InputEventKey.new()
	typed.keycode = KEY_Z
	typed.pressed = true
	root.get_viewport().push_input(typed)
	await process_frame
	_check(InputGlyphs.kind == InputGlyphs.Kind.KEYBOARD, "y pulsar una tecla los devuelve al teclado")
	prompt.queue_free()
	bar.queue_free()


func _test_enemy_damage_feedback() -> void:
	print("\n[Golpear a un enemigo se nota: número de daño, barra de vida y mayor dificultad]")
	await _load_world()
	var enemy := await _spawn_enemy_next_to_player("res://game/enemy/enemy_lancero.tscn", 60.0)
	var bar: OverheadBar = enemy.get_node("HealthBar")
	_check(not bar.visible, "la barra de vida del enemigo está oculta mientras no le hacen daño")
	enemy.take_hit(1, 1)
	_check(bar.visible, "al herirlo aparece su barra de vida")
	var numbers := 0
	for child in _room.get_children():
		if child is DamageNumber:
			numbers += 1
	_check(numbers == 1, "y sale un número de daño sobre su cabeza")
	await _wait(220)
	_check(not bar.visible, "la barra se oculta sola unos segundos después")

	# Más difícil: los ataques enemigos se preparan más rápido que antes.
	var casc: Node = load("res://game/enemy/enemy.tscn").instantiate()
	_check(casc.get_node("PatrolChaseAI").windup_time <= 0.3 and casc.get_node("PatrolChaseAI").recovery_time <= 0.5, "el cascarón ataca más rápido (aviso 0,3 s, recuperación 0,5 s)")
	casc.free()

	# Contragolpe: el parry aturde más tiempo al enemigo.
	await _load_world()
	var target := await _spawn_enemy_next_to_player("res://game/enemy/enemy.tscn", 60.0)
	target.on_parried(0.5)
	_check(is_equal_approx(target._stun_timer, target.parry_stun_time + 0.5), "un enemigo desviado queda aturdido el tiempo extra que da el Contragolpe")


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

	await _press_event(_key(KEY_ESCAPE))
	_check(pause.is_open() and paused, "Esc abre la pausa y detiene el juego")
	_check(pause.title_label.text == "Pausa" and options.visible, "se muestra la lista principal")
	var pause_panel: Control = pause.get_node("Root/Panel")
	var pause_size := pause_panel.size
	await _press_event(_key(KEY_ESCAPE))
	_check(not pause.is_open() and not paused, "Esc cierra la pausa y reanuda el juego")

	# Personaje: datos y habilidades por descubrir.
	_player.add_ecos(7)
	await _press_action("pause")
	await _press_action("ui_down")
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Personaje" and pause.info.visible, "Personaje abre su pantalla")
	_check("Vida: 5 / 5" in pause.info_label.text and "Ecos: 7" in pause.info_label.text, "muestra vida y Ecos")
	_check("Daño: 1" in pause.info_label.text and "Frascos: 3 / 3" in pause.info_label.text, "muestra el daño y los frascos")
	_check(pause_panel.size == pause_size, "el panel mide lo mismo en Personaje que en el menú principal")
	_check("Dash" not in pause.info_label.text and "???" in pause.info_label.text, "las habilidades sin recordar salen como ???")
	await _press_action("ui_cancel")
	_check(pause.is_open() and pause.title_label.text == "Pausa", "Esc en una subpantalla vuelve al menú, sin cerrar la pausa")

	# Controles.
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(pause.title_label.text == "Controles" and pause.controls_view.visible and not pause.info.visible, "Controles muestra el esquema, no la ficha del personaje")
	var device_before: int = pause.controls_view.device
	await _press_action("ui_right")
	_check(pause.controls_view.device == (device_before + 1) % 4 and pause.is_open(), "derecha cambia de dispositivo en el esquema sin cerrar la pausa")
	await _press_action("ui_left")
	_check(pause_panel.size == pause_size, "y lo mismo en Controles")
	await _press_action("ui_accept")
	_check(pause.is_open() and pause.title_label.text == "Pausa", "Intro en una subpantalla también vuelve")

	# Con una habilidad recordada, sale su nombre. La pantalla se recompone al reabrir.
	await _press_action("ui_cancel")
	_player.unlock_ability(&"dash")
	await _press_action("pause")
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
	await _press_event(_key(KEY_ESCAPE))
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
	_check(spawners == 3, "tres enemigos colocados por los marcadores (dos cascarones E y un arrojador 2)")
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
	await _press_event(event)


## Pulsa y suelta un evento de entrada real (tecla, botón o gatillo del mando),
## para probar el Mapa de entrada de project.godot y no solo las acciones.
## Un gatillo o una palanca se "sueltan" volviendo a 0.
func _press_event(event: InputEvent) -> void:
	# Hay que soltarlo: si no, la acción queda pulsada para las pruebas siguientes.
	var release: InputEvent = event.duplicate()
	if event is InputEventJoypadMotion:
		release.axis_value = 0.0
	else:
		event.pressed = true
		release.pressed = false
	Input.parse_input_event(event)
	await _wait(2)
	Input.parse_input_event(release)
	await _wait(2)


func _key(keycode: Key) -> InputEventKey:
	var event := InputEventKey.new()
	event.keycode = keycode
	event.physical_keycode = keycode
	return event


func _pad_button(button: JoyButton) -> InputEventJoypadButton:
	var event := InputEventJoypadButton.new()
	event.button_index = button
	return event


func _pad_axis(axis: JoyAxis, value: float = 1.0) -> InputEventJoypadMotion:
	var event := InputEventJoypadMotion.new()
	event.axis = axis
	event.axis_value = value
	return event


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


func _test_sound_effects() -> void:
	print("
[Efectos de sonido]")
	await _load_world()
	await _wait(2)
	var sfx := root.get_node_or_null("Sfx")
	_check(sfx != null, "el jugador prepara el reproductor de sonidos en la raíz")
	_check(AudioServer.get_bus_index(&"SFX") != -1, "existe el bus SFX con sus efectos")

	# Todo sonido que el código pide existe en la carpeta (atrapa erratas en los nombres).
	var wanted := {}
	var regex := RegEx.create_from_string("Sfx\\.play\\(&\"([a-z_]+)\"")
	for folder in ["res://core", "res://game"]:
		for path in _gd_files(folder):
			for found in regex.search_all(FileAccess.get_file_as_string(path)):
				wanted[found.get_string(1)] = path
	var missing := []
	for sound in wanted:
		if not Sfx.has(StringName(sound)):
			missing.append("%s (%s)" % [sound, wanted[sound]])
	_check(wanted.size() > 15, "el código pide muchos sonidos distintos (%d)" % wanted.size())
	_check(missing.is_empty(), "todos los sonidos que pide el código existen %s" % [missing])

	# Pasos y aterrizajes por material: existe el sonido de cada material del TileSet.
	var tiles: TileSet = load("res://game/levels/tiles_umbral.tres")
	var source := tiles.get_source(0) as TileSetAtlasSource
	var materials := {}
	for index in source.get_tiles_count():
		materials[source.get_tile_data(source.get_tile_id(index), 0).get_custom_data("material")] = true
	_check(materials.has("stone") and materials.has("moss") and materials.has("wood"), "el TileSet distingue piedra, musgo y madera %s" % [materials.keys()])
	var silent := []
	for material in materials:
		for kind in ["step", "land"]:
			if not Sfx.has(StringName("%s_%s" % [kind, material])):
				silent.append("%s_%s" % [kind, material])
	_check(silent.is_empty(), "cada material tiene su paso y su aterrizaje %s" % [silent])
	_check(GroundMaterial.under(_player) in materials, "el jugador sabe sobre qué material pisa (%s)" % GroundMaterial.under(_player))

	# Cada enemigo tiene su voz completa, su golpe y su paso.
	var incomplete := []
	for file in ["enemy", "enemy_lancero", "enemy_arrojador", "enemy_coloso", "enemy_acechador"]:
		var enemy: Node = load("res://game/enemy/%s.tscn" % file).instantiate()
		for event in ["alert", "attack", "hurt", "die"]:
			if not Sfx.has(StringName("%s_%s" % [enemy.voice, event])):
				incomplete.append("%s_%s" % [enemy.voice, event])
		for sound in [enemy.strike_sound, enemy.step_sound]:
			if not Sfx.has(sound):
				incomplete.append(String(sound))
		enemy.free()
	_check(incomplete.is_empty(), "las cinco voces de enemigo están completas %s" % [incomplete])
	var shard: Node = load("res://game/enemy/shard.tscn").instantiate()
	_check(Sfx.has(shard.hit_sound), "la esquirla tiene sonido de impacto")
	shard.free()

	# Sonar: una voz queda ocupada, y el mismo sonido no se apila al instante.
	# Cuántas voces suenan con un sonido concreto (otras cosas del mundo, como los
	# pasos de un enemigo lejano, pueden sonar a la vez).
	var playing := func(sound: String) -> int:
		var count := 0
		for voice in sfx.get_children():
			if voice.playing and voice.stream.resource_path.get_file().begins_with(sound + "_"):
				count += 1
		return count
	var silence := func() -> void:
		for voice in sfx.get_children():
			voice.stop()
		await _wait(8)
	await silence.call()
	Sfx.play(&"ui_accept")
	_check(playing.call("ui_accept") == 1, "un sonido de interfaz ocupa una voz")
	Sfx.play(&"ui_accept")
	_check(playing.call("ui_accept") == 1, "el mismo sonido pedido dos veces seguidas no se apila")
	Sfx.play(&"no_existe")
	_check(playing.call("no_existe") == 0, "un sonido que no existe se ignora sin error")

	# El pie toca el suelo en la carrera: suena un paso (solo si está en el suelo).
	await silence.call()
	_check(_player.is_on_floor(), "el jugador está en el suelo para la prueba de pasos")
	_player.animator.frame_changed.emit("run", 6)
	_check(playing.call("step") == 1, "un paso al tocar el pie el suelo")
	await silence.call()
	_player.animator.frame_changed.emit("run", 3)
	_check(playing.call("step") == 0, "sin contacto del pie no suena paso")

	# Saltar suena, y el motor avisa del tipo de salto.
	var kinds := []
	_player.motor.jumped.connect(func(kind: StringName) -> void: kinds.append(kind))
	await silence.call()
	await _press_action("ui_accept")
	_check(kinds == [&"ground"], "el motor avisa de un salto desde el suelo %s" % [kinds])
	_check(playing.call("jump") == 1, "saltar suena")
	await _wait(60)

	# Menús: moverse y elegir suenan.
	var list := MenuList.new()
	root.add_child(list)
	list.set_entries(PackedStringArray(["A", "B"]), [true, false])
	await silence.call()
	list.move_selection(1)
	_check(playing.call("ui_move") == 1, "mover la selección de un menú suena")
	await silence.call()
	list.activate()
	_check(playing.call("ui_deny") == 1, "elegir una opción desactivada suena (negado)")
	list.queue_free()

	# Romper un objeto suena.
	await silence.call()
	var prop := BreakableProp.new()
	_room.add_child(prop)
	prop.take_hit(1, 1)
	_check(playing.call("break") == 1, "romper un objeto suena")


## El sonido de la caída empieza en el MISMO fotograma de físicas en que el personaje
## toca el suelo, tanto en una caída larga como en una corta (un escalón).
func _test_landing_sound_is_in_sync() -> void:
	print("
[El aterrizaje suena justo al tocar el suelo]")
	await _load_world()
	await _wait(60)
	var sfx := root.get_node("Sfx")
	for drop in [200.0, 40.0, 14.0]:
		_player.velocity = Vector2.ZERO
		_player.global_position.y -= drop
		await _wait(2)
		for voice in sfx.get_children():
			voice.stop()
		var contact_frame := -1
		var sound_frame := -1
		for frame in 90:
			await physics_frame
			if _player.is_on_floor() and contact_frame < 0:
				contact_frame = frame
			for voice in sfx.get_children():
				if voice.playing and voice.stream.resource_path.get_file().begins_with("land_") and sound_frame < 0:
					sound_frame = frame
			if contact_frame >= 0 and frame > contact_frame + 3:
				break
		_check(contact_frame >= 0, "cae %d px y toca el suelo" % int(drop))
		_check(sound_frame == contact_frame, "caída de %d px: el sonido empieza en el fotograma del contacto (contacto %d, sonido %d)" % [int(drop), contact_frame, sound_frame])
		await _wait(30)


func _gd_files(folder: String) -> Array[String]:
	var found: Array[String] = []
	for file in DirAccess.get_files_at(folder):
		if file.ends_with(".gd"):
			found.append(folder.path_join(file))
	for sub in DirAccess.get_directories_at(folder):
		found.append_array(_gd_files(folder.path_join(sub)))
	return found


## Caer encima de un enemigo no deja al jugador subido a él: resbala hasta el suelo.
func _test_player_cannot_stand_on_enemies() -> void:
	print("
[No se puede quedar uno encima de un enemigo]")
	for scene in ["enemy", "enemy_coloso"]:
		await _load_world()
		var enemy := await _spawn_enemy_next_to_player("res://game/enemy/%s.tscn" % scene, 120.0)
		await _wait(5)
		enemy.set_physics_process(false)
		var top: float = enemy.global_position.y - enemy.get_node("CollisionShape2D").shape.size.y / 2.0
		_player.global_position = Vector2(enemy.global_position.x, top - 70.0)
		_player.velocity = Vector2.ZERO
		await _wait(120)
		_check(_player.is_on_floor() and absf(_player.global_position.y - 296.0) < 3.0, "tras caer sobre %s, el jugador acaba en el suelo y no encima (y=%d)" % [scene, int(_player.global_position.y)])
		_check(absf(_player.global_position.x - enemy.global_position.x) > 10.0, "y a un lado del enemigo")

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
	_check(rooms.size() == 8, "hay ocho salas")
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
	_check(anchors == 8, "las ocho Anclas están marcadas en el mapa (se ven al pasar cerca)")
	_check(_player.hud.message_label.text.is_empty(), "la sala de inicio no se anuncia")
	var dash_pickup := 0
	var jump_pickup := 0
	for room in rooms:
		for child in room.get_children():
			if child is AbilityPickup:
				dash_pickup += 1 if child.ability_id == &"dash" else 0
				jump_pickup += 1 if child.ability_id == &"double_jump" and room.name == "TorreDeRiego" else 0
	_check(dash_pickup == 0 and jump_pickup == 1, "el dash no está tirado por el mundo (lo suelta el jefe) y el doble salto está en la Torre de Riego")


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
	print("\n[De la Cisterna se sale subiendo por los tablones]")
	await _load_world()
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
	# (Si cae sobre un enemigo, resbala hasta el suelo: se espera a que se asiente.)
	await _wait(40)
	_check(_player.is_on_floor() and _level.current_room.name == "TerrazasSecas" and _player.global_position.y < 320.0, "del último tablón se sale al suelo de las Terrazas (suelo=%s sala=%s pos=%s)" % [_player.is_on_floor(), _level.current_room.name, _player.global_position])


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
	await _press_action("pause")
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
	_player.skills.set_level(&"filo", 2)
	_player.skills.set_level(&"vitalidad", 3)
	_level.map_data.visit(&"TerrazasSecas")
	_level.map_data.visit(&"Cisterna")
	# Un trozo explorado lejos de donde se va a reaparecer (en la Torre).
	_level.map_data.reveal_around(Vector2(174, -10), 3.0)
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
	_check(_player.skills.level(&"filo") == 2 and _player.melee.damage == 3 and _player.skills.level(&"vitalidad") == 3, "se conservan las mejoras del árbol, y sus efectos")
	_check(_player.health.max_health == 8 and _player.health.health == 8, "la vida máxima mejorada se conserva y se rellena")
	_check(_player.ecos == 0 and is_instance_valid(_player.active_echo) and _player.active_echo.ecos_held == 7, "el Eco de la última muerte sigue esperando con sus Ecos")
	_check(_player.active_echo.global_position.distance_to(echo_at) < 1.0, "en el mismo sitio")
	_check(_player.health.health == _player.health.max_health, "con la vida completa")
	var data: MapData = _level.map_data
	_check(data.is_visited(&"TerrazasSecas") and data.is_visited(&"Cisterna") and not data.is_visited(&"TorreDeRiego"), "se recuerdan las salas visitadas (no se vuelven a anunciar)")
	_check(data.is_seen(Vector2(174, -10)) and not data.is_seen(Vector2(185, -10)), "el mapa recuerda lo explorado, y solo eso")
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


func _test_title_screen() -> void:
	print("\n[Menú principal: continuar, nuevo juego, opciones]")
	paused = false
	if is_instance_valid(_level):
		_level.queue_free()
		await process_frame
	var options_file := "user://opciones_pruebas.cfg"
	DirAccess.remove_absolute(options_file)
	SaveSlot.new(TEST_SAVE).erase()
	_check(ProjectSettings.get_setting("application/run/main_scene") == "res://game/ui/title_screen.tscn", "el juego arranca en el menú principal")

	var title: Control = load("res://game/ui/title_screen.tscn").instantiate()
	title.save_path = TEST_SAVE
	title.options_path = options_file
	_level = title
	root.add_child(title)
	await _wait(2)
	var menu: MenuList = title.menu
	var started := []
	title.game_started.connect(func(new_game: bool) -> void: started.append(new_game))
	_check(not title.has_save() and menu.selected == title.MAIN_NEW_GAME, "sin partida, Continuar está desactivado y el cursor empieza en Nuevo juego")
	await _press_action("ui_up")
	await _press_action("ui_accept")
	_check(started.is_empty(), "Continuar no hace nada sin partida")
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(started == [true], "Nuevo juego sin partida empieza directamente")

	# Con partida: el cursor empieza en Continuar.
	SaveSlot.new(TEST_SAVE).write({ player = {} })
	title.queue_free()
	await process_frame
	title = load("res://game/ui/title_screen.tscn").instantiate()
	title.save_path = TEST_SAVE
	title.options_path = options_file
	_level = title
	root.add_child(title)
	await _wait(2)
	menu = title.menu
	started = []
	title.game_started.connect(func(new_game: bool) -> void: started.append(new_game))
	_check(title.has_save() and menu.selected == title.MAIN_CONTINUE, "con partida, el cursor empieza en Continuar")
	await _press_action("ui_accept")
	_check(started == [false] and FileAccess.file_exists(TEST_SAVE), "Continuar carga la partida sin borrarla")

	# Nuevo juego con partida: confirmación, con el no por defecto.
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(title.info_label.visible and menu.selected == 0, "Nuevo juego con partida pide confirmación, con el no seleccionado")
	await _press_action("ui_accept")
	_check(not title.info_label.visible and menu.selected == title.MAIN_NEW_GAME and FileAccess.file_exists(TEST_SAVE), "decir que no vuelve al menú sin borrar")
	await _press_action("ui_accept")
	await _press_action("ui_cancel")
	_check(not title.info_label.visible and FileAccess.file_exists(TEST_SAVE), "Esc en la confirmación tampoco borra")
	await _press_action("ui_accept")
	await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(started.back() == true and not FileAccess.file_exists(TEST_SAVE), "confirmar borra la partida y empieza de cero")

	# Opciones: pantalla completa, que se recuerda. (En el juego, empezar cambia
	# de escena; aquí el menú sigue en la confirmación, así que se vuelve a mano.)
	title._show_page(0, title.MAIN_OPTIONS)
	await _press_action("ui_accept")
	_check("Pantalla completa: no" in menu.get_child(0).get_child(1).text, "Opciones muestra la pantalla completa, desactivada por defecto")
	await _press_action("ui_accept")
	_check(title.fullscreen and "Pantalla completa: sí" in menu.get_child(0).get_child(1).text, "Intro la activa")
	var config := ConfigFile.new()
	_check(config.load(options_file) == OK and config.get_value("pantalla", "completa") == true, "y se guarda en el archivo de opciones")
	await _press_action("ui_accept")
	await _press_action("ui_cancel")
	_check(menu.selected == title.MAIN_OPTIONS and not title.fullscreen, "Esc vuelve al menú, con el cursor en Opciones")

	# Controles: el esquema del teclado y los mandos, con otra pestaña por dispositivo.
	title._show_page(0, title.MAIN_CONTROLS)
	await _press_action("ui_accept")
	_check(title.controls_view.visible and not title.menu_panel.visible, "Controles muestra el esquema en lugar del menú")
	var first_device: int = title.controls_view.device
	await _press_action("ui_right")
	_check(title.controls_view.device == (first_device + 1) % 4, "derecha pasa al siguiente dispositivo (teclado, Xbox, PlayStation, Nintendo)")
	await _press_action("ui_left")
	_check(title.controls_view.device == first_device, "izquierda vuelve al anterior")
	await _press_action("ui_cancel")
	_check(not title.controls_view.visible and title.menu_panel.visible and menu.selected == title.MAIN_CONTROLS, "Esc vuelve al menú, con el cursor en Controles")
	title.queue_free()
	_level = null
	await process_frame
	DirAccess.remove_absolute(options_file)


func _test_pause_returns_to_title() -> void:
	print("\n[Pausa: volver al menú principal guarda la partida]")
	await _load_world()
	_player.add_ecos(5)
	var pause = _player.pause_menu
	await _press_action("pause")
	for i in pause.OPTION_TITLE:
		await _press_action("ui_down")
	await _press_action("ui_accept")
	_check(_saved().get("player", {}).get("ecos", 0) == 5, "Menú principal guarda antes de salir")
	_check(not paused, "y quita la pausa")


func _test_menu_list_survives_leaving_the_tree() -> void:
	print("\n[MenuList: elegir una opción que saca la lista de la escena no da errores]")
	paused = false
	var menu := MenuList.new()
	menu.set_entries(PackedStringArray(["Salir de aquí"]))
	root.add_child(menu)
	# Lo que haría "Menú principal": la lista deja de estar en el árbol al elegir.
	menu.chosen.connect(func(_index: int) -> void: root.remove_child(menu))
	# Un espía que solo recibe teclas que nadie ha usado.
	var spy_script := GDScript.new()
	spy_script.source_code = "extends Node\nvar got := 0\nfunc _unhandled_input(event: InputEvent) -> void:\n\tif event.is_action_pressed(&\"ui_accept\"):\n\t\tgot += 1\n"
	spy_script.reload()
	var spy: Node = spy_script.new()
	root.add_child(spy)
	await _wait(2)
	await _press_action("ui_accept")
	_check(not menu.is_inside_tree(), "la opción elegida sacó la lista del árbol")
	_check(spy.got == 0, "y la tecla quedó marcada como usada (antes, el error lo impedía)")
	spy.queue_free()
	menu.queue_free()


# --- Primer jefe, trampas y el puzle del dash -----------------------------------

## Un cuerpo de pruebas que cuenta cuántas veces lo toca una zona peligrosa.
class HazardDummy extends CharacterBody2D:
	var hits: int = 0

	func hazard_hit(_damage: int, _hazard: Node = null) -> void:
		hits += 1


func _test_dash_is_once_per_air_time() -> void:
	await _fresh_level("Dash: uno por salto en el aire; al pisar suelo se recarga")
	_player.unlock_ability(&"dash")
	# Muy arriba, para tener tiempo de caída de sobra entre dos dashes.
	_player.global_position = Vector2(300.0, -900.0)
	_player.velocity = Vector2.ZERO
	await _wait(3)
	Input.action_press(&"dash")
	await _wait(3)
	Input.action_release(&"dash")
	await _wait(1)
	_check(_player.dash.is_dashing, "el primer dash en el aire funciona")
	await _wait(32)
	_check(not _player.dash.is_dashing and not _player.is_on_floor(), "pasados el dash y su enfriamiento seguimos en el aire")
	Input.action_press(&"dash")
	await _wait(3)
	Input.action_release(&"dash")
	await _wait(1)
	_check(not _player.dash.is_dashing, "el segundo dash en el mismo salto no sale")
	await _stand_at(300.0)
	await _wait(30)
	Input.action_press(&"dash")
	await _wait(3)
	Input.action_release(&"dash")
	await _wait(1)
	_check(_player.dash.is_dashing, "al pisar suelo el dash vuelve a estar disponible")


func _test_spikes_hurt_and_return_to_safe_ground() -> void:
	print("\n[Pinchos: hacen daño y devuelven al último suelo seguro, sin matar por caer]")
	await _load_world()
	var galerias: Node2D = _level.get_node("Rooms/GaleriasBajas")
	await _clear_enemies(galerias)
	# Se cruza el foso de pinchos caminando: de pie en la baldosa 12, antes del foso (14-19).
	_player.global_position = _standing_on("GaleriasBajas", 22, 26)
	_player.velocity = Vector2.ZERO
	await _wait(15)
	_check(_level.current_room == galerias and _player.is_on_floor(), "se está de pie junto al foso de pinchos")
	var before: int = _player.health.health
	var edge_x: float = _player.global_position.x
	# Unos pasos hacia el foso y soltar: cae y los pinchos lo devuelven.
	Input.action_press(&"ui_right")
	await _wait(12)
	Input.action_release(&"ui_right")
	await _wait(30)
	_check(_player.health.health == before - 1, "caer en los pinchos quita 1 de vida")
	_check(_player.active_echo == null, "pero no mata ni deja un Eco")
	_check(_player.is_on_floor() and _player.global_position.x < _cell("GaleriasBajas", 25, 0).x and absf(_player.global_position.x - edge_x) < 80.0, "y devuelve al último suelo seguro, antes del foso (pos=%s suelo=%s ultimo=%s)" % [_player.global_position, _player.is_on_floor(), _player.respawn.last_grounded_position])

	# Con la vida justa, sí mata.
	_player.health.health = 1
	await _wait(40)
	Input.action_press(&"ui_right")
	await _wait(12)
	Input.action_release(&"ui_right")
	await _wait(30)
	_check(_player.active_echo != null, "con 1 de vida los pinchos matan (queda un Eco)")


func _test_pulsing_hazards_cycle() -> void:
	await _fresh_level("Pinchos pulsantes: salen, avisan y se retraen; solo hacen daño al salir")
	var dummy := HazardDummy.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	(shape.shape as RectangleShape2D).size = Vector2(10, 10)
	dummy.add_child(shape)
	dummy.add_to_group("player")
	_level.add_child(dummy)
	dummy.global_position = Vector2(2000.0, 2000.0)
	var spikes: Hazard = load("res://game/environment/spikes.tscn").instantiate()
	spikes.period = 2.0
	spikes.active_fraction = 0.5
	spikes.warning_time = 0.4
	_level.add_child(spikes)
	spikes.global_position = dummy.global_position
	await _wait(3)
	_check(spikes.state == Hazard.State.ACTIVE, "empieza activa (fase 0)")
	var seen := {}
	for i in 150:
		await physics_frame
		seen[spikes.state] = true
	_check(seen.has(Hazard.State.ACTIVE) and seen.has(Hazard.State.WARNING) and seen.has(Hazard.State.RETRACTED), "en 2,5 s pasa por activa, aviso y retraída")
	_check(dummy.hits > 0, "hizo daño mientras estaba activa")
	var hits_now := dummy.hits
	# Esperar a que esté retraída y comprobar que ya no cuenta.
	while spikes.state != Hazard.State.RETRACTED:
		await physics_frame
	var at_retract: int = dummy.hits
	await _wait(10)
	_check(spikes.state == Hazard.State.RETRACTED and dummy.hits == at_retract and hits_now <= at_retract, "retraída no hace daño")
	var offset: Hazard = load("res://game/environment/spikes.tscn").instantiate()
	offset.period = 2.0
	offset.active_fraction = 0.5
	offset.warning_time = 0.4
	offset.phase = 0.5
	_level.add_child(offset)
	offset.global_position = Vector2(3000.0, 3000.0)
	_check(offset.state == Hazard.State.RETRACTED, "con medio ciclo de desfase empieza retraída")


func _test_the_way_to_the_boss() -> void:
	print("\n[De la Cisterna se llega, caminando, al Aljibe pasando por las Galerías]")
	await _load_world()
	await _clear_enemies(_level.get_node("Rooms/GaleriasBajas"))
	_player.health.max_health = 99
	_player.health.health = 99
	# Puerta este de la Cisterna: fila 17-21, columnas 62-63; la sala siguiente empieza ahí.
	_player.global_position = _standing_on("Cisterna", 118, 22)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	Input.action_press(&"ui_right")
	await _wait(50)
	Input.action_release(&"ui_right")
	await _wait(6)
	_check(_level.current_room.name == "GaleriasBajas" and _player.is_on_floor() and _player.active_echo == null, "la puerta de la Cisterna lleva a las Galerías Bajas")
	_check(_level.map_data.is_visited(&"GaleriasBajas"), "y se descubre la sala")
	var anchor := _anchor_in("GaleriasBajas")
	_check(anchor != null, "las Galerías tienen un Ancla antes del Aljibe")
	_player.global_position = _standing_on("GaleriasBajas", 106, 26)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	Input.action_press(&"ui_right")
	await _wait(50)
	Input.action_release(&"ui_right")
	await _wait(6)
	_check(_level.current_room.name == "Aljibe" and _player.is_on_floor(), "la puerta de las Galerías lleva al Aljibe")


func _arena() -> Node2D:
	return _level.get_node("Rooms/Aljibe")


## Mete al jugador en el Aljibe, pasada la línea del disparador, con vida de sobra
## para que los ataques del jefe no interfieran con lo que se comprueba.
func _enter_arena(tough: bool = true) -> void:
	_player.global_position = _standing_on("Aljibe", 14, 30)
	_player.velocity = Vector2.ZERO
	if tough:
		_player.health.max_health = 99
		_player.health.health = 99
	await _wait(8)


func _test_boss_phases_and_reward() -> void:
	print("\n[El Centinela: armadura, núcleo expuesto, tres fases y la recompensa]")
	await _load_world()
	var arena := _arena()
	var boss: Node = arena.boss
	_check(is_instance_valid(boss) and boss.state == boss.State.DORMANT, "duerme hasta que el jugador entra")
	_check(boss.armor_hp == 8 and boss.core_hp == 15 and boss.phase == 0, "fase 1: armadura 8 y núcleo 15")
	boss.take_hit(5, 1)
	_check(boss.armor_hp == 8, "dormido no recibe daño")
	var entry_open := true
	for gate in arena._entry_gates:
		entry_open = entry_open and not gate.closed
	var exit_closed := true
	for gate in arena._exit_gates:
		exit_closed = exit_closed and gate.closed
	_check(entry_open and exit_closed, "la reja de entrada está abierta y la de salida cerrada")
	var dash_pickups := 0
	for child in arena.get_children():
		dash_pickups += 1 if child is AbilityPickup else 0
	_check(dash_pickups == 0, "todavía no hay recompensa")

	await _enter_arena()
	var entry_closed := true
	for gate in arena._entry_gates:
		entry_closed = entry_closed and gate.closed
	_check(boss.is_fighting() and entry_closed, "al cruzar la línea despierta y se cierra la reja de entrada")
	_check(arena._bar.visible, "aparece su barra de vida")
	await _wait(110)

	# Fase 1: la armadura primero; el núcleo no se toca hasta romperla.
	for i in 7:
		boss.take_hit(1, 1)
	_check(boss.armor_hp == 1 and boss.core_hp == 15 and boss.state != boss.State.STAGGER, "la armadura gasta puntos pero no se aparta ni toca el núcleo")
	boss.take_hit(1, 1)
	_check(boss.state == boss.State.STAGGER and boss.armor_hp == 0, "al romperla queda expuesto")
	boss.take_hit(1, 1)
	_check(boss.core_hp == 14, "expuesto, sí pierde núcleo")
	for i in 4:
		boss.take_hit(1, 1)
	_check(boss.core_hp == 10 and boss.phase == 1 and boss.armor_hp == 9, "al bajar de la marca pasa a la fase 2 con armadura nueva")
	_check(boss.state == boss.State.GETUP, "y se levanta")
	await _wait(60)
	_check(boss.state in [boss.State.RAGE_WINDUP, boss.State.RAGE_STRIKE, boss.State.RAGE_GAP], "la fase 2 empieza con su furia de mazazos")
	var waves := 0
	for i in 400:
		await physics_frame
		for node in get_nodes_in_group(&"boss_debris"):
			waves += 1 if node is Projectile else 0
	_check(waves > 0, "la furia suelta ondas de polvo")
	_check(boss.state in [boss.State.IDLE, boss.State.WALK, boss.State.RECOVER, boss.State.SLAM_WINDUP, boss.State.SLAM_STRIKE, boss.State.LEAP_CROUCH, boss.State.LEAP_AIR], "tras la furia vuelve a pelear normal")

	# Hacerle daño en la armadura no reinicia la pelea ni la pone en marcha sola.
	for i in 9:
		boss.take_hit(1, 1)
	_check(boss.state == boss.State.STAGGER, "romper la armadura de la fase 2 lo deja expuesto otra vez")
	# Ni el exceso de golpes pasa de fase en fase: el suelo de la fase 2 es 5.
	for i in 12:
		boss.take_hit(1, 1)
	_check(boss.core_hp == 5 and boss.phase == 2 and boss.armor_hp == 10, "el núcleo no baja de la marca de la fase: no se salta ninguna")
	await _wait(60)
	for i in 400:
		await physics_frame
	for i in 10:
		boss.take_hit(1, 1)
	_check(boss.state == boss.State.STAGGER, "fase 3: otra vez armadura y núcleo")

	var defeated := [false]
	arena.boss_defeated.connect(func() -> void: defeated[0] = true)
	var ecos_before: int = _player.ecos
	for i in 6:
		boss.take_hit(1, 1)
	_check(boss.state == boss.State.DYING, "con el núcleo a 0 muere")
	await _wait(130)
	_check(defeated[0] and arena.is_defeated() and arena.boss == null, "su muerte se avisa y la sala queda vencida")
	_check(_player.ecos == ecos_before + 40, "suelta 40 Ecos")
	var open := true
	for gate in arena._entry_gates + arena._exit_gates:
		open = open and not gate.closed
	_check(open, "todas las rejas se abren")
	var reward: AbilityPickup = null
	for child in arena.get_children():
		if child is AbilityPickup:
			reward = child
	_check(reward != null and reward.ability_id == &"dash", "aparece el recuerdo del dash")
	await _wait(4)
	_check("Aljibe" in _saved().get("bosses", []), "se guarda que el jefe está vencido")
	_player.global_position = reward.global_position
	await _wait(6)
	_check(_player.has_ability(&"dash"), "al tocarlo se recuerda el dash")


func _test_boss_attacks_and_parry() -> void:
	print("\n[El Centinela: mazazo con onda, parry que lo expone, onda devuelta, salto y rocas]")
	await _load_world()
	var arena := _arena()
	var boss: Node = arena.boss
	await _enter_arena()
	await _wait(110)
	# Que no decida solo: se le fuerza cada ataque.
	boss.state = boss.State.RECOVER
	boss._timer = 100.0
	boss.global_position.x = _cell("Aljibe", 36, 29).x
	_player.global_position = _standing_on("Aljibe", 22, 30)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	boss._set_facing(-1)
	var health_before: int = _player.health.health
	boss._start_slam()
	_check(boss.state == boss.State.SLAM_WINDUP, "el mazazo empieza con un aviso")
	var windup: float = boss._timer
	_check(windup > 0.5, "que dura más de medio segundo (%.2f s)" % windup)
	# El golpe llega en el fotograma de impacto del mazazo, un poco después del aviso:
	# al empezar el tajo todavía no hay daño ni onda.
	await _wait(int(windup * 60.0) + 3)
	var early_waves := 0
	for node in get_nodes_in_group(&"boss_debris"):
		early_waves += 1 if node is Projectile else 0
	_check(boss.state == boss.State.SLAM_STRIKE and early_waves == 0 and _player.health.health == health_before, "al empezar el tajo aún no hay golpe: llega cuando el mazo toca el suelo")
	await _wait(13)
	_check(_player.health.health <= health_before - 2 or boss.state == boss.State.SLAM_STRIKE, "el mazazo pega fuerte a quien está al alcance")
	var wave: Projectile = null
	for node in get_nodes_in_group(&"boss_debris"):
		if node is Projectile:
			wave = node
	_check(wave != null and wave.target_group == &"player", "suelta una onda de polvo contra el jugador")
	_check(wave != null and wave.reflect_group == &"enemy", "que un parry devuelve contra él")
	# Onda devuelta: le hace el doble.
	var armor_before: int = boss.armor_hp
	boss.take_hit(1, 1, wave)
	_check(boss.armor_hp == armor_before - 2, "una onda devuelta le quita 2 de armadura")

	# Parry en el mazazo: queda expuesto sin romper la armadura.
	boss.state = boss.State.SLAM_STRIKE
	var armor_now: int = boss.armor_hp
	boss.on_parried(0.0)
	_check(boss.state == boss.State.STAGGER and boss.armor_hp == armor_now, "un parry lo expone sin gastar armadura")
	boss.take_hit(1, 1)
	_check(boss.core_hp == 14, "y el núcleo recibe daño")
	boss._timer = 0.0
	await _wait(2)
	_check(boss.state == boss.State.GETUP and boss.phase == 0 and boss.armor_hp == armor_now, "al levantarse sigue en la misma fase con la armadura que tenía")

	# El salto cae junto al jugador y hace daño rasante; saltar lo evita.
	boss.state = boss.State.RECOVER
	boss._timer = 100.0
	boss.global_position = Vector2(_cell("Aljibe", 52, 29).x, boss.global_position.y)
	_player.global_position = _standing_on("Aljibe", 22, 30)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	boss._face_player()
	boss._start_leap()
	_check(boss.state == boss.State.LEAP_CROUCH, "el salto empieza agachándose")
	await _wait(int(boss._timer * 60.0) + 3)
	_check(boss.state == boss.State.LEAP_AIR, "y despega")
	var land_x: float = _player.global_position.x + boss.LEAP_STANDOFF
	var landed := false
	for i in 90:
		await physics_frame
		if boss.state != boss.State.LEAP_AIR:
			landed = true
			break
	_check(landed and absf(boss.global_position.x - land_x) < 70.0, "cae junto al jugador (a ~90 px, no encima)")

	# Rocas: aviso en el suelo y luego caen.
	var rocks: Array = []
	boss._drop_rocks(2, _cell("Aljibe", 0, 30).y - 8.0)
	for node in get_nodes_in_group(&"boss_debris"):
		if node.has_method("start") and not node is Projectile:
			rocks.append(node)
	_check(rocks.size() >= 2, "caen rocas del techo")
	_check(rocks.size() > 0 and not rocks[0]._falling, "con aviso antes de caer")
	await _wait(60)
	await _wait(60)
	var all_gone := true
	for rock in rocks:
		all_gone = all_gone and (not is_instance_valid(rock) or rock.is_queued_for_deletion())
	_check(all_gone, "y se rompen al llegar al suelo")


func _test_boss_death_survives_the_player_dying() -> void:
	print("
[Si el jugador muere mientras el jefe agoniza, la victoria no se pierde]")
	await _load_world()
	var arena := _arena()
	var boss: Node = arena.boss
	await _enter_arena()
	await _wait(110)
	boss._enter_stagger(3.0)
	boss._rage_left = 0
	boss.core_hp = 1
	boss.phase = 2
	boss.take_hit(1, 1)
	_check(boss.state == boss.State.DYING, "el jefe empieza a morir")
	_player.die()
	await _wait(4)
	# (Lejos del Aljibe la sala deja de procesar; al volver, termina de morir.)
	_player.global_position = _standing_on("Aljibe", 14, 30)
	_player.velocity = Vector2.ZERO
	await _wait(150)
	_check(arena.is_defeated() and arena.boss == null, "aunque el jugador muera en ese momento, el jefe queda vencido")
	var rewards := 0
	for child in arena.get_children():
		rewards += 1 if child is AbilityPickup and not child.is_queued_for_deletion() else 0
	_check(rewards == 1, "y la recompensa está en la sala")


func _test_boss_planks_and_rocks() -> void:
	print("\n[El jefe baja de los tablones y salta hasta ellos; las rocas caen hasta el suelo que haya debajo]")
	await _load_world()
	var arena := _arena()
	var boss: Node = arena.boss
	await _enter_arena()
	await _wait(110)
	boss.state = boss.State.RECOVER
	boss._timer = 100.0
	var floor_top: float = _cell("Aljibe", 0, 30).y - 8.0
	var plank_top: float = _cell("Aljibe", 0, 23).y - 8.0
	# Sobre el tablón (columnas 12-21 de la fila 23), con el jugador abajo: baja.
	boss.global_position = Vector2(_cell("Aljibe", 16, 0).x, plank_top - boss.HALF_HEIGHT - 1.0)
	boss.velocity = Vector2.ZERO
	_player.global_position = _standing_on("Aljibe", 30, 30)
	_player.velocity = Vector2.ZERO
	await _wait(20)
	_check(absf(boss.feet_y() - plank_top) < 3.0, "el jefe se apoya en el tablón (feet=%s tablón=%s)" % [boss.feet_y(), plank_top])
	boss.state = boss.State.IDLE
	boss._timer = 100.0
	await _wait(60)
	_check(absf(boss.feet_y() - floor_top) < 3.0, "con el jugador debajo, baja del tablón hasta el suelo (feet=%s suelo=%s)" % [boss.feet_y(), floor_top])
	# Si el jugador está en su mismo tablón, se queda.
	boss.global_position = Vector2(_cell("Aljibe", 14, 0).x, plank_top - boss.HALF_HEIGHT - 1.0)
	boss.velocity = Vector2.ZERO
	_player.global_position = _standing_on("Aljibe", 19, 23)
	_player.velocity = Vector2.ZERO
	await _wait(20)
	boss.state = boss.State.IDLE
	boss._timer = 100.0
	await _wait(40)
	_check(absf(boss.feet_y() - plank_top) < 3.0, "con el jugador en su tablón, no baja")

	# El salto llega hasta un jugador que está en un tablón alto.
	boss.state = boss.State.RECOVER
	boss._timer = 100.0
	boss.global_position = Vector2(_cell("Aljibe", 30, 0).x, floor_top - boss.HALF_HEIGHT)
	boss.velocity = Vector2.ZERO
	_player.global_position = _standing_on("Aljibe", 48, 23)
	_player.velocity = Vector2.ZERO
	await _wait(20)
	boss._face_player()
	boss._start_leap()
	await _wait(int(boss._timer * 60.0) + 3)
	await _wait(75)
	_check(absf(boss.feet_y() - plank_top) < 3.0, "el salto sube hasta el tablón del jugador (feet=%s tablón=%s)" % [boss.feet_y(), plank_top])

	# Rocas: sin tablón debajo llegan al suelo aunque el jefe esté más alto; sobre un tablón se rompen en él.
	var rock_scene: PackedScene = load("res://game/boss/falling_rock.tscn")
	var ceiling: float = _cell("Aljibe", 0, 0).y + 8.0
	var open_rock: Node = rock_scene.instantiate()
	arena.add_child(open_rock)
	open_rock.start(Vector2(_cell("Aljibe", 30, 0).x, ceiling + 24.0), plank_top)
	var covered_rock: Node = rock_scene.instantiate()
	arena.add_child(covered_rock)
	covered_rock.start(Vector2(_cell("Aljibe", 16, 0).x, ceiling + 24.0), floor_top)
	_check(absf(open_rock._floor_y - floor_top) < 2.0, "una roca sin nada debajo cae hasta el suelo, aunque el jefe esté en un tablón (%s)" % open_rock._floor_y)
	_check(absf(covered_rock._floor_y - plank_top) < 2.0, "y sobre un tablón se rompe en el tablón (%s)" % covered_rock._floor_y)
	open_rock.queue_free()
	covered_rock.queue_free()


func _test_boss_does_not_stay_on_top_of_the_player() -> void:
	print("\n[Si el jefe cae encima del jugador, no se queda subido a su cabeza]")
	await _load_world()
	var arena := _arena()
	var boss: Node = arena.boss
	await _enter_arena()
	await _wait(110)
	boss.state = boss.State.RECOVER
	boss._timer = 100.0
	var floor_top: float = _cell("Aljibe", 0, 30).y - 8.0
	boss.global_position = Vector2(_cell("Aljibe", 40, 0).x, floor_top - boss.HALF_HEIGHT)
	boss.velocity = Vector2.ZERO
	_player.global_position = _standing_on("Aljibe", 24, 30)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	boss._face_player()
	boss._start_leap()
	await _wait(int(boss._timer * 60.0) + 3)
	# En pleno vuelo, el jugador se mete justo bajo el sitio de caída.
	await _wait(20)
	_player.global_position = Vector2(boss.global_position.x + boss.velocity.x * 0.45, _player.global_position.y)
	_player.velocity = Vector2.ZERO
	await _wait(90)
	_check(absf(boss.feet_y() - floor_top) < 3.0, "el jefe acaba en el suelo, no subido al jugador (feet=%s suelo=%s)" % [boss.feet_y(), floor_top])
	await _wait(60)
	_check(absf(boss.global_position.x - _player.global_position.x) >= boss.HALF_WIDTH + 12.0 and boss._ghosted == null, "y se aparta: ya no se atraviesan")


func _test_boss_waves_follow_the_ground_and_dust_needs_ground() -> void:
	print("\n[La onda cae de los tablones al suelo y sigue; el polvo solo sale sobre suelo; no golpea sobre el vacío]")
	await _load_world()
	var arena := _arena()
	var boss: Node = arena.boss
	await _enter_arena()
	await _wait(110)
	boss.state = boss.State.RECOVER
	boss._timer = 100.0
	var floor_top: float = _cell("Aljibe", 0, 30).y - 8.0
	var plank_top: float = _cell("Aljibe", 0, 23).y - 8.0
	var plank_right: float = _cell("Aljibe", 22, 0).x - 8.0
	# Una onda que sale del borde derecho del tablón (columnas 12-21) hacia la derecha.
	var wave: Projectile = load("res://game/boss/shockwave.tscn").instantiate()
	arena.add_child(wave)
	wave.global_position = Vector2(plank_right - 30.0, plank_top - 16.0)
	wave.launch(Vector2.RIGHT)
	await _wait(8)
	_check(absf(wave.global_position.y - (plank_top - 16.0)) < 4.0, "corre pegada al tablón mientras hay tablón")
	await _wait(45)
	_check(is_instance_valid(wave) and wave.global_position.x > plank_right and absf(wave.global_position.y - (floor_top - 16.0)) < 4.0, "al acabarse el tablón cae al suelo de abajo y sigue avanzando (x=%s y=%s)" % [wave.global_position.x, wave.global_position.y])
	var before: float = wave.global_position.x
	await _wait(10)
	_check(is_instance_valid(wave) and wave.global_position.x > before, "y continúa por el suelo")
	wave.queue_free()

	# Polvo: sobre el tablón solo donde hay tablón.
	var dust_script: Script = load("res://game/boss/impact_dust.gd")
	var plank_center: float = _cell("Aljibe", 16, 0).x + 8.0
	dust_script.spawn(arena, plank_center, plank_top, 150.0)
	var dust: Node2D = null
	for child in arena.get_children():
		if child.get_script() == dust_script:
			dust = child
	var inside := dust != null
	if dust:
		for puff in dust._puffs:
			inside = inside and absf(puff.x) <= 96.0
	_check(dust != null and not dust._puffs.is_empty() and inside, "el polvo de un aterrizaje en un tablón no sale fuera de él")
	if dust:
		dust.queue_free()
	dust_script.spawn(arena, _cell("Aljibe", 32, 0).x, floor_top, 150.0)
	var floor_dust: Node2D = null
	for child in arena.get_children():
		if child.get_script() == dust_script and child != dust:
			floor_dust = child
	_check(floor_dust != null and floor_dust._puffs.size() >= 9, "y sobre el suelo sale con todo su ancho")

	# No golpea con el mazo en el aire: desde un tablón (el mazo cae fuera) salta o baja.
	boss.global_position = Vector2(plank_center, plank_top - boss.HALF_HEIGHT - 1.0)
	boss.velocity = Vector2.ZERO
	_player.global_position = _standing_on("Aljibe", 24, 23 + 7)
	await _wait(15)
	boss._set_facing(1)
	_check(not boss._slam_supported(), "desde un tablón estrecho el mazo cae fuera de él: no hay golpe posible")
	boss.state = boss.State.IDLE
	boss._timer = 0.0
	boss._last_was_leap = false
	boss._decide()
	_check(boss.state == boss.State.LEAP_CROUCH or boss.state == boss.State.WALK, "y en vez de golpear en el aire, se recoloca")
	boss.global_position = Vector2(_cell("Aljibe", 36, 0).x, floor_top - boss.HALF_HEIGHT)
	boss.velocity = Vector2.ZERO
	await _wait(15)
	boss._set_facing(-1)
	_check(boss._slam_supported(), "en el suelo, el mazazo sí tiene dónde caer")


func _test_enemies_only_act_in_their_own_room() -> void:
	print("\n[Los enemigos solo actúan dentro de su sala, y no nada más entrar en ella]")
	await _load_world()
	_player.health.max_health = 99
	_player.health.health = 99
	var terrazas: Node2D = _level.get_node("Rooms/TerrazasSecas")
	var east_enemies: Array = []
	for child in terrazas.get_children():
		if child is EntitySpawner and is_instance_valid(child.instance) and child.global_position.x > terrazas.global_position.x + 50.0 * 16.0:
			east_enemies.append(child.instance)
	_check(not east_enemies.is_empty(), "hay un enemigo en el lado este de las Terrazas")
	# El jugador está en la Torre, al otro lado de la puerta, a unas baldosas del enemigo.
	_player.global_position = _standing_on("TorreDeRiego", 3, 40)
	_player.velocity = Vector2.ZERO
	await _wait(90)
	var calm := true
	for enemy in east_enemies:
		calm = calm and enemy.ai.state == PatrolChaseAI.State.PATROL
	_check(calm, "desde la sala de al lado no lo persigue ni lo ataca")
	# Recién entrado en la sala (junto a la puerta) todavía no lo nota.
	_player.global_position = _standing_on("TerrazasSecas", 62, 20)
	_player.velocity = Vector2.ZERO
	await _wait(60)
	calm = true
	for enemy in east_enemies:
		calm = calm and enemy.ai.state == PatrolChaseAI.State.PATROL
	_check(calm, "y recién cambiado de sala, junto a la puerta, tampoco")
	# Ya dentro, sí.
	_player.global_position = _standing_on("TerrazasSecas", 52, 20)
	_player.velocity = Vector2.ZERO
	await _wait(60)
	var woke := false
	for enemy in east_enemies:
		woke = woke or enemy.ai.state != PatrolChaseAI.State.PATROL
	_check(woke, "dentro de su sala sí actúa con normalidad")


func _test_boss_resets_and_stays_dead() -> void:
	print("\n[El jefe: si se muere el jugador se reinicia; vencido, sigue vencido tras cargar]")
	await _load_world()
	var arena := _arena()
	await _enter_arena(false)
	_check(arena.boss.is_fighting(), "la pelea está en marcha")
	arena.boss.armor_hp = 3
	_player.die()
	await _wait(6)
	_check(is_instance_valid(arena.boss) and arena.boss.state == arena.boss.State.DORMANT and arena.boss.armor_hp == 8, "al morir el jugador el jefe vuelve a dormir con todo")
	var entry_open := true
	for gate in arena._entry_gates:
		entry_open = entry_open and not gate.closed
	_check(entry_open and not arena._bar.visible, "se abre la reja y se oculta la barra")

	# Vencido: partida guardada y cargada.
	arena.boss.queue_free()
	arena.mark_defeated()
	_level.save_game()
	await _load_world(true)
	var again := _arena()
	_check(again.is_defeated() and again.boss == null, "cargada la partida, el jefe sigue vencido")
	var pickups := 0
	for child in again.get_children():
		pickups += 1 if child is AbilityPickup and not child.is_queued_for_deletion() else 0
	_check(pickups == 1, "y su recompensa sigue esperando si no se había recogido")
	_player.unlock_ability(&"dash")
	_level.save_game()
	await _load_world(true)
	pickups = 0
	for child in _arena().get_children():
		pickups += 1 if child is AbilityPickup and not child.is_queued_for_deletion() else 0
	_check(pickups == 0, "recogida, no vuelve a aparecer")


## Repite en el motor, fotograma a fotograma, una maniobra pensada con
## `tests/puzzle_plans.json` (generada con un simulador de los saltos). Devuelve
## si acaba de pie. Las pulsaciones de salto y dash se adelantan un fotograma
## porque Input solo las marca "recién pulsadas" en el siguiente.
func _replay_plan(plan: Dictionary, start: Vector2) -> bool:
	_player.global_position = start
	_player.velocity = Vector2.ZERO
	_player.dash.is_dashing = false
	await _wait(12)
	var delay: int = plan.delay
	var held := {}
	var left_floor := false
	for f in range(-1, 220):
		var direction := 0
		if f >= 0:
			direction = plan.d1 if (f < delay or f - delay < int(plan.k)) else plan.d2
		var jump_held := f + 1 >= delay and f + 1 - delay < int(plan.hold)
		var dash_next: bool = plan.dashAt != null and f + 1 == int(plan.dashAt)
		if plan.dashAt != null and f == int(plan.dashAt) and int(plan.dashDir) != 0:
			direction = int(plan.dashDir)
		var wanted := { &"ui_right": direction > 0, &"ui_left": direction < 0, &"ui_accept": jump_held, &"dash": dash_next }
		for action in wanted:
			# Solo al cambiar: repetir action_press cada fotograma anula el corte del salto.
			if held.get(action, false) != wanted[action]:
				held[action] = wanted[action]
				if wanted[action]:
					Input.action_press(action)
				else:
					Input.action_release(action)
		await physics_frame
		if f >= 0:
			if not _player.is_on_floor():
				left_floor = true
			elif left_floor:
				break
	for action in held:
		Input.action_release(action)
	await _wait(8)
	return _player.is_on_floor()


func _test_dash_puzzle_needs_dash() -> void:
	print("\n[El puzle del dash: cada tramo se supera con la maniobra prevista y no sin dash]")
	await _load_world()
	var plans: Array = JSON.parse_string(FileAccess.get_file_as_string("res://tests/puzzle_plans.json"))
	_check(plans.size() >= 9, "hay %d maniobras de referencia (la Chimenea y la Pasarela)" % plans.size())
	_player.unlock_ability(&"dash")
	var failures := []
	for entry in plans:
		var room: Node2D = _level.get_node("Rooms/" + entry.room)
		_level._enter_room(room, false, false)
		var start: Vector2 = room.global_position + Vector2(entry.sx, entry.from.row * 16.0 - 24.0)
		var stood: bool = await _replay_plan(entry.plan, start)
		var target_y: float = room.global_position.y + entry.to.row * 16.0 - 24.0
		var x0: float = room.global_position.x + entry.to.c0 * 16.0 - 4.0
		var x1: float = room.global_position.x + (entry.to.c1 + 1) * 16.0 + 4.0
		var good: bool = stood and absf(_player.global_position.y - target_y) < 6.0 and _player.global_position.x >= x0 and _player.global_position.x <= x1
		if not good:
			failures.append("%s fila %d -> %d (acabó en %s)" % [entry.room, entry.from.row, entry.to.row, _player.global_position])
	_check(failures.is_empty(), "las maniobras de referencia llegan a su destino%s" % ("" if failures.is_empty() else ": fallan " + str(failures)))
	# Sin el dash, la primera no llega: cae en los pinchos y vuelve.
	var first: Dictionary = plans[0]
	var room_a: Node2D = _level.get_node("Rooms/" + first.room)
	_level._enter_room(room_a, false, false)
	_player.dash.unlocked = false
	_player.health.max_health = 99
	_player.health.health = 99
	var start_a: Vector2 = room_a.global_position + Vector2(first.sx, first.from.row * 16.0 - 24.0)
	await _replay_plan(first.plan, start_a)
	await _wait(20)
	var far_x: float = room_a.global_position.x + first.to.c0 * 16.0
	_check(_player.global_position.x < far_x - 32.0 and _player.health.health == 98 and _player.active_echo == null, "sin dash el primer foso no se cruza: cae en los pinchos (1 de vida) y vuelve al suelo")


func _test_the_bridge_ends_in_a_lookout() -> void:
	print("\n[La salida alta de la Chimenea da a la Pasarela, que acaba en un mirador con Ancla]")
	await _load_world()
	_player.global_position = _standing_on("Chimenea", 34, 8)
	_player.velocity = Vector2.ZERO
	await _wait(10)
	Input.action_press(&"ui_right")
	await _wait(40)
	Input.action_release(&"ui_right")
	await _wait(6)
	_check(_level.current_room.name == "Pasarela" and _player.is_on_floor(), "se sale de la Chimenea a la Pasarela caminando")
	_check(_anchor_in("Pasarela") != null, "al final de la Pasarela hay un Ancla")
	_player.global_position = _standing_on("Pasarela", 90, 8)
	_player.velocity = Vector2.ZERO
	await _wait(20)
	Input.action_press(&"ui_right")
	await _wait(120)
	Input.action_release(&"ui_right")
	_check(_player.global_position.x < _level.get_node("Rooms/Pasarela").global_position.x + 98.0 * 16.0, "el mirador acaba en una pared: de momento no se sigue más allá")


## Quita los enemigos de una sala (para pruebas que no tratan de combatir).
func _clear_enemies(room: Node) -> void:
	for child in room.get_children():
		if child is EntitySpawner:
			child.queue_free()
	await _wait(2)
