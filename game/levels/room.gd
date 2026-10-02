extends Node2D
## Una sala del mundo (ver docs/mundo.md y docs/vertical-slice.md). El mundo
## (world.gd) las coloca una junto a otra; el jugador pasa de una a otra
## caminando, sin pantallas de carga.
##
## El terreno se dibuja como texto en un .map (lo construye TextTileMap, en el
## nodo Tiles). Este script pone las entidades del juego en los marcadores:
##   A = Ancla de Memoria, E 1 2 3 4 = enemigos (ver ENEMIES), R = objeto rompible decorativo (no
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
const LanceroScene := preload("res://game/enemy/enemy_lancero.tscn")
const ArrojadorScene := preload("res://game/enemy/enemy_arrojador.tscn")
const ColosoScene := preload("res://game/enemy/enemy_coloso.tscn")
const AcechadorScene := preload("res://game/enemy/enemy_acechador.tscn")
const AnchorScene := preload("res://game/memory_anchor/memory_anchor.tscn")
const BreakableUrnScene := preload("res://game/environment/breakable_urn.tscn")
const BreakableCrateScene := preload("res://game/environment/breakable_crate.tscn")
const BreakableBarrelScene := preload("res://game/environment/breakable_barrel.tscn")
const InscriptionScene := preload("res://game/environment/inscription.tscn")
const AbilityPickupScene := preload("res://game/ability_pickup/ability_pickup.tscn")
const DecorSheet := preload("res://game/environment/decor_sheet.png")

const CELL := 16.0
## Mitad de la altura de cada entidad, para apoyar sus pies en la celda.
## Enemigos: marcador -> [escena, mitad de la altura de su cuerpo]. E = cascarón
## (tajo), 1 = lancero (estocada larga), 2 = arrojador (a distancia), 3 = coloso
## (mazazo lento) y 4 = acechador (embestida).
const ENEMIES := {
	"E": [EnemyScene, 24.0],
	"1": [LanceroScene, 24.0],
	"2": [ArrojadorScene, 24.0],
	"3": [ColosoScene, 32.0],
	"4": [AcechadorScene, 18.0],
}
const ANCHOR_HALF_HEIGHT := 28.0
const BREAKABLE_HALF_HEIGHT := 11.0
const CRATE_HALF_HEIGHT := 7.0
const BARREL_HALF_HEIGHT := 10.0
const INSCRIPTION_HALF_HEIGHT := 13.0
const PICKUP_HALF_HEIGHT := 16.0
const ABILITY_MARKERS := {
	"d": &"dash",
	"j": &"double_jump",
	"w": &"wall_jump",
}

## Decorado sin función (sin colisión ni lógica): marcador -> [fotograma de
## art/source/decor.sprite, cuelga del techo, z_index]. Lo que está detrás del
## jugador usa z -1 (y así también detrás de enemigos y urnas); la hierba y los
## huesos van delante (z 1) para dar profundidad. Cada pieza mide 48x64 px y se
## apoya en la parte de abajo de su celda (o cuelga de la de arriba).
const DECOR := {
	"Y": [0, false, -1],  # árbol muerto
	"U": [1, false, -1],  # columna rota
	"H": [2, false, 1],  # hierba
	"Z": [3, false, -1],  # zarza seca
	"K": [4, false, 1],  # huesos y escombros
	"F": [5, true, -1],  # estandarte
	"N": [6, true, -1],  # cadenas
	"X": [7, false, -1],  # estatua decapitada
	"V": [8, false, -1],  # mojón de piedras
	"L": [9, false, -1],  # poste de señal
	"M": [10, false, -1],  # farol
	"D": [11, false, -2],  # arco ciego de muro
	"q": [12, true, -1],  # enredaderas
}
const DECOR_FRAMES := 13

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
	for at in tiles.markers.get("Q", []):
		_place(BreakableCrateScene.instantiate(), at, CRATE_HALF_HEIGHT)
	for at in tiles.markers.get("O", []):
		_place(BreakableBarrelScene.instantiate(), at, BARREL_HALF_HEIGHT)
	for symbol in DECOR:
		for at in tiles.markers.get(symbol, []):
			_place_decor(DECOR[symbol], at)
	for at in tiles.markers.get("I", []):
		_place(InscriptionScene.instantiate(), at, INSCRIPTION_HALF_HEIGHT)
	for symbol in ENEMIES:
		for at in tiles.markers.get(symbol, []):
			var spawner := EntitySpawner.new()
			spawner.scene = ENEMIES[symbol][0]
			_place(spawner, at, ENEMIES[symbol][1])
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


## Una pieza de decorado: un Sprite2D de la hoja de decorado. Si cuelga, su borde
## de arriba toca el de la celda; si no, su borde de abajo toca el de la celda. Se
## voltea según la posición para que las repeticiones no se vean idénticas.
func _place_decor(info: Array, cell_center: Vector2) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = DecorSheet
	sprite.hframes = DECOR_FRAMES
	sprite.frame = info[0]
	sprite.z_index = info[2]
	var hangs: bool = info[1]
	sprite.offset = Vector2(0.0, 32.0 if hangs else -32.0)
	sprite.position = cell_center - global_position + Vector2(0.0, -CELL / 2.0 if hangs else CELL / 2.0)
	sprite.flip_h = int(cell_center.x / CELL) % 3 == 0
	add_child(sprite)


## Los marcadores están en coordenadas globales; la sala no gira ni se escala,
## así que basta con restar su posición.
func _place(node: Node2D, cell_center: Vector2, half_height: float) -> void:
	node.position = cell_center - global_position + Vector2(0.0, CELL / 2.0 - half_height)
	add_child(node)
