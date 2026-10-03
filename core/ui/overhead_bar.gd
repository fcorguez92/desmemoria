class_name OverheadBar
extends Node2D
## Barra de vida flotante sobre una entidad (un enemigo): invisible hasta que recibe
## daño, entonces aparece unos segundos y se vuelve a ocultar. Al perder vida, un
## trozo claro se queda un momento y se encoge hasta alcanzar la barra, para que se
## vea cuánto ha costado el golpe.
##
## Escucha el `HealthComponent` (los eventos suben): no dibuja nada si nadie ha
## hecho daño. Se coloca en el dueño con `offset`.

## Vida a mostrar (requiere node_paths en el .tscn, ver core/README.md).
@export var health: HealthComponent
## Ancho de la barra en píxeles y altura.
@export var bar_width: float = 28.0
@export var bar_height: float = 4.0
## Segundos que sigue visible tras el último golpe.
@export var show_time: float = 2.5
@export var fill_color: Color = Color(0.78, 0.26, 0.24)

var _visible_time: float = 0.0
## Fracción de vida que se está "descontando" (el trozo claro).
var _chip: float = 1.0


func _ready() -> void:
	visible = false
	if health:
		_chip = float(health.health) / maxf(health.max_health, 1.0)
		health.damaged.connect(_on_damaged)
	set_process(false)


func _on_damaged(_amount: int) -> void:
	_visible_time = show_time
	visible = true
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_visible_time -= delta
	var current := _fraction()
	_chip = maxf(current, _chip - delta * 0.9)
	if _visible_time <= 0.0 and _chip <= current + 0.001:
		visible = false
		set_process(false)
	queue_redraw()


func _fraction() -> float:
	return clampf(float(health.health) / maxf(health.max_health, 1.0), 0.0, 1.0) if health else 0.0


func _draw() -> void:
	var back := Rect2(Vector2(-bar_width / 2.0, 0.0), Vector2(bar_width, bar_height))
	draw_rect(back.grow(1.0), Color(0.04, 0.03, 0.05, 0.9))
	draw_rect(back, Color(0.2, 0.16, 0.18))
	var current := _fraction()
	draw_rect(Rect2(back.position, Vector2(bar_width * _chip, bar_height)), Color(0.96, 0.92, 0.85))
	draw_rect(Rect2(back.position, Vector2(bar_width * current, bar_height)), fill_color)
