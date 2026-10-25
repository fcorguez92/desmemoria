extends RefCounted
## Topes absolutos de las estadísticas del Caminante. Ninguna mejora, reliquia o
## combinación de ellas puede pasar de aquí: sin topes, sumar bonificaciones
## acaba rompiendo el equilibrio de los jefes (ver docs/nucleo-jugable.md).
## Solo están las estadísticas que ya existen; se añaden al crearlas.

const MAX_HEALTH := 13
const BASE_HEALTH := 5
## Cuántos fragmentos de vida dan una vida máxima más.
const FRAGMENTS_PER_LIFE := 4
const MAX_FLASKS := 5
const MIN_HEAL_AMOUNT := 1
const MAX_HEAL_AMOUNT := 5
const MIN_HEAL_TIME := 0.30

const BASE_HEAL_AMOUNT := 3
const BASE_HEAL_TIME := 0.70


static func max_health(raw: int) -> int:
	return clampi(raw, 1, MAX_HEALTH)


## Vida máxima: `5 + Vitalidad + fragmentos/4 (entero) + bonus`, con el tope de 13.
## `bonus` es el hueco de las reliquias (el Trapo de Iria sumará 1); hoy siempre 0.
static func life_max(vitality_level: int, fragments: int, bonus: int = 0) -> int:
	return max_health(BASE_HEALTH + vitality_level + fragments / FRAGMENTS_PER_LIFE + bonus)


static func max_flasks(raw: int) -> int:
	return clampi(raw, 0, MAX_FLASKS)


## Vida por frasco con `bonus` vidas extra (p. ej. Aliento).
static func heal_amount(bonus: int = 0) -> int:
	return clampi(BASE_HEAL_AMOUNT + bonus, MIN_HEAL_AMOUNT, MAX_HEAL_AMOUNT)


## Duración del sorbo con `reduction` segundos menos (p. ej. la Aguja del Escriba).
static func heal_time(reduction: float = 0.0) -> float:
	return clampf(BASE_HEAL_TIME - reduction, MIN_HEAL_TIME, BASE_HEAL_TIME)
