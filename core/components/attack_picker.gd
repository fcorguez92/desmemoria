class_name AttackPicker
extends RefCounted
## Selector de ataques de un jefe (E1 de docs/jefes.md): decide **qué ataque toca
## ahora** sin ser una tirada pura. No sabe qué es un jefe ni qué hace cada ataque:
## recibe identificadores y devuelve uno. Quien lo usa lo combina con sus estados.
##
## Reglas (docs/jefes.md, "Aleatoriedad controlada"):
## - **Bolsa barajada:** cada ataque entra en la bolsa tantas veces como `copies`
##   (el peso de la fase) y sale una vez por turno; hasta que no se vacía no se
##   repite ninguno. El orden es impredecible; el reparto, no.
## - **No repetir:** el último ataque queda fuera del siguiente turno.
## - **Distancia manda:** `pick(bias)` multiplica el peso de cada candidato (p. ej.
##   los de aproximación si el jugador está lejos). Un sesgo de 0 lo descarta.
## - **Equidad:** si un ataque no ha dañado tres veces seguidas (`report`), pesa
##   menos (se favorece otro); si ha dañado dos veces seguidas, se descarta el turno
##   siguiente.
## - **Límites:** `limit(id, max, window)`: como mucho `max` veces en los últimos
##   `window` ataques. `ban(id, turns)` descarta un ataque los próximos turnos.

## Cuántos fallos seguidos (sin dañar) hacen que un ataque pese menos.
const DODGED_STREAK := 3
## Cuántos aciertos seguidos hacen que se descarte el turno siguiente.
const HIT_STREAK := 2
## Peso de un ataque que lleva `DODGED_STREAK` fallos seguidos.
const DODGED_WEIGHT := 0.35
const HISTORY_SIZE := 24

## Último ataque elegido (vacío antes del primero).
var last: StringName = &""
var rng := RandomNumberGenerator.new()

var _copies: Dictionary = {}
var _bag: Array[StringName] = []
var _dodged: Dictionary = {}
var _hits: Dictionary = {}
var _banned: Dictionary = {}
var _limits: Dictionary = {}
var _history: Array[StringName] = []


func _init() -> void:
	rng.randomize()


## Fija los ataques disponibles: identificador -> copias en la bolsa (0 = fuera).
## Cambiar de fase es llamar a esto con otros pesos; la memoria (último ataque,
## rachas, límites) se conserva.
func set_attacks(copies: Dictionary) -> void:
	_copies = copies.duplicate()
	_bag.clear()


## Como mucho `max_uses` veces entre los últimos `window` ataques elegidos.
func limit(id: StringName, max_uses: int, window: int) -> void:
	_limits[id] = [max_uses, window]


## Descarta `id` durante los próximos `turns` turnos.
func ban(id: StringName, turns: int) -> void:
	_banned[id] = turns


## Resultado de un ataque: si dañó al jugador o no. Alimenta la equidad.
func report(id: StringName, hit: bool) -> void:
	if hit:
		_dodged[id] = 0
		_hits[id] = int(_hits.get(id, 0)) + 1
		if int(_hits[id]) >= HIT_STREAK:
			_hits[id] = 0
			ban(id, 1)
	else:
		_hits[id] = 0
		_dodged[id] = int(_dodged.get(id, 0)) + 1


## Olvida todo salvo los ataques y los límites (el jugador ha muerto, la pelea
## vuelve a empezar).
func reset() -> void:
	last = &""
	_bag.clear()
	_dodged.clear()
	_hits.clear()
	_banned.clear()
	_history.clear()


## Elige el siguiente ataque. `bias`: identificador -> multiplicador del peso (los
## que no estén, 1). Devuelve &"" si no hay ningún ataque disponible.
func pick(bias: Dictionary = {}) -> StringName:
	var weights := _weights(bias, true)
	if weights.is_empty():
		# Bolsa agotada o sin candidatos válidos: se rellena y se vuelve a mirar.
		_refill()
		weights = _weights(bias, true)
	if weights.is_empty():
		# Solo queda el último ataque: se admite repetirlo antes que usar uno vetado o fuera de límite.
		weights = _weights(bias, true, true)
	if weights.is_empty():
		# Todo vetado: antes repetir cualquiera que quedarse sin ataque.
		weights = _weights(bias, false)
	if weights.is_empty():
		return &""
	var id := _choose(weights)
	_bag.erase(id)
	for banned_id in _banned.keys():
		_banned[banned_id] = int(_banned[banned_id]) - 1
		if int(_banned[banned_id]) <= 0:
			_banned.erase(banned_id)
	last = id
	_history.append(id)
	if _history.size() > HISTORY_SIZE:
		_history.pop_front()
	return id


func _refill() -> void:
	_bag.clear()
	for id in _copies:
		for i in int(_copies[id]):
			_bag.append(id)


## Candidatos de la bolsa con su peso. `strict`: sin vetados ni fuera de límite (y, salvo con
## `allow_last`, sin el último ataque).
func _weights(bias: Dictionary, strict: bool, allow_last: bool = false) -> Dictionary:
	if _bag.is_empty():
		_refill()
	var weights := {}
	for id in _bag:
		if weights.has(id):
			continue
		var weight := float(bias.get(id, 1.0))
		if weight <= 0.0:
			continue
		if strict and ((id == last and not allow_last) or _banned.has(id) or _over_limit(id)):
			continue
		if int(_dodged.get(id, 0)) >= DODGED_STREAK:
			weight *= DODGED_WEIGHT
		weights[id] = weight
	return weights


func _over_limit(id: StringName) -> bool:
	if not _limits.has(id):
		return false
	var max_uses: int = _limits[id][0]
	var window: int = _limits[id][1]
	var recent := _history.slice(maxi(_history.size() - (window - 1), 0))
	return recent.count(id) >= max_uses


func _choose(weights: Dictionary) -> StringName:
	var total := 0.0
	for id in weights:
		total += float(weights[id])
	var roll := rng.randf() * total
	var chosen: StringName = &""
	for id in weights:
		chosen = id
		roll -= float(weights[id])
		if roll <= 0.0:
			break
	return chosen
