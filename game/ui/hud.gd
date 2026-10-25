extends CanvasLayer
## Indicadores en pantalla: minimapa, vida (barra), curaciones (frascos), Ecos
## (icono y cifra), mensajes temporales y recordatorio de controles. No conoce al
## jugador: el jugador le pasa los números (los datos bajan, ver
## docs/arquitectura.md).

@onready var minimap: MapView = $Minimap
@onready var health_bar: SegmentedBar = $HealthBar
@onready var heal_flasks: IconRow = $HealFlasks
@onready var ecos_label: Label = $Ecos/Amount
@onready var message_box: PanelContainer = $MessageBox
@onready var message_label: Label = $MessageBox/MessageLabel
@onready var controls_hint: InputHintBar = $ControlsLabel


func _ready() -> void:
	# El botón de pausa y controles, con el icono del dispositivo que se use.
	controls_hint.set_entries([{ action = &"pause", hint = InputGlyphs.Hint.MENU }])


func set_health(value: int, max_value: int) -> void:
	health_bar.set_values(value, max_value)


func set_heal_charges(charges: int, max_charges: int) -> void:
	heal_flasks.set_values(charges, max_charges)


const DRINKING_TINT := Color(1.0, 0.82, 0.4)

var _drink_bar: ColorRect
var _drink_tween: Tween


## Estado "bebiendo": los frascos se tiñen de ámbar y una barrita bajo ellos se
## llena durante el sorbo. Se apaga al terminar o al ser interrumpido.
func set_drinking(active: bool, duration: float = 0.0) -> void:
	if _drink_tween:
		_drink_tween.kill()
	heal_flasks.modulate = DRINKING_TINT if active else Color.WHITE
	if _drink_bar == null:
		_drink_bar = ColorRect.new()
		_drink_bar.color = DRINKING_TINT
		_drink_bar.position = Vector2(0.0, heal_flasks.size.y + 2.0)
		heal_flasks.add_child(_drink_bar)
	_drink_bar.visible = active
	if active:
		_drink_bar.size = Vector2(0.0, 3.0)
		_drink_tween = create_tween()
		_drink_tween.tween_property(_drink_bar, "size:x", 60.0, maxf(duration, 0.01))


## Sin mapa (p. ej. en el banco de pruebas) el minimapa no se muestra.
func set_map(data: MapData) -> void:
	minimap.data = data
	minimap.visible = data != null


func set_ecos(amount: int) -> void:
	ecos_label.text = str(amount)


## Un recuadro translúcido con el texto, o nada si `text` está vacío (así no
## queda un recuadro vacío flotando cuando no hay ningún mensaje).
func set_message(text: String) -> void:
	message_label.text = text
	message_box.visible = not text.is_empty()
