extends Node2D

## Ancla de Memoria: punto de control. Al acercarse el jugador, cura del
## todo, recarga la curación de usos limitados, y fija aquí su próximo
## punto de reaparición. Se activa solo con tocarla, sin botón dedicado.
##
## Pendiente para más adelante: reiniciar a los enemigos normales del área
## al activarse (falta un sistema de seguimiento/reaparición de enemigos
## que todavía no existe).

@onready var area: Area2D = $Area2D


func _ready() -> void:
	area.body_entered.connect(_on_area_body_entered)


func _on_area_body_entered(body: Node) -> void:
	if not body.is_in_group("player"):
		return
	body.rest_at(global_position)
