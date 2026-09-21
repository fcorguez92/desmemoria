class_name AttackVisualComponent
extends Node
## Presentación de un ataque: pide al SheetAnimator las animaciones de aviso y de
## golpe (con el arma dibujada en el propio sprite) y, opcionalmente, hace
## destellar el arco del golpe.
##
## Es solo presentación: no decide cuándo se ataca ni hace daño. El dueño la llama
## en los momentos oportunos: `windup()` al empezar un aviso, `strike()` cuando cae
## el golpe, `swing()` para un ataque sin aviso, `reset()` al cancelar.

@export var animator: SheetAnimator
## Destello del arco del golpe (p. ej. un Polygon2D). Opcional.
@export var slash: CanvasItem
## Nombres de las animaciones en la hoja del dueño.
@export var windup_animation: String = "windup"
@export var strike_animation: String = "strike"
@export var swing_animation: String = "attack"
@export var slash_time: float = 0.25
@export_range(0.0, 1.0) var slash_alpha: float = 0.5

var _slash_tween: Tween


func _ready() -> void:
	if slash:
		slash.modulate.a = 0.0


## Voltea el destello según hacia dónde mira el cuerpo (-1 o 1). El sprite lo voltea
## el dueño.
func set_facing(facing: int) -> void:
	if slash:
		slash.scale.x = facing


## Aviso previo al golpe: alza el arma durante `duration` segundos y la mantiene.
func windup(duration: float) -> void:
	animator.play_action(windup_animation, true, duration)


## Cae el golpe (después de un aviso).
func strike() -> void:
	animator.play_action(strike_animation)
	_flash_slash()


## Ataque sin aviso: golpea al instante.
func swing() -> void:
	animator.play_action(swing_animation)
	_flash_slash()


## Cancela la animación de ataque y apaga el destello.
func reset() -> void:
	animator.release_action()
	if _slash_tween:
		_slash_tween.kill()
	if slash:
		slash.modulate.a = 0.0


func _flash_slash() -> void:
	if not slash:
		return
	slash.modulate.a = slash_alpha
	if _slash_tween:
		_slash_tween.kill()
	_slash_tween = create_tween()
	_slash_tween.tween_property(slash, "modulate:a", 0.0, slash_time)
