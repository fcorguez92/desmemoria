extends Node2D
## Una sala del mundo (ver docs/mundo.md y docs/vertical-slice.md). El mundo
## (world.gd) las coloca una junto a otra; el jugador pasa de una a otra
## caminando, sin pantallas de carga.
##
## El terreno se dibuja como texto en un .map (lo construye TextTileMap, en el
## nodo Tiles). Este script pone las entidades del juego en los marcadores:
##   A = Ancla de Memoria, E = enemigo, R = objeto rompible decorativo (no
##   reaparece: ver core/objects/breakable_prop.gd), I = inscripción legible
##   (ver core/objects/readable.gd), d / j / w = habilidad (dash, doble salto,
##   salto de pared) que se recuerda al tocarla.
## El marcador P (inicio del jugador) no lo usa la sala: lo busca el mundo, que
## es quien crea al jugador.
## Cada entidad se coloca con los pies en la parte de abajo de su celda.
##
## Nota: hoy solo hay una inscripción, con el texto fijado en su propia escena
## (game/environment/inscription.tscn). Si una sala necesitara varias con textos
## distintos, este script tendría que asignarles el texto por posición o por un
## marcador numerado (I1, I2...); no hace falta esa complicación todavía.

const EnemyScene := preload("res://game/enemy/enemy.tscn")
const AnchorScene := preload("res://game/memory_anchor/memory_anchor.tscn")
const BreakableUrnScene := preload("res://game/environment/breakable_urn.tscn")
const InscriptionScene := preload("res://game/environment/inscription.tscn")
const AbilityPickupScene := preload("res://game/ability_pickup/ability_pickup.tscn")

const CELL := 16.0
## Mitad de la altura de cada entidad, para apoyar sus pies en la celda.
const ENEMY_HALF_HEIGHT := 24.0
const ANCHOR_HALF_HEIGHT := 28.0
const BREAKABLE_HALF_HEIGHT := 11.0
const INSCRIPTION_HALF_HEIGHT := 13.0
const PICKUP_HALF_HEIGHT := 16.0
const ABILITY_MARKERS := {
	"d": &"dash",
	"j": &"double_jump",
	"w": &"wall_jump",
}

## Nombre de la sala: se anuncia al entrar por primera vez y sale en el mapa.
@export var title: String = ""
## Si se ve el cielo con el fondo de colinas (false en salas bajo tierra).
@export var has_sky: bool = true

@onready var tiles: TextTileMap = $Tiles


func _ready() -> void:
	for at in tiles.markers.get("A", []):
		_place(AnchorScene.instantiate(), at, ANCHOR_HALF_HEIGHT)
	for at in tiles.markers.get("R", []):
		_place(BreakableUrnScene.instantiate(), at, BREAKABLE_HALF_HEIGHT)
	for at in tiles.markers.get("I", []):
		_place(InscriptionScene.instantiate(), at, INSCRIPTION_HALF_HEIGHT)
	for at in tiles.markers.get("E", []):
		var spawner := EntitySpawner.new()
		spawner.scene = EnemyScene
		_place(spawner, at, ENEMY_HALF_HEIGHT)
	for symbol in ABILITY_MARKERS:
		for at in tiles.markers.get(symbol, []):
			var pickup := AbilityPickupScene.instantiate()
			pickup.ability_id = ABILITY_MARKERS[symbol]
			_place(pickup, at, PICKUP_HALF_HEIGHT)


## Rectángulo de la sala en el mundo, en píxeles.
func world_rect() -> Rect2:
	return Rect2(global_position, Vector2(tiles.map_size) * CELL)


## Rectángulo de la sala en el mundo, en baldosas.
func cell_rect() -> Rect2i:
	return Rect2i(Vector2i((global_position / CELL).round()), tiles.map_size)


## Posiciones globales donde se apoyan los pies de un cuerpo de media altura
## `half_height` en los marcadores `symbol` (p. ej. "P" para el jugador).
func spawn_points(symbol: String, half_height: float) -> Array[Vector2]:
	var points: Array[Vector2] = []
	for at in tiles.markers.get(symbol, []):
		points.append(at + Vector2(0.0, CELL / 2.0 - half_height))
	return points


## Los marcadores están en coordenadas globales; la sala no gira ni se escala,
## así que basta con restar su posición.
func _place(node: Node2D, cell_center: Vector2, half_height: float) -> void:
	node.position = cell_center - global_position + Vector2(0.0, CELL / 2.0 - half_height)
	add_child(node)
