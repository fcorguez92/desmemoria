class_name Projectile
extends Area2D
## Proyectil recto: vuela en línea recta a `speed` en `direction` hasta que alcanza
## algo golpeable del grupo `target_group` (le hace `damage` con el contrato
## "golpeable", ver docs/arquitectura.md), choca con el escenario o se le acaba el
## tiempo (`lifetime`). Pasa a través de cuerpos con movimiento propio que no son
## su objetivo (el que lo lanzó, otros enemigos).
##
## Si el objetivo lo desvía (parry), el golpe llama a `on_parried()`: el proyectil
## se devuelve hacia quien lo lanzó y pasa a herir al grupo `reflect_group`.
##
## Quien lo crea lo añade al árbol y lo coloca; `launch()` fija la dirección.
##
## Modo retorno (`returns`, un boomerang): tras `outbound_time` s, o al chocar con el
## escenario, da la vuelta y vuela hacia `return_to` (quien lo lanzó); al llegar a
## `catch_distance` avisa con `returned` y desaparece. Atraviesa a su objetivo (puede
## herirle a la ida y otra vez a la vuelta, una vez por pasada). Sigue a
## `return_to` aunque el objetivo haya muerto, y si `return_to` ya no existe se
## borra. Un parry lo manda de vuelta en el acto y pasa a herir a `reflect_group`.

## Se emite al desaparecer por un impacto (con el punto global) para chispas y demás.
signal hit(at: Vector2)
## Modo retorno: ha llegado de vuelta a quien lo lanzó.
signal returned

@export var speed: float = 260.0
@export var damage: int = 1
@export var lifetime: float = 2.5
@export var target_group: StringName = &"player"
## Grupo al que pasa a herir si se le devuelve con un parry. Vacío = se destruye.
@export var reflect_group: StringName = &""
## Sonido al impactar (ver core/audio/sfx.gd); vacío = ninguno.
@export var hit_sound: StringName = &""
@export var hit_volume_db: float = -8.0
@export_group("Retorno (boomerang)")
## Si es true, da la vuelta en lugar de desaparecer (ver arriba).
@export var returns: bool = false
## Segundos de ida antes de volver.
@export var outbound_time: float = 0.6
## A qué distancia de `return_to` se da por recogido.
@export var catch_distance: float = 18.0

var direction: Vector2 = Vector2.RIGHT
## Modo retorno: a quién vuelve (lo fija quien lo lanza).
var return_to: Node2D
var is_returning: bool = false

var _age: float = 0.0


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	hit.connect(_on_hit_sound)


## Fija la dirección (no hace falta que esté normalizada) y orienta el dibujo.
func launch(new_direction: Vector2) -> void:
	direction = new_direction.normalized()
	rotation = direction.angle()
	# Un dibujo con la cara "hacia abajo" no debe quedar boca abajo al ir a la izquierda.
	scale.y = -1.0 if direction.x < 0.0 else 1.0


func _physics_process(delta: float) -> void:
	_age += delta
	if returns:
		if not is_returning and _age >= outbound_time:
			_begin_return()
		if is_returning:
			if not is_instance_valid(return_to):
				queue_free()
				return
			var to_owner := return_to.global_position - global_position
			if to_owner.length() <= catch_distance:
				returned.emit()
				queue_free()
				return
			direction = to_owner.normalized()
	position += direction * speed * delta
	if _age >= lifetime:
		queue_free()


## Modo retorno: da la vuelta hacia `return_to`.
func _begin_return() -> void:
	is_returning = true


func _on_hit_sound(at: Vector2) -> void:
	if hit_sound != &"":
		Sfx.play(hit_sound, at, hit_volume_db)


## Contrato de quien recibe: se llama desde el parry del jugador.
func on_parried(_extra_stun: float = 0.0) -> void:
	if returns:
		# Un boomerang desviado vuelve ya a su dueño y pasa a herirle a él.
		if reflect_group != &"":
			target_group = reflect_group
			reflect_group = &""
		_begin_return()
		return
	if reflect_group == &"":
		hit.emit(global_position)
		queue_free()
		return
	launch(-direction)
	target_group = reflect_group
	reflect_group = &""
	_age = 0.0


func _on_body_entered(body: Node) -> void:
	if body.is_in_group(target_group):
		var group_before := target_group
		if body.has_method("take_hit"):
			body.take_hit(damage, 1 if direction.x >= 0.0 else -1, self)
		# Si el golpe lo desvió, on_parried() ya lo ha devuelto: sigue vivo.
		if target_group != group_before:
			return
		hit.emit(global_position)
		if returns:
			# Un boomerang no se gasta al dar: sigue su camino (y puede dar otra vez al volver).
			return
		queue_free()
	elif not body is CharacterBody2D:
		# Escenario: tierra, muros, objetos sólidos. Un boomerang de vuelta los
		# atraviesa (va hacia su dueño); a la ida, rebota.
		if returns:
			if not is_returning:
				hit.emit(global_position)
				_begin_return()
			return
		hit.emit(global_position)
		queue_free()
