class_name SaveSlot
extends RefCounted
## Una partida guardada en un archivo JSON. No sabe qué se guarda: escribe y lee
## un diccionario con valores que JSON entiende (números, textos, booleanos,
## listas y diccionarios). Quien guarda convierte lo demás (p. ej. un Vector2 en
## [x, y]). Ojo: al leer, JSON devuelve todos los números como decimales.
##
## Se escribe primero en un archivo temporal y luego se renombra: si el juego se
## cierra a mitad de escritura, la partida anterior sigue intacta.

## Si cambia la forma de lo guardado de modo incompatible, se sube este número y
## las partidas antiguas se ignoran (se empieza de cero) en vez de cargarse mal.
const FORMAT_VERSION := 1

## Ruta del archivo, normalmente en user:// (la carpeta de datos del juego).
var path: String


func _init(file_path: String) -> void:
	path = file_path


func exists() -> bool:
	return FileAccess.file_exists(path)


## Guarda `data`. Devuelve false si no se pudo escribir.
func write(data: Dictionary) -> bool:
	var temporary := path + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		push_warning("No se pudo guardar la partida en %s" % path)
		return false
	file.store_string(JSON.stringify({ version = FORMAT_VERSION, data = data }, "\t"))
	file.close()
	return DirAccess.rename_absolute(temporary, path) == OK


## Lo guardado, o un diccionario vacío si no hay partida o no se puede leer.
func read() -> Dictionary:
	if not exists():
		return {}
	# Con una instancia de JSON un archivo roto no llena la consola de errores.
	var json := JSON.new()
	var parsed: Variant = json.data if json.parse(FileAccess.get_file_as_string(path)) == OK else null
	if not parsed is Dictionary or parsed.get("version") != FORMAT_VERSION or not parsed.get("data") is Dictionary:
		push_warning("Partida guardada ilegible o de otra versión, se ignora: %s" % path)
		return {}
	return parsed.data


func erase() -> void:
	if exists():
		DirAccess.remove_absolute(path)
