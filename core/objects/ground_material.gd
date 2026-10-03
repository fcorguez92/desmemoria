class_name GroundMaterial
extends RefCounted
## ¿Sobre qué material pisa un cuerpo? Sirve para que los pasos y los aterrizajes
## suenen distinto en piedra, musgo o madera.
##
## Cada baldosa del TileSet puede llevar un dato personalizado de tipo texto llamado
## `material` (ver `tiles_umbral.tres`); un cuerpo que no es de baldosas puede llevar
## el metadato `material`. Si no hay ninguno, el material es `DEFAULT`.

const DEFAULT := &"stone"
const DATA_NAME := "material"


## El material del suelo justo bajo los pies del cuerpo.
static func under(body: CharacterBody2D) -> StringName:
	var hit := KinematicCollision2D.new()
	if not body.test_move(body.global_transform, Vector2(0.0, 3.0), hit):
		return DEFAULT
	var collider := hit.get_collider()
	if collider is TileMapLayer:
		var layer := collider as TileMapLayer
		if layer.tile_set == null or layer.tile_set.get_custom_data_layer_by_name(DATA_NAME) == -1:
			return DEFAULT
		# La baldosa es la que contiene el punto de contacto, un píxel hacia dentro.
		var inside := hit.get_position() - hit.get_normal()
		var data := layer.get_cell_tile_data(layer.local_to_map(layer.to_local(inside)))
		if data != null:
			var value: Variant = data.get_custom_data(DATA_NAME)
			if value is String and value != "":
				return StringName(value)
	elif collider is Node and collider.has_meta(DATA_NAME):
		return StringName(collider.get_meta(DATA_NAME))
	return DEFAULT
