extends RefCounted
## Datos del árbol de habilidades del Caminante: tres ramas (Cuerpo, Filo, Espíritu),
## tres mejoras en cada una, y lo que da cada nivel. El árbol en sí es el componente
## genérico `SkillTree` (core/components/); aquí solo está lo propio de este juego.
##
## Las estadísticas base son las del personaje sin mejoras. Cada nivel suma (o resta)
## una cantidad fija; `stat()` da el valor resultante y `describe()` lo escribe para
## el menú. Un nivel cuesta lo que dice `costs` (en Ecos): conseguirlo todo cuesta
## muchos más de los que da una vida, así que hay que elegir.

const Stats := preload("res://game/player/stats.gd")

const BRANCHES := ["Cuerpo", "Filo", "Espíritu"]

const BASE_HEALTH := Stats.BASE_HEALTH
const BASE_FLASKS := 3
const BASE_DAMAGE := 1
const BASE_COOLDOWN := 0.30
const BASE_REACH := 20.0
const BASE_GUARD := 0.20
const BASE_DASH_COOLDOWN := 0.40
const BASE_INVULNERABILITY := 0.6
const BASE_PARRY_STUN := 0.0

const COOLDOWN_STEP := 0.04
const REACH_STEP := 6.0
const GUARD_STEP := 0.05
const DASH_STEP := 0.08
const INVULNERABILITY_STEP := 0.2
const PARRY_STUN_STEP := 0.5

## Total de Ecos de la tabla final (docs/nucleo-jugable.md): 14 mejoras, 29 niveles.
const FINAL_TOTAL_COST := 1800
## Mejoras de la tabla final cuyo efecto aún no existe (paquetes aparte). No están en
## `LIST`: no salen en el menú ni se pueden comprar. Aquí solo constan sus precios
## para que la suma con `LIST` dé `FINAL_TOTAL_COST`.
const PENDING_COSTS := {
	&"brasa": [160], &"castigo": [120], &"paso_fantasma": [60, 110], &"voz": [140],
}

## branch: columna; row: fila (de arriba a abajo); requires: mejora previa (al menos nivel 1).
const LIST := [
	{ id = &"vitalidad", branch = 0, row = 0, name = "Vitalidad", requires = &"", costs = [10, 25, 50, 85],
		text = "Más vida máxima: +1 por nivel." },
	{ id = &"frascos", branch = 0, row = 1, name = "Frascos", requires = &"vitalidad", costs = [30, 65],
		text = "Un frasco de curación más por nivel." },
	{ id = &"temple", branch = 0, row = 2, name = "Temple", requires = &"frascos", costs = [35, 60],
		text = "Tras un golpe, tardas más en volver a ser herido." },
	{ id = &"aliento", branch = 0, row = 3, name = "Aliento", requires = &"frascos", costs = [50, 100],
		text = "Cada frasco cura una vida más por nivel." },
	{ id = &"filo", branch = 1, row = 0, name = "Filo afilado", requires = &"", costs = [35, 110],
		text = "Más daño en cada golpe: +1 por nivel." },
	{ id = &"ritmo", branch = 1, row = 1, name = "Ritmo", requires = &"filo", costs = [20, 50, 90],
		text = "Golpeas más seguido: menos espera entre golpes." },
	{ id = &"alcance", branch = 1, row = 2, name = "Alcance", requires = &"ritmo", costs = [30, 55],
		text = "El golpe llega más lejos." },
	{ id = &"guardia", branch = 2, row = 0, name = "Guardia", requires = &"", costs = [15, 35, 65],
		text = "Más margen para desviar un golpe a tiempo." },
	{ id = &"impulso", branch = 2, row = 1, name = "Impulso", requires = &"guardia", costs = [25, 50],
		text = "Menos espera entre un dash y el siguiente." },
	{ id = &"contragolpe", branch = 2, row = 2, name = "Contragolpe", requires = &"impulso", costs = [40, 80],
		text = "Un golpe desviado deja al enemigo aturdido más tiempo." },
]


## Valor de la estadística que mejora `id` con el nivel `level`.
static func stat(id: StringName, level: int) -> float:
	match id:
		&"vitalidad":
			return Stats.max_health(BASE_HEALTH + level)
		&"frascos":
			return Stats.max_flasks(BASE_FLASKS + level)
		&"temple":
			return BASE_INVULNERABILITY + INVULNERABILITY_STEP * level
		&"aliento":
			return Stats.heal_amount(level)
		&"filo":
			return BASE_DAMAGE + level
		&"ritmo":
			return BASE_COOLDOWN - COOLDOWN_STEP * level
		&"alcance":
			return BASE_REACH + REACH_STEP * level
		&"guardia":
			return BASE_GUARD + GUARD_STEP * level
		&"impulso":
			return BASE_DASH_COOLDOWN - DASH_STEP * level
		&"contragolpe":
			return BASE_PARRY_STUN + PARRY_STUN_STEP * level
	return 0.0


## La estadística con su valor en el nivel `level`, escrita para el jugador.
static func describe(id: StringName, level: int) -> String:
	var value := stat(id, level)
	match id:
		&"vitalidad":
			# Sin cifra absoluta: la vida real también depende de los fragmentos.
			return "Vida máxima: +%d" % level
		&"frascos":
			return "Frascos: %d" % int(value)
		&"temple":
			return "Invulnerable tras un golpe: %s s" % _seconds(value)
		&"aliento":
			return "Cura por frasco: %d" % int(value)
		&"filo":
			return "Daño: %d" % int(value)
		&"ritmo":
			return "Espera entre golpes: %s s" % _seconds(value)
		&"alcance":
			return "Alcance del golpe: %d" % int(value)
		&"guardia":
			return "Margen del parry: %s s" % _seconds(value)
		&"impulso":
			return "Espera del dash: %s s" % _seconds(value)
		&"contragolpe":
			return "Aturdimiento extra: %s s" % _seconds(value)
	return ""


static func _seconds(value: float) -> String:
	return ("%.2f" % value).replace(".", ",")
