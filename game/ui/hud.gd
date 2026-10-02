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
