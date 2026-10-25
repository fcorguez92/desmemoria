extends RefCounted
## Cifras de la economía de Ecos que no son del árbol (ver docs/nucleo-jugable.md,
## "Ecos, muerte y economía"). Hoy: lo que da una Bolsa de Rastro y el presupuesto
## que vigila la prueba de humo.

## Ecos de una Bolsa de Rastro según la región donde está (el doc: de 12 a 30).
const BAG_ECOS_BY_REGION := {
	&"umbral": 12, &"cinturon": 15, &"archivo": 18, &"minas": 22, &"costa": 26, &"herida": 30,
}
const MIN_BAG_ECOS := 12
const MAX_BAG_ECOS := 30

## Ecos del camino principal que cuestan los sumideros (árbol 1.800 + Garrán 150 +
## Cano 110 = 2.060) y margen del invariante: la suma bruta de Ecos del camino
## debe caer entre el 90 % y el 110 % de esa cifra.
const MAIN_PATH_SINKS := 2060
const BUDGET_MIN_RATIO := 0.90
const BUDGET_MAX_RATIO := 1.10
## Parte extra de Ecos de los enemigos por repetir rondas (la primera pasada + 10 %).
const ROUNDS_FACTOR := 1.10


## Ecos que da una Bolsa de la región `region` (0 si la región no existe).
static func bag_ecos(region: StringName) -> int:
	return BAG_ECOS_BY_REGION.get(region, 0)
