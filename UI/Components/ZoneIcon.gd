# ZoneIcon.gd
# Ícone pixel de 9x9 pro título das zonas: caveira (ataque) ou escudo (defesa).
# Desenhado por código, sem textura.

class_name ZoneIcon
extends Control

const SKULL: Array[String] = [
	"..XXXXX..",
	".XXXXXXX.",
	"XXXXXXXXX",
	"XOOXXXOOX",
	"XOOXXXOOX",
	"XXXXOXXXX",
	".XXXXXXX.",
	"..XXXXX..",
	"..X.X.X..",
]
const SHIELD: Array[String] = [
	"XXXXXXXXX",
	"XSSSSSSSX",
	"XSHHSSSSX",
	"XSHSSSSSX",
	".XSSSSSX.",
	".XSSSSSX.",
	"..XSSSX..",
	"...XSX...",
	"....X....",
]

var kind: String = "attack"       # "attack" | "defense"


func _init() -> void:
	custom_minimum_size = Vector2(9, 9)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func setup(icon_kind: String) -> void:
	kind = icon_kind
	queue_redraw()


func _draw() -> void:
	var grid := SKULL if kind == "attack" else SHIELD
	var colors := {"X": Palette.BONE, "O": Palette.BG_DEEP} if kind == "attack" \
			else {"X": Palette.TEXT_LIGHT, "S": Palette.DEF_BLUE, "H": Palette.DEF_BLUE.lightened(0.5)}
	for j in grid.size():
		var row: String = grid[j]
		for i in row.length():
			var ch := row[i]
			if colors.has(ch):
				draw_rect(Rect2(i, j, 1, 1), colors[ch])
