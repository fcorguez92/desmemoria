class_name ParryComponent
extends Node
## Parry: al pulsar se abre una ventana muy breve durante la que un golpe frontal
## se desvía en lugar de hacer daño. Si el golpe llega antes o después de la
## ventana, o por la espalda, se recibe con normalidad. Tras pulsar hay un
## enfriamiento, para que no se pueda pulsar sin riesgo todo el rato.
##
## No sabe qué pasa al desviar: emite `parried` y el dueño reacciona (efectos,
## aturdir al atacante...). El dueño la consulta desde su `take_hit()`.

## Se emite al abrir la ventana (para mostrar la pose de guardia).
signal started
## Se emite al desviar un golpe; `attacker` puede ser null.
signal parried(attacker: Node)

## Segundos que dura la ventana de desvío tras pulsar.
@export var window: float = 0.2
## Segundos, contados desde la pulsación, hasta poder volver a parar.
@export var cooldown: float = 0.7

var is_active: bool = false

var _window_timer: float = 0.0
var _cooldown_timer: float = 0.0


func _physics_process(delta: float) -> void:
	_cooldown_timer = maxf(_cooldown_timer - delta, 0.0)
	_window_timer = maxf(_window_timer - delta, 0.0)
	if is_active and _window_timer <= 0.0:
		is_active = false


## Abre la ventana de desvío. Devuelve false si está en enfriamiento o ya abierta.
func try_start() -> bool:
	if is_active or _cooldown_timer > 0.0:
		return false
	is_active = true
	_window_timer = window
	_cooldown_timer = cooldown
	started.emit()
	return true


## Intenta desviar un golpe. `blow_direction` es la dirección en la que viaja el
## golpe y `facing` la dirección a la que mira quien para: solo se desvían los
## golpes frontales (los que viajan hacia quien para). Devuelve true si lo desvía.
func try_deflect(blow_direction: int, facing: int, attacker: Node = null) -> bool:
	if not is_active or blow_direction != -facing:
		return false
	is_active = false
	_window_timer = 0.0
	parried.emit(attacker)
	return true
