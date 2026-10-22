extends Projectile
## Onda de polvo que corre pegada al suelo: sube escalones pequeños, **cae por los
## bordes hasta el suelo de más abajo y sigue**, y muere contra una pared. Si el
## jefe la lanza desde un tablón alto, baja al siguiente suelo y continúa. Es un
## Projectile, así que un parry sigue devolviéndola (y entonces corre hacia atrás).

## Distancia del centro de la onda al suelo (su forma mide 30 de alto).
const FOOT := 16.0
## Escalón máximo que sube sin considerarlo pared.
const STEP_UP := 14.0
const GRAVITY := 2400.0
## Mitad de su anchura (la forma mide 38).
const HALF_WIDTH := 19.0

var _vy: float = 0.0


func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return
	var side := signf(direction.x)
	var step := side * speed * delta
	# Una pared delante la deshace.
	if _solid_between(global_position, global_position + Vector2(step + side * 20.0, 0.0)):
		hit.emit(global_position)
		queue_free()
		return
	global_position.x += step
	# Suelo bajo ella: lo sigue, y si no lo hay cerca, cae hasta el siguiente.
	var ground := _ground_y(global_position)
	if is_nan(ground):
		_vy += GRAVITY * delta
		global_position.y += _vy * delta
		return
	var wanted := ground - FOOT
	if wanted < global_position.y - STEP_UP:
		hit.emit(global_position)
		queue_free()
	elif wanted <= global_position.y + 6.0:
		global_position.y = wanted
		_vy = 0.0
	else:
		_vy += GRAVITY * delta
		global_position.y = minf(global_position.y + _vy * delta, wanted)


## ¿Hay algo sólido (no un cuerpo con movimiento) entre dos puntos?
func _solid_between(from: Vector2, to: Vector2) -> bool:
	var query := PhysicsRayQueryParameters2D.create(from, to, 1)
	var found := get_world_2d().direct_space_state.intersect_ray(query)
	return not found.is_empty() and not found.collider is CharacterBody2D


## El escenario lo gestiona ella con sus rayos (paredes, escalones, bordes): solo
## reacciona al contacto con cuerpos con movimiento (el jugador, el jefe).
func _on_body_entered(body: Node) -> void:
	if body is CharacterBody2D:
		super(body)


## Y del suelo (o tablón) más alto bajo el ancho de la onda, o NAN si no hay ninguno.
## Se mira a los dos lados y al centro: no empieza a caer hasta haber pasado entera
## el borde (si no, rozaría el extremo del tablón al bajar).
func _ground_y(at: Vector2) -> float:
	var best := NAN
	for dx in [-HALF_WIDTH, 0.0, HALF_WIDTH]:
		var y := _ground_at(at + Vector2(dx, 0.0))
		if not is_nan(y) and (is_nan(best) or y < best):
			best = y
	return best


func _ground_at(at: Vector2) -> float:
	var query := PhysicsRayQueryParameters2D.create(at + Vector2(0.0, -8.0), at + Vector2(0.0, 1200.0), 1)
	var found := get_world_2d().direct_space_state.intersect_ray(query)
	if found.is_empty() or found.collider is CharacterBody2D:
		return NAN
	return found.position.y
