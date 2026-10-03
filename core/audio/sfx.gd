class_name Sfx
extends Node
## Efectos de sonido. Una biblioteca de sonidos por nombre y un reproductor con
## varias voces, para que unos sonidos no corten a otros.
##
## Uso:
##   Sfx.setup(get_tree(), "res://game/audio/sfx")    # una vez; es idempotente
##   Sfx.play(sonido)                               # sin posición (interfaz)
##   Sfx.play(sonido, global_position)          # en el mundo: suena más bajo
##                                                    # y más a un lado según dónde esté
##
## Los archivos de la carpeta se llaman `nombre_1.wav`, `nombre_2.wav`...: cada
## `nombre` es un sonido y los números son variantes, de las que se elige una al
## azar (con un poco de variación de tono) para que no suene a máquina. Si un
## sonido no existe, no pasa nada: se ignora.
##
## Todo sale por el bus "SFX", que se crea aquí con un filtro que oscurece los
## agudos y una reverberación corta de cueva (el aire de Hollow Knight). Sigue
## sonando con el juego en pausa, para los menús.
##
## Hay un solo nodo, colgado de la raíz del árbol (como InputGlyphTracker).

const BUS := &"SFX"
const WORLD_VOICES := 14
const UI_VOICES := 6
## Más lejos que esto del centro de la cámara, un sonido del mundo no se oye.
const MAX_DISTANCE := 640.0
## Segundos mínimos entre dos reproducciones del mismo sonido (evita que se
## apilen, p. ej. varios enemigos dando el mismo paso a la vez).
const MIN_GAP := 0.045

static var _instance: Sfx
static var _library: Dictionary = {}

var _world: Array[AudioStreamPlayer2D] = []
var _ui: Array[AudioStreamPlayer] = []
var _last_played: Dictionary = {}
var _rng := RandomNumberGenerator.new()


## Prepara el reproductor y carga la carpeta de sonidos (si no estaba ya).
static func setup(tree: SceneTree, directory: String) -> void:
	if not is_instance_valid(_instance):
		_instance = Sfx.new()
		_instance.name = "Sfx"
		tree.root.add_child.call_deferred(_instance)
	if _library.is_empty():
		_library = _load_directory(directory)


## ¿Existe el sonido?
static func has(sound: StringName) -> bool:
	return _library.has(sound)


## Reproduce un sonido. Sin `at`, suena sin posición (interfaz). `volume_db` se suma
## al volumen propio del sonido; `pitch` multiplica el tono (1 = tal cual).
static func play(sound: StringName, at: Variant = null, volume_db: float = 0.0, pitch: float = 1.0) -> void:
	if not is_instance_valid(_instance) or not _instance.is_inside_tree():
		return
	var variants: Array = _library.get(sound, [])
	if variants.is_empty():
		return
	_instance._play(sound, variants, at, volume_db, pitch)


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.randomize()
	_ensure_bus()
	for i in WORLD_VOICES:
		var voice := AudioStreamPlayer2D.new()
		voice.bus = BUS
		voice.max_distance = MAX_DISTANCE
		voice.attenuation = 1.6
		add_child(voice)
		_world.append(voice)
	for i in UI_VOICES:
		var voice := AudioStreamPlayer.new()
		voice.bus = BUS
		add_child(voice)
		_ui.append(voice)


func _play(sound: StringName, variants: Array, at: Variant, volume_db: float, pitch: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	if now - float(_last_played.get(sound, -1.0)) < MIN_GAP:
		return
	_last_played[sound] = now
	var stream: AudioStream = variants[_rng.randi() % variants.size()]
	var scale := pitch * _rng.randf_range(0.94, 1.06)
	if at is Vector2:
		# Un sonido fuera de alcance no se oiría: no gasta una voz.
		var camera := get_viewport().get_camera_2d()
		if camera and camera.get_screen_center_position().distance_to(at) > MAX_DISTANCE:
			return
		var voice := _free_voice(_world) as AudioStreamPlayer2D
		if voice == null:
			return
		voice.stream = stream
		voice.global_position = at
		voice.volume_db = volume_db
		voice.pitch_scale = scale
		voice.play()
	else:
		var voice := _free_voice(_ui) as AudioStreamPlayer
		if voice == null:
			return
		voice.stream = stream
		voice.volume_db = volume_db
		voice.pitch_scale = scale
		voice.play()


## Una voz libre, o la que lleva más tiempo sonando si están todas ocupadas.
func _free_voice(voices: Array) -> Node:
	for voice in voices:
		if not voice.playing:
			return voice
	var oldest: Node = voices[0]
	for voice in voices:
		if voice.get_playback_position() > oldest.get_playback_position():
			oldest = voice
	return oldest


func _ensure_bus() -> void:
	if AudioServer.get_bus_index(BUS) != -1:
		return
	AudioServer.add_bus()
	var index := AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, BUS)
	var dark := AudioEffectLowPassFilter.new()
	dark.cutoff_hz = 7000.0
	AudioServer.add_bus_effect(index, dark)
	var cave := AudioEffectReverb.new()
	cave.room_size = 0.55
	cave.damping = 0.75
	cave.wet = 0.16
	cave.dry = 1.0
	cave.spread = 0.8
	AudioServer.add_bus_effect(index, cave)


## Agrupa los .wav de una carpeta por nombre (quitando el sufijo `_<número>`).
static func _load_directory(directory: String) -> Dictionary:
	var library := {}
	for file in DirAccess.get_files_at(directory):
		# Un export de Godot deja solo los .import: se quita ese sufijo para abrir el recurso.
		var resource := file.trim_suffix(".import")
		if not resource.ends_with(".wav"):
			continue
		var base := resource.get_basename()
		var split := base.rfind("_")
		var key := StringName(base.substr(0, split) if split > 0 and base.substr(split + 1).is_valid_int() else base)
		var stream := load(directory.path_join(resource)) as AudioStream
		if stream == null:
			continue
		if not library.has(key):
			library[key] = []
		if not library[key].has(stream):
			library[key].append(stream)
	return library
