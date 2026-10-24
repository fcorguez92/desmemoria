extends Readable
## Inscripción del juego: un Readable que, si lleva un Nombre (`name_id`, uno de los
## ids de game/names.gd), lo registra como leído la primera vez que se lee y añade
## al texto que se muestra el aviso "Nombre: ... Lo sostienes." (docs/textos-del-juego.md).
## Sin `name_id` se comporta igual que un Readable normal.

const Names := preload("res://game/names.gd")

## Nombre que contiene la inscripción, o vacío si no es ninguno.
@export var name_id: StringName = &""


func _ready() -> void:
	super()
	read_by.connect(_on_read_by)


func _on_read_by(reader: Node) -> void:
	if name_id == &"":
		return
	var registry := Names.find(self)
	if registry == null or not registry.read_name(name_id):
		return
	# Se vuelve a mostrar el texto con el aviso debajo (y el tiempo de lectura
	# se calcula con el texto entero), en vez de taparlo con otro mensaje.
	reader.read_text("%s\n\nNombre: %s. Lo sostienes." % [text, Names.info(name_id).title])
