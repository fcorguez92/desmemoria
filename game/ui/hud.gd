extends CanvasLayer
## Indicadores en pantalla: vida (barra), curaciones (frascos), Ecos (icono y
## cifra), mensajes temporales y recordatorio de controles. No conoce al jugador:
## el jugador le pasa los números (los datos bajan, ver docs/arquitectura.md).

@onready var health_bar: SegmentedBar = $HealthBar
@onready var heal_flasks: IconRow = $HealFlasks
@onready var ecos_label: Label = $Ecos/Amount
@onready var message_label: Label = $MessageLabel


func set_health(value: int, max_value: int) -> void:
	health_bar.set_values(value, max_value)


func set_heal_charges(charges: int, max_charges: int) -> void:
	heal_flasks.set_values(charges, max_charges)


func set_ecos(amount: int) -> void:
	ecos_label.text = str(amount)


func set_message(text: String) -> void:
	message_label.text = text
