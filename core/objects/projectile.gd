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

## Se emite al desaparecer por un impacto (con el punto global) para chispas y demás.
signal hit(at: Vector2)

@export var speed: float = 260.0
@export var damage: int = 1
@export var lifetime: float = 2.5
@export var target_group: StringName = &"player"
## Grupo al que pasa a herir si se le devuelve con un parry. Vacío = se destruye.
@export var reflect_group: StringName = &""
## Sonido al impactar (ver core/audio/sfx.gd); vacío = ninguno.
@export var hit_sound: StringName = &""
@export var hit_volume_db: float = -8.0

var direction: Vector2 = Vector2.RIGHT

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
	position += direction * speed * delta
	_age += delta
	if _age >= lifetime:
		queue_free()


func _on_hit_sound(at: Vector2) -> void:
	if hit_sound != &"":
		Sfx.play(hit_sound, at, hit_volume_db)


## Contrato de quien recibe: se llama desde el parry del jugador.
func on_parried(_extra_stun: float = 0.0) -> void:
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
		queue_free()
	elif not body is CharacterBody2D:
		# Escenario: tierra, muros, objetos sólidos.
		hit.emit(global_position)
		queue_free()
