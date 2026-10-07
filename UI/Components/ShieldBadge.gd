# ShieldBadge.gd
# Ícone de escudo desenhado em pixels (grade de caracteres) + número da defesa.
# Sem textura externa: tudo vem de draw_rect.

class_name ShieldBadge
extends Control

const CELL := 3
# 1 = contorno, 2 = miolo, "." = vazio
const SHIELD_GRID: Array[String] = [
	"1111111",
	"1222221",
	"1222221",
	"1222221",
	".12221.",
	".12221.",
	"..121..",
	"...1...",
]

var value: int = 0


func _init() -> void:
	custom_minimum_size = Vector2(104, 28)
	size = custom_minimum_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	pivot_offset = size / 2.0


# Chamado quando a defesa muda; dá um "pulinho" em 2 passos secos.
func set_value(new_value: int) -> void:
	if new_value == value:
		return
	value = new_value
	queue_redraw()
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.05)


func _draw() -> void:
	# Plaquinha escura pra o escudo e o número lerem bem sobre a barra azul.
	draw_rect(Rect2(Vector2.ZERO, size), Palette.BORDER_DARK)
	draw_rect(Rect2(2, 2, size.x - 4, size.y - 4), Palette.PANEL_FILL)

	var origin := Vector2(7, 2)
	for y in SHIELD_GRID.size():
		var row: String = SHIELD_GRID[y]
		for x in row.length():
			var c := row[x]
			if c == ".":
				continue
			var col: Color = Palette.TEXT_LIGHT if c == "1" else Palette.DEF_BLUE
			draw_rect(Rect2(origin + Vector2(x, y) * CELL, Vector2(CELL, CELL)), col)
	# brilho no canto do escudo
	draw_rect(Rect2(origin + Vector2(1, 1) * CELL, Vector2(CELL, CELL * 2)), Palette.DEF_BLUE.lightened(0.5))

	var font := get_theme_default_font()
	var text := str(value)
	var text_pos := Vector2(34, 22)
	var text_w := size.x - 34.0 - 8.0
	draw_string_outline(font, text_pos, text, HORIZONTAL_ALIGNMENT_RIGHT, text_w, 26, 4, Palette.BORDER_DARK)
	draw_string(font, text_pos, text, HORIZONTAL_ALIGNMENT_RIGHT, text_w, 26, Palette.TEXT_LIGHT)
