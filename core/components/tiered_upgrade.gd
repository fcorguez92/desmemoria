class_name TieredUpgrade
extends Node
## Mejora por niveles: cada subida cuesta una cantidad y da un valor nuevo
## (daño de un arma, vida máxima, alcance...).
##
## `values[0]` es el valor del nivel 0. `costs[i]` es lo que cuesta pasar del
## nivel `i` al `i + 1`, así que `costs.size()` debe ser `values.size() - 1`.
## No gestiona la moneda: el dueño comprueba si hay saldo y cobra.

signal changed

@export var values: PackedInt32Array = PackedInt32Array([1, 2, 3])
@export var costs: PackedInt32Array = PackedInt32Array([5, 10])

var level: int = 0


func _ready() -> void:
	assert(values.size() == costs.size() + 1, "TieredUpgrade: values debe tener un elemento más que costs")


func current_value() -> int:
	return values[level]


func is_max() -> bool:
	return level >= costs.size()


## Coste de la siguiente subida, o -1 si ya está al máximo.
func next_cost() -> int:
	return -1 if is_max() else costs[level]


## Sube un nivel. Devuelve false si ya estaba al máximo.
func advance() -> bool:
	if is_max():
		return false
	level += 1
	changed.emit()
	return true
