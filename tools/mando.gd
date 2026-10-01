extends Control
## Diagnóstico del mando: muestra qué mandos ve Godot y, al pulsar cada botón o
## mover cada palanca, qué número le da y qué acción del juego dispara.
##
## Uso: abrir tools/mando.tscn en el editor y pulsar F6 (ejecutar escena actual).
## Si un mando sale como "no reconocido", Godot no sabe qué botón es cada uno y
## los numera en bruto: entonces los botones no caen en su sitio.

## Acciones del juego que interesa comprobar (ver project.godot, sección [input]).
const ACTIONS: Array[StringName] = [
	&"ui_left", &"ui_right", &"ui_up", &"ui_down", &"ui_accept", &"ui_cancel",
	&"attack", &"heal", &"interact", &"dash", &"parry", &"pause",
]
const MAX_LINES := 14

var _lines: PackedStringArray = []
## Último sentido (-1, 0, 1) de cada eje, para anotar solo al cruzar la zona muerta.
var _axis_state: Dictionary = {}

@onready var label: Label = $Label


func _ready() -> void:
	Input.joy_connection_changed.connect(func(_device: int, _connected: bool) -> void: _refresh())
	_refresh()


func _input(event: InputEvent) -> void:
	if event is InputEventJoypadButton and event.pressed:
		_add(event, "pulsado")
	elif event is InputEventJoypadMotion:
		var key := "%d:%d" % [event.device, event.axis]
		var direction := 0 if absf(event.axis_value) < 0.5 else int(signf(event.axis_value))
		if direction != _axis_state.get(key, 0):
			_axis_state[key] = direction
			if direction != 0:
				_add(event, "%+.2f" % event.axis_value)


func _add(event: InputEvent, detail: String) -> void:
	var actions := PackedStringArray()
	for action in ACTIONS:
		if InputMap.event_is_action(event, action):
			actions.append(action)
	var result := ", ".join(actions) if not actions.is_empty() else "NINGUNA"
	_lines.append("Mando %d · %s (%s) → %s" % [event.device, event.as_text(), detail, result])
	if _lines.size() > MAX_LINES:
		_lines.remove_at(0)
	_refresh()


func _refresh() -> void:
	var header := PackedStringArray(["DIAGNÓSTICO DEL MANDO — pulsa cada botón y mueve cada palanca", ""])
	var pads := Input.get_connected_joypads()
	if pads.is_empty():
		header.append("No hay ningún mando conectado.")
	for device in pads:
		header.append("Mando %d: %s" % [device, Input.get_joy_name(device)])
		header.append("   %s · GUID %s" % [
			"reconocido" if Input.is_joy_known(device) else "NO RECONOCIDO (botones en bruto)",
			Input.get_joy_guid(device)])
		header.append("   %s" % str(Input.get_joy_info(device)))
	header.append("")
	label.text = "\n".join(header) + "\n" + "\n".join(_lines)
