extends Node
## Registro de Nombres: los 30 nombres de personas que la Desmemoria borró (lista
## definitiva en docs/guion-maestro.md §10.1, 5 por región) y cuáles ha leído el
## jugador. Cada Nombre está en un estado: sin leer, leído (lo sostiene) o callado
## (lo leyó y lo calló con el Paño; ya no cuenta como sostenido, pero sigue leído).
##
## No sabe de salas ni de menús: quien lo lee (una inscripción), quien lo muestra
## (la pausa) y quien lo calla (el menú del Ancla) lo encuentran por el grupo
## `GROUP` con `find()`. El mundo lo crea, lo guarda (clave opcional `names` de la
## partida) y avisa al jugador cuando sale `name_read`.

## Se lee un Nombre por primera vez.
signal name_read(id: StringName)
## Se calla un Nombre.
signal name_silenced(id: StringName)

const GROUP := &"names"
## Ecos que paga el Paño por cada Nombre callado (el único número del sistema, ver
## docs/nucleo-jugable.md).
const SILENCE_REWARD := 50
## Nombres sostenidos que hacen falta para el final Compartir.
const SHARE_NEEDED := 20

const STATE_READ := "read"
const STATE_SILENCED := "silenced"

const REGIONS: Array[Dictionary] = [
	{ id = &"umbral", title = "Umbral" },
	{ id = &"cinturon", title = "Cinturón" },
	{ id = &"archivo", title = "Archivo" },
	{ id = &"minas", title = "Minas" },
	{ id = &"costa", title = "Costa" },
	{ id = &"herida", title = "Herida" },
]

## Los 30, en el orden del guion (el de la pausa). Un id nuevo se añade aquí y el
## verificador del mundo (tools/verifica_mundo.js) lo reconoce solo.
const LIST: Array[Dictionary] = [
	{ id = &"ossenna", region = &"umbral", title = "Ossenna" },
	{ id = &"fara", region = &"umbral", title = "Fara" },
	{ id = &"tomas", region = &"umbral", title = "Tomás" },
	{ id = &"ines", region = &"umbral", title = "Inés" },
	{ id = &"ruben", region = &"umbral", title = "Rubén" },
	{ id = &"oda_bellver", region = &"cinturon", title = "Oda Bellver" },
	{ id = &"tomasa", region = &"cinturon", title = "Tomasa" },
	{ id = &"jacinto_ferran", region = &"cinturon", title = "Jacinto Ferrán" },
	{ id = &"eulalia_ferran", region = &"cinturon", title = "Eulalia Ferrán" },
	{ id = &"eloy_ferran", region = &"cinturon", title = "Eloy Ferrán" },
	{ id = &"ilara", region = &"archivo", title = "Ilara" },
	{ id = &"corvel", region = &"archivo", title = "Corvel" },
	{ id = &"aurelio", region = &"archivo", title = "Aurelio" },
	{ id = &"lucia", region = &"archivo", title = "Lucía" },
	{ id = &"ardena", region = &"archivo", title = "Ardena" },
	{ id = &"berenguer", region = &"minas", title = "Berenguer" },
	{ id = &"dimas", region = &"minas", title = "Dimas" },
	{ id = &"rosendo", region = &"minas", title = "Rosendo" },
	{ id = &"magda_soler", region = &"minas", title = "Magda Soler" },
	{ id = &"aurea", region = &"minas", title = "Áurea" },
	{ id = &"marta", region = &"costa", title = "Marta" },
	{ id = &"julian", region = &"costa", title = "Julián" },
	{ id = &"elvira", region = &"costa", title = "Elvira" },
	{ id = &"mateo", region = &"costa", title = "Mateo" },
	{ id = &"rufo", region = &"costa", title = "Rufo" },
	{ id = &"inigo", region = &"herida", title = "Íñigo" },
	{ id = &"leocadia", region = &"herida", title = "Leocadia" },
	{ id = &"tadeo", region = &"herida", title = "Tadeo" },
	{ id = &"brigida", region = &"herida", title = "Brígida" },
	{ id = &"alvar", region = &"herida", title = "Álvar" },
]

## id -> STATE_READ o STATE_SILENCED. Lo que no está aquí, no se ha leído.
var _states: Dictionary = {}


## El registro del grupo `GROUP` del árbol de `node`, o null si aún no hay.
static func find(node: Node) -> Node:
	if not node.is_inside_tree():
		return null
	return node.get_tree().get_first_node_in_group(GROUP)


## Los datos del Nombre `id` (id, region, title), o un diccionario vacío si no existe.
static func info(id: StringName) -> Dictionary:
	for entry in LIST:
		if entry.id == id:
			return entry
	return {}


static func is_known(id: StringName) -> bool:
	return not info(id).is_empty()


## El título de una región ("Umbral"), o "" si no existe.
static func region_title(region: StringName) -> String:
	for entry in REGIONS:
		if entry.id == region:
			return entry.title
	return ""


## Lee el Nombre `id`. Devuelve true si es la primera vez (y avisa con `name_read`).
## Un id desconocido se ignora; uno ya callado no vuelve a sostenerse.
func read_name(id: StringName) -> bool:
	if not is_known(id) or _states.has(id):
		return false
	_states[id] = STATE_READ
	name_read.emit(id)
	return true


## Calla el Nombre `id`: solo si se ha leído y no está ya callado. Devuelve true si
## lo ha callado. El pago (SILENCE_REWARD) lo da quien llama.
func silence(id: StringName) -> bool:
	if _states.get(id) != STATE_READ:
		return false
	_states[id] = STATE_SILENCED
	name_silenced.emit(id)
	return true


## ¿Se ha leído alguna vez (aunque ahora esté callado)?
func is_read(id: StringName) -> bool:
	return _states.has(id)


## ¿Lo sostiene el mundo? Leído y no callado.
func is_held(id: StringName) -> bool:
	return _states.get(id) == STATE_READ


func is_silenced(id: StringName) -> bool:
	return _states.get(id) == STATE_SILENCED


## Los ids sostenidos, en el orden del guion; con `region`, solo los de esa región.
func held_ids(region: StringName = &"") -> Array[StringName]:
	var ids: Array[StringName] = []
	for entry in LIST:
		if is_held(entry.id) and (region == &"" or entry.region == region):
			ids.append(entry.id)
	return ids


## Cuántos se han leído (los callados cuentan).
func read_count() -> int:
	return _states.size()


## Cuántos se sostienen.
func held_count() -> int:
	return held_ids().size()


## Lo que se guarda: `{ read: [ids], silenced: [ids] }` (los callados van en las dos).
func to_dict() -> Dictionary:
	var read: Array[String] = []
	var silenced: Array[String] = []
	for entry in LIST:
		if _states.has(entry.id):
			read.append(String(entry.id))
			if _states[entry.id] == STATE_SILENCED:
				silenced.append(String(entry.id))
	return { read = read, silenced = silenced }


## Carga lo guardado, sustituyendo lo que hubiera. Tolera cualquier cosa (nada, otro
## tipo, ids desconocidos o repetidos). Un callado cuenta también como leído. No
## emite señales.
func from_dict(data: Variant) -> void:
	_states.clear()
	if not data is Dictionary:
		return
	var read: Variant = data.get("read")
	if read is Array:
		for id: Variant in read:
			if id is String and is_known(StringName(id)):
				_states[StringName(id)] = STATE_READ
	var silenced: Variant = data.get("silenced")
	if silenced is Array:
		for id: Variant in silenced:
			if id is String and is_known(StringName(id)):
				_states[StringName(id)] = STATE_SILENCED
