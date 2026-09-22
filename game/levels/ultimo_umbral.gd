extends Node2D
## El Último Umbral: primera zona del juego (ver docs/vertical-slice.md).
##
## El terreno se dibuja como texto en ultimo_umbral.map (lo construye TextTileMap).
## Este script pone las entidades del juego en los marcadores del mapa:
##   P = inicio del jugador, A = Ancla de Memoria, E = enemigo, R = objeto
##   rompible decorativo (no reaparece: ver core/objects/breakable_prop.gd).
## Cada entidad se coloca con los pies en la parte de abajo de su celda.

const PlayerScene := preload("res://game/player/player.tscn")
const EnemyScene := preload("res://game/enemy/enemy.tscn")
const AnchorScene := preload("res://game/memory_anchor/memory_anchor.tscn")
const BreakableUrnScene := preload("res://game/environment/breakable_urn.tscn")

const CELL := 16.0
## Mitad de la altura de cada entidad, para apoyar sus pies en la celda.
const PLAYER_HALF_HEIGHT := 24.0
const ENEMY_HALF_HEIGHT := 24.0
const ANCHOR_HALF_HEIGHT := 28.0
const BREAKABLE_HALF_HEIGHT := 11.0

@onready var tiles: TextTileMap = $Tiles


func _ready() -> void:
	for at in tiles.markers.get("A", []):
		_place(AnchorScene.instantiate(), at, ANCHOR_HALF_HEIGHT)
	for at in tiles.markers.get("R", []):
		_place(BreakableUrnScene.instantiate(), at, BREAKABLE_HALF_HEIGHT)
	for at in tiles.markers.get("E", []):
		var spawner := EntitySpawner.new()
		spawner.scene = EnemyScene
		_place(spawner, at, ENEMY_HALF_HEIGHT)
	for at in tiles.markers.get("P", []):
		var player := PlayerScene.instantiate()
		_place(player, at, PLAYER_HALF_HEIGHT)
		_limit_camera(player.get_node("Camera2D"))


func _place(node: Node2D, cell_center: Vector2, half_height: float) -> void:
	node.position = cell_center + Vector2(0.0, CELL / 2.0 - half_height)
	add_child(node)


## Que la cámara no muestre el vacío más allá del mapa.
func _limit_camera(camera: Camera2D) -> void:
	var rect := tiles.get_used_rect()
	camera.limit_left = int(rect.position.x * CELL)
	camera.limit_right = int(rect.end.x * CELL)
	camera.limit_bottom = int(rect.end.y * CELL)
	camera.limit_top = camera.limit_bottom - int(get_viewport_rect().size.y)
